#
class Api::Slack::Slash::CommandsController < Api::Slack::Slash::BaseController
  #
  require_relative 'concerns/commands' # method for each slack command
  require_relative 'concerns/helpers' # various utility methods/controller lib.

  before_action :authenticate_slash_user
  # before_action :authorize_user

  # Returns json slash command response. Empty text msg if command handed off
  # to bot.
  def create
    render json: local_response_or_bot_msg, status: 200
  end

  private

  def authenticate_slash_user
  end

  # Returns:
  #   If command processed by controller:
  #      json response with text, attachments fields.
  #   If command handed over to bot: empty string or err msg.
  # In all cases, @view hash has url_params with Slack slash command form parms.
  def local_response_or_bot_msg
    # Cmd Context: We need to know our team members and the last list displayed.
    @view.channel, previous_action_parse_hash = recover_previous_action_list
    return { response_type: 'ephemeral', text: '`MiaDo ERROR: team or channel not found. MiaDo command not installed?`' } if @view.channel.nil?
    # Note: previous_action_list_context: {} becomes our
    # BEFORE action list(mine) or list(team) or list(all)
    parsed = parse_slash_cmd(params, @view, previous_action_parse_hash)
    return { response_type: 'ephemeral', text: "`MiaDo ERROR: #{parsed[:err_msg]}`" } unless parsed[:err_msg].empty?
    text, attachments = process_cmd(parsed)
    # after_action_list_context: {} is AFTER action list(mine) or
    # list(team) or list(all)
    add_standard_err_help_info(parsed, text)
    return slash_response(text, attachments, parsed) unless parsed[:err_msg].empty?
    # Display an updated AFTER ACTION list if useful, i.e. task has been added
    # or deleted.
    text, attachments = prepend_text_to_list_command(parsed, text) if parsed[:display_after_action_list]
    slash_response(text, attachments, parsed)
    # return handoff_slash_command_to_bot(parsed, list) if parsed[:handoff]
  end

  def recover_previous_action_list
    @view.channel ||= Channel.find_or_create_from_slack_id(
      @view, params[:channel_id], params[:team_id])
    return [nil, nil] if @view.channel.nil?
    [@view.channel, @view.channel.after_action_parse_hash]
  end

  # Returns: [text, attachments]
  def process_cmd(parsed)
    return add_command(parsed) if parsed[:func] == :add
    return append_command(parsed) if parsed[:func] == :append
    return assign_command(parsed) if parsed[:func] == :assign
    return done_command(parsed) if parsed[:func] == :done
    return delete_command(parsed) if parsed[:func] == :delete
    return due_command(parsed) if parsed[:func] == :due
    return help_command(parsed) if parsed[:func] == :help
    return list_command(parsed) if parsed[:func] == :list
    return redo_command(parsed) if parsed[:func] == :redo
    return unassign_command(parsed) if parsed[:func] == :unassign
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
