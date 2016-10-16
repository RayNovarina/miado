
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
  return hints_add_task(parsed) if parsed[:button_callback_id][:id] == 'add task'
  return hints_taskbot_rpts(parsed) if parsed[:button_callback_id][:id] == 'taskbot'
  ["Take the hint #{parsed[:url_params][:user_name]}", []]
end

# Returns: [text, attachments, response_options]
def hints_add_task(parsed)
  text = ''
  attachments = [
    list_button_action_headline_replacement(parsed),
    hints_add_task_headline(parsed),
    hints_add_task_subsection1(parsed),
    hints_add_task_footer(parsed)]
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

# Returns: attachment{}
def hints_add_task_headline(_parsed)
  msg =
    'Add Task hints:'
  { fallback: 'headline',
    pretext: msg,
    text: '',
    color: '#f2f2f3',
    mrkdwn_in: ['pretext']
  }
end

def hints_add_task_subsection1(parsed)
  help_subsection1(parsed)
end

def hints_add_task_footer(parsed)
end
