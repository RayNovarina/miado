#
def done_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From done.rb: '
            )
end
