
def reformat_slash_command_to_browser_request(url_params)
  command = url_params[:text]
  command, debug = check_for_debug(command)
  { debug: debug, command_text: command }
end

def check_for_debug(command)
  debug = command.starts_with?('$')
  command = command.slice(1, command.length) if debug
  [command, debug]
end
