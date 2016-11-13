# Returns: [text, attachments{}, response_options{}]
def help_command(parsed)
  # Case: asking for help about what do the buttons do for a miado command.
  return help_for_buttons(parsed) if !parsed[:button_callback_id].nil? &&
                                     parsed[:first_button_value][:command] == 'buttons'
  # Case: someone has clicked one the the buttons in the help command header.
  #       Exception: someone clicked the "MiaDo Help" button which really means
  #       get the regular full help.
  return help_button_actions(parsed) unless parsed[:button_callback_id].nil? ||
                                            parsed[:first_button_value][:command] == 'app'
  # Case: display full MiaDo help.
  text, attachments, response_options = help_header(parsed)
  help_body(parsed, text, attachments)
  update_channel_activity(parsed)
  [text, attachments, response_options]
end

HELP_MORE_HLP_TEXT =
  "For MiaDo Help use the \'/do help\' command or click on the button below:" \
  .freeze

# Returns: [text, attachments{}, response_options{}]
def help_for_buttons(parsed)
  # parsed[:first_button_value][:command] == 'buttons'
  title, replacement_buttons_attachments, button_help_attachments, display_options =
    add_response_buttons_help(parsed) if parsed[:button_callback_id][:id] == 'add task'
  title, replacement_buttons_attachments, button_help_attachments, display_options =
    list_response_buttons_help(parsed) if parsed[:button_callback_id][:id] == 'lists'
  title, replacement_buttons_attachments, button_help_attachments, display_options =
    help_response_buttons_help(parsed) if parsed[:button_callback_id][:id] == 'help'
  title, replacement_buttons_attachments, button_help_attachments, display_options =
    taskbot_response_buttons_help(parsed) if parsed[:button_callback_id][:id] == 'taskbot'

  text = ''
  title_attachment = [{ pretext: "*#{title}*", mrkdwn_in: ['pretext'] }]
  # more_help_attachment = [{ pretext: "\n*#{HELP_MORE_HLP_TEXT}*", mrkdwn_in: ['pretext'] }]
  more_help_attachment =
    [{ fallback: 'Help',
       text: "\n*#{HELP_MORE_HLP_TEXT}*",
       color: '#f8f8f8',
       callback_id: { id: 'help',
                      caller_id: parsed[:button_callback_id][:caller_id],
                      debug: false }.to_json,
       mrkdwn_in: ['text'],
       actions: [
         { name: 'help',
           text: 'MiaDo Help',
           type: 'button',
           value: { command: 'app' }.to_json
         }
       ]
    }]
  attachments = replacement_buttons_attachments
                .concat(title_attachment)
                .concat(button_help_attachments)
  # Add "click MiaDo Help button" unless override.
  attachments.concat(more_help_attachment) unless display_options &&
                                                  display_options.key?(:app_help) &&
                                                  !display_options[:app_help]
  [text, attachments, parsed[:first_button_value][:resp_options]]
end

# Returns [text, attachments, response_options]
def help_header(parsed)
  text = ''
  attachments, resp_options = help_headline_replacement(parsed, nil, 'help')
  [text, attachments, resp_options]
end

# Top of report buttons and headline.
# Returns: Replacement help headline [attachment{}] if specified.
def help_headline_replacement(_parsed, response_text = nil, caller_id = 'help')
  # response_options = { replace_original: false } unless caller_id == 'add'
  response_options = { replace_original: true } # if caller_id == 'add'
  attachments = []
  attachments << {
    fallback: 'Help',
    text: response_text,
    color: '#3AA3E3',
    mrkdwn_in: ['text'] } unless response_text.nil?

  attachments <<
    { fallback: 'Help',
      text: '',
      color: '#f8f8f8',
      callback_id: { id: 'help',
                     caller_id: caller_id,
                     debug: false }.to_json,
      mrkdwn_in: ['text'],
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
        # { name: 'online',
        #  text: 'Online Doc',
        #  type: 'button',
        #  value: {}.to_json
        # },
        { name: 'lists',
          text: 'Task Lists',
          type: 'button',
          value: { command: '@me open' }.to_json,
          style: 'primary'
        },
        { name: 'help',
          text: 'Button Help',
          type: 'button',
          value: { command: 'buttons' }.to_json
        }
      ]
    }
  [attachments, response_options]
