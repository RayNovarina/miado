# Returns: [text, attachments{}, list_ids[], response_options{}]
def button_lists_taskbot_chan(parsed, list_of_records)
  text, attachments, response_options = button_taskbot_lists_header(parsed, list_of_records)
  list_ids = all_chans_taskbot_body(parsed, text, attachments, list_of_records) # in: list_all_chans_taskbot.rb
  # list_chan_footer(parsed, parsed, list_of_records, text, attachments)
  [text, attachments, list_ids, response_options]
end

# Returns [text, attachments, response_options]
def button_taskbot_lists_header(parsed, list_of_records)
  text = ''
  attachments = list_button_taskbot_headline_replacement(
    parsed, format_all_chans_taskbot_header(parsed, parsed[:channel_scope], list_of_records),
    'list')
  # attachments << {
  #  color: '#3AA3E3',
  #  text: "#{list_chan_header(parsed, parsed, list_of_records, true)}\n",
  #  mrkdwn_in: ['text']
  # }
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

# Top of report buttons and headline.
# Returns: Replacement taskbot headline [attachment{}]
def list_button_taskbot_headline_replacement(parsed, rpt_headline = '', caller_id = 'list')
  # Set color of list buttons.
  style_your_tasks, style_team_tasks = list_button_taskbot_headline_colors(parsed)
  [{ text: '',
     fallback: 'Do not view list',
     callback_id: { id: 'taskbot', caller_id: caller_id }.to_json,
     color: 'ffffff',
     actions: [ # 'Your Tasks' 'Team's' 'All' 'Feedback' 'Hints' 'Reset'
       { name: 'list',
         text: 'Your Tasks',
         type: 'button',
         value: { command: '@me all' }.to_json,
         style: style_your_tasks
       },
       { name: 'list',
         text: 'Team\'s',
         type: 'button',
         value: { command: 'team all' }.to_json,
         style: style_team_tasks
       },
       { name: 'list',
         text: 'All',
         type: 'button',
         value: { command: 'all' }.to_json,
         style: style_team_tasks
       },
       { name: 'feedback',
         text: 'Feedback',
         type: 'button',
         value: {}.to_json
       },
       { name: 'hints',
         text: 'Hints',
         type: 'button',
         value: {}.to_json
       }
     ]
   },
   { pretext: rpt_headline,
     text: '',
     color: 'ffffff',
     mrkdwn_in: ['pretext']
   }]
end

# Returns: [style_your_tasks, style_team_tasks]
def list_button_taskbot_headline_colors(parsed)
  # Set color of list buttons.
  style_your_tasks = 'primary' if parsed[:func] == :message_event
  unless parsed[:func] == :message_event
    style_your_tasks = 'default'
    if !parsed[:button_callback_id].nil? &&
       parsed[:button_callback_id][:id] == 'taskbot'
      # A taskbot channel button has been clicked. We toggle between my lists
      # and team lists as button default. (Green button means recommended one)
      if !(parsed[:button_actions].first['name'] == 'list') ||
         parsed[:list_scope] == :team
        style_your_tasks = 'primary'
      end
    end
  end
  style_team_tasks = 'primary' if style_your_tasks == 'default'
  style_team_tasks = 'default' unless style_your_tasks == 'default'
  [style_your_tasks, style_team_tasks]
end

=begin
# Returns: [text, attachments]
def all_channels_taskbot_format(parsed, context, list_of_records)
  text, attachments = all_chans_taskbot_header(parsed, context, list_of_records)
  list_ids = all_chans_taskbot_body(parsed, text, attachments, list_of_records)
  list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

# attachments = [add_response_attachments(parsed[:response_headline], item.id)]
# Returns: [text, attachments]
def all_chans_taskbot_header(parsed, _context, _list_of_records)
  rpt_headline = format_all_chans_taskbot_header(parsed, parsed[:channel_scope])
  ['', add_all_chans_taskbot_response_attachments(parsed, rpt_headline)]
