#
class Api::Slack::Slash::CommandsController < Api::Slack::Slash::BaseController
  #
  require_relative 'concerns/commands' # method for each slack command
  require_relative 'concerns/helpers' # various utility methods/controller lib.

  before_action :authenticate_slash_user
  # before_action :authorize_user

  # Returns json slash command response.
  def create
    return render nothing: true, status: :ok, content_type: 'text/html' if params.key?('ssl_check')
    response, p_hash = local_response
    return render nothing: true, status: :ok, content_type: 'text/html' if response.nil?
    unless p_hash.nil? || !p_hash[:err_msg].empty?
      # Sync up taskbot msgs, etc. in background task.
      unless (def_cmds = generate_after_action_cmds(parsed_hash: p_hash)).nil?
        # NOTE: a new Thread is generated to run these deferred commands.
        after_action_deferred_logic(def_cmds)
      end
    end
    # Reply to slash command. Could be an error response.
    render json: response, status: 200
  end

  private

  def authenticate_slash_user
  end

  # Returns:
  #   If command processed by controller:
  #      json response with { text, attachments} fields.
  #      AND parsed_hash data hash.
  # In all cases, @view hash has url_params with Slack slash command form parms.
  def local_response
    # Cmd Context: We need to know our team members and the last list displayed.
    ccb, previous_action_parse_hash = recover_previous_action_list
    return [err_resp(params, previous_action_parse_hash, nil), nil] if ccb.nil?
    # Note: previous_action_list_context: {} becomes our
    # BEFORE action list(mine) or list(team) or list(all)
    parsed = parse_slash_cmd(params, ccb, previous_action_parse_hash)
    return [err_resp(params, "`MiaDo ERROR: #{parsed[:err_msg]}`", nil), parsed] unless parsed[:err_msg].empty?
    text, attachments = process_cmd(parsed)
    # after_action_list_context: {} is AFTER action list(mine) or
    # list(team) or list(all)
    # add_standard_err_help_info(parsed, text)
    # return slash_response(text, attachments, parsed) unless parsed[:err_msg].empty?
    return [err_resp(params, text, attachments), parsed] unless parsed[:err_msg].empty?
    # Display an updated AFTER ACTION list if useful, i.e. task has been added
    # or deleted.
    text, attachments = prepend_text_to_list_command(parsed, text) if parsed[:display_after_action_list]
    [slash_response(text, attachments, parsed), parsed]
  end

  def err_resp(url_params, err_msg, err_attachments)
    { response_type: 'ephemeral',
      text: add_standard_err_help_info(nil, url_params, err_msg),
      attachments: err_attachments
    }
  end

  # the most recently active channel will have most recent member and taskbot channel list?
  # Add slack_user_id to Channel model.
  # To verify member using channel hash:
  # channel.members.key?(parsed[:mentioned_member_name])
  # rtm.members_list.each do |member|
  #  channel.members[member.name] = member.slack_user_id
  #  channel.members[member.slack_user_id] = member.name
  #  channel.members[:taskbot_channel_id] = ''
  # end

  # Note: if a new member has been added, then we will not recognize the
  #       slack_user_id.slack_team_id.slack_channel_id. In this case a new
  #       channel/ccb is created and an updated ccb.members hash is created with
  #       the new member's slack_user_id and taskbot_channel_id.
  def recover_previous_action_list
    @view.channel ||=
      Channel.find_or_create_from_slack(@view, params[:user_id],
                                        params[:team_id], params[:channel_id])
    if @view.channel.nil?
      return [nil,
              "`MiaDo server ERROR: team #{params[:team_domain]}" \
              "(#{params[:team_id]}) or channel #{params[:channel_name]}" \
              "(#{params[:channel_id]}) not found for Slack user #{params[:user_id]}." \
              'MiaDo needs to be installed via add to Slack button ' \
              'at www.miado.net/add_to_slack`']
    end
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
    return pub_command(parsed) if parsed[:func] == :pub
    return redo_command(parsed) if parsed[:func] == :redo
    return unassign_command(parsed) if parsed[:func] == :unassign
    # Default if no command given.
    return after_action_list_command(parsed) if parsed[:func] == :last_action_list
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
