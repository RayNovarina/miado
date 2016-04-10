require_relative 'web_api'

def clear_bot_channel(time_range, exclude_bot_msgs = false)
  # Setup time range for query
  oldest = time_range[:start_ts]
  latest = time_range[:end_ts]
  channel_id = web_api_channel_id(:user_id)
  user_id = -1 # clear for all users.
  exclude_pinned_msgs = false # clear pinned msgs.

  has_more = true
  while has_more
    api_resp = web_api_history(:direct, channel: channel_id, latest: latest,
                                        oldest: oldest, inclusive: 1)
    unless api_resp.key?('ok')
      err_msg = 'Error occurred on Slack\'s API:client.im.history'
      @view.slack_client.logger.error(err_msg)
      return err_msg
    end
    return 'ok' if (messages = api_resp['messages']).length == 0
    has_more = api_resp.key?('has_more')
    messages.each do |m|
      # Prepare for next page query
      latest = m['ts']
      return "Invalid msg type(#{m['type']}) from API:client.im.history" unless m['type'] == 'message'
      # Delete user messages
      next unless m.key?('user')
      # Delete message if user_name matched or `--user=*` or we are deleting
      # bot messages too.
      next unless user_id == -1 || m['user'] == user_id
      next if exclude_bot_msgs && m.key?('subtype') && m['subtype'] == 'bot_message'
      next if exclude_pinned_msgs && m.key?('subtype') && m['subtype'] == 'pinned_item'
      delete_message_on_channel(channel_id, m)
    end
  end
  'ok'
end

def delete_message_on_channel(channel_id, message)
  # No response is a good response
  # catch Slack::Web::Api::Error (cant_delete_message)
  @view.slack_client.web_client.chat_delete(channel: channel_id,
                                            ts: message['ts'])
end
