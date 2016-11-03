require 'date'
require_relative './parser_class'
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

def parse_slash_cmd(params, ccb, mcb, tcb, previous_action_parse_hash)
  p_hash = new_parse_hash(params, ccb, mcb, tcb, previous_action_parse_hash)
  scan4_command_func(p_hash)
  return p_hash unless p_hash[:err_msg].empty?
  perform_scans_for_functions(p_hash)
  p_hash
end

def perform_scans_for_functions(p_hash)
  case p_hash[:func]
  when :add
    scan4_mentioned_member(p_hash)
    scan4_due_date(p_hash)
  when :append
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
    scan4_due_date(p_hash)
  when :assign
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
  when :delete
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
    scan4_options(p_hash)
  when :discuss
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
  when :done
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
  when :due
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    p_hash[:requires_due_date] = true
    scan4_due_date(p_hash)
  when :feedback
    # nothing to do.
  when :help
    # nothing to do.
  when :hints
    # nothing to do.
  when :last_action_list
    scan4_mentioned_member(p_hash)
    scan4_options(p_hash)
  when :list
    scan4_mentioned_member(p_hash)
    scan4_options(p_hash)
  when :message_event
    # nothing to do.
  when :redo
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
    scan4_due_date(p_hash)
  when :reset
    # nothing to do.
  when :taskbot_rpts
    scan4_mentioned_member(p_hash)
    scan4_options(p_hash)
  when :unassign
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    p_hash[:requires_mentioned_member] = true
    scan4_mentioned_member(p_hash)
  end
end

# Note: what looks like a command may actually be an added task, i.e.
#       'delete all open tasks for @susan is a new task'
# Case: command is as entered from command line.
#       'a new task', 'list team'
CMD_FUNCS = %w(append assign delete done due feedback help hints list lists list_taskbot redo unassign).freeze
def scan4_command_func(p_hash)
  return command_func_from_button(p_hash) if p_hash[:button_actions].any?
  return command_func_from_event(p_hash) unless p_hash[:event_type].empty?
  scan4_taskbot_cmd_func(p_hash) if p_hash[:ccb].is_taskbot
  return p_hash unless p_hash[:err_msg].empty?
  # Default if no command given.
  return p_hash[:func] = :help if p_hash[:cmd_splits].empty?

  maybe_func = p_hash[:cmd_splits][0]
  p_hash[:func] = CMD_FUNCS.include?(maybe_func) ? maybe_func.to_sym : nil
  # discard/consume func word if we have one.
  p_hash[:cmd_splits].shift unless p_hash[:func].nil?
  p_hash[:taskbot_rpt] = true if p_hash[:func] == :list_taskbot
  p_hash[:func] = :list if p_hash[:func] == :lists
  p_hash[:func] = :list if p_hash[:func] == :list_taskbot
  # Default to add cmd if no func specified or implied.
  p_hash[:func] = :add if p_hash[:func].nil?
end

# Returns: p_hash[:func]
def command_func_from_button(p_hash)
  return command_func_from_help_button(p_hash) if p_hash[:button_callback_id][:id] == 'help'
  return command_func_from_add_task_button(p_hash) if p_hash[:button_callback_id][:id] == 'add task'
  return command_func_from_taskbot_button(p_hash) if p_hash[:button_callback_id][:id] == 'taskbot'
  return command_func_from_lists_button(p_hash) if p_hash[:button_callback_id][:id] == 'lists'
end

# Returns: p_hash[:func]
def command_func_from_help_button(p_hash)
  return p_hash[:func] = :help unless p_hash[:button_actions].first['name'] == 'lists'
  p_hash[:func] = :list # if p_hash[:button_actions].first['name'] == 'lists'
  command_text_from_button(p_hash)
end

