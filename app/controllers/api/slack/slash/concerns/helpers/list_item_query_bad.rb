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
      #------------------------------------
      if parsed[:assigned_option]
        #----------------------------------
        list_of_assigned_tasks_for_one_member_in_one_channel(parsed, params)
      else # parsed[:unassigned_option]
        #----------------------------------
        list_of_unassigned_tasks_for_one_member_in_one_channel(parsed, params)
      end
    #
    elsif parsed[:channel_scope] == :all_channels
      #------------------------------------
      list_of_assigned_tasks_for_one_member_in_all_channels(parsed, params)
    end

  #------------------------------
  elsif parsed[:list_scope] == :team
    #----------------------------
    if parsed[:channel_scope] == :one_channel
      #------------------------------------
      if parsed[:mentioned_member_id].nil?
        #------------------------------------
        if parsed[:assigned_option] && parsed[:unassigned_option]
          list_of_all_tasks_for_all_team_members_in_one_channel(parsed, params)

        elsif parsed[:assigned_option]
          list_of_all_assigned_tasks_for_all_team_members_in_one_channel(parsed, params)

        else # unless parsed[:unassigned_option]
          list_of_all_unassigned_tasks_for_all_team_members_in_one_channel(parsed, params)
        end

      else # unless parsed[:mentioned_member_id]
        #------------------------------------
        list_of_all_assigned_tasks_for_one_team_member_in_one_channel(parsed, params)

      end

    elsif parsed[:channel_scope] == :all_channels
      if parsed[:mentioned_member_id].nil?
        #------------------------------------
        if parsed[:assigned_option] && parsed[:unassigned_option]
          list_of_all_tasks_for_all_team_members_in_all_channels(parsed, params)

        elsif parsed[:assigned_option]
          list_of_all_assigned_tasks_for_all_team_members_in_all_channels(parsed, params)

        else # unless parsed[:unassigned_option]
          list_of_all_unassigned_tasks_for_all_team_members_in_all_channels(parsed, params)
        end

      else # unless parsed[:mentioned_member_id]

        list_of_all_assigned_tasks_for_one_team_member_in_all_channels(parsed, params)

      end
    end
  end
end

# /do list archived
#     Lists your ASSIGNED and ARCHIVED tasks for THIS channel.
# /do list archived all
#     Lists your ASSIGNED and ARCHIVED tasks for ALL channels.
# /do archive done
#     to archive my completed tasks in this channel
# /do archive done all
#     to archive all my completed tasks in all channels

#------------------ assigned tasks for mentioned member --------------------

def list_of_assigned_tasks_for_one_member_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_assigned_tasks_for_one_member_in_one_channel' if parsed[:debug]
  # For specified member in this channel.

  if parsed[:archived_option]
    # archived: ALL that have been archived.
    if parsed[:due_option]
      # due: All with a due date.
      if parsed[:open_option]
        # open: All which are not done.
        if parsed[:done_option] # , :open_option, :due_option, :archived.
          # open and done: All assigned to specified Slack member with a due date and archived.
          ListItem.where(channel_id: params[:channel_id],
                        assigned_member_id: parsed[:mentioned_member_id],
                        archived: true)
                  .where.not(assigned_due_date: nil)
                  .reorder('channel_name ASC, created_at ASC')
        else # parsed[:open_option], :due_option, :archived.
          # open: All assigned to specified Slack member with a due date, not done and archived.
          ListItem.where(channel_id: params[:channel_id],
                        assigned_member_id: parsed[:mentioned_member_id],
                        done: false, archived: true)
                  .where.not(assigned_due_date: nil)
                  .reorder('channel_name ASC, created_at ASC')
        end # if parsed[:done_option]

      elsif parsed[:done_option] # , :due_option, :archived.
        # done: All assigned to specified Slack member which are done, have a due date and are archived.
        ListItem.where(channel_id: params[:channel_id],
                       assigned_member_id: parsed[:mentioned_member_id],
                       done: true, archived: true)
                .where.not(assigned_due_date: nil)
                .reorder('channel_name ASC, created_at ASC')
      else # :due_option, :archived.
        # All assigned to specified Slack member which have a due date and are archived.
        ListItem.where(channel_id: params[:channel_id],
                       assigned_member_id: parsed[:mentioned_member_id],
                       archived: true)
                .where.not(assigned_due_date: nil)
                .reorder('channel_name ASC, created_at ASC')
      end # if parsed[:open_option]

    elsif parsed[:open_option] # , archived.

    else # :archived.
    end
else # not archived.
=begin  #
  elsif parsed[:open_option]
    # open: All which are not done.
    if parsed[:done_option] # , :open_option
      # member: All assigned to specified Slack member
      ListItem.where(channel_id: params[:channel_id],
                     assigned_member_id: parsed[:mentioned_member_id])
              .reorder('channel_name ASC, created_at ASC')
    else # parsed[:open_option]
      # open: All which are not done.
      ListItem.where(channel_id: params[:channel_id],
                     assigned_member_id: parsed[:mentioned_member_id],
                     done: false)
              .reorder('channel_name ASC, created_at ASC')
    end
  #
  elsif parsed[:done_option]
    # done: All which are done.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: true)
            .reorder('channel_name ASC, created_at ASC')
  #
  elsif parsed[:archived_option]
    # done: All which are archived.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   archived: true)
            .reorder('channel_name ASC, created_at ASC')
  else
    # member: All assigned to specified Slack member
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .reorder('channel_name ASC, created_at ASC')
  end
