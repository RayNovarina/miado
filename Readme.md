===================================
Production release to Dockerize app: 4/21/2017

#---------------------
Delete all local dev gems. Using only container GEMS. Update to ruby 2.3.x

#---------------------
use puma as web server: per heroku at
https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

Adding Puma to your application
Gemfile
First, add Puma to your app’s Gemfile:
gem 'puma'
$ docker-compose run --rm web bundle install

Procfile
Set Puma as the server for your web process in the Procfile of your application. You can set most values inline:
web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
However we recommend generating a config file:
web: bundle exec puma -C config/puma.rb
Make sure the Procfile is properly capitalized and checked into git.

# Note: i did not set RAILS_MAX_THREADS for production. Seems that u are suppose to use the default.
# Note: the slash command web app spawns threads for deferred/background processing of taskbot events.
# $ heroku config:set RAILS_MAX_THREADS=1

$ docker exec -it miado_web_1 bash



# use pry to debug in container per:
http://www.chris-kelly.net/2016/07/25/debugging-rails-with-pry-within-a-docker-container/

$ docker-compose run --service-ports web
$ docker attach miado_web





===================================
Pushed to production: 8:30pm.
1) Git push to heroku complained about unmerged changes in prod. Did a git pull
   and empty?/directories for rake, other rails related came over. Caused by
   rails update and ruby reinstall on ray's dev system? Pushed again with no
   git complaints.
2) Blowoff when installing @ray into ShadowHtracTeam.
   Workaround: Channel.update_all(taskbot_msg_to_slack_id: nil)
3) Blowoff when using "/do feedback" command. Problem with email. Log:
   Sent mail to RNova94037@gmail.com (1105.5ms)
   Completed 500 Internal Server Error in 1410ms (ActiveRecord: 8.4ms)
   Net::SMTPFatalError (554 Sandbox subdomains are for test purposes only.
   Please add your own domain or add the address to authorized recipients in
   domain settings.

   commands_controller.rb:241:in process_cmd
   concerns/slash_commands/feedback.rb:16:in feedback_command
   commands_controller.rb:55:in local_response

===================================
Production Dec 02 2016 release spec:
Goals: inform users how to use miado "right"
x - 1) no change in permissions.
x - 2) Public channels: (i.e. general, etc.)
x -  a) Add Button strip to public channel replies.
x -    Only after add cmd or others too? list command too?
x -    Buttons: 'Your To-Do's' 'Team To-Do's' 'All Tasks' 'Feedback' 'Help'
x -             Your To-Do's: member's assigned and open in this channel.
x -             Team To-Do's: all members' assigned and open in this channel.
x -             All Tasks: all tasks in this channel. Open or closed.
x -             Feedback: say 'use the /do feedback command.'
x -             Button Help: help info about what the buttons mean.
x - b) add /feedback command.
x - c) Help command:
x -      Add 'Task Lists' button
3) Taskbot channel:
x - a) Add Button strip
x -    Buttons: 'Your To-Do's' 'Team To-Do's' 'All Tasks' 'Reset' 'Help'
x -         Your To-Do's: member's assigned and open in this channel.
x -         Team To-Do's: all members' assigned and open in this channel.
x -         All Tasks: all tasks in this channel. Open or closed.
x -         Reset: Erase ALL taskbot channel msgs.
x -                Reset message tracking (Member.bot_msgs_json to nil).
x -                Display 'Your To-Do's list'.
x -                Restore channel buttons.
x -                Set channel and member activity fields to 'list'
x -         Button Help: help info about what the buttons mean.
x - b) 'Delete' button moved to footer of report. Tasks are now in one attachment.
x - c) Add two footer buttons: 'Mark Task as Done' and 'Delete'.
x -    Responds with edit of msg area: Deleted: strikeover of task.
x - d) Slash commands. Allow list. Other commands give err msg and button strip.
4) Onboarding:
x - a) If first install, msg is written to Taskbot channel.
  Hi @#{parsed[:mcb].slack_user_name}, Miado is now installed and ready
  to help you manage your tasks in Slack.  Your taskbot always has your
  current to-do list ready to review with one click.  To get started,
  click on your #general channel and add your first task. i.e.
  `/do @me my first task /today`
  Please note that MiaDo is most effective when used with team members
  who have also added MiaDo to Slack. Best Practices, such as that are
  available via the `/do help` command.
4) Slack app directory verbage:
5) /do command prompt verbage:
x - Now: /do hint says '/do /do help'       'todo List management from MiaDo'
x - Change to: '/do help'    'todo list management from MiaLabs'
6) MiaDo add to Slack page:
7) MiaDo installation completed page:
8) Misc:


====================
* DB update script for production push in Installation model extensions.

    #======================
    # DB update for Production release 12/02/2016
    #=======================

    # Trim Installation.rtm_start_json:
    def update_installation_recs
      Installation.all.each do |installation|
        # NOTE: Installation.start_data_from_rtm_start trims out the stuff
        #       we dont want to persist.
        rtm_start_json = start_data_from_rtm_start(installation.bot_api_token)
        next if rtm_start_json.nil?
        installation.update(
          rtm_start_json: rtm_start_json,
          last_activity_type: 'refresh rtm_start_data',
          last_activity_date: DateTime.current)
      end
    end

    # taskbot channels: change channel name, set bot_api_token
    def update_taskbot_channel_recs
      Channel.where(is_taskbot: true).each do |tbot_chan|
      member = Member.where(slack_team_id: tbot_chan.slack_team_id,
                            slack_user_id: tbot_chan.slack_user_id).first
      next if member.nil?
      tbot_chan.update(
        slack_channel_name: "taskbot_channel_for_@#{member.slack_user_name}",
        slack_user_api_token: member.slack_user_api_token,
        bot_api_token: member.bot_api_token,
        bot_user_id: member.bot_user_id)
      end
    end
    #=====================

    also updated:

            def trim_rtm_start_data(rtm_start_json)
              return nil if rtm_start_json.nil?

              unless rtm_start_json['self'].nil?
                rtm_start_json['self'].except!('prefs', 'groups', 'read_only_channels',
                                               'subteams', 'dnd', 'url')
              end
   #=========================
