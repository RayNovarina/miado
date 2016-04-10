# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module RegisteredTeamExtensions
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
    end

    def find_or_create_from_omniauth_provider(provider)
      find_by_provider(provider).first || create_from_provider(provider)
    end

    def find_by_provider(provider)
      @auth_hash ||= make_auth_info(provider)
      RegisteredTeam.where(slack_team_id: @auth_hash[:raw_info]['team_id'])
      # RegisteredTeam.where(user_id: provider.user.id,
      #                      slack_team_id: @auth_hash[:raw_info]['team_id'],
      #                      bot_user_id: @auth_hash[:bot_info]['bot_user_id'])
    end

    def create_from_provider(provider)
      @auth_hash ||= make_auth_info(provider)
      RegisteredTeam.create!(
        name: @auth_hash[:raw_info]['team'],
        url: @auth_hash[:raw_info]['url'],
        slack_team_id: @auth_hash[:raw_info]['team_id'],
        api_token: @auth_hash[:auth]['credentials']['token'],
        bot_user_id: @auth_hash[:bot_info]['bot_user_id'],
        bot_access_token: @auth_hash[:bot_info]['bot_access_token'],
        user: provider.user
      )
    end

    private

    def make_auth_info(provider)
      info = { auth: provider.auth_json }
      info[:team_info] = info[:auth]['extra']['team_info']
      info[:raw_info] = info[:auth]['extra']['raw_info']
      info[:bot_info] = info[:auth]['extra']['bot_info']
      info
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
