July 14, 2016:
I. Registration:
  1) lib/omniauth_slack_setup.rb
     customize_options() - { scope: 'commands, bot', im:read', chat:write:bot' }
  2) app/controllers/users/omniauth_callbacks_controller.rb
     sign_up_from_omniauth() ->
       Channel.update_from_or_create_from(source: :omniauth_callback, request: request)
  3) app/models/concerns/channel_extensions.rb
       create_from_omniauth_callback(options) - Channel.new(), update_channel_auth_info(channel, options)
       update_channel_auth_info(channel, options)
         members_hash, rtm_start_json = find_or_create_members_hash_from_omniauth_callback(options)
           rtm_start = start_data_from_rtm_start()
             slack_api('rtm.start', auth.extra['bot_info']['bot_access_token'])
 ** slack api method 'rtm.start' using auth.['bot_access_token'])
    use rtm start to get all dm channels and users/members without needed oauth permission scope.
II. Slash commands:
  1) Add/assign member:
      app/controllers/api/slack/slash/concerns/slash_commands/add.rb
      add command uses parser to get assigned member:
        app/controllers/api/slack/slash/concerns/helpers/parse_cmd.rb
          scan4_mentioned_member(p_hash) - if member not found,
            app/controllers/api/slack/slash/concerns/helpers/misc.rb
            mentioned_member_not_found(p_hash, name) -
              add_update_members_from_rtm_start() -
                rtm_start = start_data_from_rtm_start(p_hash[:ccb].bot_api_token)
                slack_members = rtm_start['users']
** slack api method 'rtm.start' using auth.['bot_access_token'])

III. Update taskbot msg:
  app/controllers/api/slack/slash/concerns/helpers/deferred_cmd.rb
  update_taskbot_channel() -
    app/controllers/api/slack/slash/concerns/helpers/clear_bot_channel.rb
    1) clear_channel_msgs(type: :direct, [:slack_user_api_token])
      web_api_history(type: :direct, [:slack_user_api_token]
        api_client.im_history(options)
** slack api method 'im.history' using slack_user_api_token
      delete_message_on_channel(type: :direct, [:slack_user_api_token]) -
** slack api method 'chat_delete(taskbot_channel_id, [:message]['ts']) using slack_user_api_token
    2) send_taskbot_msg([:slack_user_api_token]) -
        chat_postMessage( as_user: 'false', taskbot_username, taskbot_channel_id])
** slack api method 'chat.postMessage' using slack_user_api_token)

==================================
# Scopes and why needed:
#    bot: - to be able to get the taskbot's slack user id to use to
#           identify the taskbot's dm channel id to be able to send
#           taskbot msgs to the taskbot dm channel.
#    users:read - to be able to use the users.list api method to verify
#                 assigned names.
#    chat:write:bot - to be able to use the chat.delete and
#                 chat.postMessage api methods to clear taskbot msgs and
#                 to post a new one.
#    im:read - to be to use the api method im.list to get a list of
#              direct message channels to build a members lookup hash.
#    im:history - to be able to read the taskbot messages to get the msg
#                 id so that it can be deleted.
#    channels:read - to be able to use the api method channels.list to
#                 build a list of all team channels.
#    commands - to allow teams to install the /do slash command.
# API methods used:
# 1) in models/concerns.channel_extensions.rb:
#      def slack_dm_channels_from_rtm_data
#    Slack::Web::Client.web_client.im_list['ims']
#    uses token from team.api_token which is the miaDo api token from the
#      member installing miaDo. (auth_hash[:auth]['credentials']['token'])
# 2) in models/concerns.member_extensions.rb:
#      def slack_members_from_rtm_data
#    Slack::Web::Client.web_client.im_list['members']
#    uses token from team.api_token which is the miaDo api token from the
#      member installing miaDo. (auth_hash[:auth]['credentials']['token'])
# return { scope: 'bot,'\
#                'chat:write:bot,'\
#                'commands,'\
#                'users:read,'\
#                'channels:read,'\
#                'im:read,'\
#                'im:history'\
#       }
# ',users:read'\
# ',im:read'\
# ',im:history'\
# ',chat:write:bot'\
# ',channels:read'\
# Ok for june 20th. dont verify member names, get taskbot dm channel id.
# return { scope: ' commands'\
#                ',bot'\
#                ',im:read'\
#                ',chat:write:bot'\
#       }
return { scope: ' commands' \
                ',bot' \
                ',im:read'\
                ',chat:write:bot'\
       }
end
