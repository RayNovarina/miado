# Returns: array of ListItem records
#-----------------------------------
# LIST_SCOPES  = %w(one_member team)
# CHANNEL_SCOPES = %w(one_channel all_channels)
# options  = %w(open due done)
# assigned_member_id = id of @name assigned a task.
def list_from_parsed(parsed)
  return [] unless parsed[:err_msg].empty?
  return [] if parsed[:func] == :help
  params = parsed[:url_params]

  #--------------------------------------
  if parsed[:list_scope] == :one_member
    #------------------------------------
    if parsed[:channel_scope] == :one_channel
      list_of_assigned_tasks_for_one_member_in_one_channel(parsed, params)

    elsif parsed[:channel_scope] == :all_channels
      list_of_assigned_tasks_for_one_member_in_all_channels(parsed, params)
    end

  #------------------------------
  elsif parsed[:list_scope] == :team
    #----------------------------
    if parsed[:channel_scope] == :one_channel
      if parsed[:mentioned_member_id].nil?

        list_of_all_tasks_for_all_team_members_in_one_channel(parsed, params)

      else # unless parsed[:mentioned_member_id]

        list_of_all_tasks_for_one_team_member_in_one_channel(parsed, params)

      end

    elsif parsed[:channel_scope] == :all_channels
      if parsed[:mentioned_member_id].nil?

        list_of_all_tasks_for_all_team_members_in_all_channels(parsed, params)

      else # unless parsed[:mentioned_member_id]

        list_of_all_tasks_for_one_team_member_in_all_channels(parsed, params)

      end
    end
  end
end

#------------------ assigned tasks for mentioned member --------------------
def list_of_assigned_tasks_for_one_member_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_assigned_tasks_for_one_member_in_one_channel' if parsed[:debug]
  # For specified member in this channel.
  # parsed[:due_option] or :open

  if parsed[:due_option]
    # due: All list items for this Team Channel assigned to specified member
    #      and with a due date.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')

  elsif parsed[:open_option]
    # open: All list items for this Team Channel assigned to specified
    #       member and which are not done.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: false)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # done: All list items for this Team Channel assigned to specified
    #       member and which are done.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: true)
            .reorder('channel_name ASC, created_at ASC')
  else
    # member: All list items for this Team Channel assigned to specified
    #         Slack member
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_assigned_tasks_for_one_member_in_all_channels(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_assigned_tasks_for_one_member_in_all_channels' if parsed[:debug]
  # For member in all channels.
  # all: All list items for ALL Channels assigned to specified Slack member,
  #     clumped by channel via sorted by channel name and creation date.
  # parsed[:due_option] or :open

  if parsed[:due_option]
    # due: All list items for all channels assigned to specified Slack
    #      member and with a due date OR is open.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')

  elsif parsed[:open_option]
    # open: All list items for this Team Channel assigned to specified
    #       member and which are not done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: false)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # done: All list items for this Team Channel assigned to specified
    #       member and which are done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: true)
            .reorder('channel_name ASC, created_at ASC')
  else
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .reorder('channel_name ASC, created_at ASC')
  end
end

# --------------- all tasks for team or mentioned member -------------------

def list_of_all_tasks_for_one_team_member_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_tasks_for_one_team_member_in_one_channel' if parsed[:debug]
  # For all team members in this channel.
  # team: All list items for this Team Channel.

  # parsed[:due_option] or :open
  if parsed[:due_option]
    # due: All list items for this Team Channel
    #      and with a due date OR is open.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All list items for this Team Channel assigned to specified
    # member and which are not done.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: false)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # done: All list items for this Team Channel assigned to specified
    # member and which are done.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: true)
            .reorder('channel_name ASC, created_at ASC')
  else
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_tasks_for_all_team_members_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_tasks_for_all_team_members_in_one_channel' if parsed[:debug]
  # For all team members in this channel.
  # team: All list items for this Team Channel.

  # parsed[:due_option] or :open
  if parsed[:due_option]
    # due: All list items for this Team Channel
    #      and with a due date OR is open.
    ListItem.where(channel_id: params[:channel_id])
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All list items for this Team Channel assigned to specified
    # member and which are not done.
    ListItem.where(channel_id: params[:channel_id],
                   done: false)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All list items for this Team Channel assigned to specified
    # member and which are done.
    ListItem.where(channel_id: params[:channel_id],
                   done: true)
            .reorder('channel_name ASC, created_at ASC')
  else
    ListItem.where(channel_id: params[:channel_id])
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_tasks_for_one_team_member_in_all_channels(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_tasks_for_one_team_member_in_all_channels' if parsed[:debug]
  # For all team members in all channels.
  # all: All list items for ALL Channels assigned to any team member,
  #     clumped by channel via sorted by channel name and creation date.

  # parsed[:due_option] or :open
  if parsed[:due_option]
    # due: All list items for all channels assigned to any team
    #      member and with a due date OR is open.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_member_id: nil)
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All list items for this Team Channel assigned to any
    #       member and which are not done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: false)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All list items for this Team Channel assigned to any
    #       member and which are done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: true)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  else
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_tasks_for_all_team_members_in_all_channels(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_tasks_for_all_team_members_in_all_channels' if parsed[:debug]
  # For all team members in all channels.
  # all: All list items for ALL Channels assigned to any team member,
  #     clumped by channel via sorted by channel name and creation date.

  # parsed[:due_option] or :open
  if parsed[:due_option]
    # due: All list items for all channels assigned to any team
    #      member and with a due date OR is open.
    ListItem.where(team_id: params[:team_id])
            .where.not(assigned_member_id: nil)
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All list items for this Team Channel assigned to any
    #       member and which are not done.
    ListItem.where(team_id: params[:team_id],
                   done: false)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All list items for this Team Channel assigned to any
    #       member and which are done.
    ListItem.where(team_id: params[:team_id],
                   done: true)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  else
    ListItem.where(team_id: params[:team_id])
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_from_list_of_ids(parsed, array_of_ids)
  parsed[:list_query_trace_info] = "list_from_list_of_ids(input ids: #{array_of_ids.to_s})" if parsed[:debug]
  ListItem.where(id: array_of_ids).reorder('channel_name ASC, created_at ASC')
end

def ids_from_parsed(parsed)
  records = list_from_parsed(parsed)
  return [] unless parsed[:err_msg].empty?
  return [] if records.empty?
  ids = []
  records.each do |item|
    ids << item.id
  end
  parsed[:list_query_trace_info] = "ids_from_parsed(returned: #{ids.to_s})" if parsed[:debug]
  ids
end