# Returns: p_hash[:func]
def command_func_from_add_task_button(p_hash)
  # return p_hash[:func] = :hints if p_hash[:button_actions].first['name'] == 'hints'
  return p_hash[:func] = :help if p_hash[:button_actions].first['name'] == 'help'
  return p_hash[:func] = :feedback if p_hash[:button_actions].first['name'] == 'feedback'
  p_hash[:func] = :list # if p_hash[:button_actions].first['name'] == 'list'
  command_text_from_button(p_hash)
end

# Returns: p_hash[:func]
def command_func_from_taskbot_button(p_hash)
  return p_hash[:func] = :help if p_hash[:button_actions].first['name'] == 'help'
  return p_hash[:func] = :feedback if p_hash[:button_actions].first['name'] == 'feedback'
  return p_hash[:func] = :reset if p_hash[:button_actions].first['name'] == 'reset'
  p_hash[:taskbot_rpt] = true if p_hash[:button_actions].first['name'] == 'list'
  p_hash[:func] = :list if p_hash[:button_actions].first['name'] == 'list'
  p_hash[:func] = :done if p_hash[:button_actions].first['name'] == 'done' || p_hash[:button_actions].first['name'] == 'done and delete'
  # p_hash[:func] = :discuss if p_hash[:button_actions].first['name'] == 'discuss'
  command_text_from_button(p_hash)
end

def command_func_from_lists_button(p_hash)
  return p_hash[:func] = :help if p_hash[:button_actions].first['name'] == 'help'
  return p_hash[:func] = :feedback if p_hash[:button_actions].first['name'] == 'feedback'
  p_hash[:func] = :list
  command_text_from_button(p_hash)
end

def command_text_from_button(p_hash)
  command_without_func = p_hash[:first_button_value][:command]
  debug_char = '$' if p_hash[:button_callback_id][:debug]
  debug_char = '' unless debug_char
  p_hash[:url_params][:text] = "#{debug_char}#{p_hash[:func]} #{command_without_func}"
  p_hash[:original_command], p_hash[:debug] = check_for_debug(params)
  p_hash[:command] = command_without_func
  p_hash[:cmd_splits] = p_hash[:command].split
end

# Returns: p_hash[:func]
def command_func_from_event(p_hash)
  return command_func_from_message_event(p_hash) if p_hash[:event_type] == 'message'
end

# Returns: p_hash[:func]
def command_func_from_message_event(p_hash)
  p_hash[:func] = :message_event
end

CMD_FUNCS_OK_IN_TASKBOT_CHAN = %w(list_taskbot).freeze
def scan4_taskbot_cmd_func(p_hash)
  p_hash[:err_msg] =
    # "Error: only the '#{params[:command]} /done' command is " \
    # 'allowed in the Taskbot channel.' unless p_hash[:func] == :done
    "Error: Sorry, but at this time no '#{params[:command]}' commands " \
    'allowed in the Taskbot channel. (Except for the Done and Discuss ' \
    'buttons). Switch to a regular channel to run /do commands' \
    '.' unless CMD_FUNCS_OK_IN_TASKBOT_CHAN.include?(p_hash[:cmd_splits][0])
end

# Case: command function has been processed, leaving:
#       'open' was 'list open', '' was 'list ', '4' was 'delete team 4',
#       'open team' was 'list open team', 'team all' was 'list team all',
#       'all open tasks for @susan is a new task' was 'delete all open tasks for @susan is a new task'
CMD_OPTIONS = %w(all assigned done due due_first open team unassigned).freeze
def scan4_options(p_hash)
  return unless p_hash[:err_msg].empty?
  # Have to be adding task if command is longer than a reasonable number of
  # options. i.e. 'list team all assigned unassigned open done'
  return p_hash[:func] = :add if p_hash[:cmd_splits].length > 6 # CMD_OPTIONS.length - 1
  CMD_OPTIONS.each_with_index do |option, _index|
    next unless p_hash[:cmd_splits].include?(option)
    p_hash[''.concat(option).concat('_option').to_sym] = true
  end
  adjust_cmd_options_for_add_cmd(p_hash)
