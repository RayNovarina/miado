# Returns: [text, attachments, list_ids, options]
def button_lists(parsed, list_of_records)
  return button_my_tasks_display(parsed, list_of_records) if parsed[:first_button_value][:command] == '@me'
  button_team_display(parsed, list_of_records) # if parsed[:first_button_value][:command] == 'team'
end

# Returns: [text, attachments, list_ids, options]
def button_my_tasks_display(parsed, list_of_records)
  text, attachments, response_options = button_lists_header(parsed)
  list_ids = one_chan_body(parsed, text, attachments, list_of_records, new_attachment: true)
  # list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids, response_options]
end

# Returns [text, attachments, response_options]
def button_lists_header(parsed)
  ['',
   [list_button_action_headline_replacement(parsed)],
   parsed[:first_button_value][:resp_options]
  ]
end

# Returns: [text, attachments, list_ids, options]
def button_team_display(parsed, list_of_records)
  text, attachments, response_options = button_lists_header(parsed)
  list_ids = all_chans_body(parsed, text, attachments, list_of_records, new_attachment: true)
  # list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids, response_options]
end
