
# Returns: [text, attachments, response_options]
def feedback_command(parsed)
  return feedback_button_taskbot_rpts(parsed) if !parsed[:button_callback_id].nil? && parsed[:button_callback_id][:id] == 'taskbot'
  return feedback_button_public_chan(parsed) unless parsed[:button_callback_id].nil?
  submitted_comment = comment_from_slash_feedback(parsed)
  update_channel_activity(parsed)
  if submitted_comment.valid?
    new_comment = CommentMailer.new_comment(@view, submitted_comment)
    # log_to_channel(cb: parsed[:ccb],
    #               msg: { topic: 'Slash Feedback',
    #                      subtopic: 'new_comment = CommentMailer.new_comment(@view, submitted_comment)',
    #                      id: 'feedback_command()',
    #                      body: new_comment.to_json
    #                    })
    response = new_comment.deliver_now
    # log_to_channel(cb: parsed[:ccb],
    #               msg: { topic: 'Slash Feedback',
    #                      subtopic: 'response = new_comment.deliver_now',
    #                      id: 'feedback_command()',
    #                      body: response.to_json
    #                    })
    return ['Thank you, we appreciate your input.', []]
    # text = ''
    # attachments =
    #  list_chan_headline_replacement(parsed, nil, 'feedback') # in list.rb
    #  .concat([pretext: 'Thank you, we appreciate your input.',
    #           mrkdwn_in: ['pretext']])
    # return [text, attachments]
  end
  parsed[:err_msg] = 'Error: Feedback message is empty.'
end

# Returns: Comment object.
def comment_from_slash_feedback(parsed)
  parsed[:mcb] = slack_member_from_url_params(parsed)
  name = "#{parsed[:url_params][:user_name]} on Slack Team '#{parsed[:mcb].slack_team_name}'"
  email = '**Submitted as feedback**'
  body = parsed[:cmd_splits].join(' ')
  comment = Comment.new(name: name, email: email, body: body)
  # log_to_channel(cb: parsed[:ccb],
  #               msg: { topic: 'Slash Feedback',
  #                      subtopic: 'comment = Comment.new(name: name, email: email, body: body)',
  #                      id: 'comment_from_slash_feedback()',
  #                      body: comment.to_json
  #                    })
  comment
end

FEEDBACK_PUBLIC_TEXT =
  'Use the MiaDo `/do feedback` command to email ' \
  "MiaDo product support. \n" \
  "Please include an email address so we can respond and clarify if needed.\n" \
  'Example: `/do feedback From Jane@jj13@gmail.com This is my suggestion.`' \
  "\n".freeze

# Returns: [text, attachments, response_options]
def feedback_button_public_chan(parsed)
  text = ''
  attachments =
    list_chan_headline_replacement(parsed, nil, 'feedback') # in list.rb
    .concat([pretext: FEEDBACK_PUBLIC_TEXT,
             mrkdwn_in: ['pretext']])
  update_channel_activity(parsed)
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

def feedback_button_taskbot_rpts(parsed)
  text = ''
  attachments =
    list_button_taskbot_headline_replacement(parsed, '', 'feedback') # in list_button_taskbot.rb
    .concat([pretext: "Ok, type in a comment.\n" \
                      "\nWhen done, hit [enter] and it will be emailed to " \
                      "MiaDo product support.\n\n",
             mrkdwn_in: ['pretext']])
  # NOTE: should not need parsed[:button_callback_id]['payload_message_ts']
  # message.ts to edit is in parsed[:mcb].bot_msgs_json - should be first
  # and only taskbot msg.
  parsed[:ccb].after_action_parse_hash['button_callback_id'] = parsed[:button_callback_id]
  update_channel_activity(parsed, nil, parsed[:ccb].after_action_parse_hash)
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
