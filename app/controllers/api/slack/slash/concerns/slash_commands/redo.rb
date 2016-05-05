# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do redo 1 Send out newsletter by /fri. Deletes tasks 1 and replaces it with "Send out newsletter by /fri"
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

# Returns: text response msg, parsed[:err_msg]
def redo_one(parsed)
  return if task_num_invalid?(parsed)
  redo_response, new_task_cmd_string = redo_response_if_all_goes_well(parsed)
  # Tell the delete cmd to delete the specified item.
  parsed[:on_behalf_of_redo_cmd] = true
  del_cmd_response_text = delete_command(parsed)
  return del_cmd_response_text unless parsed[:err_msg].empty?
  # Tell the add command to process the replacement add task command.
  parsed[:command] = new_task_cmd_string
  add_cmd_response_text = add_command(parsed)
  return add_cmd_response_text unless parsed[:err_msg].empty?
  redo_response
end

def redo_response_if_all_goes_well(parsed)
  # item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  # Replace the current item task with command string starting after the
  # task num.
  new_task_cmd_string = parsed[:cmd_splits][1..-1].join(' ')
  # replaced_assigned_member = !item.assigned_member_id.nil?
  # replaced_assigned_member_name = replaced_assigned_member ? item.assigned_member_name : ''
  # replaced_due_date = !item.due_date.nil?
  # replaced_due_date_string = replaced_due_date ? item.due_date.strftime('%a, %d %b') : ''
  # replaced_done_status = !item.done

  # task_replacement_clause = '\''.concat(new_task_cmd_string).concat('\'')
  # assigned_member_replacement_clause = '' unless replaced_assigned_member
  # if replaced_assigned_member
  #  assigned_member_replacement_clause =
  #    "Replaced ASSIGNed member '@#{replaced_assigned_member_name}' with " \
  #    "'#{parsed[:assigned_member_id].nil? ? '' : "@#{parsed[:assigned_member_name]}"}'."
  # end
  # due_date_replacement_clause = '' unless replaced_due_date
  # if replaced_due_date
  #  due_date_replacement_clause =
  #    "Replaced DUE date of '#{replaced_due_date_string}' with " \
  #    "'#{parsed[:due_date].strftime('%a, %d %b')}'"
  # end
  # done_status_replacement_clause = '' unless replaced_done_status
  # done_status_replacement_clause = 'Replaced DONE status.' if replaced_done_status
  # Text response is a summary.
  # redo_response =
  #  "Task #{parsed[:task_num]} TO BE rewritten as " \
  #  "#{task_replacement_clause}  " \
  #  "#{assigned_member_replacement_clause}  " \
  #  "#{due_date_replacement_clause}  \n" \
  #  "#{done_status_replacement_clause}  "
  redo_response =
    "Deleted task #{parsed[:task_num]} and replaced it with '#{new_task_cmd_string}'."
  [redo_response, new_task_cmd_string]
end

def adjust_redo_cmd_action_context(parsed)
  # Figure out the list we are working on and its attributes.

  # Delete task from list user is looking at.
  inherit_list_scope(parsed)
  inherit_channel_scope(parsed)
  implied_list_owner(parsed)
  # adjust_redo_cmd_action_list(parsed)
  # adjust_redo_cmd_list_owner(parsed)
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
#-------------------------------------------
# /do redo 1 Send out newsletter by /fri. Deletes tasks 1 and replaces it with "Send out newsletter by /fri"
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
