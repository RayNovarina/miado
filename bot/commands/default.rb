
def default_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From /bot.rb: '
             .concat('Default command for this channel is ??')
            )
end
