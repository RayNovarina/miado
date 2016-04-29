def done_command(parsed)
  text = process_done_cmd(parsed)
  add_standard_debug_info(parsed, text)
  slash_response(text, nil, parsed)
end

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

# /do assign 3 @tony Assigns "@tony" to task 3 for this channel.
# full syntax: /do assign channel 3 @tony
#              /do assign team 3 @tony
def process_done_cmd(parsed)
  return parsed_cmd[:err_msg] unless parsed_cmd[:err_msg].empty?
end
