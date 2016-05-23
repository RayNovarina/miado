#
class Api::Slack::Slash::DeferredController < Api::Slack::Slash::BaseController
  #
  # require_relative 'concerns/commands' # method for each slack command
  # require_relative 'concerns/helpers' # various utility methods/controller lib.

  before_action :authenticate_slash_user

  # Returns
  def create
    # return render nothing: true, status: :ok, content_type: 'text/html' if params.key?('ssl_check')
    # response = local_response
    # return render nothing: true, status: :ok, content_type: 'text/html' if response.nil?
    # render json: response, status: 200
    render json: { text: 'bye' }, status: :ok
    # render nothing: true, status: :ok, content_type: 'text/html'
  end

  private

  def authenticate_slash_user
  end

  def local_response
    nil
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
