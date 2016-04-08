source 'https://rubygems.org'

ruby '2.3.0'

#========== GLOBAL GEMS ======================
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5.1'
#-------------------------------------------
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
#-------------------------------------------
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
#-------------------------------------------
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
#-------------------------------------------
# Use jquery as the JavaScript library
gem 'jquery-rails'
#-------------------------------------------
# Turbolinks makes following links in your web application faster.
#   Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
#-------------------------------------------
# Use Twitter Bootstrap 4 (4.0.0.alpha3?) as CSS framework
# gem 'bootstrap'
#------------------------------------------
# Use Twitter Bootstrap 3 as CSS framework
gem 'bootstrap-sass'
#-------------------------------------------
# per: http://www.sitepoint.com/devise-authentication-in-depth/
# If you are using Bootstrap's dropdown menu. Dropdown relies on JavaScript code
# and, using Turbolinks, it won't be executed correctly when navigating between
# pages. Use jquery-turbolinks to fix this:
gem 'jquery-turbolinks'
#--------------------------------------------
# Use Figaro to store Sendgrid and Devise credentials as environment variables.
#     Doc - Bloc: https://www.bloc.io/resources/environment-variables-with-figaro
#     GitHub - https://github.com/laserlemon/figaro#give-me-an-example
gem 'figaro', '1.0'
#-------------------------------------------
# Use Pry as alternative Rails console shell (alternative to IRB)
# To use: add    " require 'pry' " at head of file.
#         insert " binding.pry " in the code to where you want the breakpoint.
# gem 'pry'
gem 'pry-rails'
#-------------------------------------------
# Use Devise authentication
gem 'devise'
#-------------------------------------------
# Add omniauth strategy for Slack
# per: https://github.com/kmrshntr/omniauth-slack
# gem 'omniauth-slack'
# If you need to use the latest HEAD version, you can do so with:
gem 'omniauth-slack', github: 'kmrshntr/omniauth-slack'
#-------------------------------------------
# Add omniauth strategy for GitHub
# per: https://github.com/intridea/omniauth-github
gem 'omniauth-github'
#-------------------------------------------
# Add omniauth strategy for GoogleApps and Gmail
# per: https://github.com/zquestz/omniauth-google-oauth2
gem 'omniauth-google-oauth2'
#-------------------------------------------
# Use Pundit authorization
gem 'pundit'
#-------------------------------------------
# Generate data for seeding database.
gem 'faker'
#-------------------------------------------
# use postgre SQL db server for Active Record
gem 'pg'
#--------------------------------------------
# Slack bot gem.
# per: https://github.com/dblock/slack-ruby-bot/tree/v0.7.0
gem 'slack-ruby-bot'
#-----------------------------------------------
# Slack Notifier gem per:
# http://rubyinrails.com/2015/09/14/rails-slack-integration-with-slack-notifier-gem/
# gem 'exception_notification'
gem 'slack-notifier'
#------------------------------------------------
# Slack Ruby Client per:
# https://github.com/dblock/slack-ruby-client
gem 'slack-ruby-client'
#-------------------------------------------------
# For concurrency when using the slack-ruby-client gem with the Slack web api
# plus the Slack real time api.
gem 'eventmachine'
gem 'faye-websocket'
#------------------------------------------------------
#
#
#============== DEVELOPMENT only GEMS =================
group :development do
  gem 'web-console', '~> 2.0'
  gem 'pry-stack_explorer'
end

#
#============ DEVELOPMENT, TEST only GEMS =============
group :development, :test do
  gem 'byebug'
  #-------------------------------------------
  gem 'spring'
  #-------------------------------------------
  gem 'rspec-rails'
  #-------------------------------------------
  # Rspec extension that add "shoulda" test syntax.
  # To use: ??
  gem 'shoulda'
  #-------------------------------------------
  gem 'factory_girl_rails'
end

#
#=========== PRODUCTION only GEMS =================
group :production do
  #-------------------------------------------
  # Rails 4 requires some minor configuration changes to properly serve assets
  # on Heroku
  gem 'rails_12factor'
  #-------------------------------------------
end
