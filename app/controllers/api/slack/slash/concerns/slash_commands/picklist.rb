# Inputs: parsed = parsed command line info that has been verified.
# Returns: [text, attachments]
#-------------------------------------------------
def picklist_command(parsed)
  # ASSUME parsed [:button_callback_id][:id] == 'taskbot'

  # Ack the slack server ASAP. We have the parsed{} info. Handle the real
  # response work as a deferred command. It has most of our useful Slack API
  # lib methods.
  # parsed[:expedite_deferred_cmd] = false
  # [nil, nil]
  text, attachments, options = picklist_button_taskbot(parsed)
  [text, attachments, options]
end

# Returns: [text, attachments, response_options]
def picklist_button_taskbot(parsed)
  prompt_action = 'MARK the corresponding to-do task as `DONE`/closed' if parsed[:first_button_value][:id] == 'done'
  prompt_action = '`DELETE` the corresponding to-do task' if parsed[:first_button_value][:id] == 'done and delete'
  prompt_msg =
    "Ok, pick a button, any button to #{prompt_action}."
  text = parsed[:url_params][:payload][:original_message][:text]
  attachments =
    parsed[:url_params][:payload][:original_message][:attachments]
    .concat([pretext: prompt_msg, mrkdwn_in: ['pretext']])
    .concat(task_select_buttons_replacement(parsed, 'taskbot footer')) # in list_all_chans_taskbot.rb
  [text, attachments, parsed[:first_button_value][:resp_options]]
end
