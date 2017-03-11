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
  adjust_add_cmd_action_context(parsed)
  params = parsed[:url_params]
  list = parsed[:list]
  item = ListItem.new_from_slack_slash_cmd(parsed)
  item.done = false
  item.channel_id, task_num_clause =
    add_channel(params, list)
  item.assigned_member_id, _assigned_member_name, assigned_to_clause =
    add_assigned_member(parsed)
  item.assigned_due_date, due_date_clause = add_due_date(parsed)
  item.description, description_clause = add_description(parsed)

  item.debug_trace =
    "From add command - Response:#{parsed[:response_headline]}  " \
    "trace_syntax:#{parsed[:trace_syntax]}"

  if item.save
    # We have a new list that is in context.
    list << item.id
    text = ''
    parsed[:response_headline] =
      "#{task_num_clause} as: `#{description_clause}` #{assigned_to_clause} " \
      "#{due_date_clause}"
    parsed[:response_headline].concat("\nNote: Mention a member name to " \
      "create a task assigned to someone. i.e. '/do new task for @joe' or " \
      "@me. Or use the /do assign command.") if assigned_to_clause.empty?

    attachments = add_response_headline_attachments(parsed, parsed[:response_headline], item.id, 'add')
    # Special case: just doing an add task for the redo command.
    parsed[:list] = list if parsed[:on_behalf_of_redo_cmd]
    return [text, attachments] if parsed[:on_behalf_of_redo_cmd]
    # Persist the channel.list_ids[] for the next transaction.
    save_after_action_list_context(parsed, parsed, list)
    # Display modified list after adding an item if in debug mode.
    parsed[:display_after_action_list] = true if parsed[:debug]
    return [text, attachments]
  end
  [parsed[:err_msg] = 'Error creating task. Please try again.', nil]
end

# Returns: [channel_id, task_num_clause]
def add_channel(params, list)
  [params[:channel_id], "Task #{list.length + 1} added"]
  # "Task #{list.length + 1} added. "]
end

# Returns: [assigned_member_id, assigned_to_clause]
def add_assigned_member(parsed)
  return [nil, '', ''] if parsed[:assigned_member_id].nil?
  [parsed[:assigned_member_id], parsed[:assigned_member_name],
   " *Assigned* to @#{parsed[:assigned_member_name]}."
  ]
end

# Returns: [assigned_due_date, due_date_clause]
def add_due_date(parsed)
  return [nil, ''] if parsed[:due_date].nil?
  [parsed[:due_date],
   " *Due* #{parsed[:due_date].strftime('%a, %d %b')}."
  ]
end

def add_description(parsed)
  [parsed[:command], parsed[:command]]
end

# Returns: [attachment{}]
def add_response_headline_attachments(parsed, response_text = '', item_db_id = '', caller_id = 'add')
  [{ response_type: 'ephemeral',
     text: response_text,
     fallback: 'A task has been added.',
     callback_id: { id: 'add task',
                    item_db_id: item_db_id,
                    response_headline: response_text.slice(0..100),
                    caller_id: caller_id,
                    debug: false
                  }.to_json,
     color: '#3AA3E3',
     mrkdwn_in: ['text'],
     attachment_type: 'default',
     actions: [
       { name: 'list',
         text: lib_button_text(text: 'Your To-Do\'s', parsed: parsed,
                               name: 'list', match: '@me open',
                               match_list_cmd: 'list'),
         type: 'button',
         value: { command: '@me open', label: 'Your To-Do\'s' }.to_json
       },
       { name: 'list',
         text: lib_button_text(text: 'Team To-Do\'s', parsed: parsed,
                               name: 'list', match: 'team open assigned',
                               match_list_cmd: 'list team'),
         type: 'button',
         value: { command: 'team open assigned', label: 'Team To-Do\'s' }.to_json
       },
       { name: 'list',
         text: lib_button_text(text: 'All Tasks', parsed: parsed,
                               name: 'list', match: 'team all assigned unassigned open done',
                               match_list_cmd: 'list team all open done'),
         type: 'button',
         value: { command: 'team all assigned unassigned open done', label: 'All Tasks' }.to_json
       },
       { name: 'feedback',
         text: lib_button_text(text: 'Feedback', parsed: parsed, name: 'feedback'),
         type: 'button',
         # value: { resp_options: { replace_original: false } }.to_json
         value: { label: 'Feedback' }.to_json
       },
       { name: 'help',
         text: lib_button_text(text: 'Button Help', parsed: parsed,
                               name: 'help', match: 'buttons'),
         type: 'button',
         value: { command: 'buttons', label: 'Button Help' }.to_json
       }
     ]
  }]
end