=end
  end
end

def list_of_assigned_tasks_for_one_member_in_all_channels(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_assigned_tasks_for_one_member_in_all_channels' if parsed[:debug]
  # For specified member in all channels clumped by channel via sorted by
  # channel name and creation date.
  if parsed[:due_option]
    # due: All with a due date.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')

  elsif parsed[:open_option]
    # open: All which are not done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: false)
            .reorder('channel_name ASC, created_at ASC')
    # ListItem.where(team_id: params[:team_id],
    #               done: false)
    #        .where("assigned_member_id = '#{parsed[:mentioned_member_id]}' " \
    #               "OR assigned_member_id = 'id.#{parsed[:mentioned_member_name]}'")
    #        .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # done: All which are done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: true)
            .reorder('channel_name ASC, created_at ASC')

  elsif parsed[:archived_option]
    # done: All which are done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   archived: true)
            .reorder('channel_name ASC, created_at ASC')
  else
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .reorder('channel_name ASC, created_at ASC')
  end
end

# --------------- all tasks for team or mentioned member -------------------

#=====================================
=begin
list_of_all_tasks_for_all_team_members_in_one_channel(parsed, params)
list_of_all_tasks_for_all_team_members_in_all_channels(parsed, params)

list_of_all_assigned_tasks_for_one_team_member_in_one_channel(parsed, params)
list_of_all_assigned_tasks_for_one_team_member_in_all_channels(parsed, params)
list_of_all_assigned_tasks_for_all_team_members_in_all_channels(parsed, params)

list_of_all_unassigned_tasks_for_all_team_members_in_one_channel(parsed, params)
list_of_all_unassigned_tasks_for_all_team_members_in_all_channels(parsed, params)


=end
#=====================================

def list_of_all_assigned_tasks_for_one_team_member_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_assigned_tasks_for_one_team_member_in_one_channel' if parsed[:debug]
  # For specified team member in this channel.
  # team: All assigned list items for this Team Channel.

  if parsed[:due_option]
    # due: All with a due date.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option] && parsed[:done_option]
    # All tasks.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All which are not done.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: false)
            .reorder('channel_name ASC, created_at ASC')
  #
  elsif parsed[:done_option]
  # done: All which are done.
  ListItem.where(channel_id: params[:channel_id],
                 assigned_member_id: parsed[:mentioned_member_id],
                 done: true)
          .reorder('channel_name ASC, created_at ASC')
  #
  elsif parsed[:archived_option]
    # archived: All which are archived.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   archived: true)
            .reorder('channel_name ASC, created_at ASC')
  else # All tasks.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_assigned_tasks_for_all_team_members_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_assigned_tasks_for_all_team_members_in_one_channel' if parsed[:debug]
  # For all team members in this channel.
  # team: All assigned list items for this Team Channel.

  if parsed[:due_option]
    # due: All assigned with a due date.
    ListItem.where(channel_id: params[:channel_id])
            .where.not(assigned_due_date: nil)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option] && parsed[:done_option]
    # All assigned tasks.
    ListItem.where(channel_id: params[:channel_id])
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All assigned which are not done.
    ListItem.where(channel_id: params[:channel_id], done: false)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All assigned which are done.
    ListItem.where(channel_id: params[:channel_id], done: true)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:archived_option]
    # open: All assigned which are archived.
    ListItem.where(channel_id: params[:channel_id], archived: true)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  else # All assigned tasks.
    ListItem.where(channel_id: params[:channel_id])
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_unassigned_tasks_for_one_member_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_unassigned_tasks_for_one_member_in_one_channel' if parsed[:debug]
  # For All unassigned list items for specified member in this channel.

  if parsed[:due_option]
    # due: All with a due date.
    if parsed[:open_option]
      # open: All which are not done.
      if parsed[:done_option] # , :open_option, :due_option
        # All unassigned in specified channel.
        ListItem.where(channel_id: params[:channel_id],
                       assigned_member_id: nil)
                .reorder('channel_name ASC, created_at ASC')
      else # parsed[:open_option], :due_option
        # open: All which are not done.
        ListItem.where(channel_id: params[:channel_id],
                       assigned_member_id: nil,
                       done: false)
                .where.not(assigned_due_date: nil)
                .reorder('channel_name ASC, created_at ASC')
      end
    else # parsed[:done_option], :due_option
      # done: All which are done.
      ListItem.where(channel_id: params[:channel_id],
                     assigned_member_id: nil,
                     done: true)
              .where.not(assigned_due_date: nil)
              .reorder('channel_name ASC, created_at ASC')
    end
  #
  elsif parsed[:open_option]
    # open: All which are not done.
    if parsed[:done_option] # , :open_option
      # All for specified channel.
      ListItem.where(channel_id: params[:channel_id],
                     assigned_member_id: nil)
              .reorder('channel_name ASC, created_at ASC')
    else # parsed[:open_option]
      # open: All which are not done.
      ListItem.where(channel_id: params[:channel_id],
                     assigned_member_id: nil,
                     done: false)
              .reorder('channel_name ASC, created_at ASC')
    end
  #
  elsif parsed[:done_option]
    # done: All which are done.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: nil,
                   done: true)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:archived_option]
    # archived: All which are archived.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: nil,
                   archived: true)
            .reorder('channel_name ASC, created_at ASC')
  else
    # All in specified channel.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_unassigned_tasks_for_all_team_members_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_unassigned_tasks_for_all_team_members_in_one_channel' if parsed[:debug]
  # For all team members in this channel.
  # team: All unassigned list items for this Team Channel.

  if parsed[:due_option]
    # due: All unassigned with a due date.
    ListItem.where(channel_id: params[:channel_id])
            .where.not(assigned_due_date: nil)
            .where(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option] && parsed[:done_option]
    # All unassigned tasks.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All unassigned which are not done.
    ListItem.where(channel_id: params[:channel_id],
                   done: false, assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All unassigned which are done.
    ListItem.where(channel_id: params[:channel_id],
                   done: true, assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:archived_option]
    # archived: All unassigned which are archived.
    ListItem.where(channel_id: params[:channel_id],
                   archived: true, assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  else # All unassigned tasks.
    ListItem.where(channel_id: params[:channel_id],
                   assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_assigned_tasks_for_all_team_members_in_all_channels(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_assigned_tasks_for_all_team_members_in_all_channels(parsed, params)' if parsed[:debug]
  # For all team members with assigned tasks in all channels clumped by
  # channel name and creation date.

  if parsed[:due_option]
    # due: All with a due date.
    ListItem.where(team_id: params[:team_id])
            .where.not(assigned_due_date: nil)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option] && parsed[:done_option]
    # open and done: All tasks.
    ListItem.where(team_id: params[:team_id])
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All which are not done.
    ListItem.where(team_id: params[:team_id],
                   done: false)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All which are done.
    ListItem.where(team_id: params[:team_id],
                   done: true)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:archived_option]
    # open: All which are archived.
    ListItem.where(team_id: params[:team_id],
                   archived: true)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  else # All tasks.
    ListItem.where(team_id: params[:team_id])
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_tasks_for_all_team_members_in_one_channel(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_tasks_for_all_team_members_in_one_channel' if parsed[:debug]
  # For all team members in this channel.
  # team: All list items for this Team Channel.

  if parsed[:due_option]
    # due: All with a due date.
    ListItem.where(channel_id: params[:channel_id])
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option] && parsed[:done_option]
    # All tasks.
    ListItem.where(channel_id: params[:channel_id])
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All which are not done.
    ListItem.where(channel_id: params[:channel_id], done: false)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All which are done.
    ListItem.where(channel_id: params[:channel_id], done: true)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:archived_option]
    # archived: All which are archived.
    ListItem.where(channel_id: params[:channel_id], archived: true)
            .reorder('channel_name ASC, created_at ASC')
  else # All tasks.
    ListItem.where(channel_id: params[:channel_id])
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_assigned_tasks_for_one_team_member_in_all_channels(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_assigned_tasks_for_one_team_member_in_all_channels' if parsed[:debug]
  # For specified team member in all channels clumped by channel via sorted
  # by channel name and creation date.

  if parsed[:due_option]
    # due: All with a due date.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_member_id: nil)
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option] && parsed[:done_option]
    # All tasks.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All which are not done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: false)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All which are done.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   done: true)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:archived_option]
    # archived: All which are archived.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id],
                   archived: true)
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  else # All tasks.
    ListItem.where(team_id: params[:team_id],
                   assigned_member_id: parsed[:mentioned_member_id])
            .where.not(assigned_member_id: nil)
            .reorder('channel_name ASC, created_at ASC')
  end
end

def list_of_all_tasks_for_all_team_members_in_all_channels(parsed, params)
  parsed[:list_query_trace_info] = 'list_of_all_tasks_for_all_team_members_in_all_channels' if parsed[:debug]
  # For ALL team members in ALL channels clumped by channel via sorted by
  # channel name and creation date.

  if parsed[:due_option]
    # due: All with a due date.
    ListItem.where(team_id: params[:team_id])
            .where.not(assigned_due_date: nil)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option] && parsed[:done_option]
    # open and done: All tasks.
    ListItem.where(team_id: params[:team_id])
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:open_option]
    # open: All which are not done.
    ListItem.where(team_id: params[:team_id],
                   done: false)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:done_option]
    # open: All which are done.
    ListItem.where(team_id: params[:team_id],
                   done: true)
            .reorder('channel_name ASC, created_at ASC')
  elsif parsed[:archived_option]
    # archived: All which are archived.
    ListItem.where(team_id: params[:team_id],
                   archived: true)
            .reorder('channel_name ASC, created_at ASC')
  else # All tasks.
    ListItem.where(team_id: params[:team_id])
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
