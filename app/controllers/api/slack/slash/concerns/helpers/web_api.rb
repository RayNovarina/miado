
def web_api_history(type, options)
  case type
  when :channel
    # if args.channel_name:
    resp = @view.slack_client.web_client.channels_history(options)
  when :direct
    #  elif args.direct_name:
    resp = @view.slack_client.web_client.im_history(options)
  when :group
    #  elif args.group_name:
    resp = @view.slack_client.web_client.groups_history(options)
  when :mpdirect
    #  elif args.mpdirect_name:
    resp = @view.slack_client.web_client.mpim_history(options)
  end
  resp
end

def web_api_channel_id(source)
  case source
  when :user_id
    # dm channel id for miabot on shadowhtracteam: D0XTWH508   Got it variable
    # user.list and match user id to im.list. Im# is im.id.
    'D0XTWH508'
  end
end
