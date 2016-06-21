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
def slash_response(text, attachments, parsed)
  return nil if text.nil? && attachments.nil?
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
    "(team_id: #{params[:team_id]}  " \
    "channel name: #{params[:channel_name]}  " \
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

# Convert text header for @taskbot display.
def format_pub_header(parsed, _list_cmd_text)
  channel_text = 'all Team channels' if parsed[:channel_scope] == :all_channels
  channel_text = "##{parsed[:url_params]['channel_name']}" if parsed[:channel_scope] == :one_channel
  options_text = ''
  options_text.concat('Open') if parsed[:open_option]
  options_text.concat(', ') if parsed[:open_option] && parsed[:due_option] && parsed[:done_option]
  options_text.concat(' and ') if parsed[:open_option] && parsed[:due_option] && !parsed[:done_option]
  options_text.concat('Due') if parsed[:due_option]
  options_text.concat(' and ') if (parsed[:open_option] || parsed[:due_option]) && parsed[:done_option]
  options_text.concat('Done') if parsed[:done_option]
  "`Current tasks list for @#{parsed[:mentioned_member_name]} " \
  "in #{channel_text} (#{options_text})`"
end

def make_web_client(api_token)
  # Slack.config.token = 'xxxxx'
  Slack.configure do |config|
    config.token = api_token
  end
  Slack::Web::Client.new
end

def slack_member_from_name(parsed, name)
  # Fixup if called with partial copy of parsed hash.
  ccb = parsed[:ccb] || @view.channel
  return [parsed[:url_params][:user_id], parsed[:url_params][:user_name]] if name == 'me' || name == parsed[:url_params][:user_name]
  return [nil, name] if (m_hash = ccb.members_hash[name]).nil?
  [m_hash['slack_user_id'], name]
end

def slack_member_name_from_slack_user_id(parsed, slack_member_user_id)
  # Fixup if called with partial copy of parsed hash.
  ccb = parsed[:ccb] || @view.channel
  return parsed[:url_params][:user_name] if parsed[:url_params][:user_id] == slack_member_user_id
  return '??not recognized' if (m_hash = ccb.members_hash[slack_member_user_id]).nil?
  m_hash['slack_user_name']
end

# Returns: [member_slack_id, member_name]
# Note: could be a new member or a name change(but same slack_user_id)
def mentioned_member_not_found(p_hash, name)
  updated_members_hash = merge_members_hash_from_slack(p_hash, name)
  return [nil, name] if updated_members_hash[name].nil?
  # New team member added or name change.
  p_hash[:ccb].members_hash = updated_members_hash
  # Channels for this team gets an updated member lookup hash.
  # Note: a new Thread is generated to run these deferred commands.
  new_member_deferred_logic(members_hash: updated_members_hash,
                            slack_team_id: p_hash[:ccb].slack_team_id)
  [updated_members_hash[name]['slack_user_id'], name]
end

# We know that the target_name is not in our ccb.members_hash, else we would not
# be here.
# query slack for current member list for this slack user.
def merge_members_hash_from_slack(p_hash, target_name)
  ccb_members_hash = p_hash[:ccb].members_hash
  first_m_hash = nil
  ccb_members_hash.each do |m_hash|
    first_m_hash = m_hash[1]
    break
  end
  experiment = true
  if experiment
    # Experiment: just assume name is correct, don't query Slack and require so
    # many auth scopes, just add to hash.
    add_new_member(ccb_members_hash, first_m_hash, target_name, target_name,
                   'id.'.concat(target_name))
  else
    add_update_members_from_slack(p_hash, target_name, ccb_members_hash, first_m_hash)
    slack_members = slack_members_from_rtm_data(api_client: make_web_client(p_hash[:ccb].slack_user_api_token))
    slack_members.each do |slack_member|
      # next if slack_member[:name] == 'slackbot' || (slack_member[:deleted] && slack_member[:is_bot])
      next unless slack_member[:name] == target_name
      unless ccb_members_hash[slack_member[:id]].nil?
        # Name change. We have recorded that slack user_id before.
        update_member_name(ccb_members_hash, target_name)
        break
      end
      # New member has been added. Add em to our members_hash
      add_new_member(ccb_members_hash, first_m_hash, slack_member[:name],
                     slack_member[:real_name], slack_member[:id])
      break
    end
  end
  ccb_members_hash
end

def add_update_members_from_slack(p_hash, target_name, ccb_members_hash, first_m_hash)
  slack_members = slack_members_from_rtm_data(api_client: make_web_client(p_hash[:ccb].slack_user_api_token))
  slack_members.each do |slack_member|
    # next if slack_member[:name] == 'slackbot' || (slack_member[:deleted] && slack_member[:is_bot])
    next unless slack_member[:name] == target_name
    unless ccb_members_hash[slack_member[:id]].nil?
      # Name change. We have recorded that slack user_id before.
      update_member_name(ccb_members_hash, target_name)
      break
    end
    # New member has been added. Add em to our members_hash
    add_new_member(ccb_members_hash, first_m_hash, slack_member[:name],
                   slack_member[:real_name], slack_member[:id])
    break
  end
end

# New member has been added. Add em to our members_hash
def add_new_member(ccb_members_hash, first_m_hash, name, real_name, id)
  m_hash = {
    'slack_user_name' => name,
    'slack_real_name' => real_name,
    'slack_user_id' => id,
    'slack_user_api_token' => first_m_hash['slack_user_api_token'],
    'bot_user_id' => first_m_hash['bot_user_id'],
    'bot_dm_channel_id' => nil,
    'bot_api_token' => first_m_hash['bot_api_token']
  }
  ccb_members_hash[name] = m_hash
  ccb_members_hash[id] = m_hash
end

# Name change. We have recorded that slack user_id before.
def update_member_name(ccb_members_hash, target_name)
  old_name = ccb_members_hash[slack_member[:id]]['slack_user_name']
  ccb_members_hash[slack_member[:id]]['slack_user_name'] = target_name
  updated_m_hash = ccb_members_hash[slack_member[:id]]
  ccb_members_hash.delete(old_name)
  ccb_members_hash[target_name] = updated_m_hash
end

def slack_members_from_rtm_data(options)
  # response is an array of hashes. Each has name and id of a team member.
  begin
    return options[:api_client].users_list['members']
  rescue Slack::Web::Api::Error => e
    options[:api_client].logger.error "\nslack_members_from_rtm_data() " \
      "failed with e.message: #{e.message}\n" \
      "api_token: #{options[:api_client].token}\n"
    return []
  end
end
