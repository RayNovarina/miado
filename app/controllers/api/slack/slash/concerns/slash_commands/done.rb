# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do done 4  Marks task 4 for this channel as done.
def done_command(parsed)
  # We are trying to set a task's done status on a list the user is looking at.
  adjust_inherited_cmd_action_context(parsed)
  text = done_one(parsed)
  return [parsed[:err_msg], nil] unless parsed[:err_msg].empty?
  # Persist the channel.list_ids[], options for the next transaction.
  save_after_action_list_context(parsed, parsed, parsed[:list])
  # Display modified list after setting an item as done.
  parsed[:display_after_action_list] = true
  [text, nil]
end

def done_one(parsed)
  return if task_num_invalid?(parsed)
  item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  return parsed[:err_msg] = "Error: Task #{parsed[:task_num]} is not " \
    'assigned to anyone.' if item.assigned_member_id.nil?
  item.done = true
  if item.save
    return "Task #{parsed[:task_num]} " \
           "#{item.assigned_member_id.nil? ? '' : "for @#{item.assigned_member_name}"} " \
           'set to a completed/DONE status.'
  end
  parsed[:err_msg] = 'Error: There was an error setting this Task to a DONE status.'
end
