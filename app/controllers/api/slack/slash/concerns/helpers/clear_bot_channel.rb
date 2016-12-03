# Returns: { resp: 'ok' or err_msg }
def clear_channel_msgs(options)
  message_source_method  = options[:message_source]
  #----- debug
  message_source_method  = 'messages_via_im_history' if options[:message_source] == :im_history
  message_source_method  = 'messages_via_rtm_start' if options[:message_source] == :rtm_data
  message_source_method  = 'messages_via_taskbot_channel' if options[:message_source] == :taskbot_channel
  message_source_method  = 'messages_via_member_record' if options[:message_source] == :member_record
  #--------
  api_options = {
    api_client: options[:api_client],
    bot_api_token: options[:bot_api_token],
    slack_team_id: options[:slack_team_id],
    slack_user_id: options[:slack_user_id],
    taskbot_user_id: options[:taskbot_user_id],
    message_source: options[:message_source],
    message_source_method: message_source_method,
    bot_msgs: options[:bot_msgs],
    type: :direct,
    channel: options[:channel_id],
    latest: options[:time_range][:end_ts],
    oldest: options[:time_range][:start_ts],
    inclusive: 1,
    user_id: -1, # clear for all users.
    exclude_bot_msgs: false,
    exclude_pinned_msgs: false }
  has_more = true
  while has_more
    api_resp = messages_via_im_history(api_options) if options[:message_source] == :im_history
    api_resp = messages_via_rtm_start(api_options) if options[:message_source] == :rtm_data
    api_resp = messages_via_taskbot_channel(api_options) if options[:message_source] == :taskbot_channel
    api_resp = messages_via_member_record(api_options) if options[:message_source] == :member_record
    return { 'ok' => false, error: "Error occurred on Slack\'s API:client.#{options[:message_source]}" } unless api_resp['ok']
    has_more = api_resp.key?('has_more') ? api_resp['has_more'] : false
    messages_stat =
      "\nclear_channel_msgs(#{options[:message_source]}) loop: after " \
      "#{message_source_method}() has_more = " \
      "#{has_more}  num_messages.len = #{api_resp['messages'].length} \n "
    options[:api_client].logger.error(messages_stat)
    return { 'ok' => true, 'num_deleted' => 0 } if (api_options[:messages] = api_resp['messages']).length == 0
    # Returns updated delete_msgs_options hash with resp, latest.
    api_resp = delete_messages(api_options)
    return api_resp unless api_resp['ok']
  end
  { 'ok' => true, 'num_deleted' => api_resp['num_deleted'] }
end

# Returns: { 'ok' or err_msg, latest msg timestamp }
def delete_messages(options)
  num_deleted = 0
  options[:messages].each do |m|
    # Prepare for next page query
    options[:latest] = m['ts']
    options[:message] = m
    return { 'ok' => false, error: "Invalid msg type(#{m['type']}) from API:client.#{options[:message_source]}" } unless m['type'] == 'message'
    # Delete message if user_name matched or `--user=*` or we are deleting
    # bot messages too.
    next unless options[:user_id] == -1 || (m.key?('user') && (m['user'] == options[:user_id]))
    next if options[:exclude_bot_msgs] && m.key?('subtype') && m['subtype'] == 'bot_message'
    next if options[:exclude_pinned_msgs] && m.key?('subtype') && m['subtype'] == 'pinned_item'
    # api_resp: from chat.delete method: Either exception obj or {'ok' => true}
    api_resp = delete_message_on_channel(options)
    m['deleted'] = true if api_resp['ok']
    num_deleted += 1
    next if api_resp['ok'] == true
    # If we can't delete a msg, abandon delete loop, else we just keep trying.
    return { 'ok' => false,
             error: "Error occurred on Slack\'s API:client.chat_delete(#{options[:message_source]}): #{api_resp}",
             exception: api_resp
           }
  end
  { 'ok' => true, 'num_deleted' => num_deleted }
end

def delete_message_on_channel(options)
  begin
    # No response is a good response
    api_resp = options[:api_client].chat_delete(channel: options[:channel],
                                                as_user: true,
                                                ts: options[:message]['ts'])
    ok_msg = "\nSUCCESS: From delete_message_on_channel(API:client.chat_delete(#{options[:message_source]})) = " \
      "channel_id: #{options[:channel]}  " \
      "message timestamp id: #{options[:message]['ts']}\n" \
      "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
    options[:api_client].logger.error(ok_msg)
    return api_resp
  rescue Slack::Web::Api::Error => e # (cant_delete_message)
    options[:api_client].logger.error e
    # e.message == 'message_not_found'
    err_msg = "\nFrom delete_message_on_channel(API:client.chat_delete(#{options[:message_source]})) = " \
      "e.message: #{e.message}\n" \
      "channel_id: #{options[:channel]}  " \
      "message timestamp id: #{options[:message]['ts']}\n" \
      "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
    options[:api_client].logger.error(err_msg)
    return { exception: e }
  end
end

# Returns: { 'ok' or err_msg, messages: [] }
def messages_via_im_history(options)
  api_options = {
    channel: options[:channel], latest: options[:latest],
    oldest: options[:oldest], inclusive: options[:inclusive]
  }
  case options[:type]
  when :channel
    resp = options[:api_client].channels_history(api_options)
  when :direct
    begin
      return options[:api_client].im_history(api_options)
    rescue Slack::Web::Api::Error => e # (not_authed)
      options[:api_client].logger.error e
      err_msg = "\nFrom web_api_history(API:client.im_history) = " \
        "e.message: #{e.message}\n" \
        "channel_id: #{api_options[:channel]}  " \
        "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
      options[:api_client].logger.error(err_msg)
      return { exception: e }
    end
  when :group
    resp = options[:api_client].groups_history(api_options)
  when :mpdirect
    resp = options[:api_client].mpim_history(api_options)
  end
  resp
end

# NOTE: this will ONLY fetch ONE msg, i.e. the latest. NOT adequate for getting
#       ALL msgs. (unless run in a loop or rtm_start requests/delete latest)
# Returns: { 'ok' or err_msg, messages: [] }
def messages_via_rtm_start(options)
  # Get a new copy of the current dm channel msgs.
  rtm_start, _installation = Installation.refresh_rtm_start_data(options)
  slack_dm_channels = rtm_start['ims']
  messages = []
  slack_dm_channels.each do |im|
    next unless im['id'] == options[:channel]
    break if im['latest'].nil?
    # next unless im['latest']['bot_id'] == taskbot_slack_bot_id
    # HACK - reduce data alloc.
    im['latest']['attachments'] = []
    messages << im['latest']
    break
  end
  api_resp =
    { 'ok' => true,
      'has_more' => false,
      'messages' => messages
    }
  api_resp
end

# Returns: { 'ok' or err_msg, messages: [] }
def messages_via_taskbot_channel(options)
  { 'ok' => true,
    'has_more' => false,
    'messages' => options[:taskbot_channel].slack_messages
  }
end

# Returns: { 'ok' or err_msg, messages: [] }
def messages_via_member_record(options)
  { 'ok' => true,
    'has_more' => false,
    'messages' => options[:bot_msgs] || []
  }
end
