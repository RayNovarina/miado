require 'slack-ruby-client'
# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module TeamExtensions
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
    #-------------------- For omniauth support ----------------------

    # If source = :omniauth_callback, then data = response environment
    def find_or_create_from(source, data)
      @provider = data
      return find_or_create_from_omniauth_provider if source == :omniauth_provider
    end

    def find_or_create_from_omniauth_provider
      find_by_provider.first || create_from_provider
    end

    def find_by_provider
      Team.where(slack_team_id: make_auth_info[:raw_info]['team_id'])
    end

    def create_from_provider
      make_auth_info
      # create_from_provider_auth_info
      create_from_slack_web_api
    end

    private

    # The omniauth-slack gem returns standard info in the environment. We save
    # that json info off in the db.
    def make_auth_info
      @auth_hash = {
        auth: @provider.auth_json,
        team_info: @provider.auth_json['extra']['team_info'],
        raw_info: @provider.auth_json['extra']['raw_info'],
        bot_info: @provider.auth_json['extra']['bot_info']
      }
    end

    def create_from_provider_auth_info
      Team.create!(
        name: @auth_hash[:raw_info]['team'],
        url: @auth_hash[:raw_info]['url'],
        slack_team_id: @auth_hash[:raw_info]['team_id'],
        api_token: @auth_hash[:auth]['credentials']['token'],
        bot_user_id: @auth_hash[:bot_info]['bot_user_id'],
        bot_access_token: @auth_hash[:bot_info]['bot_access_token'],
        user: @provider.user)
    end

    def create_from_slack_web_api
      # @web_client ||= make_web_client
      # response has name of member installing slack app.
      # resp_auth_test = @web_client.auth_test
      # install_member_name = resp_auth_test['user']
      # install_member_slack_id = resp_auth_test['user_id']
      # install_member_team_url = resp_auth_test['url']
      # response has name of team, team.id
      # resp_team = @web_client.team_info['team']
      # team_id = resp_team['id']
      # team_name = resp_team['name']
      # team_icon_88 = resp_team['icon']['image_88']
      # response has name and id of each team member.
      # resp_team_members = @web_client.users_list['members']
      # response has name and id of every channel for this team.
      # resp_team_channels = @web_client.channels_list['channels']
      Team.create!(
        name: @auth_hash[:raw_info]['team'],
        url: @auth_hash[:raw_info]['url'],
        slack_team_id: @auth_hash[:raw_info]['team_id'],
        api_token: @auth_hash[:auth]['credentials']['token'],
        bot_user_id: @auth_hash[:bot_info]['bot_user_id'],
        bot_access_token: @auth_hash[:bot_info]['bot_access_token'],
        user: @provider.user
      # members: Member.create_from_slack_web_api(resp_team_members, resp_team_channels)
      )
    end

    def make_web_client
      Slack.configure do |config|
        config.token = @auth_hash[:auth]['credentials']['token']
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
