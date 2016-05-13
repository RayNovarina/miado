# Some of our commands, such as 'add' display a confirmation msg when done But
# not a list. The syntax '/do<enter>' is a way to display the list that would
# have been displayed if the user wants the updated list displayed.
# Returns: [text, attachments] as slash_response() return values.

# Send a direct message to the taskbot DM channel for the specified member.
def pub_command(parsed)
  # $list @dawnnova all
  # Fixup previous action list hash to look like a parsed hash.
  # context = parsed[:previous_action_list_context]
  # context[:err_msg] = ''
  # context[:url_params] = parsed[:url_params]
  # redisplay_action_list(context)
  # ["hi from pub_command for @#{parsed[:mentioned_member_name]}", nil]
  # Display an updated AFTER ACTION list if useful, i.e. task has been added
  # or deleted.
  # text, attachments = prepend_text_to_list_command(parsed, text) if parsed[:display_after_action_list]

  # Example: # $pub @suemanley1
  # Note: this prevents the list_command from resaving an after action hash to
  #       the channel. We are just getting a list report.
  parsed[:display_after_action_list] = true
  text, attachments = list_command(parsed)
  # Prevent the CommandsController from generating the list again.
  parsed[:display_after_action_list] = false
  text = format_pub_header(parsed, text)
  [text, attachments]
end

# Convert text header for @taskbot display.
def format_pub_header(parsed, _list_cmd_text)
  # text = "<##{parsed[:url_params]['channel_id']}|#{parsed[:url_params]['channel_name']}> " \
  #       "to-do list (#{format_owner_title(context)})" \
  #       "#{list_of_records.empty? ? ' (empty)' : ''}"
  # owner_title = ''
  # owner_title.concat(' all') if context[:channel_scope] == :all_channels
  # owner_title.concat(' open') if context[:open_option]
  # owner_title.concat(' due') if context[:due_option]
  # owner_title.concat(' done') if context[:done_option]
  # owner_title = ' -'.concat(owner_title) unless owner_title.empty?
  # context[:list_owner_name].concat(owner_title)

  channel_text = 'all Team channels' if parsed[:channel_scope] == :all_channels
  channel_text = "##{parsed[:url_params]['channel_name']}" if parsed[:channel_scope] == :one_channel
  options_text = ''
  options_text.concat('Open') if parsed[:open_option]
  options_text.concat(', ') if parsed[:open_option] && parsed[:due_option] && parsed[:done_option]
  options_text.concat(' and ') if parsed[:open_option] && parsed[:due_option] && !parsed[:done_option]
  options_text.concat('Due') if parsed[:due_option]
  options_text.concat(' and ') if (parsed[:open_option] || parsed[:due_option]) && parsed[:done_option]
  options_text.concat('Done') if parsed[:done_option]
  "`Current tasks list for @#{parsed[:mentioned_member_name]} " \
  "in #{channel_text} (#{options_text})`"
end


# Display whatever the parsed/context block params say to do.
# Returns: [text, attachments], parsed[:err_msg] if needed.
def XXX_redisplay_action_list(context)
  format_display_list(
    context,
    context,
    list_from_list_of_ids(context, context[:list]))
end

# Returns: [text, attachments], parsed[:err_msg] if needed.
def xxx_prepend_text_to_list_command(parsed, prepend_text)
  list_text, list_attachments =
    format_display_list(
      parsed,
      parsed[:after_action_list_context],
      list_from_list_of_ids(parsed, parsed[:after_action_list_context][:list]))
  combined_text =
    prepend_text.concat("   Updated list as follows: \n").concat(list_text)
  [combined_text, list_attachments]
end

# Returns: [text, attachments]
def xxx_format_display_list(parsed, context, list_of_records)
  text, attachments, list_ids = one_channel_display(parsed, context, list_of_records) if context[:channel_scope] == :one_channel
  text, attachments, list_ids = all_channels_display(parsed, context, list_of_records) if context[:channel_scope] == :all_channels
  # Persist the channel.list_ids[] for the next transaction.
  save_after_action_list_context(parsed, context, list_ids) unless parsed[:display_after_action_list]
  text.concat(parsed[:err_msg]) unless parsed[:err_msg].empty?
  [text, attachments]
end
