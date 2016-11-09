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

# Purpose: Taskbot report "Done" or "Delete" button has been clicked. We need
#          to generate rows of task select buttons.
# Returns: [text, attachments, response_options]
def picklist_button_taskbot(parsed)
  # Nothing to change sometimes.
  return [nil, []] if picklist_button_taskbot_the_same(parsed)

  text = parsed[:url_params][:payload][:original_message][:text]
  # Note: attachments = header, body, footer, maybe task select attachments.
  attachments = parsed[:url_params][:payload][:original_message][:attachments]
  unless parsed[:button_callback_id][:footer_pmt_num].nil?
    # Delete existing footer prompt msg attachments, we will be replacing em.
    attachments.slice!(
      parsed[:button_callback_id][:footer_pmt_idx] - 1,
      parsed[:button_callback_id][:footer_pmt_num])
    # Adjust following attachment indexes.
    parsed[:button_callback_id][:sel_idx] -= parsed[:button_callback_id][:footer_pmt_num]
    # Make sure our callback_id info is accurate, just in case.
    parsed[:button_callback_id][:footer_pmt_idx] = nil
    parsed[:button_callback_id][:footer_pmt_num] = nil
  end
  unless parsed[:button_callback_id][:sel_num].nil?
    # Delete existing task select attachments, we will be replacing em.
    attachments.slice!(
      parsed[:button_callback_id][:sel_idx] - 1,
      parsed[:button_callback_id][:sel_num])
    # Make sure our callback_id info is accurate, just in case.
    parsed[:button_callback_id][:sel_idx] = nil
    parsed[:button_callback_id][:sel_num] = nil
  end

  # We will be replacing the footer button attachments, delete em first.
  # Assume there are no footer_prompt or task_select attachments.
  attachments.delete_at(parsed[:button_callback_id][:footer_but_idx] - 1)
  footer_buttons_attch_idx = attachments.size + 1
  footer_buttons_num_attch = 1

  # Make new footer prompt attachments.
  prompt_action = 'MARK the corresponding to-do task as `DONE`/closed' if parsed[:first_button_value][:id] == 'done'
  prompt_action = '`DELETE` the corresponding to-do task' if parsed[:first_button_value][:id] == 'done and delete'
  prompt_msg =
    "Ok, pick a button, any button to #{prompt_action}."
  footer_prompt_attch_idx = footer_buttons_attch_idx + footer_buttons_num_attch
  footer_prompt_attachments = [pretext: prompt_msg, mrkdwn_in: ['pretext']]
  footer_prompt_num_attch = footer_prompt_attachments.size

  # Make new task select button attachments with updated caller_id info.
  # HACK - we need our select button caller_id to have correct task_select_attch_idx
  #        and we want to know the correct task_select_num_attch before we make
  #        the footer_buttons_attchments caller_id info.
  task_select_attch_idx = footer_prompt_attch_idx + footer_prompt_num_attch
  task_select_attachments, task_select_num_attch =
    task_select_buttons_replacement(parsed: parsed, cmd: 'new', # in list_all_chans_taskbot.rb
                                    attachments: attachments,
                                    caller_id: parsed[:button_callback_id][:caller],
                                    header_attch_idx: parsed[:button_callback_id][:header_idx],
                                    header_num_attch: parsed[:button_callback_id][:header_num],
                                    body_attch_idx: parsed[:button_callback_id][:body_idx],
                                    body_num_attch: parsed[:button_callback_id][:body_num],
                                    footer_buttons_attch_idx: footer_buttons_attch_idx,
                                    footer_buttons_num_attch: footer_buttons_num_attch,
                                    footer_prompt_attch_idx: footer_prompt_attch_idx,
                                    footer_prompt_num_attch: footer_prompt_num_attch,
                                    task_select_attch_idx: task_select_attch_idx,
                                    num_tasks: parsed[:button_callback_id][:num_tasks],
                                    # Recover the helper info we embedded in the footer buttons we just clicked.
                                    body_attch_info: parsed[:first_button_value][:ba_info])

  # Make new footer button attachments with updated caller_id info.
  footer_buttons_attachments, _footer_buttons_attch_idx, _footer_buttons_num_attch =
    list_button_taskbot_footer_replacement(parsed: parsed, cmd: 'new',
                                           attachments: attachments,
                                           caller_id: 'picklist',
                                           header_attch_idx: parsed[:button_callback_id][:header_idx],
                                           header_num_attch: parsed[:button_callback_id][:header_num],
                                           body_attch_idx: parsed[:button_callback_id][:body_idx],
                                           body_num_attch: parsed[:button_callback_id][:body_num],
                                           footer_buttons_attch_idx: footer_buttons_attch_idx,
                                           footer_buttons_num_attch: footer_buttons_num_attch,
                                           footer_prompt_attch_idx: footer_prompt_attch_idx,
                                           footer_prompt_num_attch: footer_prompt_num_attch,
                                           task_select_attch_idx: task_select_attch_idx,
                                           task_select_num_attch: task_select_num_attch,
                                           num_tasks: parsed[:button_callback_id][:num_tasks],
                                           num_but: parsed[:button_callback_id][:num_but] || parsed[:button_callback_id][:num_tasks])

  # Now add the footer buttons, prompt and select attachments to the body of the taskbot msg.
  attachments.concat(footer_buttons_attachments)
             .concat(footer_prompt_attachments)
             .concat(task_select_attachments)
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

=begin
  # Update the info in the button_callback_id block of the Slack msg so we can
  # use it on the next click.
  footer_callback = JSON.parse(attachments[parsed[:button_callback_id][:footer_buttons_attch_idx].to_i - 1]['callback_id']).with_indifferent_access
  footer_callback['footer_prompt_attch_idx'] = footer_prompt_attch_idx
  footer_callback['footer_prompt_num_attch'] = footer_prompt_num_attch
  footer_callback['task_select_attch_idx'] = footer_prompt_attch_idx + footer_prompt_num_attch
  footer_callback['task_select_num_attch'] = task_select_num_attch
  # Reinsert into json payload from slack.
  attachments[parsed[:button_callback_id][:footer_buttons_attch_idx].to_i - 1]['callback_id'] =
    footer_callback.to_json

  # Now add the prompt and select attachments to the body of the taskbot msg.
  footer_prompt_attch_idx = attachments.size + 1
    attachments.concat(footer_prompt_attachments)
               .concat(task_select_attachments
=end

# We will be replacing the footer and select attachments.
# attachments.delete_at(parsed[:button_callback_id][:footer_buttons_attch_idx].to_i - 1)
# taskbot_footer_attachments, _footer_buttons_attch_idx, _footer_buttons_num_attch =
#  list_button_taskbot_footer_replacement(parsed: parsed, cmd: 'new',
#                                         attachments: attachments,
#                                         caller_id: parsed[:button_callback_id][:caller_id],
#                                         body_attch_idx: parsed[:button_callback_id][:body_attch_idx],
#                                         list_ids: parsed[:button_callback_id][:list_ids])
# attachments.concat(taskbot_footer_attachments)
#            .concat([pretext: prompt_msg, mrkdwn_in: ['pretext']])
#            .concat(task_select_buttons_replacement(parsed: parsed, cmd: 'new')) # in list_all_chans_taskbot.rb

# Nothing to change sometimes.
def picklist_button_taskbot_the_same(_parsed)
  false
end
