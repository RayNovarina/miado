=begin
  /todo help:
  '/todo' is a link to ? remove/install /todo? at:
    https://shadowhtracteam.slack.com/services/B0XC38PDY

  :logo /todo BOT [6:53 PM] Only you can see this message
  • `/todo prepare client proposal` Adds "prepare client proposal" to the channel to-do list.
  • `/todo name Marketing Tasks` Changes the to-do list name to "Marketing Tasks”.
  • `/todo list` Lists the to-do list of the channel silently
  • `/todo show` Shares the to-do list of with the channel
  • `/todo done 1 2` Marks tasks number 1 and 2 as done.
  • `/todo list done` Lists the latest tasks completed silently
  • `/todo show done` Shows the latest tasks completed
  • `/todo remove 2` Deletes task number 2 from the list.
  • `/todo assign 1 and 2 to @johnsmith` Adds "@johnsmith" to the tasks number 1 and 2.
  • `/todo unassign 1 from @johnsmith` Removes "@johnsmith" from task 1.
  • `/todo feedback awesome app` Sends "awesome app" to us - Help us make /todo better.
  • `/todo help` Lists available commands.
  • :bulb: `/mytodo` Manage your personal to-do list and view the tasks you are assiged.
=end

def help_command(_rtm_api_client, web_api_client, data, _match)
=begin
  text =
    '• `/do rev 1 spec @susan /jun15`' \
    ' Adds "rev 1 spec" to this channel, assigns it to Susan and sets' \
    " a due date of June 15.\n" \
    '• `/do append 3 Contact Jim.`' \
    " Adds \"Contact Jim.\" to the end of task 3.\n" \
    '• `/do assign 3 @tony`' \
    " Assigns \"@tony\" to task 3 for this channel.\n" \
    '• `/do unassign 4 @joe`' \
    " Removes \"@joe\" from task 4.\n" \
    '• `/do done 4`' \
    " Marks task 4 as completed.\n" \
    '• `/do remove 4`' \
    " Deletes task number 4 from the list.\n" \
    '• `/do due 4 /wed`' \
    " Sets the task due date to Wednesday for task 4.\n" \
    '• `/do redo 1 Send out newsletter by /fri.`' \
    ' Deletes tasks 1 and replaces it with ' \
    "\"Send out newsletter by /fri\"\n" \
    '• `/do list`' \
    " Lists your tasks for this channel.\n" \
    '• `/do list due`' \
    " Lists your open tasks for this channel and their due dates.\n" \
    '• `/do list all`' \
    " Lists all team tasks for this channel.\n" \
    ':bulb: Click on the "miabot" member to see all of your up to date ' \
    'lists.'
=end
  text =
    'Click on the "miabot" member to see all of your up to date lists.'
  channel = data.channel
  # username = 'miabot'
  # icon_url = '/assets/images/bullet_grey.png'
  # '/assets/images/dog_head_icon_reverse.png'
  # icon_url = '/assets/images/120px-Gnome-stock_person_bot.svg.jpg'
  # mrkdwn = true

  # rtm_api_client_options = {
  #  # Required fields.
  #  channel: channel,
  #  text: text
  # }
  # Optional fields.
  # rtm_api_client_options[:gif] = gif unless (defined? gif).nil?

  web_api_client_options = {
    # Required fields.
    channel: channel,
    text: text
  }
  # Optional fields.
  web_api_client_options[:username] = username unless (defined? username).nil?
  web_api_client_options[:icon_url] = icon_url unless (defined? icon_url).nil?
  web_api_client_options[:attachments] = attachments unless (defined? attachments).nil?
  web_api_client_options[:mrkdwn] = mrkdwn unless (defined? mrkdwn).nil?
  web_api_client_options[:gif] = gif unless (defined? gif).nil?
  web_api_client_options[:mrkdwn] = mrkdwn unless (defined? mrkdwn).nil?

  # rtm_api_client.say(rtm_api_client_options)
  web_api_client.chat_postMessage(web_api_client_options)
end
