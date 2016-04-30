=begin
Form Params
channel_id	C0VNKV7BK
channel_name	general
command	/do
response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
team_domain	shadowhtracteam
team_id	T0VN565N0
text	assign 3 @tony
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
# /do assign 3 @tony Assigns "@tony" to task 3 for this channel.
# full syntax: /do assign channel 3 @tony
#              /do assign team 3 @tony
#-----------------------------------
def assign_command(parsed)
  adjust_assign_cmd_action_context(parsed)
  text = assign_one(parsed)
  if parsed[:err_msg].empty?
    # Persist the channel.list_ids[], options for the next transaction.
    save_after_action_list_context(parsed, parsed, parsed[:list])
    # Display modified list after assigning an item.
    parsed[:display_after_action_list] = true
    return [text, nil]
  end
  [parsed[:err_msg], nil]
end

def assign_one(parsed)
  return if task_num_invalid?(parsed)
  item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  return parsed[:err_msg] = "Error: Task #{parsed[:task_num]} is already " \
    "assigned to #{parsed[:assigned_member_name]}" if item.assigned_member_id == parsed[:assigned_member_id]
  item.assigned_member_id = parsed[:assigned_member_id]
  item.assigned_member_name = parsed[:assigned_member_name]
  if item.save
    task_owner = parsed[:list_owner]
    task_owner = 'your' if parsed[:list_owner] == :mine
    task_owner = 'team' if parsed[:list_owner] == :team
    return "Assigned #{task_owner} task #{parsed[:task_num]} to " \
           "@#{parsed[:assigned_member_name]}." \
           "#{item.assigned_member_id.nil? ? '' : '  NOTE: It was assigned ' \
           "to @#{item.assigned_member_name}"}"
  end
  parsed[:err_msg] = 'Error: There was an error assigning this Task.'
end

def adjust_assign_cmd_action_context(parsed)
  adjust_assign_cmd_assigned_member(parsed)
  # Figure out the list we are working on and its attributes.
  adjust_assign_cmd_action_list(parsed)
  adjust_assign_cmd_list_owner(parsed)
end

def adjust_assign_cmd_assigned_member(parsed)
  # Assigned member info will be stored in db and persisted as after action info
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
def adjust_assign_cmd_action_list(parsed)
  # Inherit item list from what user is looking at.
  return parsed[:list] = [] if parsed[:previous_action_list_context].empty?
  return parsed[:list] = parsed[:previous_action_list_context][:list] if assign_cmd_context_matches(parsed)
  # Note: the assign_cmd_context_matches method has already adjusted parsed
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
# /do assign 3 @tony Assigns "@tony" to task 3 for this channel.
def assign_cmd_context_matches(parsed)
  # Case: 'list @dawn' or 'list'
  #       AND THEN 'assign 3 @tony'
  if parsed[:previous_action_list_context][:list_scope] == :one_member
    # We are trying to assign a task to a specific member on a member list.
    # This is the only option to get here. We will err out if team syntax used.
    return true
  end
  # Case  'list team @ray' OR 'list team'
  #       AND THEN 'assign 1 @dawn'
  if parsed[:previous_action_list_context][:list_scope] == :team
    # We are trying to assign a task to a specific member on a team list. This
    # is the only option to get here. We will err out if team syntax used.
    return true
  end
  # Case 'list all' OR 'list all @dawn'
  #       AND THEN 'assign' anything is an err condition, already reported.
  # Can not get here.
  false
end

# @me member is implied if no Other member is mentioned. However, 'list team'
# implies no member is mentioned.
def adjust_assign_cmd_list_owner(parsed)
  return parsed[:list_owner] = :team, parsed[:list_owner_name] = 'team' if parsed[:list_scope] == :team
  parsed[:list_owner] = :member
  if parsed[:mentioned_member_id].nil?
    parsed[:mentioned_member_name] = parsed[:url_params][:user_name]
    parsed[:mentioned_member_id] = parsed[:url_params][:user_id]
  end
  parsed[:list_owner_name] = "@#{parsed[:mentioned_member_name]}"
end
