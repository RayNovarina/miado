#
def demo1_command(client, data, _match)
  client.say(channel: data.channel,
             text: 'From demo1.rb: '
            )
end
