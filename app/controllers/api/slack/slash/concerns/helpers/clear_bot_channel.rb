# Returns: { resp: 'ok' or err_msg }
def clear_channel_msgs(options)
  api_options = {
    api_client: options[:api_client],
    bot_api_token: options[:bot_api_token],
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
    return { 'ok' => false, error: 'Error occurred on Slack\'s API:client.im.history' } unless api_resp['ok']
    return { 'ok' => true } if (api_options[:messages] = api_resp['messages']).length == 0
    has_more = api_resp.key?('has_more') ? api_resp['has_more'] : false
    # Returns updated delete_msgs_options hash with resp, latest.
    api_resp = delete_messages(api_options)
    return api_resp unless api_resp['ok']
  end
  { 'ok' => true }
end

# Returns: { 'ok' or err_msg, latest msg timestamp }
def delete_messages(options)
  options[:messages].each do |m|
    # Prepare for next page query
    options[:latest] = m['ts']
    options[:message] = m
    return { 'ok' => false, error: "Invalid msg type(#{m['type']}) from API:client.im.history" } unless m['type'] == 'message'
    # Delete message if user_name matched or `--user=*` or we are deleting
    # bot messages too.
    next unless options[:user_id] == -1 || (m.key?('user') && (m['user'] == options[:user_id]))
    next if options[:exclude_bot_msgs] && m.key?('subtype') && m['subtype'] == 'bot_message'
    next if options[:exclude_pinned_msgs] && m.key?('subtype') && m['subtype'] == 'pinned_item'
    api_resp = delete_message_on_channel(options)
    m['deleted'] = true if api_resp['ok']
    next if api_resp['ok'] == true
    # If we can't delete a msg, abandon delete loop, else we just keep trying.
    return { 'ok' => false, error: "Error occurred on Slack\'s API:client.chat_delete: #{api_resp}" }
  end
  { 'ok' => true }
end

def delete_message_on_channel(options)
  begin
    # No response is a good response
    api_resp = options[:api_client].chat_delete(channel: options[:channel],
                                                as_user: true,
                                                ts: options[:message]['ts'])
    ok_msg = "\nSUCCESS: From delete_message_on_channel(API:client.chat_delete) = " \
      "channel_id: #{options[:channel]}  " \
      "message timestamp id: #{options[:message]['ts']}\n" \
      "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
    options[:api_client].logger.error(ok_msg)
    return api_resp
  rescue Slack::Web::Api::Error => e # (cant_delete_message)
    options[:api_client].logger.error e
    err_msg = "\nFrom delete_message_on_channel(API:client.chat_delete) = " \
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
  case options[:type]
  when :channel
    resp = options[:api_client].channels_history(options)
  when :direct
    begin
      return options[:api_client].im_history(options)
    rescue Slack::Web::Api::Error => e # (not_authed)
      options[:api_client].logger.error e
      err_msg = "\nFrom web_api_history(API:client.im_history) = " \
        "e.message: #{e.message}\n" \
        "channel_id: #{options[:channel]}  " \
        "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
      options[:api_client].logger.error(err_msg)
      return { exception: e }
    end
  when :group
    resp = options[:api_client].groups_history(options)
  when :mpdirect
    resp = options[:api_client].mpim_history(options)
  end
  resp
end

# Returns: { 'ok' or err_msg, messages: [] }
def messages_via_rtm_start(options)
  rtm_start = lib_start_data_from_rtm_start(options[:bot_api_token])
  slack_dm_channels = rtm_start['ims']
  messages = []
  slack_dm_channels.each do |im|
    next if im['latest'].nil?
    next unless im['id'] == options[:channel]
    messages << im['latest']
    break
  end
  { 'ok' => true,
    'has_more' => false,
    'messages' => messages
  }
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
