def check_for_debug(url_params)
  command = url_params[:text]
  debug = command.starts_with?('$')
  command = command.slice(1, command.length).lstrip if debug
  [command, debug]
end

def add_standard_err_help_info(parsed, text)
  text.concat("\n`You typed: `  ")
      .concat(parsed[:url_params][:command]).concat(' ')
      .concat(parsed[:url_params][:text]) unless parsed[:err_msg].empty?
end

# Returns json response with text, attachments fields.
def slash_response(text, attachments, parsed)
  options = {
    # Required fields.
    response_type: 'ephemeral',
    text: debug_headers(parsed).concat(text)
  }
  # Optional fields.
  options[:attachments] = attachments unless attachments.nil?
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
    "(channel name: #{params[:channel_name]}  " \
    "member name: #{parsed[:mentioned_member_name]})`\n" unless parsed[:list_query_trace_info].empty?
  query_info = '' if parsed[:list_query_trace_info].empty?
  cmd_info.concat(slack_info).concat(parse_trace_info).concat(query_info)
end

def hash_value(s)
  return nil if s.nil?
  value_s = s.slice(s.index('=>') + 2, s.length - 1)
  return nil if value_s == 'nil'
  return value_s.slice(1..-1).to_sym if value_s.starts_with?(':')
  return value_s.slice(1, value_s.length - 2) if value_s.starts_with?('"')
  return true if value_s == 'true'
  return false if value_s == 'false'
  return value_array(value_s) if value_s.starts_with?('[')
  value_s
end

def value_array(s)
  # ASSUME array of ints for now. i.e. s.slice(0).is_numeric
  return [] if s == '[]'
  # Example is: "[1, 2, 3, 4, 9, 10, 11]"
  s.slice(1, s.length - 2).split(',').map(&:to_i)
end

# Returns: true/false
def task_num_invalid?(parsed)
  task_num_out_of_range?(parsed)
  parsed[:err_msg] = 'Error: Invalid to specify team and task number.' if parsed[:team_option] && !parsed[:task_num].nil?
  parsed[:err_msg] = 'Error: Invalid to specify task number for a list of all team channels.' if parsed[:channel_scope] == :all_channels && !parsed[:task_num].nil?
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
