def help_command(debug)
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
    ':bulb: Click on the "mia-lists" member to see all of your up to date ' \
    'lists.'
  slash_response(text, nil, debug)
end
