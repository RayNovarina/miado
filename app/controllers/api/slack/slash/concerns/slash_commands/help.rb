SLASH_CMD_HLP_TEXT =
  '• `/do rev 1 spec @susan /jun15`' \
  ' Adds "rev 1 spec" task to this channel, assigns it to Susan,' \
  " due date is June 15.\n" \
  '• `/do append 3 Contact Jim.`' \
  " Adds \"Contact Jim.\" to the end of task 3.\n" \
  '• `/do assign 4 @joe`' \
  " Assigns \"@joe\" to task 4 for this channel.\n" \
  '• `/do unassign 4 @joe`' \
  " Removes \"@joe\" from task 4.\n" \
  '• `/do done 4`' \
  " Marks task 4 as completed.\n" \
  '• `/do delete 2`' \
  " Deletes task number 2 from the list.\n" \
  '• `/do due 4 /wed`' \
  " Sets the task due date to Wednesday for task 4.\n" \
  '• `/do redo 1 Send out newsletter /fri.`' \
  ' Deletes task 1, adds new task ' \
  "\"Send out newsletter /fri\"\n" \
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
  ':bulb: Click on the <https://shadowhtracteam.slack.com/messages/@a.taskbot|a.taskbot> member to see all of your up to date ' \
  'lists.' \
  "\n".freeze
# ':bulb: Click on the <https://slack.com/messages/@a.taskbot|a.taskbot> member to see all of your up to date ' \
# 'lists.' \

# Returns: [text, attachments]
def help_command(_parsed)
  @view.channel.last_activity_type = 'slash_command - help'
  @view.channel.last_activity_date = DateTime.current
  @view.channel.save
  [SLASH_CMD_HLP_TEXT, nil]
end
