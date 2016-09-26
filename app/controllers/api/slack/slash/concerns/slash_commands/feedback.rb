SLASH_CMD_HLP_TEXT =
  '• `/do list team all`' \
  " Lists all TEAM tasks that are OPEN for ALL channels.\n" \
  ':bulb: Click on the <https://shadowhtracteam.slack.com/messages/@a.taskbot|a.taskbot> member to see all of your up to date ' \
  'lists.' \
  "\n".freeze
# ':bulb: Click on the <https://slack.com/messages/@a.taskbot|a.taskbot> member to see all of your up to date ' \
# 'lists.' \

# Returns: [text, attachments]
def feedback_command(_parsed)
  @view.channel.last_activity_type = 'slash_command - help'
  @view.channel.last_activity_date = DateTime.current
  @view.channel.save
  [SLASH_CMD_HLP_TEXT, nil]
end
