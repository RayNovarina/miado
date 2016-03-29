
============================================
slack-bot-on-rails:
A slack bot that responds to say, running on Rails with a React front-end that displays messages.

Rails app with bot server per:
https://github.com/dblock/slack-bot-on-rails


Slack app console:
Configured bot on Team Blocmetrics
Api Token: xoxb-29680321941-GmwXK2ahmk6DzWaQDdpbTJAP
Name: @rubybot
Channel: #rubybot-demo

To start rails app from console: (runs at localhost:3000)
$ SLACK_API_TOKEN='xoxb-29680321941-GmwXK2ahmk6DzWaQDdpbTJAP' bundle exec rails s

In slack:
/invite rubybot
@rubybot: say hi

----------------------------------
Implementation Details (refer to commit id of github repo for this project)

1) A vanilla Rails at /RubymineProjects/bloc/other/slack-bot-on-rails.
   Created via:
   $ rails new slack-bot-on-rails --skip-activerecord -T
   (commit @d092f4ed) added to standard gemfile:
   file: /config/Gemfile
   # Slack Bot
   gem 'slack-ruby-bot'
   # HAML
   gem 'haml-rails'
   # React
   gem 'react-rails'
   gem 'sprockets-coffee-react'
   gem 'js-routes'

1b) Server listens for msgs on /messages route?
   /config/routes.rb:
     Rails.application.routes.draw do
      root 'home#index'
      resources :messages, only: :index
     end

2) A slack-ruby-bot that responds to say something.
    (commit @a93877ae)

    a) file bot/say.rb:
       (purpose?: )
      class Say < SlackRubyBot::Commands::Base
        command 'say' do |client, data, match|
          send_message client, data.channel, match['expression']
        end
      end
    b) file /bot/tatletale.rb
       (purpose?: create thread for bot server to wait for events)
    $:.unshift File.dirname(__FILE__)
    require 'say'

    Thread.abort_on_exception = true

    Thread.new do
      SlackRubyBot::App.instance.run
    end

    c) file /config/initializers/bot.rb
       (purpose?:)
    require File.join(Rails.root, 'bot/tattletale')

3) A react app that displays messages sent to Slack.
  (commit @9632e9f1)
  a) file /assets/javascripts/react/messages/message.jo.coffee
  # @cjsx React.DOM

  @Message = React.createClass
    displayName: 'Message'
    render: ->
      # let's use this add-on to set the main div's class names
      cx = React.addons.classSet

      # here we use the calculated classes
      <div className="message">
        {@props.data.id}: {@props.data.message?.text}
      </div>
  b) .... other files for react front end to show sent msgs. Web app route, etc.

---------------------------------
** install problem note: gem install of eventmachine.

Installing eventmachine 1.0.8 with native extensions
fatal error openssl ssl.h file not found
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

fix per:
https://github.com/eventmachine/eventmachine/issues/643


=====================================================

 === MiaDo listBot Rails App and Slack Bot ===
Based on: slack-bot-on-rails - A slack bot that responds to 'say', running on
Rails with a React front-end that displays messages. per:
https://github.com/dblock/slack-bot-on-rails

----------- Slack app console ------------------

1) Create new slack team at https://slack.com/create#email
   Team owner email address i used: RNova94037@gmail.com
   Team name: Shadow Htrac team
   Slack signin team name: https://shadowhtracteam.slack.com
   My password is: htrac94037
   My team name to be displayed: ray

2) Afer Slack auto logged me into team Shadow Htrac Team (on web tab), i added
   channels: blog-ideas, issues, leads, weekly-call, numbers

3) Log into Slack with email addr Rnova9.... and add custom integration to team
   Shadow Htrac Team. Add a bot:
     Bot name: miabot
     Api token: xoxb-29764368535-jbZJAh45c7qDHkmwTNAqjSUl
     Icon: used dog head image from miado web app page.
     Channels: none

4) Logged into slack/shadow team as ray.  Note that there now is a user miabot.
   Invite @miabot to every channel.
     /invite @miabot

5) Invited dawn to join team. Dawn.Novarina@wemeus.com
   Also set slack to allow anyone with wemeus.com domain to auto signup and be
   added to Slack team.

------------ miaDo app config ----------------
1) Added to /config/Gemfile
  # Slack Bot
  gem 'slack-ruby-bot'
  Note: my gemfile was previously updated for other slack experiments and other
  gems may need to be explicityly included for the slack-ruby-bot. For sure the
  gems 'slack-ruby-client', 'eventmachine' and 'faye-websocket' are needed but
  already bundled by the time i wrote this.

2) $ bundle install

3) Add SLACK_API_TOKEN to environment in dev and production via Figaro.
   Added to /config/application.yml
    SLACK_API_TOKEN: 'xoxb-29444151207-1WNDgoqvSLx5hursx3LDlPoz'

4) Added file /config/initializers/slack.rb
  purpose: Set environmental variable used by ruby-bot.
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
      fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
    end

