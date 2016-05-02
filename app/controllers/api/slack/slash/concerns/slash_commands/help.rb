SLASH_CMD_HLP_TEXT =
'• `/do rev 1 spec @susan /jun15`' \
 ' Adds "rev 1 spec" task to this channel, assigns it to Susan,' \
 " due date is June 15.\n" \
 '• `/do append 3 Contact Jim.`' \
 " Adds \"Contact Jim.\" to the end of task 3.\n" \
 '• `/do assign 3 @tony`' \
 " Assigns \"@tony\" to task 3 for this channel.\n" \
 '• `/do unassign 4 @joe`' \
 " Removes \"@joe\" from task 4.\n" \
 '• `/do done 4`' \
 " Marks task 4 as completed.\n" \
 '• `/do delete 4`' \
 " Deletes task number 4 from the list.\n" \
 '• `/do due 4 /wed`' \
 " Sets the task due date to Wednesday for task 4.\n" \
 '• `/do redo 1 Send out newsletter /fri.`' \
 ' Deletes tasks 1, adds new task ' \
 "\"Send out newsletter /fri\"\n" \
 '• `/do list`' \
 " Lists your ASSIGNED tasks for THIS channel. Includes DONE tasks.\n" \
 '• `/do list open`' \
 " Lists your tasks which are not DONE for THIS channel.\n" \
 '• `/do list due`' \
 " Lists your OPEN tasks with a due date for THIS channel.\n" \
 '• `/do list team`' \
 " Lists all TEAM tasks for THIS channel.\n" \
 '• `/do list all`' \
 " Lists your ASSIGNED tasks for ALL channels.\n" \
 # ':bulb: Click on the "miaDo" member to see all of your up to date lists.' \
 "\n".freeze

# Returns: [text, attachments]
def help_command(_parsed)
  [SLASH_CMD_HLP_TEXT, nil]
end
