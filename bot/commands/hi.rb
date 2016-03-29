
def hi_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From /bot.rb: '.concat('Hi to you. Nothing more to see.')
            )
end
