def check_for_debug(url_params)
  command = url_params[:text]
  debug = command.starts_with?('$')
  command = command.slice(1, command.length).lstrip if debug
# HACK
# debug = true
  [command, debug]
end

def add_standard_err_help_info(parsed, url_params, text)
  text.concat("\n`You typed: `  ")
      .concat(url_params[:command]).concat(' ')
      .concat(url_params[:text]) if parsed.nil? || !parsed[:err_msg].empty?
end

# Returns json response with text, attachments fields.
def slash_response(text, attachments, parsed, resp_options = nil)
  return nil if text.nil? && attachments.nil?
  options = {
    # Required fields.
    text: debug_headers(parsed).concat(text)
  }
  # Optional fields.
  options[:attachments] = attachments unless attachments.nil?
  # options[:replace_original] = false unless resp_options.nil?
  options.merge!(resp_options) unless resp_options.nil?
  options[:response_type] = 'ephemeral' unless options.key?(:response_type)
  options
end

def debug_headers(parsed)
  return '' unless parsed[:debug]
  cmd_info = "`Original command: #{params[:command]} #{params[:text]}`\n"
  slack_info =
    "`  Slack Team: #{params['team_domain']}. " \
    "Member: #{params['user_name']}. Channel: #{params['channel_name']}`\n"
  parse_trace_info =
    "`  parse trace: [#{params[:command]} #{params[:text]}] `\n" \
    "`               [func: #{parsed[:func]}]  [list_scope: #{parsed[:list_scope]}]  " \
    "[channel_scope: #{parsed[:channel_scope]}]  " \
    "[list_owner_name: #{parsed[:list_owner_name]}] `\n" \
    "`               [mentioned_member_name: #{parsed[:mentioned_member_name]}] " \
    "   options:  [team: #{parsed[:team_option]}]  " \
    "[all: #{parsed[:all_option]}]  " \
    "[archived: #{parsed[:archived_option]}]  " \
    "[assigned: #{parsed[:assigned_option]}] `\n" \
    "`               [done: #{parsed[:done_option]}] " \
    "[due: #{parsed[:due_option]}]  " \
    "[open: #{parsed[:open_option]}] " \
    "[unassigned: #{parsed[:unassigned_option]}] `\n"
  query_info =
    "`  query via: #{parsed[:list_query_trace_info]}" \
    "(team_id: #{params[:team_id]}  " \
    "channel name: #{params[:channel_name]}  " \
    "member name: #{parsed[:mentioned_member_name]})`\n" unless parsed[:list_query_trace_info].empty?
  query_info = '' if parsed[:list_query_trace_info].empty?
  cmd_info.concat(slack_info).concat(parse_trace_info).concat(query_info)
end

# Returns: true/false
def task_num_invalid?(parsed)
  task_num_out_of_range?(parsed)
  parsed[:err_msg] = 'Error: Invalid to specify team and task number.' if parsed[:team_option] && !parsed[:task_num].nil?
  #  parsed[:err_msg] = 'Error: Invalid to specify task number for a list of all team channels.' if parsed[:channel_scope] == :all_channels && !parsed[:task_num].nil?
  !parsed[:err_msg].empty?
end

def task_num_out_of_range?(parsed)
  parsed[:err_msg] = "Error: Task number #{parsed[:task_num]} is out " \
    "of range for this list of #{parsed[:list].length} " \
    "#{parsed[:list_owner_name]} " \
    "#{'task'.pluralize(parsed[:list].length)}" \
    '.' if parsed[:task_num] > parsed[:list].length
  !parsed[:err_msg].empty?
end

def save_item_info(parsed, id)
  if id == -1
    parsed[:list_action_item_info] = []
    return nil
  end
  begin
    item = ListItem.find(id)
  rescue ActiveRecord::RecordNotFound => e
    logger.info e
    return nil
  end
  unless item.nil?
    parsed[:list_action_item_info] << {
      db_id: item.id,
      assigned_member_id: item.assigned_member_id,
      done: item.done
    }
  end
  item
