# Returns: [text, attachments{}, response_options{}]
def help_command(parsed)
  text, attachments, response_options = help_header(parsed)
  help_body(parsed, text, attachments)
  @view.channel.last_activity_type = 'slash_command - help'
  @view.channel.last_activity_date = DateTime.current
  @view.channel.save
  [text, attachments, response_options]
end

# Returns [text, attachments, response_options]
def help_header(parsed)
  text = ''
  attachments = help_headline_replacement(parsed)
  [text, attachments, nil]
end

# Top of report buttons and headline.
# Returns: Replacement help headline [attachment{}] if specified.
def help_headline_replacement(_parsed)
  [{ fallback: 'header_buttons',
     text: '',
     color: '#f8f8f8',
     callback_id: { id: 'help' }.to_json,
     actions: [
       { name: 'faqs',
         text: 'FAQs',
         type: 'button',
         value: {}.to_json
       },
       { name: 'best',
         text: 'Best Practices',
         type: 'button',
         value: {}.to_json
       },
       { name: 'online',
         text: 'Online Doc',
         type: 'button',
         value: {}.to_json
       },
       { name: 'help',
         text: 'Help',
         type: 'button',
         value: {}.to_json
       }
     ]
   }]
end

# Add to the existing test, attachments[]
# Returns: [text, attachments]
def help_body(parsed, text, attachments)
  return help_button_actions(parsed, text, attachments) if parsed[:button_actions].any?
  help_body_basic(parsed, text, attachments)
end

def help_button_actions(parsed, text, attachments)
  return help_button_faqs(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'faqs'
  return help_button_best_practices(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'best'
  return help_button_online_doc(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'online'
  return help_body_basic(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'help'
end

# Returns: [text, attachments]
def help_body_basic(parsed, text, attachments)
  attachments
    .concat(help_headline(parsed))
    .concat(help_subsection1(parsed))
    .concat(help_subsection2(parsed))
    .concat(help_subsection3(parsed))
    .concat(help_footer(parsed))
  [text, attachments]
end

# Returns: [attachment{}]
def help_headline(parsed)
  # "text": "<https://honeybadger.io/path/to/event/|ReferenceError> -
  # <@U024BE7LH|bob>
  msg =
    "Hi, *@#{parsed[:url_params][:user_name]}*, " \
    'MiaDo is the easiest way for teams to track assignments and due dates, ' \
    'all in Slack.'
  [{ fallback: 'headline',
     pretext: msg,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
   }]
end

ADDING_TASKS_HLP_TEXT =
  '• `/do rev 1 spec @susan /jun15`' \
  ' Adds "rev 1 spec" task to this channel, assigns it to Susan,' \
  " due date is June 15.\n" \
  '• `/do update product meeting agenda. @me /today`' \
  ' Adds task to this channel, assigns it to you,' \
  " due date is today's date.\n" \
  "\n".freeze

# Returns: [attachment{}]
def help_subsection1(_parsed)
  msg = 'Adding tasks'
  [{ fallback: 'help_subsection1',
     title: msg,
     text: ADDING_TASKS_HLP_TEXT,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
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

# Returns: [attachment{}]
def help_subsection2(_parsed)
  msg = 'Update and delete tasks'
  [{ fallback: 'help_subsection2',
    title: msg,
    text: UPDATE_DEL_TASKS_HLP_TEXT,
    color: '#3AA3E3',
    mrkdwn_in: ['text']
  }]
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

# Returns: [attachment{}]
def help_subsection3(_parsed)
  msg = 'List tasks'
  [{ fallback: 'help_subsection3',
     title: msg,
     text: LIST_TASKS_HLP_TEXT,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end

# ':bulb: Click on the <https://shadowhtracteam.slack.com/messages/@a.taskbot|a.taskbot> member to see all of your up to date ' \
# 'lists.' \
# Returns: [attachment{}]
def help_footer(_parsed)
  msg =
    ':bulb: Click on the *a.taskbot* channel to see all of your up to date ' \
    'lists.'
  [{ fallback: 'help_footer',
     pretext: msg,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
     # footer: msg,
     # footer_icon: "https://platform.slack-edge.com/img/default_application_icon.png",
     # ts: '123456789',
     # mrkdwn_in: ['footer']
   }]
end

# Returns: [text, attachments]
def help_button_faqs(parsed, text, attachments)
  attachments
    .concat(help_faqs_headline(parsed))
    .concat(help_faqs_subsection1(parsed))
  [text, attachments]
end

# Returns: [attachment{}]
def help_faqs_headline(_parsed)
  msg = 'Frequently Asked Questions:'
  [{ fallback: 'Faqs',
     pretext: msg,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
  }]
end

# Returns: [attachment{}]
def help_faqs_subsection1(parsed)
  help_subsection1(parsed)
end

HLP_FAQS_TEXT =
  '• Hint 1' \
  " \n" \
  '• Hint 2' \
  " \n" \
  "\n".freeze

# Returns: [attachment{}]
def help_faqs_subsection1(_parsed)
  [{ fallback: 'help_faqs_subsection1',
     text: HLP_FAQS_TEXT,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end

# Returns: [text, attachments]
def help_button_best_practices(parsed, text, attachments)
  attachments
    .concat(help_best_practices_headline(parsed))
    .concat(help_best_practices_subsection1(parsed))
  [text, attachments]
end

# Returns: [attachment{}]
def help_best_practices_headline(_parsed)
  msg = 'Best Practices:'
  [{ fallback: 'Best Practices',
     pretext: msg,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
  }]
end

HLP_BEST_TEXT =
  '• Best Practice 1' \
  " \n" \
  '• Best Practice 2' \
  " \n" \
  "\n".freeze

# Returns: [attachment{}]
def help_best_practices_subsection1(_parsed)
  [{ fallback: 'help_best_practices_subsection1',
     text: HLP_BEST_TEXT,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end

# Returns: [text, attachments]
def help_button_online_doc(parsed, text, attachments)
  attachments
    .concat(help_online_doc_headline(parsed))
    .concat(help_online_doc_subsection1(parsed))
  [text, attachments]
end

# Returns: [attachment{}]
def help_online_doc_headline(_parsed)
  msg = 'Online Documentation:'
  [{ fallback: 'Online Documentation',
     pretext: msg,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
  }]
end

HLP_ONLINE_TEXT =
  '• Online doc link 1' \
  " \n" \
  '• Online doc link 2' \
  " \n" \
  "\n".freeze

# Returns: [attachment{}]
def help_online_doc_subsection1(_parsed)
  [{ fallback: 'help_online_doc_subsection1',
     text: HLP_ONLINE_TEXT,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end
