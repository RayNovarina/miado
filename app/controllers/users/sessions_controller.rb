require 'slack-notifier'
#
class Users::SessionsController < Devise::SessionsController
  before_action :make_view_helper
  # before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # IF a http GET, then we want a sign in page or oauth permissions page.
  def new
    if params.key?('oauth')
      notifier = Slack::Notifier.new(
        'https://hooks.slack.com/services/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')
      notifier.username = 'ray'
      notifier.channel = '#random'
      notifier.ping 'Hello World from sessions_controller.rb.'

      client = Slack::Web::Client.new
      client.auth_test
      client.chat_postMessage(
        channel: '#general',
        text: 'Hello from slack ruby client gem in sessions_controller/sign_in',
        as_user: true)
      channels = client.channels_list.channels
      text = ''
      channels.each_with_index do |c, index|
        text.concat("[#{index}] #{c.name.capitalize}/n")
      end
      client.chat_postMessage(
        channel: '#general',
        text: text,
        as_user: true)

      # if oauth we want to auto start a login.
      redirect_to user_omniauth_authorize_path(
        params[:oauth].to_sym,
        state: 'sign_in')
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
