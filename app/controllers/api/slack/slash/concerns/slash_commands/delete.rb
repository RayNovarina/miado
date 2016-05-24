# Inputs: parsed = parsed command line info that has been verified.
#         before_action list: [ListItem.id] for the list that the user
#                             is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          action list = deleted item removed.
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# SUB_FUNCS  = %w(open due more)
# list_owner = :team, :mine, <@name>
# mentioned_member_name = <@name>
#------------------------------
def delete_command(parsed)
  adjust_delete_cmd_action_context(parsed)
  text = delete_item(parsed)
  # Special case: just doing a delete for the redo command.
  return [text, nil] if parsed[:on_behalf_of_redo_cmd]
  if parsed[:err_msg].empty?
    # Persist the channel.list_ids[] for the next transaction.
    save_after_action_list_context(parsed, parsed, parsed[:list])
    # Display modified list after deleting an item.
    parsed[:display_after_action_list] = true
    return [text, nil]
  end
  [parsed[:err_msg], nil]
end

def delete_item(parsed)
  save_item_info(parsed, -1)
  return delete_many(parsed) if parsed[:task_num].nil?
  return delete_one(parsed) unless parsed[:task_num].nil?
end

# Returns: text msg.
#          parsed[:err_msg] if needed.
#          list is adjusted for deleted item(s)
def delete_one(parsed)
  return if task_num_invalid?(parsed)
  delete_task(parsed[:list][parsed[:task_num] - 1], parsed)
  if parsed[:err_msg].empty?
    parsed[:list].delete_at(parsed[:task_num] - 1)
    return "Deleted #{parsed[:list_scope == :team ? 'team' : 'your']} " \
           "task #{parsed[:task_num]}."
  end
  parsed[:err_msg]
end

# Returns: text msg.
#          parsed[:err_msg] if needed.
#          list is adjusted for deleted item(s)
def delete_task(id, parsed)
  item = save_item_info(parsed, id)
  return parsed[:err_msg] = "Error: Task(id: #{id}) not found to be deleted." if item.nil?
  return if item.destroy
  parsed[:err_msg] = "Error: There was an error deleting this Task(id: #{id})."
end

def save_item_info(parsed, id)
  if id == -1
    parsed[:list_action_item_info] = []
    return nil
  end
  item = ListItem.find(id)
  parsed[:list_action_item_info] << {
    db_id: item.id,
    assigned_member_id: item.assigned_member_id
  }
  item
end

def delete_many(parsed)
  return parsed[:err_msg] = 'Error: Delete command requires \'task number\', \'team\' or \'all\' options.' unless parsed[:all_option] || parsed[:team_option]
  destroy_all_by_ids(parsed[:list], parsed)
  if parsed[:err_msg].empty?
    parsed[:list] = []
    return delete_all_msg(parsed)
  end
  parsed[:err_msg]
end

def delete_all_msg(parsed)
  if parsed[:list_scope] == :team
    return 'Deleted tasks in THIS channel for ANY team member.' if parsed[:channel_scope] == :one_channel
    return 'Deleted tasks in ANY channel for ANY team member.' if parsed[:channel_scope] == :all_channels
  end
  # parsed[:list_scope] == :one_member
  if parsed[:channel_scope] == :one_channel
    return 'Deleted ALL of your ASSIGNED tasks in this channel.' if parsed[:list_owner] == :mine
    return "Deleted ALL of #{parsed[:list_owner_name]}\'s ASSIGNED tasks in this channel."
  end
  # parsed[:channel_scope] == :all_channels
  return 'Deleted ALL of your ASSIGNED tasks in ALL channels.' if parsed[:list_owner] == :mine
  "Deleted ALL of #{parsed[:list_owner]} ASSIGNED tasks in ALL channel."
end

def destroy_all_by_ids(list, parsed)
  list.each_with_index do |id, index|
    delete_task(id, parsed)
    next if parsed[:err_msg].empty?
    return parsed[:err_msg].concat("  ##{index} in list.")
  end
end

def adjust_delete_cmd_action_context(parsed)
  # Special case: doing a delete for redo command. Context already adjusted.
  return if parsed[:on_behalf_of_redo_cmd]

  # Delete task from list user is looking at.
  inherit_list_scope(parsed)
  inherit_channel_scope(parsed)
  # Figure out the list we are working on and its attributes.
  adjust_delete_cmd_action_list(parsed)
  implied_list_owner(parsed)
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
def adjust_delete_cmd_action_list(parsed)
  # Inherit item list from what user is looking at.
  return parsed[:list] = [] if parsed[:previous_action_list_context].empty?
  return parsed[:list] = parsed[:previous_action_list_context][:list] if delete_cmd_context_matches(parsed)
  # Note: the delete_cmd_context_matches method has already adjusted parsed
  #       attributes to fetch a correct list.
  parsed[:list] = ids_from_parsed(parsed)
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
#------------------------------------
def delete_cmd_context_matches(parsed)
  # Case: look at a list AND THEN 'delete 1'
  # Ok, just delete from the list.
  return true unless parsed[:task_num].nil?
  # Otherwise, fetch a list based on the list command options
  # so that delete command syntax matches what list would do. i.e. 'delete team'
  # will delete whatever 'list team' will display.
  list_of_ids_from_list_cmd(parsed)
  # Now that we have a new parsed[:list], use it.
  true
end

# @me member is implied if no Other member is mentioned. However, 'list team'
# implies no member is mentioned.
def adjust_delete_cmd_list_owner(parsed)
  return parsed[:list_owner] = :team, parsed[:list_owner_name] = 'team' if parsed[:list_scope] == :team
  parsed[:list_owner] = :member
  if parsed[:mentioned_member_id].nil?
    parsed[:mentioned_member_name] = parsed[:url_params][:user_name]
    parsed[:mentioned_member_id] = parsed[:url_params][:user_id]
  end
  parsed[:list_owner_name] = "@#{parsed[:mentioned_member_name]}"
end
