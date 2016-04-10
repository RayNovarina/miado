#
class Bot < SlackRubyBot::Bot
  require 'commands'

  command 'help' do |client, data, _match|
    help_command(client, client.web_client, data)
  end

  command 'transaction' do |client, data, _match|
    transaction_command(client, client.web_client, data)
  end

  command 'about' do |client, data, _match|
    help_command(client, client.web_client, data)
  end

  command 'hi' do |client, data, _match|
    help_command(client, client.web_client, data)
  end

  command 'say' do |client, data, _match|
    help_command(client, client.web_client, data)
  end
end
