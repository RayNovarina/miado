#
def append_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From append.rb: '
            )
end
