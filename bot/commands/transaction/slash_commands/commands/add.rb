require_relative '../helpers/clear_bot_channel'
require_relative '../helpers/write_navbar'
require_relative '../helpers/write_new_lists'

def add_command(command, debug)
  text = 'Task 4 added. | *Assigned* to @dawn. Type `/do list` for a current list.'
  text.concat("\n`Original command: `  ").concat(command) if debug
  # make_response_and_update_bot_channel(command, text, nil, debug)
  slash_response(text, nil, debug)
end

def make_response_and_update_bot_channel(command, text, attachments = nil,
                                         debug = false)
  # Get server response first in case of error conditions.
  command_resp = slash_response(text, attachments, debug)
  api_resp = update_bot_channel(debug)
  unless api_resp == 'ok'
    command_resp[:text] = command_resp[:text].concat(
      "\n*Failed to delete all messages!* ApiError: "
      .concat(api_resp))
  end
  command_resp
end

def update_bot_channel(debug)
  @view.slack_client ||= make_slack_client
  api_resp = clear_bot_channel({ start_ts: 0, end_ts: 0 }, false)
  api_resp = write_navbar if api_resp == 'ok'
  api_resp = write_new_lists(debug) if api_resp == 'ok'
  api_resp
end
