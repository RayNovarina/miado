# Inputs: parsed = parsed command line info that has been verified.
#         list = [ListItem.id] for the list that the user is referencing.
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#          parsed[:list_for_after_action] = based on the new parsed info.
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# options  = %w(open due more done)
# list_owner = :team, :mine, :member
# assigned_member_id = list.id of member assigned a task
#------------------------------
def list_command(parsed)
  adjust_list_cmd_action_context(parsed)
  format_display_list(parsed, parsed, list_from_parsed(parsed))
end

# Returns: [text, attachments], parsed[:err_msg] if needed.
def prepend_text_to_list_command(parsed, prepend_text)
  list_text, list_attachments =
    format_display_list(
      parsed,
      parsed[:previous_action_list_context].empty? ? parsed[:after_action_list_context] : parsed[:previous_action_list_context],
      list_from_list_of_ids(parsed, parsed[:after_action_list_context][:list]))
  # note: err is that parsed[:previous_action_list_context] is nil after
  # rake db:reset and then /raydo $new general task1 for ray @me
  combined_text =
    prepend_text.concat('   Updated list as follows: ').concat(list_text)
  [combined_text, list_attachments]
end

# Used by the delete command, to fetch a list based on the list command options
# so that delete command syntax matches what list would do. i.e. 'delete team'
# will delete whatever 'list team' will display.
def list_of_ids_from_list_cmd(parsed)
  adjust_list_cmd_action_context(parsed)
  parsed[:list] = ids_from_parsed(parsed)
end

# Display whatever the parsed/context block params say to do.
# Returns: [text, attachments], parsed[:err_msg] if needed.
def redisplay_action_list(context)
  format_display_list(
    context,
    context,
    list_from_list_of_ids(context, context[:list]))
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
  # "<##{parsed[:url_params]['channel_id']}|#{parsed[:url_params]['channel_name']}> "
  text = channel_display_header(parsed, context, list_of_records, '')
  list_ids = []
  attachments = []
  list_of_records.each_with_index do |item, index|
    list_add_item_to_display_list(parsed, attachments, 0, item, index)
    list_ids << item.id
  end
  channel_display_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

def channel_display_header(_parsed, context, list_of_records, channel_name)
  "#{channel_name}" \
  "`to-do list#{format_owner_title(context)}`" \
  "#{list_of_records.empty? ? ' (empty)' : ''}"
end

def channel_display_footer(_parsed, context, list_of_records, _text, attachments)
  if list_of_records.size > 10
    attachments << {
      text: "`to-do list#{format_owner_title(context)}`" \
            "#{list_of_records.empty? ? ' (empty)' : ''}",
      mrkdwn_in: ['text']
    }
  end
end

def format_owner_title(context)
  subtitle = ''
  subtitle.concat(' all') if context[:channel_scope] == :all_channels
  subtitle.concat(' open') if context[:open_option]
  subtitle.concat(' due') if context[:due_option]
  subtitle.concat(' done') if context[:done_option]
  return " (#{context[:list_owner_name]} - #{subtitle})" unless subtitle.empty?
  " (#{context[:list_owner_name]})" if subtitle.empty?
end

# Returns: updated attachments array.
def list_add_item_to_display_list(parsed, attachments, attch_idx, item, index)
  attachments << { text: '', mrkdwn_in: ['text'] } if attachments.empty?
  attachments[attch_idx][:text].concat(list_add_attachment_text(parsed, item, index))
end

def list_add_attachment_text(parsed, item, index)
  "\n" \
  "#{index + 1}) #{item.description}" \
  "#{list_cmd_assigned_to_clause(parsed, item)}" \
  "#{list_cmd_due_date_clause(item)}" \
  "#{list_cmd_task_completed_clause(item)}"
end

def list_cmd_assigned_to_clause(parsed, item)
  return '' if item.assigned_member_id.nil?
  " | *Assigned* to @#{slack_member_name_from_slack_user_id(parsed, item.assigned_member_id)}."
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
def all_channels_display(parsed, context, list_of_records)
  text = channel_display_header(parsed, context, list_of_records, '#all-channels ')
  list_ids = []
  attachments = []
  current_channel_id = ''
  list_of_records.each_with_index do |item, index|
    unless current_channel_id == item.channel_id
      current_channel_id = item.channel_id
      attachments << {
        text: "---- ##{item.channel_name} channel ----------",
        mrkdwn_in: ['text']
      }
    end
    list_add_item_to_display_list(parsed, attachments, attachments.size - 1, item, index)
    list_ids << item.id
  end
  channel_display_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

def adjust_list_cmd_action_context(parsed)
  # list command defaults to OPEN tasks.
  parsed[:open_option] = true unless parsed[:done_option] == true
  adjust_list_cmd_list_scope(parsed)
  adjust_list_cmd_channel_scope(parsed)
  implied_mentioned_member(parsed)
  implied_list_owner(parsed)
end

# Note: 'list' implies a mentioned member of @me. BUT 'list team' does not.
def adjust_list_cmd_list_scope(parsed)
  # Case: 'list team'
  parsed[:list_scope] = :team if parsed[:team_option] && parsed[:mentioned_member_id].nil?
  # Case: 'list team @ray' (same as 'list @ray')
  parsed[:team_option] = false if parsed[:team_option] && !parsed[:mentioned_member_id].nil?
  # Case: 'list', 'list @ray'
  parsed[:list_scope] = :one_member unless parsed[:team_option]
end

def adjust_list_cmd_channel_scope(parsed)
  parsed[:channel_scope] = :one_channel unless parsed[:all_option]
  parsed[:channel_scope] = :all_channels if parsed[:all_option]
end
