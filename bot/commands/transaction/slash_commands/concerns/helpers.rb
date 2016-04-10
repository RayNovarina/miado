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

def defer_slash_command_to_bot
  @view.slack_client ||= make_slack_client
  text = 'transaction '.concat({ type: 'slash_command', url_params: params }.to_json)
  api_resp = @view.slack_client.web_client
                  .chat_postMessage(
                    channel: 'D0XTWH508',
                    text: text)
  api_resp['ok'] ? '' : '*err: defer_slash_command_to_bot*'
end

def make_slack_client
  @view.slack_client = Slack::RealTime::Client.new
end
