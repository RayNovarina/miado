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

    # If source = :omniauth_callback, then data = OmniAuthProvider
    def find_or_create_from(source, data)
      return find_or_create_from_omniauth_provider(data) if source == :omniauth_provider
    end

    def find_from(source, data)
      return find_from_omniauth_provider(data) if source == :omniauth_provider
    end

    private

    def find_or_create_from_omniauth_provider(provider)
      return provider.user unless provider.user.nil?
      # We have not authenticated with this oauth server for the oauth user
      # before. But we may have already created a user via a email/pwd sign-up.
      if (user = User.where(email: provider.uid_email.downcase).first).nil?
        user = create_from_omniauth_provider(provider)
      end
      # We have the user, link it to the OmniauthProvider.
      provider.user = user
      provider.save!
      # And link the OmniauthProvider to the user.
      user.omniauth_providers << provider
      user.save!
      user
    end

    def find_from_omniauth_provider(provider)
      provider.user
    end

    def create_from_omniauth_provider(provider)
      User.create!(email: provider.uid_email.downcase,
                   password: 'password',
                   name: provider.uid_name)
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
