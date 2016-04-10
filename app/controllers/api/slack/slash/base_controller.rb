class Api::Slack::Slash::BaseController < ApplicationController

  skip_before_action :verify_authenticity_token

  rescue_from ActionController::ParameterMissing, with: :malformed_request

  def authenticate_user
    authenticate_or_request_with_http_token do |token, options|
      # if token.downcase == 'admin'
      #  @current_user = User.admin.first
      # else
      #  @current_user = User.find_by(auth_token: token)
      # end
    end
  end

  def authorize_user
    unless false # @current_user && @current_user.admin?
      render json: { error: 'Not Authorized', status: 403 }, status: 403
    end
  end

  def malformed_request
    render json: { error: 'The request could not be understood by the server ' /
                          'due to malformed syntax. The client SHOULD NOT ' /
                          'repeat the request without modifications.',
                   status: 400
                  },
           status: 400
  end
end
