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

# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          parsed[:list_for_after_action] = based on the new parsed info.
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# SUB_FUNCS  = %w(open due more done)
# list_owner = :team, :mine, :member
# assigned_member_id = list.id of member assigned a task
#------------------------------
def list_command(parsed)
  adjust_list_cmd_action_context(parsed)
  format_display_list(parsed, parsed, list_from_parsed(parsed))
end

def adjust_list_cmd_action_context(parsed)
  adjust_list_cmd_list_owner(parsed)
end

# @me member is implied if no Other member is mentioned. However, 'list team'
# implies no member is mentioned.
def adjust_list_cmd_list_owner(parsed)
  return parsed[:list_owner] = :team, parsed[:list_owner_name] = 'team' if parsed[:list_scope] == :team
  parsed[:list_owner] = :member
  if parsed[:mentioned_member_id].nil?
    parsed[:mentioned_member_name] = parsed[:url_params][:user_name]
    parsed[:mentioned_member_id] = parsed[:url_params][:user_id]
  end
  parsed[:list_owner_name] = "@#{parsed[:mentioned_member_name]}"
end

# Returns: slash_response() return values.
def prepend_text_to_list_command(parsed, prepend_text)
  list_text, list_attachments =
    format_display_list(parsed, parsed[:after_action_list_context],
                        list_from_list_of_ids(parsed, parsed[:after_action_list_context][:list]))
  combined_text =
    prepend_text.concat("   Updated list as follows: \n").concat(list_text)
  [combined_text, list_attachments]
end

# Returns: [text, attachments]
def format_display_list(parsed, context, list_of_records)
  text, attachments, list_ids = one_channel_display(parsed, context, list_of_records) if context[:channel_scope] == :one_channel
  text, attachments, list_ids = all_channels_display(parsed, context, list_of_records) if context[:channel_scope] == :all_channels
  # Persist the channel.list_ids[] for the next transaction.
  save_after_action_list_context(parsed, context, list_ids) unless parsed[:display_after_action_list]
  text.concat(parsed[:err_msg]) unless parsed[:err_msg].empty?
  [text, attachments]
end

# Returns: [text, attachments]
def one_channel_display(parsed, context, list_of_records)
  text = "<##{parsed[:url_params]['channel_id']}|#{parsed[:url_params]['channel_name']}> " \
         "to-do list (#{format_owner_title(context)})" \
         "#{list_of_records.empty? ? ' (empty)' : ''}"
  list_ids = []
  attachments = []
  list_of_records.each_with_index do |item, index|
    list_add_item_to_display_list(attachments, item, index)
    list_ids << item.id
  end
  [text, attachments, list_ids]
end

def format_owner_title(context)
  return context[:list_owner_name] if context[:channel_scope] == :one_channel
  context[:list_owner_name].concat(' - all')
end

# Returns: updated attachments array.
def list_add_item_to_display_list(attachments, item, index)
  # { text: '1) rev 1 spec @susan /jun15 | *Assigned* to @susan',
  #  mrkdwn_in: ['text']
  # }
  attachments << {
    text: "#{index + 1}) #{item.description}" \
          "#{list_cmd_assigned_to_clause(item)}" \
          "#{list_cmd_due_date_clause(item)}" \
          "#{list_cmd_task_completed_clause(item)}",
    mrkdwn_in: ['text']
  }
end

def list_cmd_assigned_to_clause(item)
  return '' if item.assigned_member_id.nil?
  " | *Assigned* to @#{item.assigned_member_name}."
end

def list_cmd_due_date_clause(item)
  return '' if item.assigned_due_date.nil?
  " | *Due* #{item.assigned_due_date.strftime('%a, %d %b %Y')}."
end

def list_cmd_task_completed_clause(item)
  return '' unless item.done
  ' | *Completed* '
end

# Returns: [text, attachments, list_ids]
def all_channels_display(_parsed, context, list_of_records)
  text = '#all-channels ' \
         "to-do list (#{format_owner_title(context)})" \
         "#{list_of_records.empty? ? ' (empty)' : ''}"
  list_ids = []
  attachments = []
  channel_index = 0
  current_channel_id = ''
  list_of_records.each do |item|
    unless current_channel_id == item.channel_id
      channel_index = 0
      current_channel_id = item.channel_id
      attachments << {
        text: "---- ##{item.channel_name} channel ----------",
        mrkdwn_in: ['text']
      }
    end
    list_add_item_to_display_list(attachments, item, channel_index)
    list_ids << item.id
    channel_index += 1
  end
  [text, attachments, list_ids]
end
