# Returns: [text, attachments]
def help_command(parsed)
  text, attachments = format_help(parsed)
  @view.channel.last_activity_type = 'slash_command - help'
  @view.channel.last_activity_date = DateTime.current
  @view.channel.save
  [text, attachments]
end

# Returns: [text, attachments]
def format_help(parsed)
  text = ''
  attachments = [
    header_buttons(parsed),
    headline(parsed),
    help_subsection1(parsed),
    help_subsection2(parsed),
    help_subsection3(parsed),
    help_footer(parsed)
  ]
  [text, attachments]
end

# Returns: attachment{}
def header_buttons(_parsed)
  { fallback: 'header_buttons',
    text: '',
    color: '#f8f8f8',
    callback_id: { id: 'help' }.to_json,
    actions: [
      { name: 'faqs',
        text: 'FAQs',
        type: 'button',
        value: ''
      },
      { name: 'hints',
        text: 'Best Practices',
        type: 'button',
        value: ''
      },
      { name: 'all',
        text: 'Online Doc',
        type: 'button',
        value: ''
      }
    ]
  }
end

# Returns: attachment{}
def headline(parsed)
  # "text": "<https://honeybadger.io/path/to/event/|ReferenceError> -
  # <@U024BE7LH|bob>
  msg =
    "Hi, *@#{parsed[:url_params][:user_name]}*, " \
    'MiaDo is the easiest way for teams to track assignments and due dates, ' \
    'all in Slack.'
  { fallback: 'headline',
    pretext: msg,
    text: '',
    color: '#f2f2f3',
    mrkdwn_in: ['pretext']
  }
end

ADDING_TASKS_HLP_TEXT =
  '• `/do rev 1 spec @susan /jun15`' \
  ' Adds "rev 1 spec" task to this channel, assigns it to Susan,' \
  " due date is June 15.\n" \
  '• `/do update product meeting agenda. @me /today`' \
  ' Adds task to this channel, assigns it to you,' \
  " due date is today's date.\n" \
  "\n".freeze

# Returns: attachment{}
def help_subsection1(_parsed)
  msg =
    'Adding tasks'
  { fallback: 'help_subsection1',
    title: msg,
    text: ADDING_TASKS_HLP_TEXT,
    color: '#3AA3E3',
    mrkdwn_in: ['text']
  }
end

UPDATE_DEL_TASKS_HLP_TEXT =
  '• `/do append 3 Contact Jim.`' \
  " Adds \"Contact Jim.\" to the end of task 3.\n" \
  '• `/do assign 4 @joe`' \
  " Assigns \"@joe\" to task 4 for this channel.\n" \
  '• `/do unassign 4 @joe`' \
  " Removes \"@joe\" from task 4.\n" \
  '• `/do done 4`' \
  " Marks task 4 as completed.\n" \
  '• `/do due 4 /wed`' \
  " Sets the task due date to Wednesday for task 4.\n" \
  '• `/do redo 1 Send out newsletter /fri.`' \
  ' Deletes task 1, adds new task ' \
  "\"Send out newsletter /fri\"\n" \
  '• `/do delete 2`' \
  " Deletes task number 2 from the list.\n" \
  "\n".freeze

# Returns: attachment{}
def help_subsection2(_parsed)
  msg =
    'Update and delete tasks'
  { fallback: 'help_subsection2',
    title: msg,
    text: UPDATE_DEL_TASKS_HLP_TEXT,
    color: '#3AA3E3',
    mrkdwn_in: ['text']
  }
end

LIST_TASKS_HLP_TEXT =
  '• `/do list`' \
  " Lists your ASSIGNED and OPEN tasks for THIS channel.\n" \
  '• `/do list done`' \
  " Lists your ASSIGNED tasks which are DONE for THIS channel.\n" \
  '• `/do list due`' \
  " Lists your ASSIGNED and OPEN tasks with a due date for THIS channel.\n" \
  '• `/do list all`' \
  " Lists your ASSIGNED and OPEN tasks for ALL channels.\n" \
  '• `/do list team`' \
  " Lists all TEAM tasks that are OPEN for THIS channel.\n" \
  '• `/do list team all`' \
  " Lists all TEAM tasks that are OPEN for ALL channels.\n" \
  "\n".freeze

# Returns: attachment{}
def help_subsection3(_parsed)
  msg =
    'List tasks'
  { fallback: 'help_subsection3',
    title: msg,
    text: LIST_TASKS_HLP_TEXT,
    color: '#3AA3E3',
    mrkdwn_in: ['text']
  }
end

# ':bulb: Click on the <https://shadowhtracteam.slack.com/messages/@a.taskbot|a.taskbot> member to see all of your up to date ' \
# 'lists.' \
# Returns: attachment{}
def help_footer(_parsed)
  msg =
    ':bulb: Click on the *a.taskbot* channel to see all of your up to date ' \
    'lists.'
  { fallback: 'help_footer',
    pretext: msg,
    text: '',
    color: '#f2f2f3',
    mrkdwn_in: ['pretext']
    # footer: msg,
    # footer_icon: "https://platform.slack-edge.com/img/default_application_icon.png",
    # ts: '123456789',
    # mrkdwn_in: ['footer']
  }
end
