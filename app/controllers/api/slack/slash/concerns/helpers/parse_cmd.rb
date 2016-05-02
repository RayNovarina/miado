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

def parse_slash_cmd(params, _view, previous_action_parse_hash)
  p_hash = new_parse_hash(params, previous_action_parse_hash)
  scan4_command_func(p_hash)
  perform_scans_for_functions(p_hash)
  add_list_scope(p_hash)
  add_channel_scope(p_hash)
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
    p_hash[:requires_mentioned_member] = true
    scan4_mentioned_member(p_hash)
  when :delete
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
    scan4_options(p_hash)
  when :done
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
  when :due
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    p_hash[:requires_due_date] = true
    scan4_due_date(p_hash)
  when :help
    scan4_options(p_hash)
  when :list
    scan4_mentioned_member(p_hash)
    scan4_options(p_hash)
  when :redo
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
    scan4_due_date(p_hash)
  when :unassign
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    p_hash[:requires_mentioned_member] = true
    scan4_mentioned_member(p_hash)
  end
end

# Case: command function split has been processed, leaving:
#       '' was 'help' or 'list', '1 @tony' was 'assign 1 @tony',
#       'team', was 'delete team', 'a new task @ray /jun15' is unchanged,
#       'channel 5' was 'list channel 5'
CMD_LIST_SCOPES = %w(one_member team).freeze
CMD_FUNCS_INHERITING_LIST_SCOPE = [:add, :append, :assign, :delete, :due,
                                   :help, :redo].freeze
def add_list_scope(p_hash)
  # Some funcs can only inherit list_scope from the list the user is looking at.
  if CMD_FUNCS_INHERITING_LIST_SCOPE.include?(p_hash[:func])
    return p_hash[:list_scope] = :one_member if p_hash[:previous_action_list_context].empty?
    return p_hash[:list_scope] = p_hash[:previous_action_list_context][:list_scope]
  end
  p_hash[:list_scope] = :one_member unless p_hash[:team_option]
  p_hash[:list_scope] = :team if p_hash[:team_option]
end

CMD_CHANNEL_SCOPES = %w(one_channel all_channels).freeze
CMD_FUNCS_INHERITING_CHANNEL_SCOPE = [:add, :append, :assign, :done, :due, :help, :redo].freeze
def add_channel_scope(p_hash)
  # Some funcs can only inherit channel_scope from the list the user is looking at.
  if CMD_FUNCS_INHERITING_CHANNEL_SCOPE.include?(p_hash[:func])
    return p_hash[:channel_scope] = :one_channel if p_hash[:previous_action_list_context].empty?
    return p_hash[:channel_scope] = p_hash[:previous_action_list_context][:channel_scope]
  end
  p_hash[:channel_scope] = :one_channel unless p_hash[:all_option]
  p_hash[:channel_scope] = :all_channels if p_hash[:all_option]
end

# Note: what looks like a command may actually be an added task, i.e.
#       'delete all open tasks for @susan is a new task'
# Case: command is as entered from command line.
#       'a new task', 'list team'
CMD_FUNCS = %w(append assign delete done due help list redo unassign).freeze
def scan4_command_func(p_hash)
  return p_hash[:func] = :help if p_hash[:cmd_splits].length == 0
  maybe_func = p_hash[:cmd_splits][0]
  p_hash[:func] = CMD_FUNCS.include?(maybe_func) ? maybe_func.to_sym : nil
  # discard/consume func word if we have one.
  p_hash[:cmd_splits].shift unless p_hash[:func].nil?
  # Default to add cmd if no func specified or implied.
  p_hash[:func] = :add if p_hash[:func].nil?
end

