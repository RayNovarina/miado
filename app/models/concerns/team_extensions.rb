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
      return find_or_create_from_omniauth_provider(data) if source == :omniauth_provider
      return find_or_create_from_slack_id(data) if source == :slack_id
    end

    def find_or_create_from_omniauth_provider(provider)
      find_by_provider(provider).first || create_from_provider(provider)
    end

    def find_by_provider(provider)
      Team.where(slack_team_id: make_auth_info(provider)[:raw_info]['team_id'])
    end

    def create_from_provider(provider)
      # create_from_provider_auth_info(provider, make_auth_info(provider))
      create_from_slack_web_api(provider, make_auth_info(provider))
    end

    def find_or_create_from_slack_id(slack_team_id)
      Team.where(slack_team_id: slack_team_id).first
    end

    # If source = :omniauth_callback, then data = response environment
    def update_from_or_create_from(source, data)
      return update_from_or_create_from_omniauth_provider(data) if source == :omniauth_provider
    end

    def update_from_or_create_from_omniauth_provider(provider)
      # Case: We have not authenticated this team before.
      return create_from_provider(provider) if (team = find_by_provider(provider).first).nil?
      # Case: We are reauthorizing. Update auth info.
      update_team_auth_info(team, make_auth_info(provider))
      team.save!
      team
    end

    private

    # The omniauth-slack gem returns standard info in the environment. We save
    # that json info off in the db.
    def make_auth_info(provider)
      { auth: provider.auth_json,
        team_info: provider.auth_json['extra']['team_info'],
        raw_info: provider.auth_json['extra']['raw_info'],
        bot_info: provider.auth_json['extra']['bot_info']
      }
    end

    def create_from_provider_auth_info(provider, auth_hash)
      team =
        Team.create!(
          name: auth_hash[:raw_info]['team'],
          user: provider.user
        )
      update_team_auth_info(team, auth_hash)
      team.save!
      team
    end

    def update_team_auth_info(team, auth_hash)
      team.url = auth_hash[:raw_info]['url']
      team.slack_team_id = auth_hash[:raw_info]['team_id']
      team.api_token = auth_hash[:auth]['credentials']['token']
      team.bot_user_id = auth_hash[:bot_info]['bot_user_id']
      team.bot_access_token = auth_hash[:bot_info]['bot_access_token']
    end

    def create_from_slack_web_api(provider, auth_hash)
      # @web_client ||= make_web_client(auth_hash[:auth]['credentials']['token'])
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
      team =
        Team.create!(
          name: auth_hash[:raw_info]['team'],
          user: provider.user
          # members: Member.create_from_slack_web_api(resp_team_members, resp_team_channels)
        )
      update_team_auth_info(team, auth_hash)
      team.save!
      team
    end

    def make_web_client(auth_token)
      Slack.configure do |config|
        config.token = auth_token
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
