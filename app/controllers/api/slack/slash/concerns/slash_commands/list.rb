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
  records = list_from_parsed(parsed) unless parsed[:display_after_action_list]
  records = list_from_list_of_ids(parsed[:after_action_list_context][:list]) if parsed[:display_after_action_list]
  parsed[:debug] = true if records.nil?
  records = [] if records.nil?
  context = parsed unless parsed[:display_after_action_list]
  context = parsed[:after_action_list_context] if parsed[:display_after_action_list]
  format_display_list(parsed, context, records)
end

# Returns: slash_response() return values.
def prepend_to_list_command(parsed, prepend_text)
  list_text, list_attachments = list_command(parsed)
  combined_text =
    prepend_text.concat("   Updated list as follows: \n").concat(list_text)
  slash_response(combined_text, list_attachments, parsed)
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
  type = context[:list_owner_name] unless context[:list_scope] == :team
  type = 'team' if context[:list_scope] == :team
  return type if context[:channel_scope] == :one_channel
  type.concat(' all') # context[:channel_scope] == :all_channels
  type
end

# Returns: updated attachments array.
def list_add_item_to_display_list(attachments, item, index)
  # { text: '1) rev 1 spec @susan /jun15 | *Assigned* to @susan',
  #  mrkdwn_in: ['text']
  # }
  attachments << {
    text: "#{index + 1}) #{item.description}",
    mrkdwn_in: ['text']
  }
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
