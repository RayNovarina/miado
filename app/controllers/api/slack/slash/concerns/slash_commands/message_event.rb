# Inputs: parsed = parsed command line info that has been verified.
# Returns: [text, attachments]
#-------------------------------------------------
def message_event_command(_parsed)
  # Ack the slack server ASAP. We have the parsed{} info. Handle the real_name
  # response work as a deferred command. It has most of our useful Slack API
  # lib methods.
  ['', []]
end
