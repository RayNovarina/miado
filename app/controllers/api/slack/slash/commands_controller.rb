#
class Api::Slack::Slash::CommandsController < Api::Slack::Slash::BaseController
  #
  # require 'slack-ruby-client'
  require_relative 'concerns/commands' # method for each slack command
  require_relative 'concerns/helpers' # various utility methods/controller lib.

  # before_action :authenticate_user
  # before_action :authorize_user

  # All slash commands create a POST or GET ajax request and pass it along to
  # our standard Web app CRUD controllers. i.e. as if posted from a web form.
  # Example:
  #  1) command:
  #     /do rev 1 spec @susan /jun15
  # 2) becomes Rails route:
  #  channel_tasks POST /channels/:channel_id/tasks(.:format)  to: tasks#create
  # 3) And is forwarded to the TaskController create() method.
  # 4) Response is converted from our Web json format to a slack command
  #    response format of { text: '...', attachments: [..] }
  def create
    render json: response_to_slash_command_from_rails_route, status: 200
  end

  private

=begin
    api/slack/slash/commands --> Api::BaseController::Commands
    /users/teams/members/channels/tasks/index,show,new,edit,destroy
    1) command:
      /do rev 1 spec @susan /jun15
      { "token"=>"tY1fGlQ1V2f6bskupMJa6ryY",
        "team_id"=>"T0VN565N0",
        "team_domain"=>"shadowhtracteam",
        "channel_id"=>"C0VNKV7BK",
        "channel_name"=>"general",
        "user_id"=>"U0VNMUXNZ",
        "user_name"=>"dawnnova",
        "command"=>"/do",
        "text"=>"help",
        "response_url"=>"https://hooks.slack.com/commands/T0VN565N0/31996879410/vAludpuTljkWnSvOliaSgWvz",
        "controller"=>"api/slack/slash/commands",
        "action"=>"create"
      }
    2) becomes route:
      channel_tasks POST /channels/:channel_id/tasks(.:format)  to: tasks#create
    3) response:
      :thumbs_up: Task 4 created and assigned to @susan. Due date is Tues. June 15. Type /do list for complete list.
      :bulb: You can unassign someone from the task by running /do unassign @susan 4
=end

=begin
  Flow for help slash command:
    params[:text] = 'help'
    1) request = reformat_slash_command_as_browser_request
         request = 'Ajax nav_to: /help'
    2) response = submit_request_to_rails_app(request)
         which maps to rails route 'help_path'
         which maps to 'pages#help'
         which renders Ajax json response.

=end
  def response_to_slash_command_from_rails_route
    request = reformat_slash_command_to_browser_request(params)
    response = submit_request_to_rails_app(request)
    reformat_browser_response_to_slash_command_response(response)
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
