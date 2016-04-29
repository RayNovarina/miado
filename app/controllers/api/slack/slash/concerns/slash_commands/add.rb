=begin
Form Params
channel_id	C0VNKV7BK
channel_name	general
command	/do
response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
team_domain	shadowhtracteam
team_id	T0VN565N0
text	call GoDaddy @susan /fri
token	3ZQVG7rk4p7EZZluk1gTH3aN
user_id	U0VLZ5P51
user_name	ray
=end

# Inputs: parsed = parsed command line info that has been verified.
#         before_action list: [ListItem.id] for the list that the user
#                             is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          action list = updated with new item.
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# SUB_FUNCS  = %w(open due more)
# list_owner = :team, :mine, <@name>
# mentioned_member_name = <@name>
#------------------------------
def add_command(parsed)
  params = parsed[:url_params]
  list = parsed[:list]
  item = ListItem.new_from_slack_slash_cmd(parsed)
  item.done = false
  item.channel_id, task_num_clause =
    add_channel(params, list)
  item.assigned_member_id, item.assigned_member_name, assigned_to_clause =
    add_assigned_member(parsed)
  item.assigned_due_date, due_date_clause =
    add_due_date(parsed)
  item.description =
    "#{parsed[:command]}#{assigned_to_clause}#{due_date_clause}"

  response =
    "#{task_num_clause}#{assigned_to_clause}#{due_date_clause}" \
  # " Type `#{params[:command]} list` for YOUR current list." \
  # " or `#{params[:command]} list team` for current TEAM list."
  item.debug_trace =
    "From add command - Response:#{response}  " \
    "trace_syntax:#{parsed[:trace_syntax]}"

  if item.save
    # We have a new list that is in context.
    list << item.id
    # Persist the channel.list_ids[] for the next transaction.
    save_after_action_list_context(parsed, parsed, list)
    # Display modified list after adding an item.
    parsed[:display_after_action_list] = true
    return [response, nil]
  end
  [parsed[:err_msg] = 'Error creating task. Please try again.', nil]
end

# Returns: [channel_id, task_num_clause]
def add_channel(params, list)
  [params[:channel_id],
   "Task #{list.length + 1} added. "
  ]
end

# Returns: [assigned_member_id, assigned_to_clause]
def add_assigned_member(parsed)
  return [nil, ''] if parsed[:mentioned_member_id].nil?
  # Assigned member info will be stored in db and persisted as after action info
  parsed[:assigned_member_id] = parsed[:mentioned_member_id]
  parsed[:assigned_member_name] = parsed[:mentioned_member_name]
  [parsed[:assigned_member_id], parsed[:assigned_member_name],
   "| *Assigned* to @#{parsed[:assigned_member_name]}."
  ]
end

# Returns: [assigned_due_date, due_date_clause]
def add_due_date(parsed)
  return [nil, ''] if parsed[:due_date].nil?
  [parsed[:due_date],
   "| *Due* #{parsed[:due_date].strftime('%a, %d %b')}."
  ]
end
