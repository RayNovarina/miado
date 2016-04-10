
def submit_request_to_rails_app(request)
  command = request[:command_text]
  debug = request[:debug]
  return help_command(command, debug) if command.starts_with?('help')
  # return append_command if command.starts_with?('append')
  # return assign_command if command.starts_with?('assign')
  # return unassign_command if command.starts_with?('unassign')
  return list_command(command, debug) if command.starts_with?('list')
  # Default to add task if no explicit command.
  add_command(command, debug)
end