ADD_RESP_BUTTONS_HLP_TEXT =
  '• `Your To-Do\'s`  ' \
  "generates the command \'/do list @me open\' and " \
  "Lists your ASSIGNED and OPEN tasks for THIS channel. \n" \
  '• `Team To-Do\'s`  ' \
  "generates the command \'/do list team open assigned\' and " \
  "Lists all tasks that are ASSIGNED and OPEN for THIS channel. \n" \
  '• `All Tasks`  ' \
  "generates the command \'/do list team all assigned unassigned open done\' and " \
  "Lists all tasks for ALL channels. \n" \
  '• `Feedback`  tells you how to email MiaDo product support with suggestions, problems, etc.' \
  "\n" \
  '• `Button Help`  describes the purpose of each button.' \
  "\n" \
  "\n\n".freeze

# Returns: [title, [replacement_buttons_attachments{}], [button_help_attachments{}], response_options]
def add_response_buttons_help(parsed)
  title = 'Add Task Buttons explained'
  replacement_buttons_attachments =
    add_response_headline_attachments(parsed,
                                      parsed[:button_callback_id][:response_headline],
                                      parsed[:button_callback_id][:item_db_id],
                                      parsed[:button_callback_id][:caller_id])
  button_help_attachments =
    [{ fallback: 'Add Task Button Info',
       text: ADD_RESP_BUTTONS_HLP_TEXT,
       color: '#3AA3E3',
       mrkdwn_in: ['text']
    }]
  [title, replacement_buttons_attachments, button_help_attachments, parsed[:first_button_value][:resp_options]]
end

def adjust_add_cmd_action_context(parsed)
  # Special case: doing a add for redo command. Context already adjusted.
  return if parsed[:on_behalf_of_redo_cmd]

  # Add task to list user is looking at.
  inherit_list_scope(parsed)
  inherit_channel_scope(parsed)
  assigned_member_is_mentioned_member(parsed)
  # Figure out the list we are working on and its attributes.
  adjust_add_cmd_action_list(parsed)
  implied_list_owner(parsed)
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
def adjust_add_cmd_action_list(parsed)
  # Inherit item list from what user is looking at.
  return parsed[:list] = [] if parsed[:previous_action_list_context].empty?
  return parsed[:list] = parsed[:previous_action_list_context][:list] if add_cmd_context_matches(parsed)
  # Note: the add_cmd_context_matches method has already adjusted parsed
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
#   4) Empty list after 'delete team'
#------------------------------------

# Case: 'list @ray' or 'list': we display list @ray. then 'new task'
#       it will be unassigned and we should display the team list, not the @ray.
# Case: 'list team', 'delete 1': list is for team. delete if for team even tho
#       no member is mentioned, i.e. @me is not implied.
# Case: context change: 'list @ray' 'new task for @dawn'. List is for @ray,
#       Afer add, list is for team because assignment to dif team member.
# Case: 'list team' 'unassigned task'. list is for team. list_owner is 'team',
#       afer add, list is for team, list_owner is 'team'
#-----------------------------------
def add_cmd_context_matches(parsed)
  # Case: 'list @dawn' or 'list'
  #       AND THEN 'new task for @dawn'
  #       OR 'new task'
  #       OR 'delete team'
  if parsed[:previous_action_list_context][:list_scope] == :one_member
    # We are trying to add to a specific member list.
    return true if parsed[:mentioned_member_id] == parsed[:previous_action_list_context][:mentioned_member_id]
    # Can't add this member to that list. Must add it to end of team list.
  else
    # Case  'list team @ray' OR 'list team'
    #       AND THEN 'new task for @dawn'
    #       OR 'new task' OR 'new task for @ray'
    #       OR 'delete team'
    # Case  'list team'
    #       AND THEN 'new task for @dawn'
    #       AND THEN 'new task for @ray'
    unless parsed[:previous_action_list_context][:all_option]
      return true if parsed[:previous_action_list_context][:mentioned_member_id].nil?
      return true if parsed[:mentioned_member_id] == parsed[:previous_action_list_context][:mentioned_member_id]
      # Can't add this member to that Team list. Must get a new team list for all
      # members or for mentioned member.
    end
  end
  # Case 'list all' OR 'list all @dawn'
  #       AND THEN 'new task for @dawn'
  #       OR 'new task' OR 'new task @ray'
  # Can only add a task to the current Team channel, not all channels.

  # List context Doesn't match. Must get a new team list.
  parsed[:list_scope] = :team
  parsed[:channel_scope] = :one_channel
  # Clear the member mention, don't fool following list logic.
  parsed[:mentioned_member_id] = nil
  parsed[:mentioned_member_name] = nil
  false
end
