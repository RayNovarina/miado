# Inputs: parsed = parsed command line info that has been verified.
# Returns: [text, attachments]
#-------------------------------------------------
def reset_command(parsed)
  adjust_reset_cmd_action_context(parsed)
  # Ack the slack server ASAP. We have the parsed{} info. Handle the real
  # response work as a deferred command. It has most of our useful Slack API
  # lib methods.
  parsed[:expedite_deferred_cmd] = false
  [nil, nil]
end

def adjust_reset_cmd_action_context(parsed)
  # Reset list that user is looking at. (update parsed[:list_ids])
  adjust_inherited_cmd_action_context(parsed)
end
