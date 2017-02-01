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

  parsed[:list_query_trace_info] = 'yylist_of_??' if parsed[:debug]
  where_clause = {}
  where_not_clause = {}
  # No sort options currently.
  reorder_string = 'channel_name ASC, created_at ASC'

  # 0) All queries are limited to the user's team.
  where_clause[:team_id] = params[:team_id]

  # 0.1) :unassigned_option overrides :list_scope == :one_member
  parsed[:list_scope] = :team if parsed[:unassigned_option]

  # 1) if parsed[:list_scope] == :one_member
  where_clause[:assigned_member_id] = parsed[:mentioned_member_id] if parsed[:list_scope] == :one_member

  # 2) if parsed[:list_scope] == :team
  # no further constraints (we are already filtering by :team_id)

  # 3) if parsed[:channel_scope] == :one_channel
  where_clause[:channel_id] = params[:channel_id] if parsed[:channel_scope] == :one_channel

  # 4) if parsed[:channel_scope] == :all_channels
  # no further constraints (we are not filtering by :channel_id)

  # 5) if parsed[:assigned_option]
  #    a) if parsed[:list_scope] == :one_member
  #       err: overriden (this is a contradiction: we are already filtering by :mentioned_member_id)
  #    b) if parsed[:list_scope] == :team
  where_not_clause[:assigned_member_id] = nil if parsed[:assigned_option] &&
                                                 !parsed[:unassigned_option] &&
                                                 parsed[:list_scope] == :team

  # 6) if parsed[:unassigned_option]
  #    a) if parsed[:list_scope] == :one_member
  #       err: overridden (this is a contradiction: we are already filtering by :mentioned_member_id)
  #    b) if parsed[:list_scope] == :team
  where_clause[:assigned_member_id] = nil if parsed[:unassigned_option] &&
                                             !parsed[:assigned_option] &&
                                             parsed[:list_scope] == :team

  # 7) if parsed[:due_option]
  where_not_clause[:assigned_due_date] = nil if parsed[:due_option]

  # 8) if parsed[:open_option]
  where_clause[:done] = false if parsed[:open_option] && !parsed[:done_option]

  # 9) if parsed[:done_option]
  where_clause[:done] = true if parsed[:done_option] && !parsed[:open_option]

  # 10) if parsed[:archived_option]
  where_clause[:archived] = true if parsed[:archived_option]

  # 11) if not parsed[:archived_option]
  where_clause[:archived] = false unless parsed[:archived_option]

# HACK:
#  if parsed[:debug]
    # 'list_of_assigned_open_tasks_for_one_member_in_one_channel'
    parsed[:list_query_trace_info] = 'xxlist_of'

    parsed[:list_query_trace_info].concat('_unassigned') if where_clause.key?(:assigned_member_id) &&
                                                            where_clause[:assigned_member_id].nil?
    parsed[:list_query_trace_info].concat('_assigned')   if where_not_clause.key?(:assigned_member_id) &&
                                                            where_not_clause[:assigned_member_id].nil?

    parsed[:list_query_trace_info].concat('_assigned')   if where_clause.key?(:assigned_member_id)

    parsed[:list_query_trace_info].concat('_done')       if where_clause.key?(:done) &&
                                                            where_clause[:done]
    parsed[:list_query_trace_info].concat('_open')       if where_clause.key?(:done) &&
                                                            !where_clause[:done]

    parsed[:list_query_trace_info].concat('_archived')   if where_clause.key?(:archived) &&
                                                            where_clause[:archived]

    parsed[:list_query_trace_info].concat('_tasks')

    parsed[:list_query_trace_info].concat('_for_one_member')  if where_clause.key?(:assigned_member_id)
    parsed[:list_query_trace_info].concat('_for_all_members') unless where_clause.key?(:assigned_member_id)


    parsed[:list_query_trace_info].concat('_in_one_channel') if where_clause.key?(:channel_id)
    parsed[:list_query_trace_info].concat('_in_all_channels') unless where_clause.key?(:channel_id)

    parsed[:list_query_trace_info].concat(
      "\nListItem.where(#{where_clause})\n" \
      "        .where.not(#{where_not_clause})\n" \
      "        .reorder(#{reorder_string})\n")
    puts "\n#{parsed[:list_query_trace_info]}\n\n"
#  end

# NOTE: HACK: fixup for debug.
  items =
    ListItem.where(where_clause)
            .where.not(where_not_clause)
            .reorder(reorder_string)
  items = [] if items.nil?
  items
end

def list_from_list_of_ids(parsed, array_of_ids)
  parsed[:list_query_trace_info] = "list_from_list_of_ids(input ids: #{array_of_ids.to_s})" if parsed[:debug]
  ListItem.where(id: array_of_ids).reorder('channel_name ASC, created_at ASC')
end

def ids_from_parsed(parsed)
  records = list_from_parsed(parsed)
  parsed[:list_query_trace_info].concat("\nids_from_parsed(returned: [] )\n") if parsed[:debug]
  return [] unless parsed[:err_msg].empty?
  return [] if records.empty?
  ids = []
  records.each do |item|
    ids << item.id
  end
  parsed[:list_query_trace_info].concat("\nids_from_parsed(returned: #{ids.to_s})\n") if parsed[:debug]
  ids
end