end

# Correct for case of add task using most of the same syntax as another cmd.
# Case: command function has been processed, leaving:
#       'all open tasks for @susan is a new task' was 'delete all open tasks for @susan is a new task'
def adjust_cmd_options_for_add_cmd(p_hash)
  # OR?? remove each option as it is processed and see if anything left over.
  #      task num, due date and mentioned_member_name removed too?
  # Have to be adding task if command is longer than a "reasonable" numboer of
  # options.
  num_options = 0
  num_options += 1 if p_hash[:all_option]
  num_options += 1 if p_hash[:assigned_option]
  num_options += 1 if p_hash[:done_option]
  num_options += 1 if p_hash[:due_option]
  num_options += 1 if p_hash[:due_first_option]
  num_options += 1 if p_hash[:open_option]
  num_options += 1 if p_hash[:team_option]
  num_options += 1 if p_hash[:unassigned_option]
  num_options += 1 unless p_hash[:task_num].nil?
  num_options += 1 unless p_hash[:mentioned_member_id].nil?
  p_hash[:func] = :add if p_hash[:cmd_splits].length > num_options
end

# Case: 'delete 4', 'delete team', 'assign 3 @tony'
def scan4_task_num(p_hash)
  return unless p_hash[:err_msg].empty?
  p_hash[:task_num] = p_hash[:command][/\d+/]
  if p_hash[:task_num].nil? && p_hash[:requires_task_num]
    return p_hash[:err_msg] = 'Error: no task number specified.'
  end
  p_hash[:task_num] = p_hash[:task_num].to_i unless p_hash[:task_num].nil?
end

# Member is mentioned in channel, becomes the target for get a new list.
# s = 'get donuts @susan /fri all kinds'
def scan4_mentioned_member(p_hash)
  return unless p_hash[:err_msg].empty?
  at_pos = 0 if p_hash[:command].starts_with?('@')
  at_pos = p_hash[:command].index(' @') + 1 unless p_hash[:command].starts_with?('@') || p_hash[:command].index(' @').nil?
  return p_hash[:err_msg] = 'Error: team member must be mentioned.' if at_pos.nil? && p_hash[:requires_mentioned_member]
  return if at_pos.nil?
  delimiter_pos = p_hash[:command].index(' ', at_pos) || p_hash[:command].index(',', at_pos)

  end_of_name_pos = p_hash[:command].length - 1 if delimiter_pos.nil?
  end_of_name_pos = delimiter_pos - 1 unless delimiter_pos.nil?

  name = p_hash[:command].slice(at_pos + 1, end_of_name_pos - at_pos)
  p_hash[:mentioned_member_id], p_hash[:mentioned_member_name] =
    slack_member_from_name(p_hash, name)
  if p_hash[:mentioned_member_id].nil?
    p_hash[:mentioned_member_id], p_hash[:mentioned_member_name] =
      mentioned_member_not_found(p_hash, name)
  end
  return p_hash[:err_msg] = "Error: Member '@#{name}' not recognized." if p_hash[:mentioned_member_id].nil?

  p_hash[:mentioned_member_name_begin_pos] = at_pos
  p_hash[:mentioned_member_name_end_pos] = end_of_name_pos
  remove_mentioned_member_from_command(p_hash)
end

def remove_mentioned_member_from_command(p_hash)
  return if p_hash[:mentioned_member_name].nil?
  begin_phrase = p_hash[:command].slice(0, p_hash[:mentioned_member_name_begin_pos]).rstrip
  end_phrase = p_hash[:command].slice(p_hash[:mentioned_member_name_end_pos] + 1, p_hash[:command].length - p_hash[:mentioned_member_name_end_pos] - 1)
  p_hash[:command] = begin_phrase.concat(end_phrase)
end

