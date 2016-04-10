# MiaDo Bot help command.
def help_command(_rtm_api_client, web_api_client, data)
  chat_post_message(
    web_api_client, data,
    text: 'Click on the "miabot" member to see all of your up to date lists.')
end

def chat_post_message(web_api_client, bot_msg_data, options)
  api_options = {
    channel: bot_msg_data.channel,
    as_user: false # ,
    # username: options.key?(:username) ? options[:username] : 'miabot'
  }.merge(options)
  web_api_client.chat_postMessage(api_options)
end