end

HELP_RESP_BUTTONS_HLP_TEXT =
  "Button: FAQs \n" \
  "Button: Best Practices \n" \
  "Button: Task Lists \n" \
  "Button: Help \n" \
  "\n\n".freeze
# "Button: Online Doc \n" \

# Returns: [title, [replacement_buttons_attachments{}], [button_help_attachments{}], response_options]
def help_response_buttons_help(parsed)
  title = 'MiaDo Help'
  replacement_buttons_attachments =
    help_headline_replacement(parsed, nil, 'help')
  button_help_attachments =
    [{ pretext: HELP_RESP_BUTTONS_HLP_TEXT,
       mrkdwn_in: ['pretext']
     }
    ]
  [title, replacement_buttons_attachments, button_help_attachments, parsed[:first_button_value][:resp_options]]
end

# Add to the existing test, attachments[]
# Returns: [text, attachments]
def help_body(parsed, text, attachments)
  help_body_basic(parsed, text, attachments)
end

def help_button_actions(parsed)
  text, attachments, _response_options = help_header(parsed)
  return help_button_faqs(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'faqs'
  return help_button_best_practices(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'best'
  # return help_button_online_doc(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'online'
  return help_body_basic(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'help' &&
                                                       parsed[:first_button_value][:command] == 'app'
  help_buttons_help(parsed, text, attachments)
end

# Returns: [text, attachments]
def help_body_basic(parsed, text, attachments)
  attachments
    .concat(help_headline(parsed))
    .concat(help_subsection1(parsed))
    .concat(help_subsection2(parsed))
    .concat(help_subsection3(parsed))
    .concat(help_subsection4(parsed))
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
  '• `/do rev 1 spec `' \
  ' Adds "rev 1 spec" task to this channel. It can later be ' \
  ' updated via the assign, append or redo commands.' \
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

LIST_YOUR_TASKS_HLP_TEXT =
  '• `/do list`' \
  " Lists your ASSIGNED and OPEN tasks for THIS channel.\n" \
  '• `/do list done`' \
  " Lists your ASSIGNED and OPEN tasks which are DONE for THIS channel.\n" \
  '• `/do list due`' \
  " Lists your ASSIGNED and OPEN tasks with a due date for THIS channel.\n" \
  '• `/do list all`' \
  " Lists your ASSIGNED and OPEN tasks for ALL channels.\n" \
  '• `/do list open done`' \
  " Lists your ASSIGNED tasks, both OPEN and DONE, for THIS channel.\n" \
  '• `/do list unassigned`' \
  " Lists tasks that are NOT ASSIGNED for THIS channel.\n" \
  "\n".freeze

# Returns: [attachment{}]
def help_subsection3(_parsed)
  msg = 'List your tasks'
  [{ fallback: 'help_subsection3',
     title: msg,
     text: LIST_YOUR_TASKS_HLP_TEXT,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end

LIST_TEAM_TASKS_HLP_TEXT =
  '• `/do list team`' \
  " Lists all TEAM tasks that are ASSIGNED and OPEN for THIS channel.\n" \
  '• `/do list team done`' \
  " Lists all TEAM tasks that are ASSIGNED and DONE for THIS channel.\n" \
  '• `/do list team all`' \
  " Lists all TEAM tasks that are ASSIGNED and OPEN for ALL channels.\n" \
  '• `/do list team open done`' \
  " Lists all TEAM tasks that are ASSIGNED, both OPEN and DONE, for THIS channel.\n" \
  '• `/do list team all open done`' \
  " Lists all TEAM tasks, both OPEN and DONE, for ALL channels.\n" \
  '• `/do list team all unassigned`' \
  " Lists all TEAM tasks that are NOT ASSIGNED for ALL channels.\n" \
  "\n".freeze

# Returns: [attachment{}]
def help_subsection4(_parsed)
  msg = 'List team tasks'
  [{ fallback: 'help_subsection4',
     title: msg,
     text: LIST_TEAM_TASKS_HLP_TEXT,
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

=begin
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
=end
