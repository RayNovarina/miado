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
     fallback: 'Taskbot lists',
     callback_id: { id: 'taskbot',
                    response_headline: rpt_headline,
                    caller_id: caller_id,
                    debug: false
                  }.to_json,
     color: 'ffffff',
     actions: [
       { name: 'list',
         text: 'Your To-Do\'s',
         type: 'button',
         value: { command: '@me all' }.to_json,
         style: style_your_tasks
       },
       { name: 'list',
         text: 'Team To-Do\'s',
         type: 'button',
         value: { command: 'team all' }.to_json,
         style: style_team_tasks
       },
       { name: 'list',
         text: 'All Tasks',
         type: 'button',
         value: { command: 'team all assigned unassigned open done' }.to_json
       },
       # { name: 'feedback',
       # text: 'Feedback',
       # type: 'button',
       # value: {}.to_json
       # },
       # { name: 'hints',
       # text: 'Hints',
       # type: 'button',
       # value: {}.to_json
       # }
       { name: 'reset',
         text: 'Reset',
         type: 'button',
         value: { command: '@me' }.to_json
       },
       { name: 'help',
         text: 'Help',
         type: 'button',
         value: { command: 'buttons' }.to_json
       }
     ]
   },
   { pretext: rpt_headline,
     text: '',
     color: 'ffffff',
     mrkdwn_in: ['pretext']
   }]
end

TASKBOT_RESP_BUTTONS_HLP_TEXT =
  "Button: Your To-Do\'s generates the command \'/do list @me open\' and \n" \
  "        Lists your ASSIGNED and OPEN tasks for THIS channel. \n" \
  'Button: Team To-Do\'s generates the command \'/do list team open ' \
  "assigned\' and \n" \
  "        Lists all tasks that are ASSIGNED and OPEN for THIS channel.\n" \
  "Button: All Tasks generates the command \'/do list team all assigned " \
  "unassigned open done\' and \n" \
  "        Lists all tasks for ALL channels. \n" \
  "Button: Reset erases taskbot messages, displays default lists\n" \
  "Button: Help displays tooltips about these buttons. \n" \
  "\n\n".freeze

# Returns: [title, [replacement_buttons_attachments{}], [button_help_attachments{}], display_options]
def taskbot_response_buttons_help(parsed)
  title = 'Taskbot Reports'
  replacement_buttons_attachments =
    list_button_taskbot_headline_replacement(parsed,
                                             # parsed[:button_callback_id][:response_headline],
                                             '',
                                             parsed[:button_callback_id][:caller_id])
  button_help_attachments =
    [{ pretext: TASKBOT_RESP_BUTTONS_HLP_TEXT,
       mrkdwn_in: ['pretext']
     }
    ]
  [title, replacement_buttons_attachments, button_help_attachments, app_help: false]
end

# Returns: [style_your_tasks, style_team_tasks]
def list_button_taskbot_headline_colors(parsed)
  # Set color of list buttons.
  style_your_tasks = 'primary' if parsed[:func] == :message_event
  unless parsed[:func] == :message_event
    style_your_tasks = 'default'
    if !parsed[:button_callback_id].nil? &&
       parsed[:button_callback_id][:id] == 'taskbot'
      # A taskbot channel button has been clicked. We toggle between My To-Do's,
      # Team To-Do's and All Tasks lists as button default.
      # (Green button means recommended one)
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
