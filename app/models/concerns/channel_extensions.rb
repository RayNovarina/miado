require 'slack-ruby-client'
# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module ChannelExtensions
  extend ActiveSupport::Concern
  #
  included do
    # see user_extensions.rb for usage.
  end
  #
  #======== CLASS METHODS, i.e. User.authenticate()
  #
  # The code contained within this block will be added to the Class itself.
  # For example, the code above adds an authenticate function to the User class.
  # This allows you to do User.authenticate(email, password) instead of
  # User.find_by_email(email).authenticate(password).
  module ClassMethods
    attr_accessor :view

    def find_from_slack(view, slack_user_id, slack_team_id, slack_channel_id)
      @view ||= view
      Channel.where(slack_user_id: slack_user_id,
                    slack_team_id: slack_team_id,
                    slack_channel_id: slack_channel_id).first
    end
=begin
      Form Params
      channel_id	C0VNKV7BK
      channel_name	general
      command	/do
      response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
      team_domain	shadowhtracteam
      team_id	T0VN565N0
      text	call GoDaddy @susan /fri
      token	3ZQVG7rk4p7EZZluk1gTH3aN
      user_id	U0VLZ5P51
      user_name	ray
=end
    def create_from_slack(view, slash_url_params)
      @view ||= view
      # we could create channel and copy members_hash from last active channel
      # for this team. Else we need to mimic an install and create a miado user,
      # team, members, channels.
      # team = Team.find_from_slack(:slack,
      #                            slack_team_id: slash_url_params['team_id'],
      #                            slack_user_id: slash_url_params['user_id'])
      # return nil if team.nil?
      # Get a members lookup hash from another member's channel.
      other_member_channel =
        Channel.where(slack_team_id: slash_url_params['team_id']).first
      return nil if other_member_channel.nil?
      Channel.create!(
        slack_channel_name: slash_url_params['channel_name'],
        slack_channel_id: slash_url_params['channel_id'],
        slack_user_id: slash_url_params['user_id'],
        slack_team_id: slash_url_params['team_id'],
        slack_user_api_token: other_member_channel.slack_user_api_token,
        bot_api_token: other_member_channel.bot_api_token,
        bot_user_id: other_member_channel.bot_user_id,
        members_hash: other_member_channel.members_hash,
        team: other_member_channel.team
      )
    end

    def create_all_from_slack(view, team)
      @view ||= view
      @view.web_client = make_web_client(team.api_token)
      slack_team_channels = slack_team_channels_from_rtm_data
      slack_team_channels.each do |team_channel|
        next if team_channel[:is_archived]
        Channel.find_or_create_by(
          archived: team_channel[:is_archived],
          slack_channel_name: team_channel[:name],
          slack_channel_id: team_channel[:id],
          slack_user_id: team.slack_user_id,
          slack_team_id: team.slack_team_id,
          slack_user_api_token: team.api_token,
          bot_api_token: team.bot_access_token,
          bot_user_id: team.bot_user_id,
          # Note: members hash created separately via
          #       Member.update_or_create_all_members_hash when all are known.
          team: team
        )
      end
      bot_dm_channel_id = nil
      slack_dm_channels = slack_dm_channels_from_rtm_data
      slack_dm_channels.each do |im|
        next if im[:is_user_deleted]
        Channel.find_or_create_by(
          deleted: im[:is_user_deleted],
          dm_user_id: im[:user],
          slack_channel_name: nil,
          slack_channel_id: im[:id],
          slack_user_id: team.slack_user_id,
          slack_team_id: team.slack_team_id,
          slack_user_api_token: team.api_token,
          bot_api_token: team.bot_access_token,
          bot_user_id: team.bot_user_id,
          # Note: members hash created separately via
          #       Member.update_or_create_all_members_hash when all are known.
          team: team
        )
        bot_dm_channel_id = im[:id] if im[:user] == team.bot_user_id
      end
      bot_dm_channel_id
    end

    def create_from_slack_url_params(view)
      @view ||= view
      url_params = view.url_params
      Channel.create!(
        name: url_params[:channel_name],
        slack_id: url_params[:channel_id],
        is_im_channel: url_params[:channel_name] == 'directmessage',
        dm_user_id: nil,
        team: view.team
      )
    end

    def all_or_create_all_from_slack(view)
      @view ||= view
      return Channel.all if Channel.count > 0
      create_all_from_slack(@view)
      Channel.all
    end

    def update_or_create_all_members_hash(view, slack_team_id)
      @view ||= view
      # Build a hash to be used by our slash commands to verify mentioned
      # members and to lookup api info about em.
      # We now know the taskbot dm channel id for the installing member.
      members_hash = {}
      # Get all installations for this Slack team.
      Team.where(slack_team_id: slack_team_id).each do |team|
        # Get member records for all known team members.
        team.members.each do |member|
          unless members_hash[member.slack_user_id].nil?
            # We have already seen this member. Part of another installation for
            # this team. Skip it unless it installed the bot and has a dm id.
            next if member.bot_dm_channel_id.nil?
          end
          m_hash = {
            slack_user_name: member.name,
            slack_real_name: member.real_name,
            slack_user_id: member.slack_user_id,
            slack_user_api_token: team.api_token,
            bot_user_id: team.bot_user_id,
            # Note: the bot_dm_channel_id is only present on a Member record
            #       when the member installs the bot. Else it is nil when
            #       someone else is installing.
            bot_dm_channel_id: member.bot_dm_channel_id,
            bot_api_token: team.bot_access_token
          }
          members_hash[member.name] = m_hash
          members_hash[member.slack_user_id] = m_hash
        end
      end
      # Channels for this team gets an updated member lookup hash.
      Channel.where(slack_team_id: slack_team_id).update_all(members_hash: members_hash)
      members_hash
    end

    private

    def slack_team_channels_from_rtm_data
      # response is an array of hashes. Each has name and id of a team channel.
      begin
        return @view.web_client.channels_list['channels']
      rescue Slack::Web::Api::Error => e
        @view.web_client.logger.error e
        @view.web_client.logger.error "\ne.message: #{e.message}\n" \
          "@view.team - name: #{@view.team.name}" \
          "api_token: #{Slack.config.token}\n"
        @view.exception = e
        return []
      end
    end

    def slack_dm_channels_from_rtm_data
      # response is an array of hashes. Each has name and id of a team channel.
      @view.web_client.im_list['ims']
    end

    def make_web_client(api_token)
      # Slack.config.token = 'xxxxx'
      Slack.configure do |config|
        config.token = api_token
      end
      Slack::Web::Client.new
    end
    #
  end # module ClassMethods

  #
  #======== INSTANCE METHODS, i.e. User.find_by(1).create_password_token()
  #
  # Code not included in the ClassMethods block or the included block will be
  # included as instance methods.
  # see user_extensions.rb for usage.
end # module UserExtensions
