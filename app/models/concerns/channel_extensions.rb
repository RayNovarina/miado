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
    # channel = Channel.find_or_create_from_slack(@view, name)
    # Find the slack channel in our db or get a current Team channel list from
    # Slack and merge those into our db.
    # find_or_create_from_slack(params[:user_id], params[:team_id], params[:channel_id])
    def find_or_create_from_slack(view, slack_user_id, slack_team_id, slack_channel_id)
      @view ||= view
      if (channel = find_from_slack(view, slack_user_id, slack_team_id, slack_channel_id)).nil?
        channel = create_from_slack(view, slack_user_id, slack_team_id)
      end
      channel
    end

    def find_from_slack(view, slack_user_id, slack_team_id, slack_channel_id)
      @view ||= view
      Channel.where(slack_user_id: slack_user_id,
                    slack_team_id: slack_team_id,
                    slack_channel_id: slack_channel_id).first
    end

    def create_from_slack(view, _slack_user_id, _slack_team_id)
      @view ||= view
      # we could create channel and copy members_hash from last active channel
      # for this team. Else we need to mimic an install and create a miado user,
      # team, members, channels.
      # create_all_from_slack(@view, slack_user_id, slack_team_id)
      # find_from_slack(view, slack_user_id, slack_team_id, slack_channel_id)
      nil
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
          "api_token: #{api_token}\n"
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
