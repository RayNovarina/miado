# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do unassign 3 @tony Unassigns "@tony" from task 3 for this channel.
# When I unassign a team task, the result list does not include the unassigned
# task.  But a "/do list team" done immediately after displays the unassigned
# task.

def unassign_command(parsed)
  # We are trying to unassign a task to a list the user is looking at.
  adjust_inherited_cmd_action_context(parsed)
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
  return if parsed[:previous_action_list_context].empty?
  parsed[:list].delete_at(parsed[:task_num] - 1) if parsed[:previous_action_list_context][:list_scope] == :one_member
end