end

# Purpose: make a new web client or select and use an existing one.
# Returns: Slack::Web::Client new or existing.
#          Updates an input of hash[:api_client user/bot] if needed.
def make_web_client(token_or_hash)
  return new_web_client(token_or_hash) unless token_or_hash.is_a?(Hash)
  return token_or_hash[:api_client_user] if token_or_hash[:api_client_type] == :user &&
                                            !token_or_hash[:api_client_user].nil?
  return token_or_hash[:api_client_bot] if token_or_hash[:api_client_type] == :bot &&
                                            !token_or_hash[:api_client_bot].nil?
  web_client = new_web_client(
    token_or_hash[:api_client_type] == :user ? token_or_hash[:slack_user_api_token] : token_or_hash[:taskbot_api_token])
  token_or_hash[:api_client_user] = web_client if token_or_hash[:api_client_type] == :user
  token_or_hash[:api_client_bot] = web_client if token_or_hash[:api_client_type] == :bot
  web_client
end

def new_web_client(token)
  Slack.configure do |config|
    config.token = token
  end
  Slack::Web::Client.new
end

# Returns: slack user id (or nil if name not found),
#          slack user name
def slack_member_from_name(parsed, name)
  name = parsed[:url_params][:user_name] if name == 'me'
  return [nil, name] if (
    member = Member.find_from(source: :slack,
                              slack_user_name: name,
                              slack_team_id: parsed[:url_params][:team_id]
                             )).nil?
  [member.slack_user_id, name]
end

# Returns: err msg if name not found
#          slack user name
def slack_member_name_from_slack_user_id(parsed, id)
  return '??not recognized' if (
    member = Member.find_from(source: :slack,
                              slack_user_id: id,
                              slack_team_id: parsed[:url_params][:team_id]
                             )).nil?
  member.slack_user_name
end

# Returns: Member record
def slack_member_from_url_params(parsed)
  Member.find_from(
    source: :slack,
    slack_user_id: parsed[:url_params][:user_id],
    slack_team_id: parsed[:url_params][:team_id])
end

# Returns: [member_slack_id, member_name]
# Note: could be a new member or a name change(but same slack_user_id)
def mentioned_member_not_found(parsed, name)
  name = parsed[:url_params][:user_name] if name == 'me'
  member = Member.find_or_create_from(
    source: :rtm_data,
    installation_slack_user_id: parsed[:url_params][:user_id],
    slack_user_name: name,
    slack_team_id: parsed[:url_params][:team_id]
  )
  return [nil, name] if member.nil?
  [member.slack_user_id, name]
end

# Inputs: Flexible - 1) parsed only implies channel = parsed[:ccb] and that
#                       activity_type is implied.
#                    2) cb, activity_type = explicit context.
def update_channel_activity(parsed_or_cb, activity_type = nil, after_action_parse_hash = nil)
  parsed = parsed_or_cb if parsed_or_cb.is_a?(Hash)
  cb = parsed[:ccb] if parsed_or_cb.is_a?(Hash)
  cb = parsed_or_cb unless parsed_or_cb.is_a?(Hash)
  activity_type = "#{parsed[:button_actions].any? ? 'button_action' : 'slash_command'} - #{parsed[:func]}" if activity_type.nil?
  return cb.update(last_activity_type: activity_type,
                   last_activity_date: DateTime.current) if after_action_parse_hash.nil?
  cb.update(after_action_parse_hash: after_action_parse_hash,
            last_activity_type: activity_type,
            last_activity_date: DateTime.current)
end

