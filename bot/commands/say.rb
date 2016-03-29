
def say_command(client, data, match)
  client.say(channel: data.channel,
             text: 'From /bot.rb: '.concat(match['expression'])
            )
end
