# Inputs: parsed = parsed command line info that has been verified.
#         before_action list: [ListItem.id] for the list that the user
#                             is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          action list = deleted item removed.
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# list_owner = :team, :mine, <@name>
# assigned_member_name = <@name>
#------------------------------
# /do assign 3 @tony Assigns "@tony" to task 3 for this channel.
# full syntax: /do assign channel 3 @tony
#              /do assign team 3 @tony
#-----------------------------------
def assign_command(parsed)
  # We are trying to assign a task to a list the user is looking at.
  adjust_inherited_cmd_action_context(parsed)
  text = assign_one(parsed)
  return [parsed[:err_msg], nil] unless parsed[:err_msg].empty?
  # Persist the channel.list_ids[], options for the next transaction.
  save_after_action_list_context(parsed, parsed, parsed[:list])
  # Display modified list after adding an item if in debug mode.
  parsed[:display_after_action_list] = true if parsed[:debug]
  [text, nil]
end

def assign_one(parsed)
  return if task_num_invalid?(parsed)
  item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  return parsed[:err_msg] = "Error: Task #{parsed[:task_num]} is already " \
    "assigned to #{parsed[:assigned_member_name]}" if item.assigned_member_id == parsed[:assigned_member_id]
  prev_assigned_member_name = slack_member_name_from_slack_user_id(parsed, item.assigned_member_id)
  item.assigned_member_id = parsed[:assigned_member_id]
  if item.save
    task_owner = parsed[:list_owner]
    task_owner = 'your' if parsed[:list_owner] == :mine
    task_owner = 'team' if parsed[:list_owner] == :team
    return "Assigned #{task_owner} task #{parsed[:task_num]} to " \
           "@#{parsed[:assigned_member_name]}." \
           "#{prev_assigned_member_name.nil? ? '' : '  NOTE: It was previously assigned ' \
           "to @#{prev_assigned_member_name}"}"
  end
  parsed[:err_msg] = 'Error: There was an error assigning this Task.'
end
