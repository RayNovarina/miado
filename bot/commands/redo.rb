#
def redo_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From redo.rb: '
            )
end
