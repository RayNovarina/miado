#
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_action :make_view_helper
  # Implemented per: https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
  # Note: we get here here when the user has finished with the oauth provider's
  # permission page and the oauth provider uses the "redirect uri" we set when
  # we configured our app. I.e. Slack redirects to /users/auth/slack/callback
  # which is mapped to the following route:
  # Rails route path: "user_omniauth_callback"
  #  url: POST /users/auth/:action/callback(.:format)
  #  Rails controller#action:
  #    users/omniauth_callbacks#(?-mix:github|slack|google_oauth2)
  # Sooo.... /users/auth/slack/callback -->
  #   OmniauthCallbacksController.slack method below.

  # Flow is generally the same for all. But customize as needed here.
  def slack
    sign_in_omniauth_user
  end

  def github
    sign_in_omniauth_user
  end

  def google_oauth2
    sign_in_omniauth_user
  end

  def failure
    redirect_to :back
  end

  private

  def sign_in_omniauth_user
    # IF we allow multiple oath login providers, i.e. login with GitHub and
    # Gmail, then we need a OmniAuthProviders model with provider, uid and
    # auth_token fields. To find the user, first query the Providers model for
    # the provider/uid.
    # Note: we are using omniauth-slack at
    #       https://github.com/kmrshntr/omniauth-slack for a ruby oauth lib.
    #       It stores oauth info in the environment, which is accessed via
    #       request.env
    # Note: we use the update_from methods so as to update existing providers
    #       or teams if we are reauthorizing a registered team.
    @view.provider = OmniauthProvider.update_from_or_create_from(:omniauth_callback, request.env)
    @view.user = User.find_or_create_from(:omniauth_provider, @view.provider)
    @view.team = Team.update_from_or_create_from(:omniauth_provider, @view.provider)
    #
    # Note: sign_in_and_redirect method is at:
    # .rvm/gems/ruby-2.3.0/gems/devise-3.5.6/lib/devise/controllers/helpers.rb
    # It will finally redirect via "redirect_to after_sign_in_path_for(User)"
    # which we handle in our /controllers/application_controller
    # "after_sign_in_path_for(_resource_or_scope)" method which finally
    # redirects a welcome aboard landing page.
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
