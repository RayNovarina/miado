#
def list_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From list.rb: '
            )
end
