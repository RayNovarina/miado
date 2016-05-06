# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do append 3 Contact Jim. Adds "Contact Jim." to the end of task 3.
def append_command(parsed)
  adjust_append_cmd_action_context(parsed)
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

def adjust_append_cmd_action_context(parsed)
  # Figure out the list we are working on and its attributes.

  inherit_list_scope(parsed)
  inherit_channel_scope(parsed)
  implied_list_owner(parsed)
  # adjust_append_cmd_action_list(parsed)
  # adjust_append_cmd_list_owner(parsed)
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
#-------------------------------------------
# /do append 3 Contact Jim. Adds "Contact Jim." to the end of task 3.
#--------------------------------------------------------
def adjust_append_cmd_action_list(parsed)
  # We are trying to append to a task for a specific member on a
  # member or team list. This is the only option to get here. We will err out
  # otherwise.
  return parsed[:list] = [] if parsed[:previous_action_list_context].empty?
  # Inherit item list from what user is looking at.
  parsed[:list] = parsed[:previous_action_list_context][:list]
end

# Inherit list_owner from what user is looking at.
def adjust_append_cmd_list_owner(parsed)
  return parsed[:list_owner] = :team, parsed[:list_owner_name] = '??team' if parsed[:previous_action_list_context].empty?
  parsed[:list_owner] = parsed[:previous_action_list_context][:list_owner]
  parsed[:list_owner_name] = parsed[:previous_action_list_context][:list_owner_name]
end