end

# Returns: [attachment{}]
def add_all_chans_taskbot_response_attachments(parsed, rpt_headline = '')
  # If "Team Tasks" or "Hints" buttons are clicked, change "Your Tasks" button
  # color to primary.
  style_your_tasks = 'default'
  style_your_tasks = 'primary' if !parsed[:button_callback_id].nil? &&
                                  parsed[:button_callback_id][:id] == 'taskbot' &&
                                  (parsed[:button_actions].first['name'] == 'hints' ||
                                   parsed[:list_scope] == :team
                                  )
  style_team_tasks = 'primary' if style_your_tasks == 'default'
  style_team_tasks = 'default' unless style_your_tasks == 'default'
  [{ text: '',
     fallback: 'Do not view list',
     callback_id: { id: 'taskbot' }.to_json,
     color: 'ffffff',
     actions: [
       { name: 'list',
         text: 'Your Tasks',
         type: 'button',
         value: { command: '@me all' }.to_json,
         style: style_your_tasks
       },
       { name: 'list',
         text: 'Team Tasks',
         type: 'button',
         value: { command: 'team all' }.to_json,
         style: style_team_tasks
       },
       { name: 'feedback',
         text: 'Feedback',
         type: 'button',
         value: {}.to_json
       },
       { name: 'hints',
         text: 'Hints',
         type: 'button',
         value: {}.to_json
       }
     ]
   },
   { pretext: rpt_headline,
     text: '',
     color: 'ffffff',
     mrkdwn_in: ['pretext']
   }]
end

# text = debug_headers(context).concat(format_pub_header(context, text))
# Convert text header for @taskbot display.
def format_all_chans_taskbot_header(parsed, channel_scope)
  channel_text = 'all Team channels' if channel_scope == :all_channels
  channel_text = "##{parsed[:url_params]['channel_name']}" if channel_scope == :one_channel
  options_text = ''
  options_text.concat('Open') if parsed[:open_option]
  options_text.concat(', ') if parsed[:open_option] && parsed[:due_option] && parsed[:done_option]
  options_text.concat(' and ') if parsed[:open_option] && parsed[:due_option] && !parsed[:done_option]
  options_text.concat('Due') if parsed[:due_option]
  options_text.concat(' and ') if (parsed[:open_option] || parsed[:due_option]) && parsed[:done_option]
  options_text.concat('Done') if parsed[:done_option]
  "#{debug_headers(parsed)}" \
  "`@#{parsed[:mentioned_member_name]}'s current (#{options_text}) tasks in " \
  "#{channel_text}:`"
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
  attachment_text = list_add_attachment_text(parsed, item, nil)
  attachments <<
    { response_type: 'ephemeral',
      text: attachment_text,
      fallback: 'not done',
      callback_id: { id: 'taskbot' }.to_json,
      color: '#3AA3E3',
      attachment_type: 'default',
      actions: [
        { name: 'done',
          text: 'Done',
          style: 'primary',
          type: 'button',
          value: { tasknum: tasknum }.to_json
        },
        { name: 'done and delete',
          text: 'Done and Delete',
          type: 'button',
          value: { tasknum: tasknum }.to_json,
          style: 'danger'
        },
        { name: 'discuss',
          text: 'Discuss',
          type: 'button',
          value: { attch_idx: attch_idx, slack_chan_id: item.channel_id, slack_chan_name: item.channel_name, item_db_id: item.id }.to_json
        }
      ]
    }
end

# Top of report buttons and headline.
# Returns: Replacement add_task headline [attachment{}] if specified.
def taskbot_button_action_headline_replacement(parsed)
  if parsed[:first_button_value][:resp_options].nil? ||
     parsed[:first_button_value][:resp_options][:replace_original]
    return add_all_chans_taskbot_response_attachments(
      parsed,
      parsed[:button_callback_id][:response_headline] || '')
  end
  []
end
=end
