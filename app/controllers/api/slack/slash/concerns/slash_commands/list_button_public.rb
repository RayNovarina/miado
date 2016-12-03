# Returns: [text, attachments{}, list_ids[], response_options{}]
def button_lists_public_chan(parsed, list_of_records)
  return one_channel_display(parsed, parsed, list_of_records, 'list') if parsed[:channel_scope] == :one_channel # list_one_chan.rb
  all_channels_display(parsed, parsed, list_of_records, 'list') # list_all_chans.rb
end
