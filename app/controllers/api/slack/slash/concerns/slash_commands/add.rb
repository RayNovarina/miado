def add_command(debug)
  params = @view.url_params
  text = process_add_cmd(params)
  text.concat("\n`Original command: `  ").concat(params[:text]) if debug
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
text	add
token	3ZQVG7rk4p7EZZluk1gTH3aN
user_id	U0VLZ5P51
user_name	ray
=end

def process_add_cmd(params)
  parsed_cmd = parse_slash_cmd(:add, params)
  item = ListItem.create!(
    channel_name: params[:channel_name],
    command_text:  params[:text],
    team_domain: params[:team_domain],
    team_id: params[:team_id],
    slack_user_id: params[:user_id],
    slack_user_name: params[:user_name],
    slack_deferred_response_url: params[:response_url]
  )

  item.channel_id, task_num_clause =
    add_assigned_channel(params)
  item.assigned_member_id, assigned_to_clause =
    add_assigned_member(parsed_cmd)
  item.assigned_due_date, due_date_clause =
    add_due_date(parsed_cmd)

  item.description =
    "#{task_num_clause}#{assigned_to_clause}#{due_date_clause}" \
    'Type `/do list` for a current list.'
  item.save!
  item.description
end

def add_assigned_channel(params)
  [params[:channel_id],
   "Task #{ListItem.where(channel_id: params[:channel_id]).count + 1} added. "
  ]
end

def add_assigned_member(parsed_cmd)
  return [nil, ''] if parsed_cmd[:assigned_member_id].nil?
  [parsed_cmd[:assigned_member_id],
   "| *Assigned* to #{parsed_cmd[:assigned_members_name]}."
  ]
end

def add_due_date(parsed_cmd)
  return [nil, ''] if parsed_cmd[:due_date].nil?
  [parsed_cmd[:due_date],
   "| *Due* #{parsed_cmd[:due_date.strftime('%a, %d %b')]}."
  ]
end

def parse_slash_cmd(_cmd, _params)
  { assigned_member_id: nil,
    assigned_members_name: nil,
    due_date: nil
  }
end