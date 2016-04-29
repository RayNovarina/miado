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
  return parsed[:err_msg] = 'Error: Invalid to specify team and task number.' if parsed[:sub_func] == :team && !parsed[:task_num].nil?
  return delete_all(parsed) if parsed[:task_num].nil?
  return delete_one(parsed) unless parsed[:task_num].nil?
end

# Returns: text msg.
#          parsed[:err_msg] if needed.
#          list is adjusted for deleted item(s)
def delete_one(parsed)
  return if task_num_out_of_range?(parsed)
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
    return "Deleted ALL of #{parsed[:list_owner]} ASSIGNED tasks in this channel."
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
