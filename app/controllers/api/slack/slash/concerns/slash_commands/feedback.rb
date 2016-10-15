
# Returns: [text, attachments]
def feedback_command(parsed)
  text, attachments, options = send_comment(parsed)
  @view.channel.update(
    last_activity_type:  parsed[:button_callback_id].nil? ? 'slash_command - feedback' : 'button_action - feedback',
    last_activity_date: DateTime.current)
  [text, attachments, options]
end

# Returns: [text, attachments]
def send_comment(parsed)
  return feedback_button_add_task(parsed) if parsed[:button_callback_id][:func] == 'add task'
  return feedback_button_taskbot_rpts(parsed) if parsed[:button_callback_id][:func] == 'taskbot'
  submitted_comment = comment_from_slash_feedback(parsed)
  if submitted_comment.valid?
    CommentMailer.new_comment(@view, submitted_comment).deliver_now
    return ['Thank you, we appreciate your input.', []]
  end
  parsed[:err_msg] = 'Error: Feedback message is empty.'
end

=begin
  Form Params
  channel_id	C0VNKV7BK
  channel_name	general
  command	/do
  response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
  team_domain	shadowhtracteam
  team_id	T0VN565N0
  text	call GoDaddy @susan /fri
  token	3ZQVG7rk4p7EZZluk1gTH3aN
  user_id	U0VLZ5P51
  user_name	ray
=end

# Returns: Comment object.
def comment_from_slash_feedback(parsed)
  parsed[:mcb] = slack_member_from_url_params(parsed)
  name = "#{parsed[:url_params][:user_name]} on Slack Team '#{parsed[:mcb].slack_team_name}'"
  email = '**Submitted as feedback**'
  body = parsed[:cmd_splits].join(' ')
  Comment.new(name: name, email: email, body: body)
end

# Returns: [text, attachments]
def feedback_button_add_task(parsed)
  feedback_button_add_task_response(parsed)
  # feedback_button_add_task_chat_msg(parsed)
end

=begin
{ name: 'feedback',
  text: 'Feedback',
  type: 'button',
  # value: { item_db_id: item_db_id,
  #         response_headline: response_text
  #       }.to_json
  value: { resp_options: { replace_original: false } }.to_json
}
=end
def feedback_button_add_task_response(parsed)
  text = ''
  attachments = []
  attachments <<
    add_response_attachment(
      parsed[:button_callback_id][:response_headline],
      parsed[:button_callback_id][:item_db_id]
    ) if parsed[:first_button_value][:resp_options].nil? ||
         parsed[:first_button_value][:resp_options][:replace_original]
  attachments <<
    { pretext: 'Please use the MiaDo `/do feedback` command to email MiaDo ' \
      "product support.\n" \
      "Example: `/do feedback This is my suggestion. [enter]`\n\n",
      mrkdwn_in: ['pretext']
    }
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
