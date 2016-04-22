def list_command(debug)
  params = @view.url_params
  text, attachments = process_list_cmd(params)
  text.concat("\n`You typed: `  ")
      .concat(params[:command]).concat(' ')
      .concat(params[:text]) if debug || text.starts_with?('Error:')
  slash_response(text, attachments, debug)
end

def prepend_to_list_command(type, prepend_text, debug)
  list_text, list_attachments = process_list_cmd(@view.url_params, type)
  combined_text =
    prepend_text
    .concat(" Updated list as follows: \n")
    .concat(list_text)
  slash_response(combined_text, list_attachments, debug)
end

=begin
  Form Params
  channel_id	C0VNKV7BK
  channel_name	general
  command	/do
  response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
  team_domain	shadowhtracteam
  team_id	T0VN565N0
  text	list me
  token	3ZQVG7rk4p7EZZluk1gTH3aN
  user_id	U0VLZ5P51
  user_name	ray
=end

def process_list_cmd(params, type = nil)
  parsed_cmd = parse_slash_cmd(:list, params)
  type ||= parsed_cmd[:sub_func]

  list = list_item_query(parsed_cmd, params)
  # return 'Error: List empty.' if list.empty?

  format_display_list(type, list, params)
end

def list_item_query(parsed_cmd, params)
  # mine: All list items for this Team Channel assigned to this Slack member
  return ListItem.where(channel_id: params[:channel_id],
                        assigned_member_id: params[:user_id]
                       ) if parsed_cmd[:sub_func] == :mine
  # due: All list items for this Team Channel assigned to this Slack member and
  # with a due date.
  return ListItem.where(channel_id: params[:channel_id],
                        assigned_member_id: params[:user_id],
                        due_date: nil
                       ) if parsed_cmd[:sub_func] == :due
  # team: All list items for this Team Channel.
  return ListItem.where(channel_id: params[:channel_id]
                       ) if parsed_cmd[:sub_func] == :team
  # member: All list items for this Team Channel assigned to a Slack member
  return ListItem.where(channel_id: params[:channel_id],
                        assigned_member_id: parsed_cmd[:assigned_member_id]
                       ) if parsed_cmd[:sub_func] == :member
  # all: All list items for ALL Channels assigned to this Slack member
  return ListItem.where(team_id: params[:team_id],
                        assigned_member_id: params[:user_id]
                       ) if parsed_cmd[:sub_func] == :all
end

def format_display_list(type, list, params)
  text = "<##{params['channel_id']}|#{params['channel_name']}> " \
         "to-do list (#{type.to_s})" \
         "#{list.empty? ? ' (empty)' : ''}"
  attachments = []
  list.each_with_index do |item, index|
    # { text: '1) rev 1 spec @susan /jun15 | *Assigned* to @susan',
    #  mrkdwn_in: ['text']
    # }
    attachments << {
      text: "#{index + 1}) #{item.description}",
      mrkdwn_in: ['text']
    }
  end
  [text, attachments]
end

=begin
  1) order flow CRM
  2) Brent & shipping info @tony | ​*Assigned:*​ @tony
  3) Kendra todo invoices @tony | ​*Assigned:*​ @tony
  4) CSM leads in @tony | ​*Assigned:*​ @tony
  5) SMP @tony | ​*Assigned:*​ @tony
  6) NEXT/APTA June @Tony | ​*Assigned:*​ @tony
  7) example newsletter @tony | ​*Assigned:*​ @tony
  8) 1 @tony | ​*Assigned:*​ @tony
=end
