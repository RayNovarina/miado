#
class Bot < SlackRubyBot::Bot
  #
  command 'about' do |client, data, match|
    about_command(client, data, match, client.web_client)
  end
  require 'commands/about'

  command 'add' do |client, data, match|
    add_command(client, client.web_client, data, match)
  end
  require 'commands/add'

  command 'append' do |client, data, match|
    append_command(client, client.web_client, data, match, client.web_client)
  end
  require 'commands/append'

  command 'assign' do |client, data, match|
    assign_command(client, client.web_client, data, match)
  end
  require 'commands/assign'

  command 'default' do |client, data, match|
    default_command(client, client.web_client, data, match)
  end
  require 'commands/default'

  command 'demo1' do |client, data, match|
    demo1_command(client, client.web_client, data, match)
  end
  require 'commands/demo1'

  command 'done' do |client, data, match|
    done_command(client, client.web_client, data, match)
  end
  require 'commands/done'

  command 'help' do |client, data, match|
    help_command(client, client.web_client, data, match)
  end
  require 'commands/help'

  command 'hi' do |client, data, match|
    hi_command(client, client.web_client, data, match)
  end
  require 'commands/hi'

  command 'list' do |client, data, match|
    list_command(client, client.web_client, data, match)
  end
  require 'commands/list'

  command 'redo' do |client, data, match|
    redo_command(client, client.web_client, data, match)
  end
  require 'commands/redo'
end