def scan4_due_date(p_hash)
  return unless p_hash[:err_msg].empty?
  slash_pos = p_hash[:command].index('/')
  return p_hash[:err_msg] = 'Error: due date is required.' if slash_pos.nil? && p_hash[:requires_due_date]
  return if slash_pos.nil?
  blank_pos = p_hash[:command].index(' ', slash_pos)

  end_of_date_pos = p_hash[:command].length - 1 if blank_pos.nil?
  end_of_date_pos = blank_pos - 1 unless blank_pos.nil?

  p_hash[:due_date_string] =
    p_hash[:command].slice(slash_pos + 1, end_of_date_pos - slash_pos)

  p_hash[:due_date], is_day_of_week = date_from_due_date(p_hash[:due_date_string])
  adjust_due_date_into_future(p_hash, is_day_of_week)
  return if p_hash[:due_date].nil?

  p_hash[:due_date_begin_pos] = slash_pos
  p_hash[:due_date_end_pos] = end_of_date_pos
  remove_due_date_from_command(p_hash)
end

def remove_due_date_from_command(p_hash)
  return if p_hash[:due_date].nil?
  begin_phrase = p_hash[:command].slice(0, p_hash[:due_date_begin_pos] - 1)
  end_phrase = p_hash[:command].slice(p_hash[:due_date_end_pos], p_hash[:command].length - (p_hash[:due_date_end_pos] + 1))
  p_hash[:command] = begin_phrase.concat(end_phrase)
end

# Returns: [nil, false] if invalid date.
#          [datetime object, true/false if due date input string is of format]
#         'sun' thru 'sat'
def date_from_due_date(due_date_string)
  # Case: /today
  due_date_string = DateTime.now.strftime('%a').downcase if due_date_string == 'today'
  numeric_partition = due_date_string.partition(/\d/)
  # Case: no numeric portion. /fri or /jun or /half
  if numeric_partition[1].empty?
    begin
      due_date = due_date_string.to_datetime
    rescue ArgumentError
      return [nil, false]
    end
    is_day_of_week =
      Date::ABBR_DAYNAMES.map(&:downcase).include?(numeric_partition[0].downcase) ||
      Date::DAYNAMES.map(&:downcase).include?(numeric_partition[0].downcase)
    return [due_date, is_day_of_week]
  end
  # Case: just day of month specified. /12
  if numeric_partition[0].empty?
    begin
      due_date = DateTime.now.strftime('%b')
                         .concat(' ').concat(due_date_string)
                         .to_datetime
    rescue ArgumentError
      p_hash[:err_msg] = 'Error: invalid day of month.'
      return [nil, false]
    end
    return [due_date, false]
  end
  # Case: normal. /jun15
  begin
    due_date = numeric_partition[0]
               .concat(' ')
               .concat(numeric_partition[1])
               .concat(numeric_partition[2])
               .to_datetime
  rescue ArgumentError
    p_hash[:err_msg] = 'Error: invalid day of month.'
    return [nil, false]
  end
  [due_date, false]
end

# Assume standalone day or month refers to a future date.
# Example1) if today is Wednesday, then /mon refers to Monday of next week,
# not the Monday of two days ago.
# Example2) # i.e. if today is March 15th. Then the date /feb2 refers to
# next year.
# Ruby defaults to "this week" and "this year".
# p_hash[:err_msg] =
# 'Error: Due date has already passed.' if p_hash[:due_date] < DateTime.now
def adjust_due_date_into_future(p_hash, is_day_of_week)
  return if p_hash[:due_date].nil?
  return if p_hash[:due_date] > DateTime.now
  return if p_hash[:due_date].today?
  # Case: just day of week specified.
  return p_hash[:due_date] = (p_hash[:due_date].to_date + 7).to_datetime if is_day_of_week
  # Case: Month/day specified:
  p_hash[:due_date] = p_hash[:due_date].to_date.next_year.to_datetime
end

