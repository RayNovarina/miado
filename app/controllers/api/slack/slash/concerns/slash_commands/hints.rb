
# Returns: [text, attachments]
def hints_command(parsed)
  text = hints(parsed)
  @view.channel.last_activity_type = 'slash_command - hints'
  @view.channel.last_activity_date = DateTime.current
  @view.channel.save
  [text, nil]
end

# Returns: text response message.
def hints(parsed)
  "Take the hint #{parsed[:url_params][:user_name]}"
end

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

# Returns: Comment object.
def comment_from_slash_feedback(parsed)
  team_name = Member.find_from(
    source: :slack,
    slack_user_id: parsed[:url_params][:user_id],
    slack_team_id: parsed[:url_params][:team_id]).first.slack_team_name
  name = "#{parsed[:url_params][:user_name]} on Slack Team '#{team_name}'"
  email = '**Submitted as feedback**'
  body = parsed[:cmd_splits].join(' ')
  Comment.new(name: name, email: email, body: body)
end
