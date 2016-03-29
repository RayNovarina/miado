
def help_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From /bot.rb: '.concat('HELP!!!!')
            )
end
