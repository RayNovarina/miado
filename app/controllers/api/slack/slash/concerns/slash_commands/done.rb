# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do done 4  Marks task 4 for this channel as done.
def done_command(parsed)
  return taskbot_done_command(parsed) if parsed[:is_taskbot_channel]
  # We are trying to set a task's done status on a list the user is looking at.
  adjust_inherited_cmd_action_context(parsed)
  text = done_one(parsed)
  return [parsed[:err_msg], nil] unless parsed[:err_msg].empty?
  # Persist the channel.list_ids[], options for the next transaction.
  save_after_action_list_context(parsed, parsed, parsed[:list])
  # Display modified list after adding an item if in debug mode.
  parsed[:display_after_action_list] = true if parsed[:debug]
  [text, nil]
end

def done_one(parsed)
  save_item_info(parsed, -1)
  return if task_num_invalid?(parsed)
  item = save_item_info(parsed, parsed[:list][parsed[:task_num] - 1])
  item.done = true
  item.updated_by_slack_user_id = parsed[:url_params]['user_id']
  if item.save
    return "Task #{parsed[:task_num]} " \
           "#{item.assigned_member_id.nil? ? '' : "for @#{slack_member_name_from_slack_user_id(parsed, item.assigned_member_id)}"} " \
           'set to a completed/DONE status.'
  end
  parsed[:err_msg] = 'Error: There was an error setting this Task to a DONE status.'
end

def taskbot_done_command(parsed)
  parsed[:err_msg] = 'Error: Taskbot done command not supported yet.'
end
