#
class Api::Slack::Slash::CommandsController < Api::Slack::Slash::BaseController
  #
  require_relative 'concerns/commands' # method for each slack command
  require_relative 'concerns/helpers' # various utility methods/controller lib.

  # before_action :authenticate_user
  # before_action :authorize_user

  # Slash commands are handed off to the bot process generally.
  # Static page responses are directly sent here to be more responsive to user.
  # Returns json slash command response. Empty text msg if command handed off
  # to bot.
  def create
    render json: static_response_or_bot_msg, status: 200
  end

  private

  # Returns:
  #   If command processed by controller:
  #      json response with text, attachments fields.
  #   If command handed over to bot: empty string or err msg.
  # In all cases, @view hash has url_params with Slack slash command form parms.
  def static_response_or_bot_msg
    command, debug = check_for_debug(params)
    return add_command(debug) if command.starts_with?('add')
    return help_command(debug) if command.starts_with?('help')
    return list_command(debug) if command.starts_with?('list')
    # handoff_slash_command_to_bot
    add_command(debug)
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
