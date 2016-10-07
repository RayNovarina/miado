# Returns: [text, attachments]
def one_channel_display(parsed, context, list_of_records)
  text, attachments = one_chan_header(parsed, context, list_of_records)
  list_ids = one_chan_body(parsed, text, attachments, list_of_records)
  list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

# Returns: [text, attachments]
def one_chan_header(parsed, context, list_of_records)
  return one_chan_header_button_action(
    parsed, context, list_of_records) unless parsed[:button_callback_id].nil?
  # Default case.
  list_chan_header(parsed, context, list_of_records) if parsed[:button_callback_id].nil?
end

# Returns [text, attachments]
def one_chan_header_button_action(parsed, _context, _list_of_records)
  rpt_type = "`Your #{parsed[:list_owner_name] == 'team' ? 'team\'s ' : ''}current (open) tasks in this channel:`"
  ['', [{ text: "#{parsed[:response_headline]}\n\n#{rpt_type}",
          color: '#3AA3E3',
          mrkdwn_in: ['text']
        }
       ]
  ]
end

# Returns: list_ids[]
def one_chan_body(parsed, _text, attachments, list_of_records)
  list_ids = []
  list_of_records.each_with_index do |item, index|
    list_add_item_to_display_list(parsed, attachments, attachments.length - 1, item, index + 1)
    list_ids << item.id
  end
  list_ids
end
