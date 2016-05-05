# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do append 3 Contact Jim. Adds "Contact Jim." to the end of task 3.
def append_command(parsed)
  # We are trying to append to a task on a list the user is looking at.
  adjust_inherited_cmd_action_context(parsed)
  text = append_one(parsed)
  return [parsed[:err_msg], nil] unless parsed[:err_msg].empty?
  # Persist the channel.list_ids[], options for the next transaction.
  save_after_action_list_context(parsed, parsed, parsed[:list])
  # Display modified list after appending to the task.
  parsed[:display_after_action_list] = true
  [text, nil]
end

def append_one(parsed)
  return if task_num_invalid?(parsed)
  return parsed[:err_msg] = "Error: The string to be appended can not include a member assignment. You included '@#{parsed[:mentioned_member_name]}'" unless parsed[:mentioned_member_id].nil?
  return parsed[:err_msg] = "Error: The string to be appended can not include a due date. You included '#{parsed[:due_date_string]}'" unless parsed[:due_date].nil?
  item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  # Rebuild command string starting after the task num.
  item.description += ' '.concat(parsed[:cmd_splits][1..-1].join(' '))
  return "Task #{parsed[:task_num]} appended." if item.save
  parsed[:err_msg] = 'Error: There was an error appending this Task.'
end
