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
#          action list = unchanged.
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# SUB_FUNCS  = %w(open due more)
# list_owner = :team, :mine, <@name>
# assigned_member_name = <@name>
#------------------------------
# /do assign 3 @tony Assigns "@tony" to task 3 for this channel.
# full syntax: /do assign channel 3 @tony
#              /do assign team 3 @tony
def assign_command(parsed)
  response = assign_one(parsed)
  if parsed[:err_msg].nil?
    # Display modified list after assigning an item.
    # This will also rebuild and save the channel.list_ids[]
    parsed[:display_after_action_list] = true
    parsed[:scope_for_list_after_action] = parsed[:list_scope]
    parsed[:list_for_after_action] = list
    return [response, nil]
  end
  [parsed[:err_msg], nil]
end

def assign_one(parsed)
  # ASSUMES list[task_num] is verified as belonging to the @name in cmd line.
  item = ListItem.find(parsed[:list][parsed[:task_num] - 1])
  item.assigned_member_id = parsed[:assigned_member_id]
  item.assigned_member_name = parsed[:assigned_member_name]
  if item.save
    task_owner = parsed[:list_owner]
    task_owner = 'your' if parsed[:list_owner] == :mine
    task_owner = 'team' if parsed[:list_owner] == :team
    return "Assigned #{task_owner} task #{parsed_cmd[:task_num]} to " \
           "@#{parsed_cmd[:assigned_member_name]}." \
           "#{item.assigned_member_id.nil? ? '' : '  NOTE: It was assigned ' \
           "to @#{item.assigned_member_name}"}"
  end
  parsed[:err_msg] = 'Error: There was an error assigning this Task.'
end
