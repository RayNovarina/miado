# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do redo /wed   Sets the task redo date to Wednesday for task 4.
def redo_command(parsed)
  adjust_redo_cmd_action_context(parsed)
  text = redo_one(parsed)
  return [parsed[:err_msg], nil] unless parsed[:err_msg].empty?
  # Persist the channel.list_ids[], options for the next transaction.
  save_after_action_list_context(parsed, parsed, parsed[:list])
  # Display modified list after setting an item's redo date.
  parsed[:display_after_action_list] = true
  [text, nil]
end

def redo_one(parsed)
  # error if invalide task num
  return if task_num_invalid?(parsed)
  item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  item.assigned_redo_date = parsed[:redo_date]
  if item.save
    return "Task #{parsed[:task_num]} " \
           "#{item.assigned_member_id.nil? ? '' : "for @#{item.assigned_member_name}"} " \
           "set to a redo date of #{item.assigned_redo_date.strftime('%a, %d %b')}"
  end
  parsed[:err_msg] = 'Error: There was an error setting this Task\'s redo date.'
end

def adjust_redo_cmd_action_context(parsed)
  # Figure out the list we are working on and its attributes.
  adjust_redo_cmd_action_list(parsed)
  adjust_redo_cmd_list_owner(parsed)
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
#-------------------------------------------
# /do redo /wed   Sets the task redo date to Wednesday for task 4.
#--------------------------------------------------------
def adjust_redo_cmd_action_list(parsed)
  # We are trying to set a task's redo date for a specific member on a
  # member or team list. This is the only option to get here. We will err out
  # otherwise.
  return parsed[:list] = [] if parsed[:previous_action_list_context].empty?
  # Inherit item list from what user is looking at.
  parsed[:list] = parsed[:previous_action_list_context][:list]
end

# Inherit list_owner from what user is looking at.
def adjust_redo_cmd_list_owner(parsed)
  return parsed[:list_owner] = :team, parsed[:list_owner_name] = '??team' if parsed[:previous_action_list_context].empty?
  parsed[:list_owner] = parsed[:previous_action_list_context][:list_owner]
  parsed[:list_owner_name] = parsed[:previous_action_list_context][:list_owner_name]
end
