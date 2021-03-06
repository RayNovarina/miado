=begin
per: http://stackoverflow.com/questions/25841377/rescue-from-actioncontrollerroutingerror-in-rails4
application_conroller.rb add the following:

 # You want to get exceptions in development, but not in production.
 unless Rails.application.config.consider_all_requests_local
   rescue_from ActionController::RoutingError, with: -> { render_404  }
 end

 def render_404
   respond_to do |format|
     format.html { render template: 'errors/not_found', status: 404 }
     format.all { render nothing: true, status: 404 }
   end
 end
I usually also rescue following exceptions, but that's up to you:

rescue_from ActionController::UnknownController, with: -> { render_404  }
rescue_from ActiveRecord::RecordNotFound, with: -> { render_404  }
Create the errors controller:

class ErrorsController < ApplicationController
 def error_404
   render 'errors/not_found'
 end
end
Then in routes.rb

 unless Rails.application.config.consider_all_requests_local
   # having created corresponding controller and action
   get '*not_found', to: 'errors#error_404'
 end
And the last thing is to create not_found.html.haml (or whatever template engine you use) under /views/errors/:

 %span 404
 %br
 Page Not Found
=end

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
    # Note: at this time: flash[:notice] => "Signed in successfully." (or nil)
    #                     current_user is valid.
    if @view.nil?
      # we seem to get here in a dev environment if we haven't signed out the
      # previous session/loaded new dev app.
      return root_path
    end
    # Case: oauth sign_in or sign_up
    return after_sign_in_path_for_omniauth_callback if @view.controller.is_a?(Devise::OmniauthCallbacksController)
    # Case: admin login. users_path => "/users"
    return users_path if @view.current_user.admin?
    # Case: Manual login.
    if @view.flash_messages.key?(:notice) &&
       @view.flash_messages[:notice] == 'Signed in successfully.'
      # Our view makes up it own welcome msg.
      @view.flash_messages[:notice] = ''
    end
    # Flash msgs are filled in.
    welcome_back_path
  end

  # There exists a similar method for sign in; after_sign_in_path_for
  def after_sign_out_path_for(_resource_or_scope)
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

  # request.env['omniauth.params']['state'] => "sign_in" or "sign_up"
  def after_sign_in_path_for_omniauth_callback
    if @view.user.nil?
      # Signin failed. User not known.
      flash.now[:alert] = 'oauth user not found. You must sign up first.'
      return new_user_session_path if request.env['omniauth.params']['state'] == "sign_in"
      return new_user_registration_path if request.env['omniauth.params']['state'] == "sign_up"
    end
    return welcome_back_path if request.env['omniauth.params']['state'] == "sign_in"
    # omniauth_landing_page => "/welcome/add_to_slack_new?team_id=T0VN565N0"
    return omniauth_landing_page if request.env['omniauth.params']['state'] == "sign_up"
  end

  def omniauth_landing_page
    # Got here via oauth callback after sign_up or sign_in.
    auth_action = @view.installation.auth_params_json['state']
    if auth_action == 'sign_up'
      # return welcome_add_to_slack_new_path if @view.provider.name == 'slack'
      if @view.installation.auth_json['provider'] == 'slack'
        return welcome_add_to_slack_new_path(
          installation_db_id: @view.installation.id)
      end
      welcome_new_path
    else # auth_action == 'sign_in'
      welcome_back_path
    end
  end
end
