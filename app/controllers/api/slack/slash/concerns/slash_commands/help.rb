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
  "For MiaDo general Help use the \'/do help\' command or click on a button below:" \
  .freeze

# Returns: [text, attachments{}, response_options{}]
def help_for_buttons(parsed)
  # parsed[:first_button_value][:command] == 'buttons'
  title, replacement_buttons_attachments, button_help_attachments, display_options =
    add_response_buttons_help(parsed) if parsed[:button_callback_id][:id] == 'add task'   # in add.rb
  title, replacement_buttons_attachments, button_help_attachments, display_options =
    list_response_buttons_help(parsed) if parsed[:button_callback_id][:id] == 'lists'   # in list.rb
  title, replacement_buttons_attachments, button_help_attachments, display_options =
    help_response_buttons_help(parsed) if parsed[:button_callback_id][:id] == 'help'    # in help.rb
  title, replacement_buttons_attachments, button_help_attachments, display_options =
    taskbot_response_buttons_help(parsed) if parsed[:button_callback_id][:id] == 'taskbot'  # in list_button_taskbot.rb

  text = ''
  title_attachment = [{ pretext: "*#{title}*", mrkdwn_in: ['pretext'] }]
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
         },
         { name: 'tutorial',
           text: 'Tutorials',
           type: 'button',
           value: {}.to_json
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
def help_headline_replacement(parsed, response_text = nil, caller_id = 'help')
  # response_options = { replace_original: false } unless caller_id == 'add'
  response_options = {} # replace_original: true } # if caller_id == 'add'
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
        { name: 'tutorial',
          text: lib_button_text(text: 'Tutorials', parsed: parsed, name: 'tutorial'),
          type: 'button',
          value: { label: 'Tutorials' }.to_json
        },
        # { name: 'faqs',
        #  text: 'FAQs',
        #  type: 'button',
        #  value: {}.to_json
        # },
        { name: 'best',
          text: lib_button_text(text: 'Best Practices', parsed: parsed, name: 'best'),
          type: 'button',
          value: { label: 'Best Practices' }.to_json
        },
        # { name: 'online',
        #  text: 'Online Doc',
        #  type: 'button',
        #  value: {}.to_json
        # },
        { name: 'lists',
          text: lib_button_text(text: 'Task Lists', parsed: parsed, name: 'lists'),
          type: 'button',
          value: { command: '@me open', label: 'Task Lists' }.to_json
        },
        { name: 'feedback',
          text: lib_button_text(text: 'Feedback', parsed: parsed, name: 'feedback'),
          type: 'button',
          value: { resp_options: { replace_original: false, label: 'Feedback' } }.to_json
        },
        { name: 'help',
          text: lib_button_text(text: 'Button Help', parsed: parsed,
                                name: 'help', match: 'buttons'),
          type: 'button',
          value: { command: 'buttons', label: 'Button Help' }.to_json
        }
      ]
    }
  [attachments, response_options]
end

HELP_RESP_BUTTONS_HLP_TEXT =
  '• `Tutorials`  ' \
  "are short YouTube videos about using MiaDo. \n" \
  '• `Best Practices`  ' \
  "describe what we think are effective ways to use MiaDo. \n" \
  '• `Task Lists`  ' \
  "generates the command \'/do list @me open\' and " \
  "Lists your ASSIGNED and OPEN tasks for THIS channel. \n" \
  '• `Feedback`  tells you how to email MiaDo product support with suggestions, problems, etc.' \
  "\n" \
  '• `Button Help`  describes the purpose of each button.' \
  "\n" \
  "\n\n".freeze
# "Button: Online Doc \n" \
# "Button: FAQs \n" \

# Returns: [title, [replacement_buttons_attachments{}], [button_help_attachments{}], response_options]
def help_response_buttons_help(parsed)
  title = 'MiaDo Help Buttons explained'
  replacement_buttons_attachments, resp_options =
    help_headline_replacement(parsed, nil, 'help')
  button_help_attachments =
    [{ fallback: 'Help Button Info',
       text: HELP_RESP_BUTTONS_HLP_TEXT,
       color: '#3AA3E3',
       mrkdwn_in: ['text']
    }]
  [title, replacement_buttons_attachments, button_help_attachments, parsed[:first_button_value][:resp_options]]
