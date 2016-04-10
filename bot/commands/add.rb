#
def add_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From add.rb: '
            )
end
