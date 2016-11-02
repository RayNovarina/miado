# Returns: [text, attachments{}, list_ids[], response_options{}]
def button_lists_public_chan(parsed, list_of_records)
  text, attachments = one_chan_header(parsed, parsed, list_of_records, 'list')
  # text, attachments, response_options = button_public_lists_header(parsed, list_of_records)
  list_ids = one_chan_body(parsed, text, attachments, list_of_records, new_attachment: false) # in: list_all_chans.rb
  # list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids] # ], response_options]
end

=begin
# Returns [text, attachments, response_options]
def button_public_lists_header(parsed, list_of_records)
  text = ''
  attachments = list_button_public_headline_replacement(parsed, 'list')
  attachments << {
    color: '#3AA3E3',
    text: "#{list_format_headline_text(parsed, parsed, list_of_records, true)}\n", # in list.rb
    mrkdwn_in: ['text']
  }
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

# Top of report buttons and headline.
# Returns: Replacement add_task headline [attachment{}] if specified.
def list_button_public_headline_replacement(parsed, caller_id = 'list')
  if parsed[:first_button_value][:resp_options].nil? ||
     parsed[:first_button_value][:resp_options][:replace_original]
    return add_response_headline_attachments( # in add.rb
      parsed,
      parsed[:button_callback_id][:response_headline],
      parsed[:button_callback_id][:item_db_id],
      caller_id
    )
  end
  []
end
=end