end

# Add to the existing test, attachments[]
# Returns: [text, attachments]
def help_body(parsed, text, attachments)
  help_body_basic(parsed, text, attachments)
end

# Returns: [text, attachments]
def help_button_actions(parsed)
  text, attachments, _response_options = help_header(parsed)
  # return help_button_faqs(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'faqs'
  return help_button_best_practices(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'best'
  # return help_button_online_doc(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'online'
  return help_button_feedback(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'feedback'
  return help_button_tutorial(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'tutorial'
  return help_body_basic(parsed, text, attachments) if parsed[:button_actions].first['name'] == 'help' &&
                                                       parsed[:first_button_value][:command] == 'app'
  help_body_basic(parsed, text, attachments)
end

# Returns: [text, attachments]
def help_body_basic(parsed, text, attachments)
  attachments
    .concat(help_headline(parsed))
    .concat(help_all_subsections(parsed))
  #  .concat(help_subsection1(parsed))
  # .concat(help_subsection2(parsed))
  # .concat(help_subsection3(parsed))
  # .concat(help_subsection4(parsed))
  # .concat(help_subsection5(parsed))
  # .concat(help_footer(parsed))
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

ALL_HLP_TEXT =
  "*Adding Tasks*\n" \
  '• `/do rev 1 spec @susan /jun15`' \
  ' Adds "rev 1 spec" task to this channel, assigns it to Susan,' \
  " due date is June 15.\n" \
  '• `/do update product meeting agenda. @me /today`' \
  ' Adds task to this channel, assigns it to you,' \
  " due date is today's date.\n" \
  '• `/do rev 1 spec `' \
  ' Adds "rev 1 spec" task to this channel. It can later be ' \
  " updated via the assign, append or redo commands.\n\n" \
  "*Update and delete tasks*\n" \
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
  " Deletes task number 2 from the list.\n\n" \
  "*List your tasks*\n" \
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
  " Lists tasks that are NOT ASSIGNED for THIS channel.\n\n" \
  '*Feedback and more resources*' \
  "\n".freeze

# Returns: [attachment{}]
def help_all_subsections(_parsed)
  root_url = @view.controller.request.base_url
  all_text =
    "#{ALL_HLP_TEXT}" \
    '• `Feedback`' \
    "\n#{FEEDBACK_PUBLIC_TEXT}" \
    '• `Online Help`' \
    " Click here:  <#{root_url}/add_to_slack#product|Help>  \n" \
    '• `Online FAQs`' \
    " Click here:  <#{root_url}/about#faq|FAQs>  \n" \
    '• `Online Contact Us`' \
    " Click here:  <#{root_url}/add_to_slack#contact_us|Contact Us>  \n" \
    '• `Install Taskbot, Reinstall or Upgrade`' \
    " Click here:  <#{root_url}/add_to_slack|Add to Slack>  \n" \
    "\n"
  [{ fallback: 'MiaDo general Help',
     text: all_text,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end

=begin
ADDING_TASKS_HLP_TEXT =
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

# Returns: [attachment{}]
def help_subsection5(_parsed)
  root_url = @view.controller.request.base_url
  msg = 'Feedback and more resources'
  [{ fallback: msg,
     title: msg,
     text: resources_hlp_text,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end
=end

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

=begin
# Returns: [text, attachments]
def help_button_tutorial(parsed, _text, _attachments)
  api_client_user = make_web_client(parsed[:mcb].slack_user_api_token)
  slack_channel_id = parsed[:ccb].slack_channel_id
  attachments = []
  api_resp =
    send_msg_to_public_channel(
      as_user: false,
      api_client: api_client_user,
      username: 'taskbot',
      channel_id: slack_channel_id,
      text: 'https://davidwalsh.name/demo/facebook-metas.php',
      attachments: attachments
    )
  [nil, nil]
end
=end

# Returns: [text, attachments]
# def help_button_tutorial(_parsed, text, attachments)
#  text = 'https://davidwalsh.name/demo/facebook-metas.php'
#  attachments = []
#  [text, attachments]
# end

=begin
TUTORIAL_HLP_TEXT =
  "Tutorial\n" \
  "\n".freeze
  '• `Online Help`' \
  " Click here:  <#{root_url}/add_to_slack#product|Help>  \n" \

# Returns: [attachment{}]
def help_tutorial_headline(_parsed)
  # root_url = @view.controller.request.base_url
  [{ fallback: 'Tutorial Videos',
     pretext: '', # TUTORIAL_HLP_TEXT,
     # <https://youtu.be/AlEbz21imX0>',
     # text: "<#{root_url}/tutorials|Tutorial>",
     # text: '<https://youtu.be/AlEbz21imX0|Tutorial>',
     color: '#f2f2f3',
     # mrkdwn_in: ['pretext']
  }]
end
=end

# Returns: [text, attachments]
def help_button_tutorial(parsed, text, attachments)
  attachments
    .concat(help_tutorial_headline(parsed))
  [text, attachments]
end

TUTORIAL_HLP_TEXT =
  "<https://youtu.be/AlEbz21imX0|Brief Overview>  \n" \
  "\n".freeze

# Returns: [attachment{}]
def help_tutorial_headline(_parsed)
  [{ fallback: 'Tutorial Videos',
     pretext: TUTORIAL_HLP_TEXT,
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
  }]
end

# Returns: [text, attachments]
def help_button_feedback(parsed, text, attachments)
  attachments
    .concat(help_feedback_headline(parsed))
  [text, attachments]
end

# Returns: [attachment{}]
def help_feedback_headline(_parsed)
  # msg = 'Feedback'
  [{ fallback: 'feedback',
     pretext: FEEDBACK_PUBLIC_TEXT,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
  }]
end

# Returns: [text, attachments]
def help_button_best_practices(parsed, text, attachments)
  attachments
    .concat(help_best_practices_headline(parsed))
    .concat(help_best_practices_subsection1(parsed))
    .concat(help_best_practices_subsection2(parsed))
  [text, attachments]
end

BEST_PRACTICES_HEADLINE_HLP_TEXT =
  "*Best Practices* \n" \
  'MiaDo was designed to accommodate the realities of \'micro\',  i.e. 1-5 ' \
  'member Slack teams.  Usually one adult and a bunch of cranky associates.  ' \
  'It usually works out just fine for one member to create and manage tasks. ' \
  'MiaDo makes it painless for the other team members to see what they have ' \
  'been assigned and to easily indicate that they have done it.  Team ' \
  "members only need to remember to click on their \'a.taskbot\'  Direct " \
  'Message channel and to notice when they get a Slack update indicator in ' \
  "their a.taskbot channel. \n\n" \
  "We see two basic ways to use MiaDo, in a  \'Single shared channel\' style " \
  "or in a  \'Slack centric multi-channel\' style. \n" \
  "\n".freeze

# Returns: [attachment{}]
def help_best_practices_headline(_parsed)
  [{ fallback: 'General Help - Best Practices',
     pretext: BEST_PRACTICES_HEADLINE_HLP_TEXT,
     text: '',
     color: '#f2f2f3',
     mrkdwn_in: ['pretext']
  }]
end

=begin
  I.) Single shared channel
    Use your existing 'general' or add a 'todo' channel and invite other team
    members to it.
    1) One person installs MiaDo. All team members now have access
       to the '/do' command and buttons.
    2) Just add tasks, update em, etc.
    3) Discussions about tasks will be public and shared team wide.
    4) Use the '/do list' command to easily see what is assigned to you or
       others.
    5) Use the 'Team To-Do's' button to list assigned tasks for all team
       members.
    6) Us the 'All Tasks' button to list team, unassigned and completed tasks.
    7) A convenient and effective alternative to each member remembering
       the '/do list' is to use the features of the MiaDo 'a.taskbot' Direct
       message channel. That team member must install MiaDo via
       <www.miado.net|MiaDo Add to Slack>. Now they merely have to notice when
       they get a Slack message waiting indicator for their todo list.
