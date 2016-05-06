# Returns status msg.
#   If ok: empty string.
#   If err: err msg string.
def handoff_slash_command_to_bot
  # bot_name = '@miabot'
  bot_user_id = 'U0XTWH45N'
  bot_dm_channel_id = 'D0XTWH508'
  @view.slack_client ||= make_slack_client
  text =
    "<@#{bot_user_id}> transaction "
    .concat({ json_target: '> transaction {',
              type: 'slash_command',
              url_params: params
            }.to_json)
  api_resp = @view.slack_client.web_client
                  .chat_postMessage(
                    channel: bot_dm_channel_id,
                    text: text)
  api_resp['ok'] ? '' : '*err: defer_slash_command_to_bot*'
end

def make_slack_client
  @view.slack_client = Slack::RealTime::Client.new
end
