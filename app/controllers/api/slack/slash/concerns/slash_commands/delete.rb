=begin
Form Params
channel_id	C0VNKV7BK
channel_name	general
command	/do
response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
team_domain	shadowhtracteam
team_id	T0VN565N0
text	remove 4
token	3ZQVG7rk4p7EZZluk1gTH3aN
user_id	U0VLZ5P51
user_name	ray
=end

# Inputs: parsed = parsed command line info that has been verified.
#         before_action list: [ListItem.id] for the list that the user
#                             is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          action list = deleted item removed.
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# SUB_FUNCS  = %w(open due more done)
# list_owner = :team, :mine, <@name>
# assigned_member_name = <@name>
#------------------------------
def delete_command(parsed)
  adjust_delete_cmd_action_context(parsed)
  text = delete_item(parsed)
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
  return delete_all(parsed) if parsed[:task_num].nil?
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
  return if ListItem.find(id).destroy
  parsed[:err_msg] = 'Error: There was an error deleting this Task.'
end

def delete_all(parsed)
  destroy_all_by_ids(parsed[:list], parsed)
  if parsed[:err_msg].empty?
    parsed[:list] = []
    return delete_all_msg(parsed)
  end
  parsed[:err_msg]
end

def delete_all_msg(parsed)
  if parsed[:list_scope] == :team
    return 'Deleted ALL tasks in this channel for ANY team member.' if parsed[:channel_scope] == :one_channel
    return 'Deleted ALL tasks in ANY channel for ANY team member.' if parsed[:channel_scope] == :all_channels
  end
  # parsed[:list_scope] == :one_member
  if parsed[:channel_scope] == :one_channel
    return 'Deleted ALL of your ASSIGNED tasks in this channel.' if parsed[:list_owner] == :mine
    return "Deleted ALL of @#{parsed[:list_owner_name]}\'s ASSIGNED tasks in this channel."
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
  # Figure out the list we are working on and its attributes.
  adjust_delete_cmd_action_list(parsed)
  adjust_delete_cmd_list_owner(parsed)
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
  # Case: 'list @dawn' or 'list'
  #       AND THEN 'delete 1'
  if parsed[:previous_action_list_context][:list_scope] == :one_member
    # We are trying to delete from a specific member list.
    return true
  end
  # Case  'list team @ray' OR 'list team'
  #       AND THEN 'delete 1'
  unless parsed[:previous_action_list_context][:all_option]
    # We are trying to delete from a team list on current channel.
    return true
  end
  # Case 'list all' OR 'list all @dawn'
  #       AND THEN 'delete' anything is an err condition, already reported.
  # Can not get here.
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
