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
  add_list_owner(p_hash)
  build_action_list_context(p_hash)
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
  when :assign, :unassign
    p_hash[:requires_task_num] = true
    p_hash[:requires_member] = true
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
  when :delete
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
    scan4_sub_func(p_hash)
  when :done
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    scan4_mentioned_member(p_hash)
  when :due
    p_hash[:requires_task_num] = true
    scan4_task_num(p_hash)
    scan4_due_date(p_hash)
    scan4_mentioned_member(p_hash)
  when :help
    scan4_sub_func(p_hash)
  when :list
    scan4_sub_func(p_hash)
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
  p_hash[:list_scope] = :one_member unless p_hash[:sub_func] == :team
  p_hash[:list_scope] = :team if p_hash[:sub_func] == :team
end

CMD_CHANNEL_SCOPES = %w(one_channel all_channels).freeze
CMD_FUNCS_INHERITING_CHANNEL_SCOPE = [:add, :append, :assign, :done, :due, :help, :redo].freeze
def add_channel_scope(p_hash)
  # Some funcs can only inherit channel_scope from the list the user is looking at.
  if CMD_FUNCS_INHERITING_CHANNEL_SCOPE.include?(p_hash[:func])
    return p_hash[:channel_scope] = :one_channel if p_hash[:previous_action_list_context].empty?
    return p_hash[:channel_scope] = p_hash[:previous_action_list_context][:channel_scope]
  end
  p_hash[:channel_scope] = :one_channel unless p_hash[:sub_func] == :all
  p_hash[:channel_scope] = :all_channels if p_hash[:sub_func] == :all
end

def add_list_owner(p_hash)
  return p_hash[:list_owner] = :team, p_hash[:list_owner_name] = 'team' if p_hash[:list_scope] == :team
  p_hash[:list_owner] = :member
  unless p_hash[:previous_action_list_context].empty?
    # Some funcs can only inherit list_owner from the list the user is looking
    # at. Note: we just inherited the list_scope.
    if CMD_FUNCS_INHERITING_LIST_SCOPE.include?(p_hash[:func])
      p_hash[:mentioned_member_name] = p_hash[:previous_action_list_context][:mentioned_member_name]
      p_hash[:mentioned_member_id] = p_hash[:previous_action_list_context][:mentioned_member_id]
    end
  end
  # list command is special case: @me member is implied if 'list' and no Other
  # member is mentioned. However, 'list team' implies no member is mentioned.
  p_hash[:mentioned_member_name] = p_hash[:url_params][:user_name] if p_hash[:mentioned_member_id].nil?
  p_hash[:mentioned_member_id] = p_hash[:url_params][:user_id] if p_hash[:mentioned_member_id].nil?
  p_hash[:list_owner_name] = "@#{p_hash[:mentioned_member_name]}"
end

CMD_FUNCS_REQUIRING_ACTION_LIST = [:add, :assign, :unassign, :delete, :done].freeze
def build_action_list_context(p_hash)
  return unless CMD_FUNCS_REQUIRING_ACTION_LIST.include?(p_hash[:func])
  if p_hash[:previous_action_list_context].empty?
    p_hash[:list] = []
  elsif context_matches(p_hash, p_hash[:previous_action_list_context])
    p_hash[:list] =
      p_hash[:previous_action_list_context][:list]
  else
    p_hash[:list] =
      ids_from_context(p_hash, p_hash[:previous_action_list_context])
  end
end

def context_matches(context1, context2)
  return false if context1.empty? || context2.empty?
  true # if context1[:list_scope] == context2[:list_scope] &&
  #               context1[:channel_scope] == context2[:channel_scope] &&
  #               context1[:list_scope] == context2[:list_scope] &&
  #               context1[:list_scope] == context2[:list_scope] &&
  #               context1[:list_scope] == context2[:list_scope] &&
  #               context1[:list_scope] == context2[:list_scope]
end