=end

BEST_PRACTICES1_HLP_TITLE =
  'Single shared channel'.freeze

# Returns: [attachment{}]
def help_best_practices_subsection1(_parsed)
  root_url = @view.controller.request.base_url
  best_practices1_hlp_text =
    "Use your existing \'general\' or add a \'todo\' channel and invite " \
    "other team members to it. \n" \
    '• One person installs MiaDo via ' \
    "<#{root_url}/add_to_slack|Add to Slack>.   " \
    "All team members now have access to the \'/do\' command and buttons. \n" \
    "• Just add tasks, update em, etc. \n" \
    "• Discussions about tasks will be public and shared team wide. \n" \
    "• Use the \'/do list\' command to easily see what is assigned to you or " \
    "others. \n" \
    "• Use the \'Team To-Do's\' button to list assigned tasks for all team " \
    "members. \n" \
    "• Use the \'All Tasks\' button to list team, unassigned and completed " \
    "tasks. \n" \
    '• A convenient and effective alternative to each member remembering ' \
    "the \'/do list\' command is to use the features of the MiaDo " \
    "\'a.taskbot\'  Direct message channel. " \
    'In that case, a team member must install MiaDo via ' \
    "<#{root_url}/add_to_slack|Add to Slack>.   " \
    'Now they merely have to notice when they get a Slack message waiting ' \
    "indicator for their todo list. \n"
  [{ fallback: 'General Help - Best Practices',
     title: BEST_PRACTICES1_HLP_TITLE,
     text: best_practices1_hlp_text,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end

=begin
  II.) Slack centric multi-channel
    In this style, todo lists and conversations are organized by Slack channels.
    Each channel is specific to a topic and conversations occur within this
    communications silo. The a.taskbot channel is very useful to help team
    members be organized and effective dealing with multiple tasks created in
    multiple Slack channels.
    1) Each team member must install MiaDo via <www.miado.net|MiaDo Add to Slack>.
       Every team member now has an a.taskbot channel.
    2) Tasks are created and assigned in many public channels such as general,
       issues, numbers, marketing, development, etc.  Each todo list is
       attached to that channel. Conversations are public in that channel. This
       is very Slack-like.
    3) Doing a '/do list' will show your assigned tasks for only the channel
       you are looking at.
    4) The 'All Tasks' button will list tasks for the other
       channels as well as unassigned and completed tasks.
