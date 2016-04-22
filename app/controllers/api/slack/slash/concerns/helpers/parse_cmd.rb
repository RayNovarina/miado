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

'• `/do rev 1 spec @susan /jun15`' \
' Adds "rev 1 spec" to this channel, assigns it to Susan and sets' \
" a due date of June 15.\n" \
'• `/do append 3 Contact Jim.`' \
" Adds \"Contact Jim.\" to the end of task 3.\n" \
'• `/do assign 3 @tony`' \
" Assigns \"@tony\" to task 3 for this channel.\n" \
'• `/do unassign 4 @joe`' \
" Removes \"@joe\" from task 4.\n" \
'• `/do done 4`' \
" Marks task 4 as completed.\n" \
'• `/do remove 4`' \
" Deletes task number 4 from the list.\n" \
'• `/do due 4 /wed`' \
" Sets the task due date to Wednesday for task 4.\n" \
'• `/do redo 1 Send out newsletter by /fri.`' \
' Deletes tasks 1 and replaces it with ' \
"\"Send out newsletter by /fri\"\n" \
'• `/do list`' \
" Lists your tasks for this channel.\n" \
'• `/do list due`' \
" Lists your open tasks for this channel and their due dates.\n" \
'• `/do list all`' \
" Lists all team tasks for this channel.\n" \
'• `/do help more`' \
" Display /do keyboard shortcuts, misc. commands.\n" \
':bulb: Click on the "mia-lists" member to see all of your up to date ' \
'lists.\n' \
'• `-- more help --`' \
'• `/do list me`' \
" Lists your open tasks for all channels and their due dates.\n" \
=end

def parse_slash_cmd(func, params)
  command, _debug = check_for_debug(params)
  p_hash =
    { command: command,
      err_msg: '',
      assigned_member_id: nil,
      assigned_member_name: nil,
      due_date: nil,
      task_num: nil,
      func: func,
      sub_func: nil
    }
  case func
  when :add
    adjust_add_command(p_hash)
    scan4_member(p_hash)
    scan4_due_date(p_hash) if p_hash[:err_msg].empty?
  when :list
    scan4_sub_func(p_hash)
  when :help
  when :delete
    scan4_sub_func(p_hash)
    scan4_task_num(p_hash)
  end
  p_hash
end

def adjust_add_command(p_hash)
  return unless p_hash[:command].starts_with?('add')
  blank_pos = p_hash[:command].index(' ')
  return 'Error: no task specified.' if blank_pos.nil?
  p_hash[:command] = p_hash[:command].slice(blank_pos..-1).lstrip
end

# p_hash = { command: 'list all', func: :list, sub_func: nil }
def scan4_sub_func(p_hash)
  sub_funcs = %w(due all team mine me)
  # Do we have pattern 'list<b>'?
  if p_hash[:command].index(p_hash[:func].to_s.concat(' ')).nil?
    # no
    p_hash[:sub_func] = :mine if p_hash[:func] == :list
    return
  end
  # yes
  sub_func_begin_pos = p_hash[:command].index(' ', 1) + 1
  sub_func_end_pos =
    p_hash[:command].index(' ', sub_func_begin_pos) ||
    sub_func_begin_pos + p_hash[:command].length - sub_func_begin_pos - 1
  sub_func =
    p_hash[:command].slice(sub_func_begin_pos, sub_func_end_pos)
  p_hash[:sub_func] = sub_funcs.include?(sub_func) ? sub_func.to_sym : nil
  p_hash[:sub_func] = :mine if sub_func == 'me'
end

def scan4_task_num(p_hash)
  return unless p_hash[:sub_func].nil?
  p_hash[:task_num] = p_hash[:command][/\d+/]
  p_hash[:err_msg] =
    'Error: no task number specified.' if p_hash[:task_num].nil?
end

# s = 'get donuts @susan /fri all kinds'
def scan4_member(p_hash)
  at_pos = p_hash[:command].index('@')
  return if at_pos.nil?
  blank_pos = p_hash[:command].index(' ', at_pos)

  end_of_name_pos = p_hash[:command].length - 1 if blank_pos.nil?
  end_of_name_pos = blank_pos - 1 unless blank_pos.nil?

  name = p_hash[:command].slice(at_pos + 1, end_of_name_pos - at_pos)

  p_hash[:assigned_member_id], p_hash[:assigned_member_name] =
    slack_member_from_name(p_hash, name)
end

def slack_member_from_name(p_hash, name)
  return [p_hash[:user_id], p_hash[:user_name]] if name == 'me'
  member = Member.find_or_create_from_slack(@view, name)
  if member.nil?
    p_hash[:err_msg] =
      "Error: Member @#{name} not found."
    return [nil, name]
  end
  [member.slack_user_id, name]
end

def scan4_due_date(p_hash)
  slash_pos = p_hash[:command].index('/')
  return if slash_pos.nil?
  blank_pos = p_hash[:command].index(' ', slash_pos)

  end_of_date_pos = p_hash[:command].length - 1 if blank_pos.nil?
  end_of_date_pos = blank_pos - 1 unless blank_pos.nil?

  due_date_string =
    p_hash[:command].slice(slash_pos + 1, end_of_date_pos - slash_pos)

  p_hash[:due_date] = date_from_due_date(due_date_string)
  return if p_hash[:due_date].nil?
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
    # Assume standalone day or month refers to a future date.
    # if due_date < DateTime.now
    # end
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
    # Assume standalone day or month refers to a future date.
    # if due_date < DateTime.now
    # end
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
  # Assume standalone day or month refers to a future date.
  # if due_date < DateTime.now
  # end
  due_date
end
