def check_for_debug(url_params)
  command = url_params[:text]
  debug = command.starts_with?('$')
  command = command.slice(1, command.length) if debug
  [command, debug]
end

# Returns json response with text, attachments fields.
def slash_response(text, attachments = nil, debug = false)
  options = {
    # Required fields.
    response_type: 'ephemeral',
    text: debug_headers(debug).concat(text)
  }
  # Optional fields.
  options[:attachments] = attachments unless attachments.nil?
  options
end

def debug_headers(debug)
  return '' unless debug
  # "`MiaDo User: #{'??'}. " \
  "Slack Team: #{params['team_domain']}. " \
  "Member: #{params['user_name']}. Channel: #{params['channel_name']}`\n"
end
