# Returns: [text, attachments{}, list_ids[], response_options{}]
def button_lists_taskbot_chan(parsed, list_of_records)
  all_channels_taskbot_format(parsed, parsed, list_of_records)
end

# Top of report buttons and headline.
# Inputs: options{ parsed, rpt_headline, caller_id }
# Returns: Replacement taskbot headline [attachment{}], header_attch_idx, num_header_attch
def list_button_taskbot_header_replacement(options)
  # Set color of list buttons.
  style_your_tasks, style_team_tasks = list_button_taskbot_header_colors(options[:parsed])
  header_attch_idx = options.key?(:attachments) ? options[attachments].length + 1 : 1
  taskbot_header_attachments =
    [{ text: '',
       fallback: 'Taskbot lists',
       callback_id: { id: 'taskbot',
                      response_headline: options[:rpt_headline] || '',
                      caller: options[:caller_id] || 'list',
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
     { pretext: options[:rpt_headline] || '',
       text: '',
       color: 'ffffff',
       mrkdwn_in: ['pretext']
     }]
  [taskbot_header_attachments,
   header_attch_idx,
   options.key?(:attachments) ? options[:attachments].size + 1 - header_attch_idx :2
  ]
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
  replacement_buttons_attachments, _header_attch_idx, _header_num_attch =
    list_button_taskbot_header_replacement(
      parsed: parsed,
      rpt_headline: parsed[:button_callback_id][:response_headline],
      caller_id: parsed[:button_callback_id][:caller_id])

  button_help_attachments =
    [{ pretext: TASKBOT_RESP_BUTTONS_HLP_TEXT,
       mrkdwn_in: ['pretext']
     }
    ]
  [title, replacement_buttons_attachments, button_help_attachments, app_help: false]
end

# Returns: [style_your_tasks, style_team_tasks]
def list_button_taskbot_header_colors(parsed)
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
