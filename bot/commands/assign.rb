#
def assign_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From assign.rb: '
            )
end
