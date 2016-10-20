def check_for_debug(url_params)
  command = url_params[:text]
  debug = command.starts_with?('$')
  command = command.slice(1, command.length).lstrip if debug
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
    "`  parse trace: [#{params[:command]} #{params[:text]}] " \
    "[func: #{parsed[:func]}]  [list_scope: #{parsed[:list_scope]}]  " \
    "[channel_scope: #{parsed[:channel_scope]}]  " \
    "[list_owner_name: #{parsed[:list_owner_name]}] `\n" \
    "`               [mentioned_member_name: #{parsed[:mentioned_member_name]}] " \
    "   options:  [team: #{parsed[:team_option]}]  " \
    "[all: #{parsed[:all_option]}]  " \
    "[open: #{parsed[:open_option]}]  " \
    "[done: #{parsed[:done_option]}]  " \
    "[due: #{parsed[:due_option]}] `\n"
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
      assigned_member_id: item.assigned_member_id
    }
  end
  item
end

def make_web_client(api_token)
  # Slack.config.token = 'xxxxx'
  Slack.configure do |config|
    config.token = api_token
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

# p_hash[:ccb] --> channel of the member who typed in the slash cmd that caused
# us to be here.
def update_ccb_channel_activity(parsed, activity_type)
  return if parsed[:ccb].nil?
  parsed[:ccb].update(
    last_activity_type: activity_type,
    last_activity_date: DateTime.current)
end

def lib_slack_api(method_name, api_token)
  uri = URI.parse('https://slack.com')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new("/api/#{method_name}?token=#{api_token}")
  response = http.request(request)
  JSON.parse(response.body)
end
