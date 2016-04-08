require_relative 'helpers/reformat_slash_command'
require_relative 'helpers/submit_request'
require_relative 'helpers/reformat_browser_response'

def slash_response(text, attachments = nil, debug = false)
  web_api_client_options = {
    # Required fields.
    response_type: 'ephemeral',
    text: debug_headers(debug).concat(text)
  }
  # Optional fields.
  web_api_client_options[:attachments] = attachments unless (defined? attachments).nil?
  web_api_client_options
end

def debug_headers(debug)
  return '' unless debug
  "`MiaDo User: #{'??'}. " \
  "Slack Team: #{params['team_domain']}. " \
  "Member: #{params['user_name']}. Channel: #{params['channel_name']}`\n"
end

def make_slack_client
  @view.slack_client = Slack::RealTime::Client.new
end