# Inputs: HACK - if {}, we use it to update db with nil.
def update_member_record_activity(options_or_mcb, activity_type, bot_msgs_json = nil)
  options = options_or_mcb if options_or_mcb.is_a?(Hash)
  mcb = options[:member_mcb] if options_or_mcb.is_a?(Hash)
  mcb = options_or_mcb unless options_or_mcb.is_a?(Hash)
  return mcb.update(last_activity_type: activity_type,
                    last_activity_date: DateTime.current) if bot_msgs_json.nil?
  bot_msgs_json = nil if bot_msgs_json == {}
  mcb.update(bot_msgs_json: bot_msgs_json,
             last_activity_type: activity_type,
             last_activity_date: DateTime.current)
end

def lib_num_archived_tasks(options)
  ListItem.num_archived(slack_team_id: options[:slack_team_id])
end

def lib_format_archived_text(options)
  return '' if (button_info = lib_button_info_from_click(options[:parsed])).nil?
  return '' unless button_info[:label] == 'All Tasks'
  slack_team_id = options[:tcb].slack_team_id if options.key?(:tcb)
  slack_team_id = options[:ccb].slack_team_id if options.key?(:ccb)
  num_archived = lib_num_archived_tasks(slack_team_id: slack_team_id)
  return " (#{num_archived} archived)" if num_archived > 0
  ''
end

def lib_slack_api(method_name, api_token)
  uri = URI.parse('https://slack.com')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new("/api/#{method_name}?token=#{api_token}")
  response = http.request(request)
  JSON.parse(response.body)
end

# ["---- #general channel (1st tasknum: 1)----------",
def chan_name_from_taskbot_line(line)
  line.slice(6, line.length - 7).split.first
end

# "1) gen 1 | *Assigned* to @dawnnova."
def tasknum_from_taskbot_line(line)
  return nil if line.index(')').nil?
  line.slice(0, line.index(')'))
end

# inputs: { cb: Channel,
#           msg: { topic: '', subtopic: '', id: '', datetime: '', body: '', tags: ''}
#         }
def log_to_channel(options)
  # slack_messages
  options[:msg_bufr] = log2chan_make_room(options)
  log2chan_add_msg(options)
  log2chan_update(options)
end

def log2chan_make_room(options)
  options[:err_msg] = ''
  return [] if options[:cb].slack_messages.nil?
  options[:cb].slack_messages.pop if options[:cb].slack_messages.size > 10
  options[:cb].slack_messages
end

# msg_bufr: [msg{}]
def log2chan_add_msg(options)
  return unless options[:err_msg].empty?
  msg = options[:msg]
  msg[:topic] = '*none given*' if msg[:topic].nil?
  msg[:subtopic] = '' if msg[:subtopic].nil?
  msg[:id] = '' if msg[:id].nil?
  msg[:datetime] = DateTime.current if msg[:datetime].nil?
  msg[:body] = '*none given*' if msg[:body].nil?
  msg[:tags] = '' if msg[:tags].nil?
  options[:msg_bufr] << msg
end

def log2chan_update(options)
  return unless options[:err_msg].empty?
  options[:cb].update(slack_messages: options[:msg_bufr])
  options[:cb].slack_messages = options[:msg_bufr]
end

def lib_button_text(options)
  parsed = options[:parsed]
  unless (actions = parsed[:button_actions]).empty?
    if actions.first['name'] == options[:name]
      return lib_button_active(options[:text], parsed) if (command = parsed[:first_button_value][:command]).nil?
      return lib_button_active(options[:text], parsed) if command == options[:match]
    end
    return options[:text]
  end
  active = false
  active = true if parsed[:func] == :list &&
                   options[:match_list_cmd] == parsed[:original_command]
  return lib_button_active(options[:text], parsed) if active
  options[:text]
end

def lib_button_active(button_text, parsed)
  parsed[:active_button_label] = button_text
  # "· #{button_text} ·"
  "• #{button_text} •"
end

# Returns: button_info {}
def lib_button_info_from_click(parsed)
  return nil if parsed[:button_callback_id].nil?
  { func_id: parsed[:button_callback_id][:id],
    func_name: parsed[:button_actions].first['name'],
    value: parsed[:first_button_value],
    label: parsed[:first_button_value][:label] || ''
  }
end