# Case: command function has been processed, leaving:
#       'open' was 'list open', '' was 'list ', '4' was 'delete team 4',
#       'open team' was 'list open team', 'team all' was 'list team all',
#       'all open tasks for @susan is a new task' was 'delete all open tasks for @susan is a new task'
CMD_OPTIONS = %w(open due done all team more).freeze
def scan4_options(p_hash)
  return unless p_hash[:err_msg].empty?
  # Have to be adding task if command is longer than options allow.
  return p_hash[:func] = :add if p_hash[:cmd_splits].length > CMD_OPTIONS.length - 1
  p_hash[:team_option] = p_hash[:cmd_splits].include?('team')
  p_hash[:all_option] = p_hash[:cmd_splits].include?('all')
  p_hash[:open_option] = p_hash[:cmd_splits].include?('open')
  p_hash[:due_option] = p_hash[:cmd_splits].include?('due')
  p_hash[:done_option] = p_hash[:cmd_splits].include?('done')
  p_hash[:more_option] = p_hash[:cmd_splits].include?('more')
  adjust_cmd_options_for_add_cmd(p_hash)
end

# Case: command function has been processed, leaving:
#       'all open tasks for @susan is a new task' was 'delete all open tasks for @susan is a new task'
def adjust_cmd_options_for_add_cmd(p_hash)
  # Have to be adding task if command is longer than options specified.
  num_options = 0
  num_options += 1 if p_hash[:team_option]
  num_options += 1 if p_hash[:all_option]
  num_options += 1 if p_hash[:open_option]
  num_options += 1 if p_hash[:due_option]
  num_options += 1 if p_hash[:done_option]
  num_options += 1 if p_hash[:more_option]
  num_options += 1 unless p_hash[:task_num].nil?
  num_options += 1 unless p_hash[:mentioned_member_id].nil?
  p_hash[:func] = :add if p_hash[:cmd_splits].length > num_options
end

# Trim off the leading command func, scope and sub_func. Remainder is what
# most of our following parse logic cares about.
# def rebuild_remaining_command_line(p_hash)
#  p_hash[:command] =
#    p_hash[:cmd_splits][p_hash[:next_cmd_split_to_parse]..-1].join(' ')
# end

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
  at_pos = p_hash[:command].index('@')
  return p_hash[:err_msg] = 'Error: team member must be mentioned.' if at_pos.nil? && p_hash[:requires_mentioned_member]
  return if at_pos.nil?
  blank_pos = p_hash[:command].index(' ', at_pos)

  end_of_name_pos = p_hash[:command].length - 1 if blank_pos.nil?
  end_of_name_pos = blank_pos - 1 unless blank_pos.nil?

  name = p_hash[:command].slice(at_pos + 1, end_of_name_pos - at_pos)

  p_hash[:mentioned_member_id], p_hash[:mentioned_member_name] =
    slack_member_from_name(p_hash, name)
  return if p_hash[:mentioned_member_id].nil?
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

def slack_member_from_name(p_hash, name)
  return [p_hash[:user_id], p_hash[:user_name]] if name == 'me'
  member = Member.find_or_create_from_slack_name(@view, name,
                                                 p_hash[:url_params][:team_id])
  if member.nil?
    p_hash[:err_msg] =
      "Error: Member @#{name} not found."
    return [nil, name]
  end
  [member.slack_user_id, name]
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

# Returns: [nil, false] if invalide date.
#          [datetime object, true/false if due date input string is of format]
#         'sun' thru 'sat'
def date_from_due_date(due_date_string)
  numeric_partition = due_date_string.partition(/\d/)
  # Case: no numeric portion. /fri or /jun or /half
  if numeric_partition[1].empty?
    begin
      due_date = due_date_string.to_datetime
    rescue ArgumentError
      return [nil, false]
    end
    return due_date,
           Date::ABBR_DAYNAMES.map {|abbr| abbr.downcase}.include?(numeric_partition[0].downcase)
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
  return if p_hash[:due_date] > DateTime.now
  return if p_hash[:due_date].today?
  # Case: just day of week specified.
  return p_hash[:due_date] = (p_hash[:due_date].to_date + 7).to_datetime if is_day_of_week
  # Case: Month/day specified:
  p_hash[:due_date] = p_hash[:due_date].to_date.next_year.to_datetime
end
