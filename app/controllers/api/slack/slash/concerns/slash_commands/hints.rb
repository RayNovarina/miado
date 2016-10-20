
# Returns: [text, attachments, response_options]
def hints_command(parsed)
  text, attachments, options = hints(parsed)
  @view.channel.last_activity_type = 'slash_command - hints'
  @view.channel.last_activity_date = DateTime.current
  @view.channel.save
  [text, attachments, options]
end

# Returns: [text, attachments, response_options]
def hints(parsed)
  return hints_button_add_task(parsed) if !parsed[:button_callback_id].nil? && parsed[:button_callback_id][:id] == 'add task'
  return hints_button_taskbot_rpts(parsed) if !parsed[:button_callback_id].nil? && parsed[:button_callback_id][:id] == 'taskbot'
  ["Take the hint #{parsed[:url_params][:user_name]}", []]
end

# Returns: [text, attachments, response_options]
def hints_button_add_task(parsed)
  text = ''
  attachments =
    list_button_public_headline_replacement(parsed) # in list_button_public.rb
    .concat(hints_add_task_headline(parsed))
    .concat(hints_add_task_subsection1(parsed))
    .concat(hints_add_task_footer(parsed))
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

# Returns: [attachment{}]
def hints_add_task_headline(_parsed)
  msg = 'Add Task hints:'
  [{ fallback: 'headline',
     pretext: msg,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
  }]
end

# Returns: [attachment{}]
def hints_add_task_subsection1(parsed)
  help_subsection1(parsed)
end

# Returns: [attachment{}]
def hints_add_task_footer(parsed)
  []
end

# Returns: [text, attachments, response_options]
def hints_button_taskbot_rpts(parsed)
  text = ''
  attachments =
    list_button_taskbot_headline_replacement(parsed) # in list_button_taskbot.rb
    .concat(hints_taskbot_rpts_headline(parsed))
    .concat(hints_taskbot_rpts_subsection1(parsed))
    .concat(hints_taskbot_rpts_footer(parsed))
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

# Returns: [attachment{}]
def hints_taskbot_rpts_headline(_parsed)
  msg = 'Taskbot hints:'
  [{ fallback: 'headline',
     pretext: msg,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
  }]
end

TASKBOT_LISTS_HLP_TEXT =
  '• Hint 1' \
  " \n" \
  '• Hint 2' \
  " \n" \
  "\n".freeze

# Returns: [attachment{}]
def hints_taskbot_rpts_subsection1(_parsed)
  msg = 'Taskbot Lists'
  [{ fallback: 'taskbot_subsection1',
     title: msg,
     text: TASKBOT_LISTS_HLP_TEXT,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end

# Returns: [attachment{}]
def hints_taskbot_rpts_footer(_parsed)
  []
end
