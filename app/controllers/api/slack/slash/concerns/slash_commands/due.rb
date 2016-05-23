# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do due /wed   Sets the task due date to Wednesday for task 4.
def due_command(parsed)
  # We are trying to set a task's due date on a list the user is looking at.
  adjust_inherited_cmd_action_context(parsed)
  text = due_one(parsed)
  return [parsed[:err_msg], nil] unless parsed[:err_msg].empty?
  # Persist the channel.list_ids[], options for the next transaction.
  save_after_action_list_context(parsed, parsed, parsed[:list])
  # Display modified list after adding an item if in debug mode.
  parsed[:display_after_action_list] = true if parsed[:debug]
  [text, nil]
end

def due_one(parsed)
  return if task_num_invalid?(parsed)
  item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  item.assigned_due_date = parsed[:due_date]
  if item.save
    return "Task #{parsed[:task_num]} " \
           "#{item.assigned_member_id.nil? ? '' : "for @#{slack_member_name_from_slack_user_id(parsed, item.assigned_member_id)}"} " \
           "set to a due date of #{item.assigned_due_date.strftime('%a, %d %b')}"
  end
  parsed[:err_msg] = 'Error: There was an error setting this Task\'s due date.'
end
