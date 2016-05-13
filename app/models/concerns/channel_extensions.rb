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
    def find_or_create_from_slack_id(view, slack_channel_id, slack_team_id)
      @view ||= view
      channel = Channel.where(slack_id: slack_channel_id).first
      return channel unless channel.nil?
      create_from_slack_id(view, slack_channel_id, slack_team_id)
    end

    def create_from_slack_id(view, slack_channel_id, slack_team_id)
      @view ||= view
      create_all_from_slack(@view, slack_team_id)
      Channel.where(slack_id: slack_channel_id).first
    end

    def create_all_from_slack(view, slack_team_id)
      @view ||= view
      @view.team ||= Team.find_or_create_from(:slack_id, slack_team_id)
      return [] if @view.team.nil?
      slack_team_channels = slack_team_channels_from_rtm_data(@view)
      slack_team_channels.each do |team_channel|
        # next if team_channel[:is_archived]
        Channel.find_or_create_by(
          name: team_channel[:name],
          slack_id: team_channel[:id],
          archived: team_channel[:is_archived],
          team: @view.team
        )
      end
      slack_dm_channels = slack_dm_channels_from_rtm_data(@view)
      slack_dm_channels.each do |im|
        # next if im[:is_user_deleted]
        Channel.find_or_create_by(
          name: im[:user],
          slack_id: im[:id],
          is_im_channel: true,
          deleted: im[:is_user_deleted],
          dm_user_id: im[:user],
          team: @view.team
        )
      end
      Channel.all
    end

    def all_or_create_all_from_slack(view)
      @view ||= view
      return Channel.all if Channel.count > 0
      create_all_from_slack(@view)
      Channel.all
    end

    private

    def slack_team_channels_from_rtm_data(view)
      @view ||= view
      @view.web_client ||= make_web_client
      # response is an array of hashes. Each has name and id of a team channel.
      @view.web_client.channels_list['channels']
    end

    def slack_dm_channels_from_rtm_data(view)
      @view ||= view
      @view.web_client ||= make_web_client
      # response is an array of hashes. Each has name and id of a team channel.
      @view.web_client.im_list['ims']
    end

    def make_web_client
      # Slack.config.token = 'xxxxx'
      Slack.configure do |config|
        config.token = @view.team.api_token
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