# Case: command is as entered from command line.
#       'a new task', 'list team'
CMD_FUNCS = %w(add append assign delete done due help list redo unasign).freeze
def scan4_command_func(p_hash)
  return p_hash[:func] = :help if p_hash[:next_cmd_split_to_parse] >= p_hash[:cmd_splits].length
  maybe_func = p_hash[:cmd_splits][p_hash[:next_cmd_split_to_parse]]
  p_hash[:func] = CMD_FUNCS.include?(maybe_func) ? maybe_func.to_sym : nil
  # discard/consume func word if we have one.
  p_hash[:next_cmd_split_to_parse] += 1 unless p_hash[:func].nil?
  p_hash[:func] = :add if p_hash[:func].nil?
end

# Case: command function and scope have been processed, leaving:
#       'open' was 'list open', '' was 'list ', '4' was 'delete team 4'
CMD_SUB_FUNCS = %w(open due done all team more).freeze
def scan4_sub_func(p_hash)
  return unless p_hash[:err_msg].empty?
  return if p_hash[:next_cmd_split_to_parse] >= p_hash[:cmd_splits].length
  maybe_sub_func = p_hash[:cmd_splits][p_hash[:next_cmd_split_to_parse]]
  p_hash[:sub_func] = CMD_SUB_FUNCS.include?(maybe_sub_func) ? maybe_sub_func.to_sym : nil
  return (parsed[:err_msg] =
           'Error: sub command required.') if p_hash[:sub_func].nil? &&
                                              p_hash[:requires_sub_func]
  p_hash[:sub_func] = nil if p_hash[:sub_func] == :more && !p_hash[:func] == :help
  # discard/consume sub_func word if we have one.
  p_hash[:next_cmd_split_to_parse] += 1 unless p_hash[:sub_func].nil?
  rebuild_remaining_command_line(p_hash)
end

# Trim off the leading command func, scope and sub_func. Remainder is what
# most of our following parse logic cares about.
def rebuild_remaining_command_line(p_hash)
  p_hash[:command] =
    p_hash[:cmd_splits][p_hash[:next_cmd_split_to_parse]..-1].join(' ')
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
  at_pos = p_hash[:command].index('@')
  return if at_pos.nil?
  blank_pos = p_hash[:command].index(' ', at_pos)

  end_of_name_pos = p_hash[:command].length - 1 if blank_pos.nil?
  end_of_name_pos = blank_pos - 1 unless blank_pos.nil?

  name = p_hash[:command].slice(at_pos + 1, end_of_name_pos - at_pos)

  p_hash[:mentioned_member_id], p_hash[:mentioned_member_name] =
    slack_member_from_name(p_hash, name)
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
  return if slash_pos.nil?
  blank_pos = p_hash[:command].index(' ', slash_pos)

  end_of_date_pos = p_hash[:command].length - 1 if blank_pos.nil?
  end_of_date_pos = blank_pos - 1 unless blank_pos.nil?

  due_date_string =
    p_hash[:command].slice(slash_pos + 1, end_of_date_pos - slash_pos)

  p_hash[:due_date] = date_from_due_date(due_date_string)
  return if p_hash[:due_date].nil?
  adjust_and_verify_due_date(p_hash)
end

def adjust_and_verify_due_date(p_hash)
  # ??Assume standalone day or month refers to a future date.
  p_hash[:err_msg] =
    'Error: Due date has already passed.' if p_hash[:due_date] < DateTime.now
end

def date_from_due_date(due_date_string)
  numeric_partition = due_date_string.partition(/\d/)
  # Case: no numeric portion. /fri or /jun or /half
  if numeric_partition[1].empty?
    begin
      due_date = due_date_string.to_datetime
    rescue ArgumentError
      return nil
    end
    return due_date
  end
  # Case: just day of month specified. /12
  if numeric_partition[0].empty?
    begin
      due_date = DateTime.now.strftime('%b')
                         .concat(' ').concat(due_date_string)
                         .to_datetime
    rescue ArgumentError
      p_hash[:err_msg] = 'Error: invalid day of month.'
      return nil
    end
    return due_date
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
    return nil
  end
  due_date
end
