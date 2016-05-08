#
class ApplicationController < ActionController::Base
  before_action :make_view_helper
  # Use Pundit for authorization/permissions.
  include Pundit
  # Customize the user_not_authorized method in every controller.
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  #============== DEVISE Authentication gem related ===========================
  # per doc at: https://github.com/plataformatec/devise#getting-started
  # Most devise helpers for views and controllers are found in sources at:
  #   gems/devise-3.5.6/lib/devise/controllers/helpers.rb
  #   I generated copies of the devise controllers to /app/controllers/users
  #   and set the sign_in and sign_out paths, added name to sign_up page, etc.
  #
  #   after_sign_out_path_for method in
  #       controllers/users/sessions_controller.rb
  #   after_sign_up_path_for method in
  #       controllers/users/sessions_controller.rb
  #   Added name to configure_sign_up_params at
  #      controllers/users/registrations_controller.rb
  #   Added name to configure_account_update_params at
  #      controllers/users/registrations_controller.rb
  #   If name added to sign_in form, add name to configure_sign_in_params at
  #       controllers/users/sessions_controller.rb

  def after_sign_in_path_for(_resource_or_scope)
    # Note: at this time: flash[:notice] => "Signed in successfully."
    #                     current_user is valid.
    # user_path(@view.current_user) # users#show
    # registered_applications_path # registered_applications#index
    if @view.nil?
      # we seem to get here in a dev environment if we haven't signed out the
      # previous session/loaded new dev app.
      return root_path
    end
    if @view.flash_messages.key?(:notice) &&
       @view.flash_messages[:notice] == 'Signed in successfully.'
      # Our view makes up it own welcome msg.
      @view.flash_messages[:notice] = ''
    end
    return omniauth_landing_page if @view.controller.is_a?(Devise::OmniauthCallbacksController)
    return users_path if @view.current_user.admin?
    welcome_back_path
  end

  # There exists a similar method for sign in; after_sign_in_path_for
  def after_sign_out_path_for(_resource_or_scope)
    # require 'pry'
    # binding.pry
    # Note: at this time: flash[:notice] => "Signed out successfully."
    #                     current_user is nil.
    new_user_session_path # signIn page
  end

  private

  def make_view_helper
    @view = ApplicationHelper::View.new(self, resource || User.new)
  end

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || root_path)
  end

  def omniauth_landing_page
    # Got here via oauth callback after sign_up or sign_in.
    auth_action = @view.provider.auth_params_json['state']
    if auth_action == 'sign_up'
      # return welcome_add_to_slack_new_path if @view.provider.name == 'slack'
      if @view.provider.name == 'slack'
        return welcome_add_to_slack_new_path(
          team_id: @view.provider.auth_json['info']['team_id'])
      end
      welcome_new_path
    else # auth_action == 'sign_in'
      welcome_back_path
    end
  end
end
