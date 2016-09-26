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
  #      response: json response with { text, attachments} fields.
  #      p_hash:   parsed_hash data hash.
  # In all cases, @view hash has url_params with Slack slash command form parms.
  def local_response
    # Cmd Context: We need to know our team members and the last list displayed.
    ccb, err_msg = channel_control_block_from_slack
    return [err_resp(params, err_msg, nil), nil] unless err_msg.empty?
    # Note: ccb.previous_action_list_context: {} becomes our
    # BEFORE action list(mine) or list(team) or list(all)
    parsed = parse_slash_cmd(params, ccb, ccb.after_action_parse_hash)
    return [err_resp(params, "`MiaDo ERROR: #{parsed[:err_msg]}`", nil), parsed] unless parsed[:err_msg].empty?
    text, attachments = process_cmd(parsed)
    # after_action_list_context: {} is AFTER action list(mine) or
    # list(team) or list(all)
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

=begin
  Form Params
  channel_id	C0VNKV7BK
  channel_name	general
  command	/do
  response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
  team_domain	shadowhtracteam
  team_id	T0VN565N0
  text	call GoDaddy @susan /fri
  token	3ZQVG7rk4p7EZZluk1gTH3aN
  user_id	U0VLZ5P51
  user_name	ray
=end
  # Returns: [channel, error_message]
  # Case1: Member1 installs miaDo. Only this member has a taskbot dm channel and
  #        token. BUT the slash command is available to all members.
  #        Member2 uses /do.
  # Case2: a new member has been added to a team.
  #
  # In these cases we will not recognize the
  #   slack_user_id.slack_team_id.slack_channel_id.  A new channel/ccb is
  #   created.
  def channel_control_block_from_slack
    return channel_control_block_from_wordpress_plugin if params.has_key?('channel_id') && params[:channel_id].starts_with?('wordpress:')
    update_url_params_from_interactive_msg if params.has_key?('payload')
    if (@view.channel = Channel.find_or_create_from(source: :slack, view: @view, slash_url_params: params)).nil?
      return [nil,
              "`MiaDo server ERROR: team #{params[:team_domain]}" \
              "(#{params[:team_id]}) or channel #{params[:channel_name]}" \
              "(#{params[:channel_id]}) not found for Slack user #{params[:user_id]}." \
              'MiaDo needs to be installed via add to Slack button ' \
              'at www.miado.net/add_to_slack`']
    end
    [@view.channel, '']
  end

=begin
channel_id	=> wordpress: plugin; name: contact-form-slack
channel_name	general
command	/do
response_url
team_domain	shadowhtracteam => 'Shadow Htrac Team'
team_id	WordPress for Attack Cats
text	@ray wordpress Contact Us message. Name: visitor 1, Email: visitor1@example.com, Message: hi from visitor 1.
token	page-contact-us.php: 0.1
user_id	contact-form-slack
user_name	wordpress => 'ray'

def find_from_slack(options)
  @view ||= options[:view]
  Channel.where(slack_user_id: options[:slash_url_params]['user_id'],
                slack_team_id: options[:slash_url_params]['team_id'],
                slack_channel_id: options[:slash_url_params]['channel_id'])
end
def create_from_slack(options)
  @view ||= options[:view]
  channel = Channel.new(
    slack_channel_name: options[:slash_url_params]['channel_name'],
    slack_channel_id: options[:slash_url_params]['channel_id'],
    slack_user_id: options[:slash_url_params]['user_id'],
    slack_team_id: options[:slash_url_params]['team_id'],
  )
=end
  # Returns: [channel, error_message]
  # //HACK
  def channel_control_block_from_wordpress_plugin
    if (@view.channel = Channel.find_or_create_from(source: :wordpress, view: @view, slash_url_params: params)).nil?
      return [nil,
              "`MiaDo server ERROR: team #{params[:team_domain]}" \
              " or channel #{params[:channel_name]}" \
              " not found for Slack user #{params[:user_name]}." \
              ' MiaDo Contact Us Wordpress plugin needs to be configured properly.`']
    end
    params[:channel_id] = @view.channel.slack_channel_id
    params[:channel_name] = @view.channel.slack_channel_name
    params[:response_url] = params[:response_url]
    params[:team_domain] = params[:team_domain]
    params[:team_id] = @view.channel.slack_team_id
    params[:token] = params[:token]
    params[:user_id] = @view.channel.slack_user_id
    params[:user_name] = params[:user_name]
    [@view.channel, '']
  end

  # Returns: url_params{}
  # //HACK
  def update_url_params_from_interactive_msg
    payload = JSON.parse(params[:payload])
    params[:channel_id] = payload['channel']['id']
    params[:channel_name] = payload['channel']['name']
    params[:response_url] = payload['response_url']
    params[:team_domain] = payload['team']['domain']
    params[:team_id] = payload['team']['id']
    params[:token] = payload['token']
    params[:user_id] = payload['user']['id']
    params[:user_name] = payload['user']['name']
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
    return feedback_command(parsed) if parsed[:func] == :feedback
    return after_action_list_command(parsed) if parsed[:func] == :last_action_list
    # Default if no command given.
    help_command(parsed)
  end

  def make_view_helper
    @view = ApplicationHelper::View.new(self, User.new)
  end
end
