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
  unless parsed[:button_callback_id][:sel_idx].nil?
    # Delete existing task select attachments, we will be replacing em.
    attachments.slice!(
      parsed[:button_callback_id][:sel_idx] - 1,
      attachments.size - parsed[:button_callback_id][:sel_idx] + 1)
    # Make sure our callback_id info is accurate, just in case.
    parsed[:button_callback_id][:sel_idx] = nil
  end
  unless parsed[:button_callback_id][:footer_pmt_idx].nil?
    # Delete existing footer prompt msg attachments, we will be replacing em.
    attachments.slice!(
      parsed[:button_callback_id][:footer_pmt_idx] - 1,
      parsed[:button_callback_id][:footer_pmt_num])
    # Make sure our callback_id info is accurate, just in case.
    parsed[:button_callback_id][:footer_pmt_idx] = nil
    parsed[:button_callback_id][:footer_pmt_num] = nil
  end

  # Create map of select button labels and action values.
  select_list_info = select_list_pattern_from_body_attachments(
    body_attachments: attachments.slice(
      parsed[:button_callback_id][:body_idx] - 1,
      parsed[:button_callback_id][:body_num]),
    parsed: parsed)

  # We will be replacing the footer button attachments, delete em first.
  # Assume there are no footer_prompt or task_select attachments.
  attachments.delete_at(parsed[:button_callback_id][:footer_but_idx] - 1)
  # We know we will be creating one footer button attachment.
  footer_buttons_attch_idx = attachments.size + 1
  footer_buttons_num_attch = 1

  # Make new footer prompt attachments.
  prompt_action = 'MARK the corresponding to-do task as `DONE`/closed' if parsed[:first_button_value][:id] == 'done'
  prompt_action = '`DELETE` the corresponding to-do task' if parsed[:first_button_value][:id] == 'done and delete'
  prompt_msg =
    "Ok, pick a button, any button to #{prompt_action}." unless select_list_info[:select_lists].empty?
  prompt_msg =
    'All tasks are already completed for this list. They can only be Deleted.' if select_list_info[:select_lists].empty?
  footer_prompt_attch_idx = footer_buttons_attch_idx + footer_buttons_num_attch
  footer_prompt_attachments, footer_prompt_num_attch =
    list_button_taskbot_footer_prompt_replacement(
      parsed: parsed, cmd: 'new', # in list_all_chans_taskbot.rb
      prompt_msg: prompt_msg)

  # Make new task select button attachments with updated caller_id info.
  # HACK - we need our select button caller_id to have correct task_select_attch_idx
  #        and we want to know the correct task_select_num_attch before we make
  #        the footer_buttons_attchments caller_id info.
  task_select_attch_idx = footer_prompt_attch_idx + footer_prompt_num_attch
  task_select_attachments, task_select_num_attch =
    task_select_buttons_replacement(parsed: parsed, cmd: 'new', # in list_all_chans_taskbot.rb
                                    # attachments: attachments,
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
                                    # HACK: we want each button caller_id to
                                    # have the total num of button strips/attchs
                                    # We know one select_attachment per 5 buttons.
                                    # task_select_num_attch: (select_list_info[:total_options].to_f / 5.0).ceil,
                                    select_list_info: select_list_info
                                   )

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
                                           task_select_num_attch: task_select_num_attch
                                          )
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

=begin
{ caller: 'taskbot footer picklists',
  total_options: 3,
  select_lists: [
    { name: 'general',
      first_option_num: 1,
      last_option_num: 2,
      num_options: 2,
      options: [{ label: '1', value: { tasknum: 1,
                                       slack_channel_name: 'general'}
                },
                { label: '2', value: { tasknum: 2,
                                       slack_channel_name: 'general'}
                }
              ]
    },
    { name: 'issues',
      options: [{ label: '3', value: { tasknum: 3,
                                       slack_channel_name: 'issues'}
                }
              ]
    }
=end
def select_list_pattern_from_body_attachments(options)
  options[:sel_pattern] = new_pattern(caller: 'taskbot footer picklists')
  options[:body_attachments].each_with_index do |body_attch, body_idx|
    body_attch[:text].split("\n").each_with_index do |line, line_idx|
      # ["---- #general channel (1st tasknum: 1)----------",
      # "1) gen 1 | *Assigned* to @dawnnova.",
      # "2) gen 3 | *Assigned* to @dawnnova.",
      # "3) gen 1 | *Assigned* to @ray."]
      add_taskbot_select_option(options.merge!(sel_body_idx: body_idx,
                                               sel_line: line,
                                               sel_line_idx: line_idx))
    end
  end
  options[:sel_line_idx] = nil # signal that we are not starting a new list.
  end_of_previous_taskbot_select_list(options)
  options[:sel_pattern]
end

# Returns: either a select_list{} or a select_options{}
def add_taskbot_select_option(options)
  # End of one channel list, begin of another if line_idx == 0
  return end_of_previous_taskbot_select_list(options) if options[:sel_line_idx] == 0
  tasknum = tasknum_from_taskbot_line(options[:sel_line])
  current_list = options[:sel_pattern][:select_lists].last
  # HACK - exclude completed tasks from button list.
  return current_list if options[:parsed][:first_button_value][:id] == 'done' &&
                         done_option_from_taskbot_line(options[:sel_line])
  current_list[:options] <<
    new_select_option(options.merge!(label: tasknum,
                                     value: { tasknum: tasknum,
                                              slack_channel_name: current_list[:name]
                                            }
                                    ))
  options[:sel_pattern][:total_options] += 1
  current_list
end

def done_option_from_taskbot_line(line)
  line.end_with?('| *Completed*')
end

# Inputs: :line_idx == nil means just ending current list, not starting new.
# Returns: updated current select list{}
def end_of_previous_taskbot_select_list(options)
  prev_list = options[:sel_pattern][:select_lists].last
  # Previous channel block may be empty. No buttons. Remove.
  unless prev_list.nil? || !prev_list[:options].empty?
    options[:sel_pattern][:select_lists].pop
    prev_list = options[:sel_pattern][:select_lists].last
  end
  unless options[:sel_line_idx].nil?
    options[:sel_pattern][:select_lists] <<
      new_select_list(
        options.merge!(name: chan_name_from_taskbot_line(options[:sel_line]),
                       first_option_num: options[:first_option_num] || nil,
                       last_option_num: options[:last_option_num] || nil,
                       num_options: options[:num_options] || nil
                      ))
  end
  # Update previous list fields that are now known.
  return nil if prev_list.nil?
  prev_list[:num_options] = prev_list[:options].size
  prev_list[:first_option_num] =
    prev_list[:options].first[:value][:tasknum]
  prev_list[:last_option_num] =
    prev_list[:options].last[:value][:tasknum]
  return prev_list if options[:sel_line_idx].nil?
  # Return new current select list.
  options[:sel_pattern][:select_lists].last
end

# Purpose: to populate picklists or button strips.
# select_list_pattern:
#   { select_lists: [
#       ...
#       options: [
#         ...
#       ]
#     ]
#   }
def new_pattern(options)
  { caller: options[:caller],
    total_options: 0,
    select_lists: []
  }
end

def new_select_list(options)
  { name: options[:name],
    first_option_num: options[:first_option_num] || nil,
    last_option_num: options[:last_option_num] || nil,
    num_options: options[:first_option_num] || nil,
    options: []
  }
end

def new_select_option(options)
  { label: options[:label],
    value: options[:value]
  }
end