5) Added file /config/initializers/bot.rb
   purpose: upon rails server init, load the /bot/tattletale.rb file which
   will start a bot server thread using default gem config and uses the
   environmental variable 'SLACK_API_TOKEN' to talk to Slack.

   require File.join(Rails.root, 'bot/tattletale'

    a) file bot/bot.rb:
      purpose: Define command that bot will listen for ('say').

      class Bot < SlackRubyBot::Bot
        command 'say' do |client, data, match|
          client.say(channel: data.channel,
                     text: match['expression'])
        end
      end

    b) file /bot/tatletale.rb
       (purpose?: create thread for bot server to wait for events)
    $:.unshift File.dirname(__FILE__)
    require 'say'

    Thread.abort_on_exception = true

    Thread.new do
      SlackRubyBot::App.instance.run
    end

5) Added MessagesController and index action.
   purpose: ?bot-server does a GET /messages   ????
     $ rails generate controller Messages index

X) Gem files and bot startup flow of interest:
  x) The Bot class that we create. Found at:
  /.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/bot.rb
    class Bot < SlackRubyBot::Commands::Base

  x) The bot server class. Found at:
  /.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/server.rb
       module SlackRubyBot
         class Server
x) config options:
Disable animated GIFs via `SlackRubyBot::Config.send_gifs` or ENV['SLACK_RUBY_BOT_SEND_GIFS']
----------------------------------------------
rails server startup, Webrick ruby-bot trace. Intentionaly using inactive
SLACK_API_TOKEN to force error/stack trace and server shutdown:

=> Booting WEBrick
=> Rails 4.2.5.1 application starting in development on http://localhost:3000
=> Run `rails server -h` for more startup options
=> Ctrl-C to shutdown server
I, [2016-03-26T21:46:50.466960 #5118]  INFO -- : post https://slack.com/api/rtm.start
D, [2016-03-26T21:46:50.467077 #5118] DEBUG -- request: Accept: "application/json; charset=utf-8"
User-Agent: "Slack Ruby Client/0.7.0"
Content-Type: "application/x-www-form-urlencoded"
I, [2016-03-26T21:46:50.673057 #5118]  INFO -- Status: 200
D, [2016-03-26T21:46:50.673138 #5118] DEBUG -- response: content-type: "application/json; charset=utf-8"
transfer-encoding: "chunked"
connection: "close"
access-control-allow-origin: "*"
content-security-policy: "referrer no-referrer;"
date: "Sun, 27 Mar 2016 04:46:50 GMT"
server: "Apache"
strict-transport-security: "max-age=31536000; includeSubDomains; preload"
vary: "Accept-Encoding"
x-content-type-options: "nosniff"
x-xss-protection: "0"
x-cache: "Miss from cloudfront"
via: "1.1 fd0d5729063b609cfc65050d0d7e8759.cloudfront.net (CloudFront)"
x-amz-cf-id: "LCUjwTbG0DTKJrGJoQ366AdmHrVOYpwlH6Uj86RlePQOl4KGGbmWFA=="
E, [2016-03-26T21:46:50.673439 #5118] ERROR -- : account_inactive (Slack::Web::Api::Error)
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-client-0.7.0/lib/slack/web/faraday/response/raise_error.rb:9:in `on_complete'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/faraday-0.9.2/lib/faraday/response.rb:9:in `block in call'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/faraday-0.9.2/lib/faraday/response.rb:57:in `on_complete'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/faraday-0.9.2/lib/faraday/response.rb:8:in `call'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/faraday-0.9.2/lib/faraday/request/url_encoded.rb:15:in `call'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/faraday-0.9.2/lib/faraday/request/multipart.rb:14:in `call'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/faraday-0.9.2/lib/faraday/rack_builder.rb:139:in `build_response'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/faraday-0.9.2/lib/faraday/connection.rb:377:in `run_request'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/faraday-0.9.2/lib/faraday/connection.rb:177:in `post'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-client-0.7.0/lib/slack/web/faraday/request.rb:25:in `request'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-client-0.7.0/lib/slack/web/faraday/request.rb:10:in `post'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-client-0.7.0/lib/slack/web/api/endpoints/rtm.rb:21:in `rtm_start'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-client-0.7.0/lib/slack/real_time/client.rb:86:in `build_socket'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-client-0.7.0/lib/slack/real_time/client.rb:50:in `start!'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/server.rb:30:in `start!'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/server.rb:22:in `block (2 levels) in run'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/server.rb:61:in `handle_execeptions'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/server.rb:20:in `block in run'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/server.rb:19:in `loop'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/server.rb:19:in `run'
/Users/raynovarina/.rvm/gems/ruby-2.3.0/gems/slack-ruby-bot-0.7.0/lib/slack-ruby-bot/bot.rb:6:in `run'
/Users/raynovarina/RubymineProjects/bloc/capstone/miado/bot/tattletale.rb:7:in `block in <top (required)>'
Exiting
