# Inputs: parsed = parsed command line info that has been verified.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
def post_comment_command(parsed)
  payload = JSON.parse(parsed[:url_params][:payload]).with_indifferent_access
  button_value = JSON.parse(payload[:actions].first[:value]).with_indifferent_access
  # { attch_idx: attch_idx, slack_chan_id: item.channel_id, slack_chan_name: item.channel_name, item_db_id: item.id }
  text = "Comment from @#{payload[:user][:name]} about the task '#{ListItem.find(button_value[:item_db_id].to_i).description}'."
  attachments = [{
    text: 'Comment, comment, comment.',
    mrkdwn_in: ['text']
  }]
  api_resp = send_channel_msg(
    api_client: make_web_client(
      Member.where(slack_user_id: parsed[:ccb].slack_user_id,
                   slack_team_id: parsed[:ccb].slack_team_id)
            .first.slack_user_api_token),
    username: 'taskbot',
    channel_id: button_value[:slack_chan_id],
    text: text,
    attachments: attachments
  )
  # Persist the channel.list_ids[] for the next transaction.
  save_after_action_list_context(parsed, parsed)
  ['', []]
end

# Returns: slack api response hash.
def send_channel_msg(options)
  api_resp =
    options[:api_client]
    .chat_postMessage(
      as_user: 'false',
      username: options[:username],
      channel: options[:channel_id],
      text: options[:text],
      attachments: options[:attachments])
  options[:api_client].logger.error "\nSent channel msg to: " \
    "#{options[:taskbot_username]} at dm_channel: " \
    "#{options[:channel_id]}.  Msg title: #{options[:text]}. " \
    "For member: #{options[:member_name]}\n"
  return api_resp if api_resp['ok'] == true
  err_msg = "Error: From send_channel_msg(API:client.chat_postMessage) = '#{api_resp['error']}'"
  options[:api_client].logger.error(err_msg)
  return api_resp
rescue Slack::Web::Api::Error => e # (not_authed)
  options[:api_client].logger.error e
  err_msg = "\nFrom send_channel_msg(API:client.chat_postMessage) = " \
    "e.message: #{e.message}\n" \
    "channel_id: #{options[:channel]}  " \
    "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, 'error' => err_msg }
end
