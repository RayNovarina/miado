# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do unassign 3 @tony Unassigns "@tony" from task 3 for this channel.
def unassign_command(parsed)
  adjust_unassign_cmd_action_context(parsed)
  text = unassign_one(parsed)
  return [parsed[:err_msg], nil] unless parsed[:err_msg].empty?
  # Persist the channel.list_ids[], options for the next transaction.
  save_after_action_list_context(parsed, parsed, parsed[:list])
  # Display modified list after unassigning an item.
  parsed[:display_after_action_list] = true
  [text, nil]
end

def unassign_one(parsed)
  return if task_num_invalid?(parsed)
  item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  return parsed[:err_msg] = "Error: Task #{parsed[:task_num]} is not " \
    'assigned to anyone.' if item.assigned_member_id.nil?
  return parsed[:err_msg] = "Error: Task #{parsed[:task_num]} is not " \
    "assigned to #{parsed[:assigned_member_name]}" unless item.assigned_member_id == parsed[:assigned_member_id]
  item.assigned_member_id = nil
  item.assigned_member_name = nil
  if item.save
    adjust_unassign_after_action_list(parsed)
    return "Unassigned task #{parsed[:task_num]} from " \
           "@#{parsed[:assigned_member_name]}."
  end
  parsed[:err_msg] = 'Error: There was an error unassigning this Task.'
end

# If we are looking at a member's assigned items only list, drop the
# unassigned item.
def adjust_unassign_after_action_list(parsed)
  parsed[:list].delete_at(parsed[:task_num] - 1) if parsed[:list_scope] == :one_member
end

def adjust_unassign_cmd_action_context(parsed)
  adjust_unassign_cmd_assigned_member(parsed)
  # Figure out the list we are working on and its attributes.
  adjust_unassign_cmd_action_list(parsed)
  adjust_unassign_cmd_list_owner(parsed)
end

def adjust_unassign_cmd_assigned_member(parsed)
  # Unassigned member info will be stored in db and persisted as after action info
  parsed[:assigned_member_id] = parsed[:mentioned_member_id]
  parsed[:assigned_member_name] = parsed[:mentioned_member_name]
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
#-------------------------------------------
# /do unassign 3 @tony Unassigns "@tony" from task 3 in this channel.
#--------------------------------------------------------
def adjust_unassign_cmd_action_list(parsed)
  # We are trying to unassign a task to a specific member on a member or team
  # list. This is the only option to get here. We will err out otherwise.
  return parsed[:list] = [] if parsed[:previous_action_list_context].empty?
  # Inherit item list from what user is looking at.
  parsed[:list] = parsed[:previous_action_list_context][:list]
end

# Inherit list_owner from what user is looking at.
def adjust_unassign_cmd_list_owner(parsed)
  return parsed[:list_owner] = :team, parsed[:list_owner_name] = '??team' if parsed[:previous_action_list_context].empty?
  parsed[:list_owner] = parsed[:previous_action_list_context][:list_owner]
  parsed[:list_owner_name] = parsed[:previous_action_list_context][:list_owner_name]
end
