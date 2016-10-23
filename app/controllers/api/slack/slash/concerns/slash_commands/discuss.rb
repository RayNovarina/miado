# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments, response_options]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
def discuss_command(parsed)
  text, attachments, options = discuss_button_taskbot(parsed)
  # Save parsed[:after_action_list_context] because it has handy button
  # callback_id{} used by our event handler.
  # Save channel activity type as helper for our event handler.
  save_after_action_list_context(parsed, parsed, parsed[:previous_action_list_context][:list])
  [text, attachments, options]
end

# Returns: [text, attachments, response_options]
def discuss_button_taskbot(parsed)
  text = ''
  attachments =
    list_button_taskbot_headline_replacement(parsed) # in list_button_taskbot.rb
    .concat([pretext: "Ok, type in a comment for the task:`#{parsed[:button_callback_id][:task_desc].delete('|')}`" \
                      "\nWhen done, hit [enter] and it will be posted as " \
                      "a team message in your `##{parsed[:button_callback_id][:slack_chan_name]}` channel.\n\n",
             mrkdwn_in: ['pretext']])
  [text, attachments, parsed[:first_button_value][:resp_options]]
end
