# per: https://richonrails.com/articles/rails-4-code-concerns-in-active-record-models
module UserExtensions
  extend ActiveSupport::Concern
  #
  included do
    # The code contained within the included block will be executed within the
    # context of the class that is including the module. This is perfect for
    # including functionality provided by 3rd party gems, etc.
    # Example:
    # has_secure_password
  end
  #
  #======== CLASS METHODS, i.e. User.authenticate()
  #
  # The code contained within this block will be added to the Class itself.
  # For example, the code above adds an authenticate function to the User class.
  # This allows you to do User.authenticate(email, password) instead of
  # User.find_by_email(email).authenticate(password).
  module ClassMethods
    #
    # Note: include helper methods for all models, such as return_view_hash_of.
    # include ModelHelper # /models/concerns/model_helper.rb
    #
    #-------------------- For Devise and omniauth support ----------------------
    # per: https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
    #
    def from_omniauth(auth, params)
      provider = get_or_create_from_omniauth(auth, params)
      # Return authenticated oauth User with current auth callback info.
      provider.auth_json = auth
      provider.auth_params_json = params
      provider.save!
      provider
    end

    private

    # IF we allow multiple oath login providers, i.e. login with GitHub and
    # Gmail, then we need a OmniAuthProviders model with provider, uid and
    # auth_token fields. To find the user, first query the Providers model for
    # the provider/uid.
    def get_or_create_from_omniauth(auth, params)
      if (provider = OmniauthProvider.where(name: auth.provider,
                                            uid: auth.uid).first).nil?
        # We have not authenticated this oauth user before.
        if (user = User.where(email: auth.info.email.downcase).first).nil?
          # We don't have this oauth user currently in our db. i.e. they haven't
          # authenticated with another provider already or have logged in with
          # username/password manually before.
          user = make_new_oauth_user(auth, params)
        end
        # We have the oauth user in our db, make sure provider, providerId,
        # name, email addr are all in our db.
        provider = OmniauthProvider.create(
          name: auth.provider,
          uid: auth.uid,
          auth_token: auth.credentials[:token])
        user.omniauth_providers << provider
      end
      provider
    end

    def make_new_oauth_user(auth, _params)
      User.create!(email: auth.info.email.downcase,
                   password: 'password',
                   name: auth.info.name)
    end
    #
  end # module ClassMethods

  #
  #======== INSTANCE METHODS, i.e. User.find_by(1).create_password_token()
  #
  # Code not included in the ClassMethods block or the included block will be
  # included as instance methods.
  # For example, You could do @user = User.find(params[:id]) and then do
  #                           @user.create_password_reset_token
  # to create a password reset token for the specified user.
  #
  # def create_password_reset_token
  #   self.password_reset_token = 123
  # end
  #
  # The liked? method will let you know if a given user has liked a bookmark
  # def liked?(bookmark)
  #  Like.where(bookmark_id: bookmark.id).first
  # end
end # module UserExtensions
