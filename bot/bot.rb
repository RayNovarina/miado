#
class Bot < SlackRubyBot::Bot
  #
  command 'about' do |client, data, match|
    about_command(client, data, match)
  end
  require 'commands/about'

  command 'default' do |client, data, match|
    default_command(client, data, match)
  end
  require 'commands/default'

  command 'help' do |client, data, match|
    help_command(client, data, match)
  end
  require 'commands/help'

  command 'hi' do |client, data, match|
    hi_command(client, data, match)
  end
  require 'commands/hi'

  command 'say' do |client, data, match|
    say_command(client, data, match)
  end
  require 'commands/say'
end
