# Inputs: parsed = parsed command line info that has been verified.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
=begin
{"actions"=>[{"name"=>"discuss", "value"=>"2:C0VNKV7BK"}],
 "callback_id"=>"taskbot",
 "team"=>{"id"=>"T0VN565N0", "domain"=>"shadowhtracteam"},
 "channel"=>{"id"=>"D18E3GH2P", "name"=>"directmessage"},
 "user"=>{"id"=>"U0VLZ5P51", "name"=>"ray"},
 "action_ts"=>"1475292461.677481",
 "message_ts"=>"1475292447.000003",
 "attachment_id"=>"4",
 "token"=>"eUPXYEyP40qAztzCdmDANPHt",
 "original_message"=>
  {"text"=>"`Current tasks list for @ray in all Team channels (Open)`",
   "username"=>"MiaDo Taskbot",
   "bot_id"=>"B1YEP3QH5",
   "attachments"=>
    [{"text"=>"---- #general channel ----------", "id"=>1, "mrkdwn_in"=>["text"], "fallback"=>"NO FALLBACK DEFINED"},
     {"callback_id"=>"taskbot",
      "fallback"=>"not done",
      "text"=>"\n new general task1 for ray | *Assigned* to @ray.",
      "id"=>2,
      "actions"=>
       [{"id"=>"1", "name"=>"done", "text"=>"Done", "type"=>"button", "value"=>"1", "style"=>"primary"},
        {"id"=>"2", "name"=>"discuss", "text"=>"Discuss", "type"=>"button", "value"=>"0:C0VNKV7BK", "style"=>"primary"}]},
     {"callback_id"=>"taskbot",
      "fallback"=>"not done",
      "text"=>"\n new general task2 for ray | *Assigned* to @ray.",
      "id"=>3,
      "actions"=>
       [{"id"=>"3", "name"=>"done", "text"=>"Done", "type"=>"button", "value"=>"2", "style"=>"primary"},
        {"id"=>"4", "name"=>"discuss", "text"=>"Discuss", "type"=>"button", "value"=>"1:C0VNKV7BK", "style"=>"primary"}]},
     {"callback_id"=>"taskbot",
      "fallback"=>"not done",
      "text"=>"\n new general task2 for ray | *Assigned* to @ray.",
      "id"=>4,
            "actions"=>
             [{"id"=>"5", "name"=>"done", "text"=>"Done", "type"=>"button", "value"=>"3", "style"=>"primary"},
              {"id"=>"6", "name"=>"discuss", "text"=>"Discuss", "type"=>"button", "value"=>"2:C0VNKV7BK", "style"=>"primary"}]},
           {"callback_id"=>"taskbot",
            "fallback"=>"not done",
            "text"=>"\n new general task3 for ray | *Assigned* to @ray.",
            "id"=>5,
            "actions"=>
             [{"id"=>"7", "name"=>"done", "text"=>"Done", "type"=>"button", "value"=>"4", "style"=>"primary"},
              {"id"=>"8", "name"=>"discuss", "text"=>"Discuss", "type"=>"button", "value"=>"3:C0VNKV7BK", "style"=>"primary"}]}],
         "type"=>"message",
         "subtype"=>"bot_message",
         "ts"=>"1475292447.000003"},
       "response_url"=>"https://hooks.slack.com/actions/T0VN565N0/86266339975/N8jQrfSpwOCflm548YQCe6YK"}

       task_num_to_discuss, chan_id_to_discuss = payload['actions'].first['value'].split(':')
       chan_to_discuss = Channel.find_from(
         source: :slack,
         slash_url_params: { 'user_id' => parsed[:url_params][:user_id],
                             'team_id' => parsed[:url_params][:team_id],
                             'channel_id' => chan_id_to_discuss
                           })
       task_to_discuss = ListItem.items(team_id: parsed[:url_params][:team_id],
                                       channel_id: chan_id_to_discuss)[task_num_to_discuss.to_i]
=end
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
