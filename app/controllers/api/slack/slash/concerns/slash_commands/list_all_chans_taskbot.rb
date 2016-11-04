# Returns: [text, attachments{}, list_ids[]]
def all_channels_taskbot_format(parsed, context, list_of_records)
  text, attachments = all_chans_taskbot_header(parsed, context, list_of_records)
  list_ids = all_chans_taskbot_body(parsed, text, attachments, list_of_records)
  # list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

# Returns: [text, attachments]
def all_chans_taskbot_header(parsed, _context, list_of_records)
  text = ''
  attachments = list_button_taskbot_headline_replacement( # in list_button_taskbot.rb
    parsed, format_all_chans_taskbot_header(parsed, parsed[:channel_scope], list_of_records),
    'list')
  [text, attachments]
end

# text = debug_headers(context).concat(format_pub_header(context, text))
# Convert text header for @taskbot display.
def format_all_chans_taskbot_header(parsed, channel_scope, list_of_records)
  empty_text = ' *empty*' if list_of_records.empty?
  empty_text = '' unless list_of_records.empty?
  channel_text = 'all channels' if channel_scope == :all_channels
  channel_text = "##{parsed[:url_params]['channel_name']}" if channel_scope == :one_channel
  member_text = "TEAM's current" if parsed[:mentioned_member_name].nil?
  member_text = "@#{parsed[:mentioned_member_name]}'s current" unless parsed[:mentioned_member_name].nil?
  options_text = ''
  options_text.concat('Open') if parsed[:open_option]
  options_text.concat(', ') if parsed[:open_option] && parsed[:due_option] && parsed[:done_option]
  options_text.concat(' and ') if parsed[:open_option] && parsed[:due_option] && !parsed[:done_option]
  options_text.concat('Due') if parsed[:due_option]
  options_text.concat(' and ') if (parsed[:open_option] || parsed[:due_option]) && parsed[:done_option]
  options_text.concat('Done') if parsed[:done_option]
  "#{debug_headers(parsed)}" \
  "`#{member_text} (#{options_text}) tasks in #{channel_text}:`#{empty_text}"
  # rpt_type = "`Your #{parsed[:list_owner_name] == 'team' ? 'team\'s ' : ''}current (open) tasks in All channels:`\n"
end

# Returns: list_ids[], updated attachments[]
def all_chans_taskbot_body(parsed, _text, attachments, list_of_records)
  list_ids = []
  current_channel_id = ''
  list_of_records.each_with_index do |item, index|
    unless current_channel_id == item.channel_id
      current_channel_id = item.channel_id
      attachments << {
        color: 'f8f8f8',
        text: "---- ##{item.channel_name} channel ----------",
        mrkdwn_in: ['text']
      }
    end
    list_add_item_to_taskbot_display_list(parsed, attachments, attachments.size - 1, item, index + 1)
    list_ids << item.id
  end
  list_ids
end

def list_add_item_to_taskbot_display_list(parsed, attachments, attch_idx, item, tasknum)
  attachment_text = list_add_attachment_text(parsed, item, tasknum) # in list.rb
  attachments <<
    { response_type: 'ephemeral',
      text: attachment_text,
      fallback: 'Taskbot list',
      callback_id: { id: 'taskbot',
                     attch_idx: attch_idx,
                     tasknum: tasknum,
                     item_db_id: item.id,
                     task_desc: attachment_text.slice(2..-1),
                     slack_chan_id: item.channel_id,
                     slack_chan_name: item.channel_name
                   }.to_json,
      color: '#3AA3E3',
      attachment_type: 'default',
      actions: [
        { name: 'done',
          text: 'Done',
          style: 'primary',
          type: 'button',
          value: { command: tasknum.to_s }.to_json
        },
        { name: 'done and delete',
          text: 'Delete',
          type: 'button',
          value: { command: tasknum.to_s }.to_json,
          style: 'danger'
        }
        # ,
        # { name: 'discuss',
        # text: 'Discuss',
        # type: 'button',
        # value: { command: tasknum.to_s }.to_json
        # }
      ]
    }
end
