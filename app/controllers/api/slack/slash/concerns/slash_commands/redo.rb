# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          list = unmodified.
#-------------------------------------------------
# /do redo 1 Send out newsletter by /fri. Deletes tasks 1 and replaces it with "Send out newsletter by /fri"
def redo_command(parsed)
  # We are trying to delete and re-add a task on a list the user is looking at.
  adjust_inherited_cmd_action_context(parsed)
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
