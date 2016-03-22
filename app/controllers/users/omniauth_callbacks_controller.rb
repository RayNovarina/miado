#
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_action :make_view_helper
  # Implemented per: https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
  # Flow is generally the same for all. But customize as needed here.

  def slack
    @view.provider = provider_from_omniauth_callback
    @view.user = @view.provider.user
    sign_in_omniauth_user
  end

  def github
    @view.provider = provider_from_omniauth_callback
    @view.user = @view.provider.user
    sign_in_omniauth_user
  end

  def google_oauth2
    @view.provider = provider_from_omniauth_callback
    @view.user = @view.provider.user
    sign_in_omniauth_user
  end

  def failure
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
    sign_in_and_redirect @view.user, event: :authentication
    set_flash_message(:notice, :success, kind: @view.provider.name.capitalize) if is_navigational_format?
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, resource || User.new)
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