=end

BEST_PRACTICES2_HLP_TITLE =
  'Slack centric multi-channel'.freeze

# Returns: [attachment{}]
def help_best_practices_subsection2(_parsed)
  root_url = @view.controller.request.base_url
  best_practices2_hlp_text =
    'In this style, todo lists and conversations are organized by Slack ' \
    'channels.  Each channel is specific to a topic and conversations occur ' \
    'within this communications silo.  The a.taskbot channel is very useful ' \
    'to help team members be organized and effective dealing with multiple ' \
    "tasks created in multiple Slack channels. \n" \
    '•  Each team member must install MiaDo via ' \
    "<#{root_url}/add_to_slack|Add to Slack>.   " \
    "Every team member now has an a.taskbot channel. \n" \
    "• Tasks are created and assigned in many public channels such as " \
    'general, ssues, numbers, marketing, development, etc.  Each todo list ' \
    'is attached to that channel. Conversations are public in that channel. ' \
    "This is very Slack-like. \n" \
    "• Doing a \'/do list\' will show your assigned tasks for only the " \
    "channel you are looking at. \n" \
    "• The \'All Tasks\' button will list tasks for the other channels as " \
    "well as unassigned and completed tasks. \n"
  [{ fallback: 'General Help - Best Practices',
     title: BEST_PRACTICES2_HLP_TITLE,
     text: best_practices2_hlp_text,
     color: '#3AA3E3',
     mrkdwn_in: ['text']
  }]
end

=begin
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
  ' Hint 1' \
  " \n" \
  ' Hint 2' \
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
  ' Online doc link 1' \
  " \n" \
  ' Online doc link 2' \
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