#----------- HELPERS for command methods after parsing done ----------------
#
# Case: command function split has been processed, leaving:
#       '' was 'help' or 'list', '1 @tony' was 'assign 1 @tony',
#       'team', was 'delete team', 'a new task @ray /jun15' is unchanged,
#       'channel 5' was 'list channel 5'
CMD_LIST_SCOPES = %w(one_member team).freeze
# CMD_FUNCS_INHERITING_LIST_SCOPE = [:add, :append, :assign, :delete, :done, :due,
#                                   :help, :redo].freeze
def inherit_list_scope(p_hash)
  # Note: Default is to inherit list_scope from the list the user is looking at.
  #       And then to adjust list_scope in each individual command if needed.
  return p_hash[:list_scope] = :one_member if p_hash[:previous_action_list_context].empty?
  p_hash[:list_scope] = p_hash[:previous_action_list_context][:list_scope]
end

CMD_CHANNEL_SCOPES = %w(one_channel all_channels).freeze
# CMD_FUNCS_INHERITING_CHANNEL_SCOPE = [:add, :append, :assign, :due,
#                                      :help, :redo].freeze
def inherit_channel_scope(p_hash)
  # Note: Default is to inherit channel_scope from the list the user is looking at.
  #       And then to adjust channel_scope in each individual command if needed.
  return p_hash[:channel_scope] = :one_channel if p_hash[:previous_action_list_context].empty?
  p_hash[:channel_scope] = p_hash[:previous_action_list_context][:channel_scope]
end

# @me member is implied if 'list' and no Other member is mentioned.
def implied_mentioned_member(parsed)
  return if parsed[:list_scope] == :team
  parsed[:mentioned_member_name] = parsed[:url_params][:user_name] if parsed[:mentioned_member_id].nil?
  parsed[:mentioned_member_id] = parsed[:url_params][:user_id] if parsed[:mentioned_member_id].nil?
end

# @me member is implied if no Other member is mentioned.
def implied_list_owner(p_hash)
  return p_hash[:list_owner] = :team, p_hash[:list_owner_name] = 'team' if p_hash[:list_scope] == :team
  p_hash[:list_owner] = :member
  p_hash[:list_owner_name] = "@#{p_hash[:url_params][:user_name]}" if p_hash[:mentioned_member_id].nil?
  p_hash[:list_owner_name] = "@#{p_hash[:mentioned_member_name]}" unless p_hash[:mentioned_member_id].nil?
end

def assigned_member_is_mentioned_member(p_hash)
  # Assigned member info will be stored in db and persisted as after action info
  p_hash[:assigned_member_id] = p_hash[:mentioned_member_id]
  p_hash[:assigned_member_name] = p_hash[:mentioned_member_name]
end

# The user is looking at either:
#   1) Items assigned to a member for one channel.
#      i.e. 'list' or 'list @dawn open'
#   2) All items for this channel.
#      i.e. 'list team'
#   3) All items for all channels.
#      i.e. 'list all'
#-------------------------------------------
# /do assign 3 @tony Assigns "@tony" to task 3 for this channel.
#--------------------------------------------------------
def adjust_inherited_cmd_action_context(p_hash)
  assigned_member_is_mentioned_member(p_hash)
  # Assign task from list user is looking at.
  inherit_list_scope(p_hash)
  inherit_channel_scope(p_hash)
  # Figure out the list we are working on and its attributes.
  adjust_inherited_cmd_action_list(p_hash)
  implied_list_owner(p_hash)
end

def adjust_inherited_cmd_action_list(p_hash)
  # We are trying to assign/unassign/due/done a task to a specific member
  # on a member or team list. This is the only option to get here. We will
  # err out otherwise.
  return p_hash[:list] = [] if p_hash[:previous_action_list_context].empty?
  # Inherit item list from what user is looking at.
  p_hash[:list] = p_hash[:previous_action_list_context][:list]
end
