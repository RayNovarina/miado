# Inputs: parsed = parsed command line info that has been verified.
#         before_action list: [ListItem.id] for the list that the user
#                             is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          action list = archived item removed.
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# SUB_FUNCS  = %w(open due more)
# list_owner = :team, :mine, <@name>
# mentioned_member_name = <@name>
#------------------------------
def archive_command(parsed)
  adjust_archive_cmd_action_context(parsed)
  text = archive_item(parsed)
  return [parsed[:err_msg], nil] unless parsed[:err_msg].empty?
  # Persist the channel.list_ids[], options for the next transaction.
  save_after_action_list_context(parsed, parsed, parsed[:list])
  # Display modified list after modifying an item if in debug mode.
  parsed[:display_after_action_list] = true if parsed[:debug]
  [text, nil]
end

def archive_item(parsed)
  save_item_info(parsed, -1)
  return archive_many(parsed) if parsed[:task_num].nil?
  archive_one(parsed) unless parsed[:task_num].nil?
end

# Returns: text msg.
#          parsed[:err_msg] if needed.
#          list is adjusted for archived item(s)
def archive_one(parsed)
  return if task_num_invalid?(parsed)
  text = archive_task(parsed[:list][parsed[:task_num] - 1], parsed, true)
  return parsed[:err_msg] unless parsed[:err_msg].empty?
  # Drop an archived item from the display list.
  # parsed[:list].delete_at(parsed[:task_num] - 1)
  text
end

# Returns: text msg.
#          parsed[:err_msg] if needed.
def archive_task(id, parsed, return_a_msg = false)
  item = save_item_info(parsed, id)
  return parsed[:err_msg] = "Error: Task(id: #{id}) not found to be archived." if item.nil?
  item.archived = true
  item.updated_by_slack_user_id = parsed[:url_params]['user_id']
  return (parsed[:err_msg] = 'Error: There was an error setting this Task to a DONE status.') unless item.save
  return "Task #{parsed[:task_num]} " \
         "#{item.assigned_member_id.nil? ? '' : "for @#{slack_member_name_from_slack_user_id(parsed, item.assigned_member_id)}"} " \
         'set to a ARCHIVED status.' if return_a_msg
end

# Returns: text msg.
#          parsed[:err_msg] if needed.
def archive_many(parsed)
  archive_all_by_ids(parsed[:list], parsed)
  return parsed[:err_msg] unless parsed[:err_msg].empty?
  text = archive_all_msg(parsed)
  parsed[:list] = []
  text
end

# Returns: text msg.
def archive_all_msg(parsed)
  num_archived = parsed[:list].size
  if parsed[:list_scope] == :team
    return "`archived #{num_archived} tasks in THIS channel for ALL team members.`" if parsed[:channel_scope] == :one_channel
    return "`archived #{num_archived} tasks in ANY channel for ALL team members.`" if parsed[:channel_scope] == :all_channels
  end
  # parsed[:list_scope] == :one_member
  if parsed[:channel_scope] == :one_channel
    return "`archived #{num_archived} of your tasks in this channel.`" if parsed[:list_owner] == :mine
    return "`archived #{num_archived} of #{parsed[:list_owner_name]}\'s tasks in this channel.`"
  end
  # parsed[:channel_scope] == :all_channels
  "`archived #{num_archived} of your tasks in ALL channels.`" if parsed[:list_owner] == :mine
  "`archived #{num_archived} of #{parsed[:list_owner_name]}\'s tasks in ALL channels.`"
end

def archive_all_by_ids(list, parsed)
  list.each_with_index do |id, index|
    archive_task(id, parsed, false)
    return parsed[:err_msg].concat("  ##{index} in list.") unless parsed[:err_msg].empty?
  end
end

def adjust_archive_cmd_action_context(parsed)
  unless parsed[:task_num].nil?
    # If task number is specified, use the list the user is looking at.
    inherit_list_scope(parsed)
    inherit_channel_scope(parsed)
    implied_list_owner(parsed)
    # Figure out the list we are working on and its attributes.
    adjust_archive_cmd_action_list(parsed)
  end
  if parsed[:task_num].nil?
    # We are archiving a group of tasks. Explicitly get a new list, do not
    # use what user is looking at.
    # list command defaults to DONE/completed tasks.
    implied_mentioned_member(parsed)
    parsed[:list_scope] = :one_member unless parsed[:team_option]
    parsed[:list_scope] = :team if parsed[:team_option]
    parsed[:channel_scope] = :one_channel unless parsed[:all_option]
    parsed[:channel_scope] = :all_channels if parsed[:all_option]
    implied_list_owner(parsed)
    parsed[:done_option] = true unless parsed[:open_option]
    parsed[:list] = ids_from_parsed(parsed)
  end
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
def adjust_archive_cmd_action_list(parsed)
  # Inherit item list from what user is looking at.
  return parsed[:list] = [] if parsed[:previous_action_list_context].empty?
  return parsed[:list] = parsed[:previous_action_list_context][:list] if archive_cmd_context_matches(parsed)
  # Note: the archive_cmd_context_matches method has already adjusted parsed
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
def archive_cmd_context_matches(parsed)
  # Case: look at a list AND THEN 'archive 1'
  # Ok, just archive from the list.
  return true unless parsed[:task_num].nil?
  # Otherwise, fetch a list based on the list command options
  # so that archive command syntax matches what list would do. i.e. 'archive team'
  # will archive whatever 'list team' will display.
  list_of_ids_from_list_cmd(parsed)
  # Now that we have a new parsed[:list], use it.
  true
end

# @me member is implied if no Other member is mentioned. However, 'list team'
# implies no member is mentioned.
def adjust_archive_cmd_list_owner(parsed)
  return parsed[:list_owner] = :team, parsed[:list_owner_name] = 'team' if parsed[:list_scope] == :team
  parsed[:list_owner] = :member
  return parsed[:list_owner_name] = "@#{parsed[:mentioned_member_name]}" unless parsed[:mentioned_member_id].nil?
  parsed[:mentioned_member_name] = parsed[:url_params][:user_name]
  parsed[:mentioned_member_id] = parsed[:url_params][:user_id]
end
