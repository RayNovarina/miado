#
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Implemented per: https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
  # Flow is generally the same for all. But customize as needed here.

  def slack
    @provider = provider_from_omniauth_callback
    @user = @provider.user
    sign_in_omniauth_user
  end

  def github
    @provider = provider_from_omniauth_callback
    @user = @provider.user
    sign_in_omniauth_user
  end

  def google_oauth2
    @provider = provider_from_omniauth_callback
    require 'pry'
    binding.pry
    @user = @provider.user
    sign_in_omniauth_user
  end

  def failure
    super
    redirect_to :back
  end

  private

  def provider_from_omniauth_callback
    User.from_omniauth(request.env['omniauth.auth'],
                       request.env['omniauth.params'])
  end

  def sign_in_omniauth_user
    # Note: sign_in_and_redirect method is at:
    # .rvm/gems/ruby-2.3.0/gems/devise-3.5.6/lib/devise/controllers/helpers.rb
    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: @provider.name.capitalize) if is_navigational_format?
  end

  #
  # You should also create an action method in this controller like this:
  # def twitter
  # end

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
