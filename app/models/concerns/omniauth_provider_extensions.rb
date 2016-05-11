# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module OmniauthProviderExtensions
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

    # If source = :omniauth_callback, then data = response environment.
    # Note: we are using omniauth-slack at
    #       https://github.com/kmrshntr/omniauth-slack for a ruby oauth lib.
    #       It stores oauth info in the environment, which is accessed via
    #       request.env
    def find_or_create_from(source, data)
      return find_or_create_from_omniauth_callback(data) if source == :omniauth_callback
    end

    def update_from_or_create_from(source, data)
      return update_from_or_create_from_omniauth_callback(data) if source == :omniauth_callback
    end

    def find_from(source, data)
      return find_from_omniauth_callback(data) if source == :omniauth_callback
    end

    private

    def find_or_create_from_omniauth_callback(response_env)
      if (provider = find_from_omniauth_callback(response_env)).nil?
        # Case: We have not authenticated this oauth user before.
        provider = create_from_omniauth_callback(response_env)
      end
      provider
    end

    def update_from_or_create_from_omniauth_callback(response_env)
      auth, auth_params = auth_info_from_env(response_env)
      # Case: We have not authenticated this oauth user before.
      return create_from_oauth(auth, auth_params) if (provider = find_by_oauth(auth).first).nil?
      # Case: We are reauthorizing. Update auth info.
      update_provider_auth_info(provider, auth, auth_params)
      provider.save!
      # Return oauth provider with current auth callback info
      provider
    end

    def find_from_omniauth_callback(response_env)
      auth, _auth_params = auth_info_from_env(response_env)
      find_by_oauth(auth).first
    end

    def auth_info_from_env(response_env)
      [response_env['omniauth.auth'],
       response_env['omniauth.params']
      ]
    end

    def find_by_oauth(auth)
      OmniauthProvider.where(name: auth.provider, uid: auth.uid)
    end

    def create_from_omniauth_callback(response_env)
      auth, auth_params = auth_info_from_env(response_env)
      provider = create_from_oauth(auth, auth_params)
      update_provider_auth_info(provider, auth, auth_params)
      provider.save!
      # Return oauth provider with current auth callback info
      provider
    end

    def create_from_oauth(auth, auth_params)
      provider = OmniauthProvider.create!(
        name: auth.provider,
        uid: auth.uid
      )
      update_provider_auth_info(provider, auth, auth_params)
      provider.save!
      provider
    end

    def update_provider_auth_info(provider, auth, auth_params)
      provider.auth_json = auth
      provider.auth_params_json = auth_params
      provider.uid_email = auth.info.email
      provider.uid_name = auth.info.name.empty? ? auth.info.user : auth.info.name
      provider.auth_token = auth.credentials[:token]
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
