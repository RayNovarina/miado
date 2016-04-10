require_relative 'transaction/slash_commands/commands' # method for each slack command

# Processes transaction, sends response back as msgs to slack as needed.
# Returns: nothing, status msgs sent back as msgs to slack.
def transaction_command(rtm_api_client, web_api_client, data)
  transaction = from_rtm_data(data)
  command, debug = check_for_debug(transaction['url_params']['text'])

  case transaction['type']
  when 'slash_command'
    return help_commandx(rtm_api_client, web_api_client, data) if command.starts_with?('xhelp')
    # return append_command if command.starts_with?('append')
    # return assign_command if command.starts_with?('assign')
    # return unassign_command if command.starts_with?('unassign')
    return list_command(rtm_api_client, web_api_client, data) if command.starts_with?('list')
    # Default to add task if no explicit command.
    return add_command(rtm_api_client, web_api_client, data)
  end
end

def from_rtm_data(data)
  json_target = '> transaction {'
  json_text_idx =
    data[:text].index(json_target) + json_target.length - 1
  JSON.parse data[:text][json_text_idx..-1]
end

def check_for_debug(command)
  debug = command.starts_with?('$')
  command = command.slice(1, command.length) if debug
  [command, debug]
end
