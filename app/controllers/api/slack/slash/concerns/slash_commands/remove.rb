def remove_command(debug)
  params = @view.url_params
  text = process_remove_cmd(params, debug)
  add_debug_header(params, text) if debug
  slash_response(text, nil, debug)
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

def process_remove_cmd(params, _debug)
  parsed_cmd = parse_slash_cmd(:remove, params)
  return parsed_cmd[:err_msg] unless parsed_cmd[:err_msg].empty?

  channel_list =
    ListItem.where(channel_id: params[:channel_id]).reorder('created_at ASC')
  return 'Error: List empty.' if channel_list.empty?
  if (channel_list[parsed_cmd[:task_num].to_i - 1]).destroy
    return "Removed task #{parsed_cmd[:task_num]}. " \
           'Type `/do list` for a current list.'
  end
  'There was an error deleting this Task.'
end
