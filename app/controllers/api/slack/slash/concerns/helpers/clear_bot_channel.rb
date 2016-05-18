def clear_channel_msgs(options)
  # api_client, channel_id, time_range, exclude_bot_msgs = false
  # Setup time range for query
  oldest = options[:time_range][:start_ts]
  latest = options[:time_range][:end_ts]
  user_id = -1 # clear for all users.
  exclude_bot_msgs = false
  exclude_pinned_msgs = false

  has_more = true
  while has_more
    api_resp = web_api_history(options[:api_client], options[:type],
                               channel: options[:channel_id], latest: latest,
                               oldest: oldest, inclusive: 1)
    unless api_resp.key?('ok')
      err_msg = 'Error occurred on Slack\'s API:client.im.history'
      options[:api_client].logger.error(err_msg)
      return err_msg
    end
    return 'ok' if (messages = api_resp['messages']).length == 0
    has_more = api_resp.key?('has_more')
    messages.each do |m|
      # Prepare for next page query
      latest = m['ts']
      return "Invalid msg type(#{m['type']}) from API:client.im.history" unless m['type'] == 'message'
      # Delete message if user_name matched or `--user=*` or we are deleting
      # bot messages too.
      next unless user_id == -1 || (m.key?('user') && (m['user'] == user_id))
      next if exclude_bot_msgs && m.key?('subtype') && m['subtype'] == 'bot_message'
      next if exclude_pinned_msgs && m.key?('subtype') && m['subtype'] == 'pinned_item'
      api_resp = delete_message_on_channel(api_client: options[:api_client], channel_id: options[:channel_id], message: m)
      next if api_resp.key?('ok')
      err_msg = 'Error occurred on Slack\'s API:client.chat_delete'
      options[:api_client].logger.error(err_msg)
      return err_msg
    end
  end
  'ok'
end

def delete_message_on_channel(options)
  begin
    # No response is a good response
    return options[:api_client].chat_delete(channel: options[:channel_id], ts: options[:message]['ts'])
  rescue Slack::Web::Api::Error => e # (cant_delete_message)
    options[:api_client].logger.error e
    options[:api_client].logger.error "\ne.message: #{e.message}\n" \
      "channel_id: #{options[:channel_id]}  " \
      "message timestamp id: #{options[:message]['ts']}\n"
    return { exception: e }
  end
end

def web_api_history(api_client, type, options)
  case type
  when :channel
    resp = api_client.channels_history(options)
  when :direct
    begin
      return api_client.im_history(options)
    rescue Slack::Web::Api::Error => e # (not_authed)
      api_client.logger.error e
      api_client.logger.error "\ne.message: #{e.message}\n" \
        "channel_id: #{options[:channel]}  " \
        "token: #{api_client.token.nil? ? '*EMPTY!*' : api_client.token}\n"
      return { exception: e }
    end
  when :group
    resp = api_client.groups_history(options)
  when :mpdirect
    resp = api_client.mpim_history(options)
  end
  resp
end
