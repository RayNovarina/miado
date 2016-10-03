# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
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
                           }).first
       task_to_discuss = ListItem.items(team_id: parsed[:url_params][:team_id],
                                       channel_id: chan_id_to_discuss)[task_num_to_discuss.to_i]
=end
def discuss_command(parsed)
  payload = JSON.parse(parsed[:url_params][:payload]).with_indifferent_access
  button_value = JSON.parse(payload[:actions].first[:value]).with_indifferent_access
  task_desc = ListItem.find(button_value[:item_db_id].to_i).debug_trace.split("`")[1]
  text = "Ok, type in a comment for the task:\n`#{task_desc}`\n" \
    "\nWhen done, hit [enter] and it will be posted as " \
    "a team message in your `##{button_value[:slack_chan_name]}` channel."
  attachments = []
  # { attch_idx: attch_idx, slack_chan_id: item.channel_id, slack_chan_name: item.channel_name, item_db_id: item.id }
=begin
  text = "Ok, type in a comment for the task '#{ListItem.find(button_value[:item_db_id].to_i).description}'.\n" \
    "When done, hit [enter] and click the 'Post Comment' button and it will be posted as " \
    "a team message in your ##{button_value[:slack_chan_name]} channel."
  attachments = [
    { response_type: 'ephemeral',
      text: text,
      fallback: 'Do not discuss',
      callback_id: 'taskbot',
      color: '#3AA3E3',
      attachment_type: 'default',
      actions: [
        { name: 'post comment',
          text: "Post Comment",
          type: 'button',
          value: payload[:actions].first[:value]
        }
      ]
    }
  ]
=end
  # Persist the channel.list_ids[] for the next transaction.
  save_after_action_list_context(parsed, parsed)
  [text, attachments]
end
