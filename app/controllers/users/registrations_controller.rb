#
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :make_view_helper
  before_filter :configure_sign_up_params, only: [:create]
  before_filter :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # IF a http GET, then we want a sign up page or oauth permissions page.
  def new
    if params.key?('oauth')
      # if oauth we want to auto start a login.
      # per: https://github.com/plataformatec/devise/blob/master/CHANGELOG.md
      #      4.0.0.rc2 - 2016-03-09
      #      deprecations
      #         omniauth routes are no longer defined with a wildcard
      #         :provider parameter, and provider specific routes are defined
      #         instead, so route helpers
      #         like user_omniauth_authorize_path(:github) are deprecated in
      #         favor of user_github_omniauth_authorize_path. You can still use
      #         omniauth_authorize_path(:user, :github) if you need to call the
      #         helpers dynamically.
      # redirect_to user_omniauth_authorize_path(
      redirect_to omniauth_authorize_path(
        :user,
        params[:oauth].to_sym,
        state: 'sign_up')
      return
    end
    super
    # else name/pwd, drop thru to views/reg/new
  end

  # POST /resource
  # def create
  # end

  # GET /resource/edit
  # def edit
  # end

  # PUT /resource
  # def update
  # end

  # DELETE /resource
  # def destroy
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.for(:sign_up) << :name
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.for(:account_update) << :name
  end

  # The path used after sign up.
  def after_sign_up_path_for(_resource)
    # Note: at this time: current_user is valid.
    if @view.flash_messages.key?(:notice) &&
       @view.flash_messages[:notice] == 'Welcome! You have signed up successfully.'
      # Our view makes up it own welcome msg for new users.
      @view.flash_messages[:notice] = ''
    end
    welcome_new_path
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, resource || User.new)
  end
end
