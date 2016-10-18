
# Returns: [text, attachments, response_options]
def feedback_command(parsed)
  text, attachments, options = send_comment(parsed)
  @view.channel.update(
    last_activity_type:  parsed[:button_callback_id].nil? ? 'slash_command - feedback' : 'button_action - feedback',
    last_activity_date: DateTime.current)
  [text, attachments, options]
end

# Returns: [text, attachments, response_options]
def send_comment(parsed)
  return feedback_button_add_task(parsed) if !parsed[:button_callback_id].nil? && parsed[:button_callback_id][:id] == 'add task'
  return feedback_button_taskbot_rpts(parsed) if !parsed[:button_callback_id].nil? && parsed[:button_callback_id][:id] == 'taskbot'
  submitted_comment = comment_from_slash_feedback(parsed)
  if submitted_comment.valid?
    CommentMailer.new_comment(@view, submitted_comment).deliver_now
    return ['Thank you, we appreciate your input.', []]
  end
  parsed[:err_msg] = 'Error: Feedback message is empty.'
end

# Returns: Comment object.
def comment_from_slash_feedback(parsed)
  parsed[:mcb] = slack_member_from_url_params(parsed)
  name = "#{parsed[:url_params][:user_name]} on Slack Team '#{parsed[:mcb].slack_team_name}'"
  email = '**Submitted as feedback**'
  body = parsed[:cmd_splits].join(' ')
  Comment.new(name: name, email: email, body: body)
end

# Returns: [text, attachments, response_options]
def feedback_button_add_task(parsed)
  text = ''
  attachments =
    list_button_public_headline_replacement(parsed)
    .concat([pretext: 'Please use the MiaDo `/do feedback` command to email ' \
                      "MiaDo product support.\n" \
                      "Example: `/do feedback This is my suggestion. [enter]`\n\n",
             mrkdwn_in: ['pretext']])
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

def feedback_button_taskbot_rpts(parsed)
  text = ''
  attachments =
    list_button_action_headline_replacement(parsed)
    .concat([pretext: "Ok, type in a comment.\n" \
                      "\nWhen done, hit [enter] and it will be emailed to " \
                      "MiaDo product support and then removed from this channel.\n\n",
             mrkdwn_in: ['pretext']])
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

=begin
def feedback_button_add_task_chat_msg(parsed)
  text = "Ok, type in a comment.\n" \
    "\nWhen done, hit [enter] and it will be emailed to MiaDo product " \
    'support and then removed from this channel.'
  attachments = []
  parsed[:mcb] = slack_member_from_url_params(parsed)
  # api_resp =
  send_channel_msg(
    api_client: make_web_client(parsed[:mcb].slack_user_api_token),
    username: 'taskbot',
    channel_id: parsed[:url_params][:channel_id],
    text: text,
    attachments: attachments
  )
  # Persist our actions for the next transaction.
  # save_after_action_list_context(parsed, parsed)
  [nil, nil]
end
=end
