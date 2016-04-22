def delete_command(debug)
  params = @view.url_params
  parsed_cmd = parse_slash_cmd(:delete, params)
  text = process_delete_cmd(params, parsed_cmd, debug)
  text.concat("\n`You typed: `  ")
      .concat(params[:command]).concat(' ')
      .concat(params[:text]) if debug || text.starts_with?('Error:')
  return slash_response(text, nil, debug) if text.starts_with?('Error:')
  return slash_response(text, nil, debug) if parsed_cmd[:sub_func] == :team
  prepend_to_list_command(:mine, text, debug)
end

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

def process_delete_cmd(params, parsed_cmd, _debug)
  return parsed_cmd[:err_msg] unless parsed_cmd[:err_msg].empty?

  channel_list = list_item_query(parsed_cmd, params)

  return 'Error: List empty.' if channel_list.empty?
  return delete_team(parsed_cmd, channel_list) if parsed_cmd[:sub_func] == :team
  return delete_mine(parsed_cmd, channel_list) if parsed_cmd[:sub_func] == :mine
  return delete_member(parsed_cmd, channel_list) if parsed_cmd[:sub_func] == :member
  delete_one(parsed_cmd, channel_list)
end

def list_item_query(parsed_cmd, params)
  return ListItem.where(channel_id: params[:channel_id]) if parsed_cmd[:sub_func] == :team
  return ListItem.where(channel_id: params[:channel_id], assigned_member_id: params[:user_id]) if parsed_cmd[:sub_func] == :mine
  ListItem.where(channel_id: params[:channel_id]).reorder('created_at ASC')
end

def delete_one(parsed_cmd, channel_list)
  return 'Error: Task number is out of range for this list.' if parsed_cmd[:task_num].to_i > channel_list.size
  if (channel_list[parsed_cmd[:task_num].to_i - 1]).destroy
    return "Deleted task #{parsed_cmd[:task_num]}."
  end
  'Error: There was an error deleting this Task.'
end

def delete_team(_parsed_cmd, channel_list)
  channel_list.destroy_all
  'Deleted all tasks for your Team in this channel.'
end

def delete_mine(_parsed_cmd, channel_list)
  channel_list.destroy_all
  'Deleted all of your ASSIGNED tasks in this channel.'
end

def delete_member(_parsed_cmd, channel_list)
  channel_list.destroy_all
  "Deleted all ASSIGNED tasks in this channel for member #{parsed_cmd[:assigned_member_name]}."
end
