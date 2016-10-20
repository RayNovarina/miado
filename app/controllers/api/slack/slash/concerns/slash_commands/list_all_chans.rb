# Returns: [text, attachments]
def all_channels_display(parsed, context, list_of_records)
  text, attachments = all_chans_header(parsed, context, list_of_records)
  list_ids = all_chans_body(parsed, text, attachments, list_of_records)
  # list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

# Returns: [text, attachments]
def all_chans_header(parsed, context, list_of_records)
  [list_chan_header(parsed, context, list_of_records, '#all-channels '), []] # in list.rb
end

# Returns: list_ids[]
def all_chans_body(parsed, _text, attachments, list_of_records, options = { new_attachment: false })
  list_ids = []
  current_channel_id = ''
  list_of_records.each_with_index do |item, index|
    unless current_channel_id == item.channel_id
      current_channel_id = item.channel_id
      attachments << {
        color: '#3AA3E3',
        text: "---- ##{item.channel_name} channel ----------",
        mrkdwn_in: ['text']
      }
    end
    list_add_item_to_display_list(
      parsed,
      attachments,
      options[:new_attachment] && index == 0 ? 'new' : 'last',
      item,
      index + 1)
    list_ids << item.id
  end
  list_ids
end
