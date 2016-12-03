=====================
Production Readme.md


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
