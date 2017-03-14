#
class Users::SessionsController < Devise::SessionsController
  before_action :make_view_helper
  # before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # IF a http GET, then we want a sign in page or oauth permissions page.
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
    # else fall thru to devise users/sessions/new and render the
    # views/users/sessions/new.html.erb page
  end

  # POST /resource/sign_in
  # def create
  # end

  # DELETE /resource/sign_out
  # def destroy
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.for(:sign_in) << :attribute
  # end

  # NOTE: after_sign_out_path_for and after_sign_in_path_for MOVED to
  # applicationController because omniauth sign_in_and_redirect methods
  # uses the devise gem methods and not the users/sessions_controller
  # methods i modified.
  # There exists a similar method for sign in; after_sign_in_path_for
  # def after_sign_out_path_for(_resource_or_scope)
  #  # Note: at this time: flash[:notice] => "Signed out successfully."
  #  #                     current_user is nil.
  #  new_user_session_path # signIn page
  # end

  # def after_sign_in_path_for(_resource_or_scope)
  #  # Note: at this time: flash[:notice] => "Signed in successfully."
  #  #                     current_user is valid.
  #  # user_path(@view.current_user) # users#show
  #  # registered_applications_path # registered_applications#index
  #  if @view.flash_messages.key?(:notice) &&
  #     @view.flash_messages[:notice] == 'Signed in successfully.'
  #    # Our view makes up it own welcome msg.
  #    @view.flash_messages[:notice] = ''
  #  end
  #  welcome_back_path
  # end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, resource || User.new)
  end
end
