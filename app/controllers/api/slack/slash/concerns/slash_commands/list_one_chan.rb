# Returns: [text, attachments, list_ids]
def one_channel_display(parsed, context, list_of_records, caller_id = 'list')
  text, attachments = one_chan_header(parsed, context, list_of_records, caller_id)
  list_ids = one_chan_body(parsed, text, attachments, list_of_records)
  # list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

# Returns: [text, attachments]
def one_chan_header(parsed, context, list_of_records, caller_id)
  parsed[:response_headline] = list_format_headline_text(parsed, context, list_of_records, true) # in list.rb
  ['', list_chan_headline_replacement(parsed, parsed[:response_headline], caller_id)] # in list.rb
end

# Returns: list_ids[]
def one_chan_body(parsed, _text, attachments, list_of_records,
                  options = { new_attachment: true })
  list_ids = []
  list_of_records.each_with_index do |item, index|
    list_add_item_to_display_list( # in list.rb
      parsed,
      attachments,
      options[:new_attachment] && index == 0 ? 'new' : 'last',
      item,
      index + 1)
    list_ids << item.id
  end
  list_ids
end
