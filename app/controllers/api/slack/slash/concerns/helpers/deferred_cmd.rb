# /raydo delete 1 does not update taskbot channel?
# return options[:parsed][:tcb][:after_action_parse_hash]['func'] == 'list' &&
#       team_option && open_option && done_option &&
#       options[:parsed][:first_button_value][:id] == 'done'

def after_action_deferred_logic(def_cmds)
  if def_cmds[0][:p_hash][:expedite_deferred_cmd]
    send_after_action_deferred_cmds(def_cmds)
  else
    # Thread.new do
      send_after_action_deferred_cmds(def_cmds)
    # end
  end
end

def new_member_deferred_logic(options)
  Thread.new do
    update_all_team_members_hash(options)
  end
end

CMD_FUNCS_IGNORED_BY_AFTER_ACTION_DEFERRED =
  [:discuss, :feedback, :hints, :help, :last_action_list, :list,
   :taskbot_rpts].freeze
#
# if a member's taskbot lists could be changed, then we need to update em.
# Returns: [ deferred_cmd{} ]
def generate_after_action_cmds(options)
  parsed = options[:parsed_hash]
  return nil if CMD_FUNCS_IGNORED_BY_AFTER_ACTION_DEFERRED.include?(parsed[:func])
  return nil if parsed[:func] == :add && parsed[:assigned_member_id].nil?

  impacted_task = {}
  # Optional logic for here or to defer to background thread.
  #   impacted_task = {} means we did not look OR commented out the method call.
  #   impacted_task = nil means we looked up task and we won't process it or it
  #                   doesn't require the taskbot list be updated.
  #   impacted_task = ListItem record means we have an updated task to process
  #                   that may require the taskbot list to be updated.
  return nil if !parsed[:func] == :add && (impacted_task = taskbot_list_item(parsed)).nil?
  # d = Deferred.new
  [{ func: parsed[:func],
     # def_obj: d,
     p_hash: parsed,
     impacted_task: impacted_task
  }]
end

# Note: url_params and parsed[:ccb] is the context of the member issuing the
# slash cmd.
# The chat_msgs{} contains the context of the member receiving the
# msg, one hash per member, different member record, taskbot channel record.

DEFERRED_EVENT_CMD_FUNCS = [:message_event, :picklist].freeze
# Route deferred command to proper handler.
# Returns: nothing. Cmd will send msgs, etc.
def send_after_action_deferred_cmds(cmds)
  cmds.each do |d_hash|
    parsed = d_hash[:p_hash]
    send_deferred_event_cmds(d_hash, parsed) if DEFERRED_EVENT_CMD_FUNCS.include?(parsed[:func])
    send_deferred_list_cmds(d_hash, parsed) unless DEFERRED_EVENT_CMD_FUNCS.include?(parsed[:func])
  end
end

# 1) generate list commands array.
# 2) clear taskbot channel of task lists to be replaced. or replace em?
# 3) generate new task lists.
# 4) post new lists into taskbot channel.
# Returns: nothing. Cmd will send msgs, etc.
def send_deferred_list_cmds(d_hash, parsed)
  #----------------------
  parsed[:am_hash_source] = :member_record
  #----------------------
  list_cmds = generate_list_commands(parsed, d_hash)
  chat_msgs = generate_task_list_msgs(parsed, list_cmds)
  chat_msgs.each do |msg|
    update_taskbot_channel(
      edit_taskbot_msg: msg[:edit_taskbot_msg],
      api_client_type: msg[:api_client_type],
      taskbot_username: msg[:taskbot_username],
      taskbot_channel_id: msg[:taskbot_channel_id],
      taskbot_user_id: msg[:taskbot_user_id],
      slack_user_api_token: msg[:slack_user_api_token],
      taskbot_api_token: msg[:taskbot_api_token],
      taskbot_msg_id: msg[:taskbot_msg_id],
      taskbot_msgs: msg[:taskbot_msgs],
      taskbot_list_scope: msg[:list_scope],
      member_name: msg[:member_name],
      member_id: msg[:member_id],
      member_mcb: msg[:member_mcb],
      member_tcb: msg[:member_tcb],
      text: msg[:text],
      attachments: msg[:attachments],
      after_action_list_context: msg[:after_action_list_context],
      p_hash: d_hash[:p_hash]
    )
  end
end

# Returns: [ list_cmd{} ]
def generate_list_commands(parsed, deferred_cmd)
  # return [] if parsed[:func] == :done && parsed[:button_actions].any? && parsed[:button_actions].first['name'] == 'done'
  list_cmds = []
  determine_impacted_members(parsed, deferred_cmd).each do |i_item|
    # impacted_member = ['id string', {impacted_member_hash}
    next unless i_item.respond_to?(:to_hash)
    type = 'rpts'
    # Edit msg, not list if clicking on taskbot Done button.
    type = 'edit msg' if parsed[:func] == :done &&
                         parsed[:button_actions].any? &&
                         (parsed[:button_actions].first['name'] == 'done' ||
                          parsed[:button_actions].first['name'] == 'done and delete')
    list_cmds <<
      { type: type,
        member_name: i_item[:name],
        member_id: i_item[:id],
        member_mcb: i_item[:member_mcb],
        member_tcb: i_item[:member_tcb],
        slack_user_api_token: i_item[:slack_user_api_token],
        taskbot_api_token: i_item[:taskbot_api_token],
        taskbot_channel_id: i_item[:taskbot_channel_id],
        taskbot_user_id: i_item[:taskbot_user_id],
        taskbot_msg_id: i_item[:taskbot_msg_id],
        taskbot_msgs: i_item[:taskbot_msgs],
        taskbot_list_scope: i_item[:taskbot_list_scope],
        taskbot_username: 'MiaDo Taskbot'
      }
  end
  list_cmds
end

# ccb.members_hash:
# "ray"=>
#   { "slack_user_id"=>"U0VLZ5P51",
#     "slack_real_name"=>"Ray Novarina",
#     "slack_user_name"=>"ray",
#     "slack_user_api_token"=>"xoxp-29753209748-29713193171-43134216116-f423bbc4f9",
#     "bot_dm_channel_id"=>"D18E3GH2P"
#     "bot_user_id"=>"U18F7T2H2",
#     "bot_api_token"=>"xoxb-42517920580-GoqqNNgcoPDH1DruSQtDef7p",
#   }
# "U0VLZ5P51"=>
#   { "slack_user_id"=>"U0VLZ5P51",
#     "slack_real_name"=>"Ray Novarina",
#     "slack_user_name"=>"ray",
#     "bot_dm_channel_id"=>"D18E3GH2P"
#   }

# if a member's taskbot lists could be changed, then we need to update em.

# If add and [parsed[:assigned_member_id], update assigned_member_id's list dm.

# If delete: task has been deleted. Need to get impacted_member info from
#    parsed[:list_action_item_info]

# If append tasknum and the task[tasknum] being appended has an
#    assigned_member_id, update that assigned_member_id's list dm.
# If slash cmd done, same as for append.
# If taskbot button done: user is looking at list. If the user's task, then
#    update the user's/assigned_member_id's list dm. If someone else's task,
#    then update both someone else's list dm and the user's list dm.

# If due, same as for append.

# If assign, always update the assigned_member_id's list dm.
# If unassign, same as assign.

# If redo tasknum, same as for add for new command and same as for delete for
# the task being deleted.
#-------------------------------------------------------------------------
# Note: deferred_cmd[:impacted_task] is optional logic for here or has already
# been done.
#   {} means we did not look OR commented out the method call.
#   ListItem record means we have an updated task to process
#     that may require the taskbot list to be updated.

# Returns: [ impacted_member_id, impacted_member{} ]
def determine_impacted_members(parsed, deferred_cmd)
  func = parsed[:func]
  # Init our trace info. Gets updated and written to disk if needed.
  parsed[:ccb].taskbot_msg_to_slack_id = nil
  # redo and taskbot button done are such special cases, it is easier to handle
  # them specially.
  return build_redo_impacted_members(parsed) if func == :redo
  impacted_task = deferred_cmd[:impacted_task] unless deferred_cmd[:impacted_task] == {}
  impacted_task = taskbot_list_item(parsed) if deferred_cmd[:impacted_task] == {}
  am_hash = am_hash_from_assigned_member_id(parsed, parsed[:assigned_member_id]) if impacted_task.nil?
  am_hash = am_hash_from_assigned_member_id(parsed, impacted_task[:assigned_member_id]) unless impacted_task.nil?
  # nil if MiaDo not installed by this member.
  update_ccb_chan_taskbot_msg_info(
    { 'error' => 'Task not impacted: determine_impacted_members().MiaDo not installed by this member.' },
    p_hash: { ccb: parsed[:ccb] }) if am_hash['bot_dm_channel_id'].nil?
  update_ccb_chan_taskbot_msg_info(
    { 'error' => "Task not impacted: determine_impacted_members().assigned_member = #{impacted_task.nil? ? parsed[:assigned_member_id] : impacted_task[:assigned_member_id]}" },
    p_hash: { ccb: parsed[:ccb] }) if am_hash.nil?
  return [] if am_hash.nil? || am_hash['bot_dm_channel_id'].nil?
  case func
  when :add, :assign, :unassign
    return build_impacted_team_members(parsed, am_hash)
  when :append, :done, :due
    update_ccb_chan_taskbot_msg_info(
      { 'error' => 'Task not impacted: determine_impacted_members().:append, :done, :due - impacted_task.nil?' },
      p_hash: { ccb: parsed[:ccb] }) if impacted_task.nil?
    return [] if impacted_task.nil?
    return build_taskbot_button_done_impacted_members(parsed, am_hash) if parsed[:button_actions].any?
    return build_impacted_team_members(parsed, am_hash)
  when :delete
    # delete command has already deleted the impacted task.
    return build_many_impacted_members_for_deleted_tasks(parsed) if parsed[:list_action_item_info].size > 1
    update_ccb_chan_taskbot_msg_info(
      { 'error' => 'Task not impacted: determine_impacted_members().:delete - impacted_task[:done]' },
      p_hash: { ccb: parsed[:ccb] }) if impacted_task[:done]
    return [] if impacted_task[:done]
    return build_impacted_team_members(parsed, am_hash)
  when :reset
    # reset taskbot channel. Regenerate the default reports for @me.
    # Reset: Erase ALL taskbot channel msgs.
    #       Reset message tracking (Member.bot_msgs_json to nil).
    #       Display 'Your To-Do's list'. This will:
    #               Restore channel buttons.  Track one msg.
    #               Set channel and member activity fields to 'list'
    update_member_record_activity(parsed[:mcb], 'reset', {})
    am_hash['mcb'] = parsed[:mcb]
    # Flow 2: Deletes all msgs in bot dm channel.
    #         requires chat:write:bot scope.
    # def update_via_rtm_data(options)
    #  options[:message_source] = :rtm_data
    #  options[:bot_api_token] = options[:p_hash][:ccb].bot_api_token
    #  clear_taskbot_msg_channel(options)
    #  api_resp = send_msg_to_taskbot_channel(options)
    #  update_ccb_chan_taskbot_msg_info(api_resp, options)
    #  api_resp
    # end
    # clear_taskbot_msg_channel(
    #  message_source: :rtm_data,
    #  bot_api_token: parsed[:ccb].bot_api_token)
    # NOTE: our clear_taskbot_msg_channel method will delete msgs from fresh
    # rtm_start msgs because func = :reset
    return build_one_impacted_member(am_hash: am_hash)
  end
  []
end

#   impacted_task{} = nil means we looked up task and we won't process it or it
#                   doesn't require the taskbot list be updated.
#   impacted_task{} = ListItem record info means we have an updated task to
#                   process that may require the taskbot list to be updated.
CMD_FUNCS_IGNORED_IF_TASK_HAS_NO_ASSIGNED_MEMBER = [:append, :done, :due].freeze
# CMD_FUNCS_WE_ALWAYS_GET_impacted_task_FOR = [:assign, :unassign].freeze
# Returns: impacted_task{}
def taskbot_list_item(parsed)
  return impacted_task_if_no_assigned_member(parsed) if CMD_FUNCS_IGNORED_IF_TASK_HAS_NO_ASSIGNED_MEMBER.include?(parsed[:func])
  # add, assign and unassign commands include the name of the impacted member,
  # don't need to ask db. delete and redo commands have already deleted the
  # impacted task.
  return parsed[:list_action_item_info][0] if parsed[:func] == :delete ||
                                              parsed[:func] == :done ||
                                              parsed[:func] == :redo
  nil
end

#   impacted_task{} = nil means we looked up task and we won't process it or it
#                   doesn't require the taskbot list be updated.
#   impacted_task{} = ListItem record info means we have an updated task to
#                   process that may require the taskbot list to be updated.
# Returns: impacted_task{}
def impacted_task_if_no_assigned_member(parsed)
  return impacted_task_if_taskbot_done(parsed) if parsed[:button_actions].any? &&
                                                  (parsed[:button_actions].first['name'] == 'done and delete' ||
                                                   parsed[:button_actions].first['name'] == 'done')
  task = ListItem.where(id: parsed[:list][parsed[:task_num] - 1]).first
  unless task.nil?
    return nil if parsed[:func] == :redo && parsed[:assigned_member_id].nil? &&
                  task.assigned_member_id.nil?
    return nil if task.assigned_member_id.nil?
    return { db_id: task.id, assigned_member_id: task.assigned_member_id }
  end
  nil
end

# Taskbot channel done_and_delete button command has already deleted the
# impacted task.
def impacted_task_if_taskbot_done(parsed)
  impacted_task = parsed[:list_action_item_info][0]
  return impacted_task unless impacted_task[:assigned_member_id].nil?
  # Only refresh the taskbot report for the user looking at a All Tasks rpt.
  impacted_task[:assigned_member_id] = parsed[:url_params]['user_id']
  impacted_task
end

# Returns: am_hash{}
def am_hash_from_assigned_member_id(parsed, assigned_member_id)
  return nil if assigned_member_id.nil?
  return am_hash_from_member_record(parsed: parsed,
                                    slack_user_id: assigned_member_id,
                                    slack_team_id: parsed[:url_params]['team_id']
                                   ) if parsed[:am_hash_source] == :member_record
  parsed[:ccb].members_hash[assigned_member_id]
end

# Inputs: options hash { slack_user_id:, slack_team_id:, mcb:, tcb: }
# Returns: am_hash{}
def am_hash_from_member_record(options)
  if options.key?(:mcb) && options[:mcb].slack_user_id == options[:slack_user_id]
    mcb = options[:mcb]
  else
    mcb = Member.find_from(
      source: :slack,
      slack_team_id: options[:slack_team_id],
      slack_user_id: options[:slack_user_id])
    return nil if mcb.nil?
  end
  if options.key?(:tcb) && (options[:tcb].slack_channel_id == mcb.bot_dm_channel_id)
    tcb = options[:tcb]
  else
    # tcb = find_or_create_taskbot_channel(mcb: mcb) unless options.key?(:tcb) && (options[:tcb].slack_channel_id == mcb.bot_dm_channel_id)
    tcb = Channel.find_taskbot_channel_from(
      source: :slack,
      slash_url_params: { 'user_id' => options[:slack_user_id],
                          'team_id' => options[:slack_team_id]
                        })
  end
  list_scope = nil
  list_scope = tcb.after_action_parse_hash['list_scope'] if tcb && tcb.after_action_parse_hash &&
                                                            tcb.after_action_parse_hash.key?('list_scope') &&
                                                            (tcb.last_activity_type == 'msg_update - taskbot_msgs' ||
                                                             tcb.last_activity_type == 'button_action - list')
  list_scope = 'empty' if mcb.bot_msgs_json.nil? || mcb.bot_msgs_json.empty?
  # HACK: we can't be sure what is in the channel unless we monitor message
  # events. User can delete all messages.
  list_scope = 'team' if list_scope.nil?
  # Special case: if resetting taskbot channel, default to 'Your To-Do's' list
  list_scope = 'one_member' if options[:parsed][:func] == :reset
  { 'mcb' => mcb,
    'tcb' => tcb,
    'bot_dm_channel_id' => mcb.bot_dm_channel_id,
    'slack_user_name' => mcb.slack_user_name,
    'slack_user_id' => mcb.slack_user_id,
    'slack_user_api_token' => mcb.slack_user_api_token,
    'bot_api_token' => mcb.bot_api_token,
    'bot_user_id' => mcb.bot_user_id,
    'bot_msgs' => mcb.bot_msgs_json,
    'taskbot_list_scope' => list_scope
  }
end

# Inputs: am_hash, OPTIONAL: parsed
# Returns: [ impacted_member_id, impacted_member{} ]
def build_one_impacted_member(options)
  impacted_member =
    { name: options[:parsed][:assigned_member_name],
      id: options[:parsed][:assigned_member_id] } if options.key?(:parsed)
  impacted_member =
    { name: options[:am_hash]['slack_user_name'],
      id: options[:am_hash]['slack_user_id'] } unless options.key?(:parsed)

  # skip if user member does not have a taskbot list being displayed.
  update_ccb_chan_taskbot_msg_info(
    { 'error' => 'Task not impacted: build_one_impacted_member().Member(' \
      "#{impacted_member[:name]}) does not have a taskbot list being displayed."
    }, p_hash: { ccb: options[:parsed][:ccb] }) if options[:am_hash]['taskbot_list_scope'].nil?
  return [] if options[:am_hash]['taskbot_list_scope'].nil?

  impacted_member[:member_mcb] = options[:am_hash]['mcb']
  impacted_member[:member_tcb] = options[:am_hash]['tcb']
  impacted_member[:slack_user_api_token] = options[:am_hash]['slack_user_api_token']
  impacted_member[:taskbot_api_token] = options[:am_hash]['bot_api_token']
  impacted_member[:taskbot_channel_id] = options[:am_hash]['bot_dm_channel_id']
  impacted_member[:taskbot_user_id] = options[:am_hash]['bot_user_id']
  impacted_member[:taskbot_msg_id] = options[:am_hash]['bot_msg_id']
  impacted_member[:taskbot_msgs] = options[:am_hash]['bot_msgs']
  impacted_member[:taskbot_list_scope] = options[:am_hash]['taskbot_list_scope']
  [impacted_member[:id], impacted_member]
end

# If a team member with a taskbot channel is looking at a list then update the
# member's taskbot list dm.
# Returns: [ impacted_member_id, impacted_member{} ]
def build_impacted_team_members(parsed, task_am_hash)
  taskbot_trace_msg = ''
  impacted_members = []
  Member.team_members(slack_team_id: parsed[:ccb].slack_team_id).each do |member|
    am_hash = am_hash_from_member_record(
      parsed: parsed,
      mcb: member,
      slack_user_id: member.slack_user_id,
      slack_team_id: member.slack_team_id)
    # skip if MiaDo not installed by this member.
    taskbot_trace_msg.concat(
      "Member.DbId:#{member.id}(#{member.slack_user_name}) has not installed " \
      'MiaDo') if am_hash.nil? || am_hash['bot_dm_channel_id'].nil?
    next if am_hash.nil? ||
            am_hash['bot_dm_channel_id'].nil?
    # Always generate reports if taskbot channel has no message displayed.
    unless am_hash['taskbot_list_scope'] == 'empty'
      # skip if user member does not have a taskbot list being displayed.
      taskbot_trace_msg.concat(
        "Member.DbId:#{member.id}(#{member.slack_user_name}) does not have a " \
        'taskbot list being displayed.') if am_hash['taskbot_list_scope'].nil?
      next if am_hash['taskbot_list_scope'].nil?
      # skip if impacted task is not on this member's displayed taskbot list.
      taskbot_trace_msg.concat(
        "Member.DbId:#{member.id}(#{member.slack_user_name}) impacted task " \
        'is not on this member\'s displayed taskbot ' \
        'list.') unless am_hash['taskbot_list_scope'] == 'team' || am_hash['taskbot_list_scope'] == 'empty' || (am_hash['slack_user_id'] == task_am_hash['slack_user_id'])
      next unless am_hash['taskbot_list_scope'] == 'team' ||
                  am_hash['slack_user_id'] == task_am_hash['slack_user_id']
    end
    impacted_member_id, impacted_member = build_one_impacted_member(am_hash: am_hash)
    impacted_members << impacted_member_id
    impacted_members << impacted_member
  end
  update_ccb_chan_taskbot_msg_info(
    { 'error' => "Task not impacted: build_impacted_team_members().#{taskbot_trace_msg}" },
    p_hash: { ccb: parsed[:ccb] }) unless taskbot_trace_msg.empty?
  impacted_members
end

# If taskbot button done: user is looking at list. If the user's task, then
#    update the user's/assigned_member_id's list dm. If someone else's task,
#    then update both someone else's list dm and the user's list dm.
# Returns: [ impacted_member_id, impacted_member{} ]
def build_taskbot_button_done_impacted_members(parsed, done_task_am_hash)
  # 1) the owner of the done task is impacted.
  impacted_members = build_one_impacted_member(am_hash: done_task_am_hash)
  return impacted_members if parsed[:url_params][:user_id] == done_task_am_hash['slack_user_id']
  # 2) the user clicking the done button is also impacted if not the owner of the done task.
  taskbot_user_hash = am_hash_from_assigned_member_id(parsed, parsed[:url_params][:user_id])
  impacted_member_id, impacted_member = build_one_impacted_member(am_hash: taskbot_user_hash)
  impacted_members << impacted_member_id
  impacted_members << impacted_member
  impacted_members
end

# Returns: [ impacted_member_id, impacted_member{} ]
def build_many_impacted_members_for_deleted_tasks(parsed)
  taskbot_trace_msg = ''
  impacted_members = []
  parsed[:list_action_item_info].each do |task_info|
    am_hash = am_hash_from_assigned_member_id(parsed, task_info[:assigned_member_id])
    taskbot_trace_msg.concat(
      "Member.SlackId:#{task_info[:assigned_member_id]} we already saw " \
      'this member or member is not looking at taskbot list.') if am_hash.nil? || impacted_members.include?(am_hash['slack_user_id']) || am_hash['taskbot_list_scope'].nil?
    # skip if we already saw this member or member is not looking at taskbot list
    next if am_hash.nil? ||
            impacted_members.include?(am_hash['slack_user_id']) ||
            am_hash['taskbot_list_scope'].nil?
    impacted_member_id, impacted_member = build_one_impacted_member(am_hash: am_hash)
    impacted_members << impacted_member_id
    impacted_members << impacted_member
  end
  update_ccb_chan_taskbot_msg_info(
    { 'error' => "Task not impacted: build_many_impacted_members_for_deleted_tasks().#{taskbot_trace_msg}" },
    p_hash: { ccb: parsed[:ccb] }) unless taskbot_trace_msg.empty?
  impacted_members
end

# same as for add for new command and same as for delete for
# the task being deleted. So the delete could impact one member and the
# add could impact another.
# Returns: [ impacted_member_id, impacted_member{} ]
def build_redo_impacted_members(parsed)
  deleted_member_id = parsed[:list_action_item_info][0][:assigned_member_id]
  added_member_id = parsed[:assigned_member_id]
  update_ccb_chan_taskbot_msg_info(
    { 'error' => 'Task not impacted: build_redo_impacted_members().no assigned member' },
    p_hash: { ccb: parsed[:ccb] }) if deleted_member_id.nil? && added_member_id.nil?
  return [] if deleted_member_id.nil? && added_member_id.nil?
  return build_redo_both_tasks(parsed) unless deleted_member_id.nil? ||
                                              added_member_id.nil?
  return build_redo_only_deleted_task(parsed) unless deleted_member_id.nil?
  build_redo_only_added_task(parsed)
end

def build_redo_both_tasks(parsed)
  deleted_task_member = build_many_impacted_members_for_deleted_tasks(parsed)
  # Now the add task. Don't generate dup msgs.
  added_task_hash = am_hash_from_assigned_member_id(parsed, parsed[:assigned_member_id])
  return deleted_task_member if deleted_task_member.include?(added_task_hash['slack_user_id'])
  # Add task member is different from deleted task member. Both are impacted.
  added_task_member_id, added_task_member = build_one_impacted_member(parsed: parsed, am_hash: added_task_hash)
  impacted_members = deleted_task_member
  impacted_members << added_task_member_id
  impacted_members << added_task_member
end

def build_redo_only_deleted_task(parsed)
  # parsed[:list_action_item_info] = the task that was deleted.
  build_many_impacted_members_for_deleted_tasks(parsed)
end

def build_redo_only_added_task(parsed)
  added_task_hash = am_hash_from_assigned_member_id(parsed, parsed[:assigned_member_id])
  build_one_impacted_member(parsed: parsed, am_hash: added_task_hash)
end

# Returns: [ chat_msg{} ]
def generate_task_list_msgs(parsed, list_cmds)
  chat_msgs = []
  list_cmds.each do |cmd_hash|
    chat_msgs << { as_user: false,
                   api_client_type: :user,
                   member_mcb: cmd_hash[:member_mcb],
                   member_tcb: cmd_hash[:member_tcb],
                   slack_user_api_token: cmd_hash[:slack_user_api_token],
                   taskbot_api_token: cmd_hash[:taskbot_api_token],
                   taskbot_channel_id: cmd_hash[:taskbot_channel_id],
                   taskbot_user_id: cmd_hash[:taskbot_user_id],
                   taskbot_msg_id: cmd_hash[:taskbot_msg_id],
                   taskbot_username: cmd_hash[:taskbot_username],
                   taskbot_msgs: cmd_hash[:taskbot_msgs],
                   taskbot_list_scope: cmd_hash[:taskbot_list_scope],
                   member_name: cmd_hash[:member_name],
                   member_id: cmd_hash[:member_id],
                   # api_client_bot: make_web_client(cmd_hash[:taskbot_api_token])
                   api_client_user: make_web_client(cmd_hash[:slack_user_api_token])
                 }
    if cmd_hash[:type] == 'edit msg'
      chat_msgs.last[:edit_taskbot_msg] = true
    else
      chat_msgs.last[:member_tcb] ||= find_or_create_taskbot_channel(mcb: chat_msgs.last[:member_mcb])
      text, attachments = taskbot_rpts(parsed, chat_msgs.last)
      text = "`MiaDo ERROR: #{parsed[:err_msg]}`" unless parsed[:err_msg].empty?
      chat_msgs.last[:edit_taskbot_msg] = false
      chat_msgs.last[:text] = text
      chat_msgs.last[:attachments] = attachments
    end
  end
  chat_msgs
end

# Inputs: parsed, chat_msg{} from generate_task_list_msgs()
# Returns: [text, attachments, options, list_cmd_after_action_list_context]
#          parsed[:err_msg] if needed.
#-----------------------------------
# Generate a variety of lists/reports formatted for the taskbot channel.
# Example:
#   Member john:
#   >list team
#   >assign 1 @jane
# John sends a taskbot msg to Jane's channel AS IF Jane executed the '/do list'
# commands in her taskbot channel.
#
# Note: We simulate the case of these reports, i.e. list cmds,  being run on
# the taskbot channel of the impacted member, i.e. cmd_hash[:member_tcb]
# url_params and parsed[:ccb] is the context of the member issuing the slash cmd.
# context is the parsed{} for the list command/report we want.
# After the list command is run on the taskbot channel, its
# Channel.after_action_parse_hash is updated via the list command.
def taskbot_rpts(parsed, chat_msg)
  list_cmd = "list_taskbot @#{chat_msg[:member_name]} all due_first" if chat_msg[:taskbot_list_scope] == 'one_member' ||
                                                                        chat_msg[:taskbot_list_scope] == 'empty' ||
                                                                        chat_msg[:taskbot_list_scope].nil?
  list_cmd = 'list_taskbot team all due_first' if chat_msg[:taskbot_list_scope] == 'team'
  list_cmd = 'list_taskbot team all assigned unassigned open done' if chat_msg[:taskbot_list_scope] == 'all'
  url_params = {
    channel_id: chat_msg[:member_tcb].slack_channel_id,
    channel_name: chat_msg[:member_tcb].slack_channel_name,
    response_url: parsed[:url_params][:response_url],
    team_domain: parsed[:url_params][:team_domain],
    team_id: chat_msg[:member_tcb].slack_team_id,
    token: parsed[:url_params][:token],
    user_id: chat_msg[:member_tcb].slack_user_id,
    user_name: parsed[:url_params][:user_name],
    command: '/do',
    text: list_cmd
  }
  @view.channel = chat_msg[:member_tcb]
  context = parse_slash_cmd(url_params, chat_msg[:member_tcb], chat_msg[:member_mcb], chat_msg[:member_tcb], chat_msg[:member_tcb].after_action_parse_hash)
  return ["`MiaDo ERROR: #{context[:err_msg]}`", nil] unless context[:err_msg].empty?
  # context[:mcb] = chat_msg[:member_mcb]
  # context[:tcb] = chat_msg[:member_tcb]
  # context[:debug] = true
  text, attachments, options, list_cmd_after_action_list_context = list_command(context)
  @view.channel = parsed[:ccb]
  [text, attachments, options, list_cmd_after_action_list_context]
end

# Returns: slack api response hash.
def update_taskbot_channel(options)
  # Flow 0: Just edit the specified msg. Nothing is deleted.
  return edit_taskbot_msg(options) if options[:edit_taskbot_msg]

  # Flow 1: Deletes all msgs in bot dm channel.
  #         requires im_history, chat:write:bot scopes.
  # update_via_im_history(options)

  # Flow 2: Deletes all msgs in bot dm channel.
  #         requires chat:write:bot scope.
  # update_via_rtm_data(options)

  # Flow 3: Deletes all msgs in bot dm channel.
  #         requires chat:write:bot scope.
  update_via_member_record(options)

  # Flow 4: Deletes all msgs in bot dm channel.
  #         requires chat:write:bot scope.
  # update_via_taskbot_channel(options)

  # Flow 5: No msg delete, Update the single bot dm msg in place.
  #         requires chat:write:bot scope.
  # update_via_update_msg(options)

  # Flow 6: misc experiments.
  # update_experiments(options)
end

# Pluck taskbot summary list msg from the button payload, edit it and write
# back the msg via chat_update
# Returns: slack api response hash.
def edit_taskbot_msg(options)
  edit_taskbot_msg_for_taskbot_done_button(options) if options[:p_hash][:func] == :done
end

=begin
# Flow 1: Deletes all msgs in bot dm channel.
#         requires im_history, chat:write:bot scopes.
def update_via_im_history(options)
  options[:message_source] = :im_history
  clear_taskbot_msg_channel(options)
  api_resp = send_msg_to_taskbot_channel(options)
  update_taskbot_ccb_channel(options, 'msg_update')
  update_ccb_chan_taskbot_msg_info(api_resp, options)
  api_resp
end

# Flow 2: Deletes all msgs in bot dm channel.
#         requires chat:write:bot scope.
def update_via_rtm_data(options)
  options[:message_source] = :rtm_data
  options[:bot_api_token] = options[:p_hash][:ccb].bot_api_token
  clear_taskbot_msg_channel(options)
  api_resp = send_msg_to_taskbot_channel(options)
  update_ccb_chan_taskbot_msg_info(api_resp, options)
  api_resp
end

# Flow 4: Deletes all msgs in bot dm channel.
#         requires chat:write:bot scope.
def update_via_taskbot_channel(options)
  options[:message_source] = :taskbot_channel
  options[:bot_api_token] = options[:p_hash][:ccb].bot_api_token
  options[:taskbot_channel] =
    Channel.find_or_create_taskbot_channel(slack_team_id: options[:slack_team_id],
                                           slack_user_id: options[:slack_user_id])
  # am_hash['bot_dm_channel_id'] = taskbot_channel_ccb.slack_channel_id
  # am_hash['slack_user_api_token'] = taskbot_channel_ccb.slack_user_api_token
  # am_hash['bot_api_token'] = taskbot_channel_ccb.bot_api_token
  # am_hash['bot_user_id'] = taskbot_channel_ccb.bot_user_id
  # am_hash['bot_messages'] = taskbot_channel_ccb.bot_messages
  clear_taskbot_msg_channel(options)
  api_resp = send_msg_to_taskbot_channel(options)
  update_ccb_chan_taskbot_msg_info(api_resp, options)
  update_taskbot_channel(api_resp, options)
  api_resp
end

# Flow 5: No msg delete, Update the single bot dm msg in place.
#         requires chat:write:bot scope.
def update_via_update_msg(options)
  api_resp = send_msg_to_taskbot_channel(options) if options[:taskbot_msg_id].nil?
  api_resp = send_taskbot_update_msg(options) unless options[:taskbot_msg_id].nil?
  # Now that we know the taskbot msg id, save it for all members.
  # NOTE!! probably flawed logic because ccb for this user will have the msg
  # id in members_hash of one or more other members. Other member can then send
  # a taskbot msg to the same Other member but have nil in their ccb. MsgId
  # needs to propagate to all other members, also on reinstall.
  remember_taskbot_msg_id(api_resp, options)
  update_ccb_chan_taskbot_msg_info(api_resp, options)
  api_resp
end

# Flow 6: misc experiments.
def update_experiments(options)
  # delete_taskbot_msg(options) unless options[:taskbot_msg_id].nil?
  # blank_taskbot_msg(options) unless options[:taskbot_msg_id].nil?
  # api_resp = send_msg_to_taskbot_channel(options)
  # Now that we know the taskbot msg id, save it for all members.
  # remember_taskbot_msg_id(api_resp, options)
  # update_ccb_chan_taskbot_msg_info(api_resp, options)
  # api_resp
end
=end

# Flow 3: Deletes all msgs in bot dm channel.
#         requires chat:write:bot scope.
def update_via_member_record(options)
  options[:message_source] = :member_record
  clear_taskbot_msg_channel(options)
  api_resp = send_msg_to_taskbot_channel(options)
  remember_taskbot_msg_id(api_resp, options)
  update_taskbot_ccb_channel(options, 'msg_update - taskbot_msgs')
  update_ccb_chan_taskbot_msg_info(api_resp, options)
  update_member_record(options)
  api_resp
end

# update_ccb_chan_taskbot_msg_info(error: 'there was an error', p_hash: { ccb: parsed[:ccb] })
# p_hash[:ccb] --> channel of the member who typed in the slash cmd that caused
# us to be here.
def update_ccb_chan_taskbot_msg_info(api_resp, options)
  return if options[:p_hash][:ccb].nil?
  trace = [] if options[:p_hash][:ccb].taskbot_msg_to_slack_id.nil?
  trace = JSON.parse(options[:p_hash][:ccb].taskbot_msg_to_slack_id) unless options[:p_hash][:ccb].taskbot_msg_to_slack_id.nil?
  trace << {
    ok: api_resp['ok'] ? true : false,
    value: api_resp['ok'] ? "#{options[:member_id]}(#{options[:member_name]})" : "*failed*: #{api_resp['error']}"
  }
  options[:p_hash][:ccb].update(
    taskbot_msg_to_slack_id: trace.to_json,
    taskbot_msg_date: DateTime.current)
end

# p_hash[:tcb] --> taskbot channel of the member who we just wrote a msg to.
def update_taskbot_ccb_channel(options_or_parsed, activity_type)
  taskbot_ccb = options_or_parsed[:member_tcb] if options_or_parsed.key?(:member_tcb)
  taskbot_ccb = options_or_parsed[:tcb] if options_or_parsed.key?(:tcb)
  taskbot_ccb ||= find_or_create_taskbot_channel(options_or_parsed)
  update_channel_activity(taskbot_ccb, activity_type)
end

def find_or_create_taskbot_channel(options_or_parsed)
  user_id = options_or_parsed[:member_id] if options_or_parsed.key?(:member_mcb)
  user_id = options_or_parsed[:mcb].slack_user_id if options_or_parsed.key?(:mcb)
  team_id = options_or_parsed[:member_mcb].slack_team_id if options_or_parsed.key?(:member_mcb)
  team_id = options_or_parsed[:mcb].slack_team_id if options_or_parsed.key?(:mcb)
  Channel.find_or_create_taskbot_channel_from(
    source: :slack,
    slash_url_params: { 'user_id' => user_id,
                        'team_id' => team_id
                      })
end

def remember_taskbot_msg_id(api_resp, options)
  return unless api_resp['ok']
  return remember_msgs_via_member_record(api_resp, options) if options[:message_source] == :member_record
  # remember_msg_via_ccb(api_resp, options)
end

# { "text": "`Current tasks list for @suemanley1 in all Team channels (Open)`",
#   "username": "MiaDo Taskbot",
#   "bot_id": "B18E3GGJF",
#   "type": "message",
#   "subtype": "bot_message",
#   "ts": "1468010494.521738"
# }
def remember_msgs_via_member_record(api_resp, options)
  message = { 'text' => api_resp['message']['text'],
              'username' => api_resp['message']['username'],
              'bot_id' => api_resp['message']['bot_id'],
              'type' => api_resp['message']['type'],
              'subtype' => api_resp['message']['subtype'],
              'ts' => api_resp['message']['ts']
            }
  options[:taskbot_msgs] = [message] if options[:member_mcb].bot_msgs_json.nil?
  options[:taskbot_msgs] = options[:member_mcb].bot_msgs_json << message unless options[:member_mcb].bot_msgs_json.nil?
end

def update_member_record(options)
  options[:taskbot_msgs].delete_if { |m| m['deleted'] == true }
  update_member_record_activity(options, 'msg_update - taskbot_msgs', options[:taskbot_msgs])
end

# Returns: text status msg. 'ok' or err msg.
def clear_taskbot_msg_channel(options)
  return clear_channel_interface(options) unless options[:p_hash][:func] == :reset
  # Taskbot reset may require extra effort.
  return clear_channel_interface(options) unless options[:message_source] == :member_record
  # Try default first, clean up with rtm_start
  api_resp = clear_channel_interface(options)
  # NOTE: We are using user_token for im_history AND we dont have permission.
  #       Works on local dev but not on staging.
  # options[:message_source] = :im_history
  prev_msg_src = options[:message_source]
  prev_client_type = options[:api_client_type]
  options[:message_source] = :rtm_data
  options[:api_client_type] = :bot
  while api_resp['ok']
    api_resp = clear_channel_interface(options)
    break if api_resp['num_deleted'].nil? ||
             api_resp['num_deleted'] == 0
  end
  options[:message_source] = prev_msg_src
  options[:api_client_type] = prev_client_type
  api_resp
end

def clear_channel_interface(options)
  options[:api_client] = make_web_client(options)
  api_resp =
    clear_channel_msgs(message_source: options[:message_source],
                       type: :direct,
                       api_client: options[:api_client],
                       api_client_type: options[:api_client_type],
                       bot_api_token: options[:taskbot_api_token],
                       slack_team_id: options[:member_mcb].slack_team_id,
                       slack_user_id: options[:member_mcb].slack_user_id,
                       taskbot_user_id: options[:taskbot_user_id],
                       bot_msgs: options[:taskbot_msgs],
                       channel_id: options[:taskbot_channel_id],
                       time_range: { start_ts: 0, end_ts: 0 },
                       exclude_bot_msgs: false)
  options[:api_client].logger.error "\nCleared taskbot channel for: " \
       "#{options[:taskbot_username]} at dm_channel: " \
       "#{options[:taskbot_channel_id]}. " \
       "For member: #{options[:member_name]}. " \
       "Token type: #{options[:api_client_type]}.  " \
       "Using msg src: #{options[:message_source]}\n"
  return api_resp if api_resp['ok']
  err_msg = "ERROR: clear_taskbot_msgs failed with '#{api_resp}"
  options[:api_client].logger.error(err_msg)
  { 'ok' => false, error: err_msg }
end

# Returns: slack api response hash.
def send_msg_to_taskbot_channel(options)
  options[:api_client] = make_web_client(options)
  api_resp =
    options[:api_client]
    .chat_postMessage(
      as_user: options[:as_user],
      username: options[:taskbot_username],
      channel: options[:taskbot_channel_id],
      text: options[:text],
      attachments: options[:attachments])
  options[:api_client].logger.error "\nSent taskbot msg to: " \
    "#{options[:taskbot_username]} at dm_channel: " \
    "#{options[:taskbot_channel_id]}.  Msg title: #{options[:text]}. " \
    "For member: #{options[:member_name]}. " \
    "Token type: #{options[:api_client_type]}\n"
  return api_resp if api_resp['ok']
  err_msg = "Error: From send_msg_to_taskbot_channel(API:client.chat_postMessage) = '#{api_resp['error']}'"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, error: err_msg }
rescue Slack::Web::Api::Error => e # (not_authed)
  options[:api_client].logger.error e
  err_msg = "\nFrom send_msg_to_taskbot_channel(API:client.chat_postMessage) = " \
    "e.message: #{e.message}\n" \
    "channel_id: #{options[:channel]}  " \
    "Token type: #{options[:api_client_type]}  " \
    "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, 'error' => err_msg }
end

=begin
def remember_msg_via_ccb(api_resp, options)
  members_hash = options[:member_ccb].members_hash
  am_hash = members_hash[options[:member_id]]
  am_hash['bot_msg_id'] = api_resp['ts']
  members_hash[options[:member_id]] = am_hash
  members_hash[options[:member_name]] = am_hash
  update_all_team_members_hash(
    members_hash: members_hash,
    slack_team_id: options[:member_ccb].slack_team_id)
end

# Inputs: options{ members_hash: hash, slack_team_id: team_id }
# Update the ccb.members hash for all channels for this team.
def update_all_team_members_hash(options)
  Channel.where(slack_team_id: options[:slack_team_id])
         .update_all(members_hash: options[:members_hash])
end

# Returns: slack api response hash.
def blank_taskbot_msg(options)
  org_text_arg = options[:text]
  org_attachments_arg = options[:attachments]
  options[:text] = ' '
  options[:attachments] = {}
  api_resp = send_taskbot_update_msg(options)
  options[:text] = org_text_arg
  options[:attachments] = org_attachments_arg
  api_resp
end

# Deletes specified taskbot msg.
# Returns 'ok' or err_msg
def delete_taskbot_msg(options)
  api_resp = delete_message_on_channel(
    api_client: options[:api_client],
    channel_id: options[:taskbot_channel_id],
    message: { 'ts' => options[:taskbot_msg_id] })
  return 'ok' if api_resp.key?('ok')
  err_msg = "Error occurred on Slack\'s API:client.chat_delete: #{api_resp[:error]}"
  options[:api_client].logger.error(err_msg)
  err_msg
end

# Returns: slack api response hash.
def send_taskbot_update_msg(options)
  api_resp =
    options[:api_client]
    .chat_update(
      ts: options[:taskbot_msg_id],
      as_user: 'false',
      channel: options[:taskbot_channel_id],
      text: options[:text],
      attachments: options[:attachments].to_json)
  options[:api_client].logger.error "\nSent taskbot msg UPDATE to: " \
    "#{options[:taskbot_username]} at dm_channel: " \
    "#{options[:taskbot_channel_id]}.  Msg title: #{options[:text]}. " \
    "Message ts Id: #{options[:taskbot_msg_id]}. " \
    "For member: #{options[:member_name]}\n"
  return api_resp if api_resp['ok'] == true
  err_msg = "Error: From update_taskbot_msg(API:client.chat_update) = '#{api_resp['error']}'"
  options[:api_client].logger.error(err_msg)
  return api_resp
rescue Slack::Web::Api::Error => e # (not_authed)
  if e.message == 'message_not_found'
    api_resp = send_msg_to_taskbot_channel(options)
    remember_taskbot_msg_id(api_resp, options)
    return api_resp
  end
  options[:api_client].logger.error e
  err_msg = "\nFrom update_taskbot_msg(API:client.chat_update) = " \
    "e.message: #{e.message}\n" \
    "channel_id: #{options[:channel]}  " \
    "Message ts Id: #{options[:taskbot_msg_id]}. " \
    "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
  options[:api_client].logger.error(err_msg)
  return api_resp
end

# Inputs: options{ members_hash, slack_team_id, slack_user_id }
# Update the ccb.members hash for all channels for this team member.
def update_one_team_members_hash(options)
  Channel.where(slack_team_id: options[:slack_team_id],
                slack_user_id: options[:slack_user_id])
         .update_all(members_hash: options[:members_hash])
end
=end

################### Deferred Events. Does not use chat_msgs options hash.
#
# Process deferred event.
# Returns: nothing
def send_deferred_event_cmds(_d_hash, parsed)
  return respond_to_picklist_button_event(parsed) if parsed[:button_actions].first['name'] == 'picklist'
  parsed[:mcb] = Member.find_from(
    source: :slack,
    slack_user_id: parsed[:url_params][:user_id],
    slack_team_id: parsed[:url_params][:team_id])
  parsed[:api_client_user] = make_web_client(parsed[:ccb].slack_user_api_token)
  parsed[:api_client_bot] = make_web_client(parsed[:ccb].bot_api_token)
  parsed[:button_callback_id] = parsed[:ccb].after_action_parse_hash['button_callback_id']
  # return respond_to_reset_button_event(parsed) if parsed[:button_actions].first['name'] == 'reset'
  return respond_to_discuss_msg_event(parsed) if parsed[:ccb]['last_activity_type'] == 'button_action - discuss'
  respond_to_feedback_msg_event(parsed) if parsed[:ccb]['last_activity_type'] == 'button_action - feedback'
end

# Returns: nothing
def respond_to_feedback_msg_event(parsed)
  submitted_comment = comment_from_feedback_button(parsed)
  if submitted_comment.valid?
    CommentMailer.new_comment(@view, submitted_comment).deliver_now
    # return ['Thank you, we appreciate your input.', []]
    update_taskbot_ccb_channel(parsed, 'msg_update - feedback')
    status_msg = 'Thank you, we appreciate your input.'
  else
    update_channel_activity(parsed[:ccb], 'msg_update - feedback:error')
    parsed[:err_msg] = 'Error: Feedback message is empty.'
    status_msg = '*Error: Feedback message is empty.*' unless api_resp['ok']
  end
  # Delete feedback msg and display taskbot button header and response msg.
  delete_event_msg_and_update_taskbot_msg(parsed, status_msg)
end

# Returns: Comment object.
def comment_from_feedback_button(parsed)
  name = "#{parsed[:mcb].slack_user_name} on Slack Team '#{parsed[:mcb].slack_team_name}'"
  email = '**Submitted as feedback**'
  body = parsed[:url_params][:event][:text]
  Comment.new(name: name, email: email, body: body)
end

# Delete event msg and display taskbot button header and response msg.
def delete_event_msg_and_update_taskbot_msg(parsed, text_msg)
  delete_event_msg(parsed)
  attachments = list_button_taskbot_headline_replacement(parsed, text_msg, 'list') # in list_button_taskbot.rb
  # NOTE: should not need parsed[:button_callback_id]['payload_message_ts']
  # message.ts to edit is in parsed[:mcb].bot_msgs_json - should be first
  # and only taskbot msg.
  edit_and_send_taskbot_update_msg(
    api_client: parsed[:api_client_user],
    taskbot_channel_id: parsed[:ccb].slack_channel_id,
    text: '',
    attachments: attachments,
    taskbot_msg_id: parsed[:button_callback_id]['payload_message_ts'])
end

# Returns: nothing
def respond_to_discuss_msg_event(parsed)
  button_callback_id = parsed[:button_callback_id]
  api_resp = post_discuss_msg_from_taskbot_to_channel(
    parsed,
    "Comment from @#{parsed[:mcb].slack_user_name} about the task:\n" \
    "`#{button_callback_id['task_desc'].delete('|')}`",
    parsed[:url_params]['event']['text'],
    button_callback_id['slack_chan_id'])
  # :ccb is the Channel the event ocurred on (taskbot, same as :tcb)
  update_channel_activity(parsed[:ccb], 'msg_update - discuss')
  status_msg = 'Your comment has been added to the ' \
               "`##{button_callback_id['slack_chan_name']}` channel.\n" if api_resp['ok']
  status_msg = '*Your comment failed to send*' unless api_resp['ok']
  # Delete discuss msg and display taskbot button header and response msg.
  delete_event_msg_and_update_taskbot_msg(parsed, status_msg)
end

# Returns: api response{} from delete_message_on_channel()
def delete_event_msg(parsed)
  # options[:api_client].chat_delete(channel: options[:channel], ts: options[:message]['ts']
  # api_resp =
  delete_message_on_channel(
    api_client: parsed[:api_client_user],
    # api_client: make_web_client(parsed[:ccb].bot_api_token),
    channel: parsed[:url_params]['event']['channel'],
    message: { 'ts' => parsed[:url_params]['event']['ts'] })
end

def post_discuss_msg_from_taskbot_to_channel(parsed, headline, comment, slack_channel_id)
  attachments = [{
    text: comment,
    color: '#3AA3E3',
    mrkdwn_in: ['text']
  }]
  # api_resp =
  send_msg_to_public_channel(
    as_user: false,
    api_client: parsed[:api_client_user],
    username: 'taskbot',
    channel_id: slack_channel_id,
    text: headline,
    attachments: attachments
  )
end

# Returns: slack api response hash.
def send_msg_to_public_channel(options)
  api_resp =
    options[:api_client]
    .chat_postMessage(
      as_user: options[:as_user],
      username: options[:username],
      channel: options[:channel_id],
      text: options[:text],
      attachments: options[:attachments])
  options[:api_client].logger.error "\nSent channel msg to: " \
    "#{options[:taskbot_username]} at dm_channel: " \
    "#{options[:channel_id]}.  Msg title: #{options[:text]}. " \
    "For member: #{options[:member_name]}\n"
  return api_resp if api_resp['ok']
  err_msg = "Error: From send_msg_to_public_channel(API:client.chat_postMessage) = '#{api_resp['error']}'"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, error: err_msg }
rescue Slack::Web::Api::Error => e # (not_authed)
  options[:api_client].logger.error e
  err_msg = "\nFrom send_msg_to_public_channel(API:client.chat_postMessage) = " \
    "e.message: #{e.message}\n" \
    "channel_id: #{options[:channel]}  " \
    "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, 'error' => err_msg }
end

# Returns: nothing
def respond_to_picklist_button_event(parsed)
   # parsed[:button_callback_id]
end

# Click done button. Regular done logic runs, db is updated.
# Remove button from task_select list:
# Attachment is republished with one less button.
# If attachment is empty, then remove attachment, adjust caller_id.
# If all select attachments removed, then remove the promp attachment and
#    adjust caller_id.
#
# Inputs: options[:p_hash][:url_params][:payload] is the complete(yikes!)
#         taskbot report message that the user is looking at.
# Returns: api response{} from send_taskbot_update_msg()
def edit_taskbot_msg_for_taskbot_done_button(options)
  # Error if task is completed/done already. Can happen if All Tasks list.
  taskbot_burst_attachments(options)
  options[:done_task_info] = taskbot_done_find_task(options)
  # Note: options[:done_task_info][:ok] controls later actions.
  taskbot_done_button_remove_button(options)
  taskbot_done_remove_done_task(options)
  options[:text] = taskbot_done_button_response_text(options)
  options[:attachments] = taskbot_done_button_rebuild_attachments(options)
  options[:taskbot_msg_id] = options[:p_hash][:url_params][:payload]['message_ts']
  edit_and_send_taskbot_update_msg(options)
end

# Purpose: Find the task we are deleting and remember info about it.
#          Assume taskbot rpts are grouped by slack channel name.
# Inputs: options[:body_attachments] which is
#         options[:p_hash][:url_params][:payload] broken into its component
#         attachments.
# Returns: options[:done_task_info]
def taskbot_done_find_task(options)
  props = options[:p_hash][:first_button_value]
  tasknum = props[:command]
  task_channel_name = props[:chan_name]
  options[:body_attachments].each_with_index do |body_attch, channel_group_num|
    channel_group_lines = body_attch[:text].split("\n")
    channel_group_lines.each_with_index do |line, line_idx|
      # ["---- #general channel (1st tasknum: 1)----------",
      # "1) gen 1 | *Assigned* to @dawnnova.",
      # "2) gen 3 | *Assigned* to @dawnnova.",
      # "3) gen 1 | *Assigned* to @ray."]
      # Skip this report block if it is not the channel we are looking for.
      break if line_idx == 0 && !chan_name_from_taskbot_line(line) == task_channel_name
      return { ok: true, task_found: true, err_msg: '',
               tasknum: tasknum, channel_name: task_channel_name,
               task_description: line.slice(line.index(') ') + 2..-1), # slice off the leading tasknum.
               channel_group_num: channel_group_num,
               channel_group_lines: channel_group_lines,
               channel_group_line_idx: line_idx } if tasknum_from_taskbot_line(line) == tasknum
    end
  end
  { ok: false, task_found: false,
    tasknum: tasknum, channel_name: task_channel_name,
    err_msg: "*internal ERROR: Task #{tasknum} not found. Contact MiaDo support.*"
  }
end

# Purpose: Delete the Task Select Button associated with the Task msg that is
#          going to be removed from the Taskbot Report.
# Inputs: options[:done_task_info], taskbot rpt msg attachments{}
# Returns: updated Select button strip with the Select button deleted from the
#          options[:task_select_attachments][:actions]
def taskbot_done_button_remove_button(options)
  return unless options[:done_task_info][:ok]
  props = options[:done_task_info]
  props.merge!(taskbot_done_find_select_button(options))
  return taskbot_remove_task_select_attachment(options) if options[:task_select_attachments][props[:select_row_num]][:actions].size == 1
  # Remove action/button.
  options[:task_select_attachments][props[:select_row_num]][:actions].slice!(props[:select_action_idx])
end

def taskbot_done_find_select_button(options)
  props = options[:done_task_info]
  options[:task_select_attachments].each_with_index do |sel_attch, row_num|
    sel_attch[:actions].each_with_index do |action, action_idx|
      # [{"id"=>"8", "name"=>"done", "text"=>"1", "type"=>"button", "value"=>"{\"command\":\"1\",\"chan_name\":\"general\"}", "style"=>"primary"},
      return { ok: true, button_found: true, err_msg: '',
               select_attachment: sel_attch, select_row_num: row_num,
               select_action_idx: action_idx } if JSON.parse(action[:value]).with_indifferent_access[:command] == props[:tasknum]
    end
  end
  { ok: false, button_found: false,
    select_row_num: nil, select_action_idx: nil,
    err_msg: "*internal ERROR: Button for task #{props[:tasknum]} not found. Contact MiaDo support.*" }
end

# Purpose: Delete the Task Task msg from the Taskbot Report. It has either been
#          marked Done or has been deleted.
# Inputs: options[:done_task_info], taskbot rpt msg attachments{}
# Returns: options[:body_attachments] with the line of text for the Task
#          deleted.
def taskbot_done_remove_done_task(options)
  return unless options[:done_task_info][:ok]
  # props =>
  # { :err_msg=>'',
  #   :tasknum=>"4",
  #   :channel_name=>"issues",
  #   :task_description=>"4) issue 2 | *Assigned* to @ray.",
  #   :channel_group_lines=>"---- #general channel (1st tasknum: 1)----------
  #                          \n1) gen 1 | *Assigned* to @dawnnova.]"
  #   :channel_group_num=>1,
  #   :channel_group_line_idx=>1,
  #   :select_row_num=>0,
  #   :select_action_idx=>3 }
  props = options[:done_task_info]
  # Delete the report channel list attachment if we are removing the last task.
  return taskbot_remove_body_attachment(options) if props[:channel_group_lines].size == 2
  # Remove task line.
  props[:task_removed] = props[:channel_group_lines].slice!(props[:channel_group_line_idx])
  props[:new_text] = props[:channel_group_lines].join("\n")
  options[:body_attachments][props[:channel_group_num]][:text] = props[:new_text]
end

def taskbot_remove_task_select_attachment(options)
  options[:task_select_attachments][options[:p_hash][:button_callback_id][:select_row_num]] = {}
  # Note: if we just deleted the last button row,
  #       taskbot_remove_body_attachment() will notice that the body_attachments
  #       are empty and therefore remove the footer_attachments.
end

def taskbot_remove_body_attachment(options)
  options[:body_attachments][options[:done_task_info][:channel_group_num]] = {}
  # If we just deleted the last report channel body attachment, we dont need
  # the footer button attachments.
  body_empty = (options[:body_attachments].count(&:empty?) == options[:body_attachments].size)
  taskbot_remove_footer_attachments(options) if body_empty
  return taskbot_update_headline_attachments(options) if body_empty
end

def taskbot_remove_footer_attachments(options)
  # Empty the arrays. The task_select caller_id info does not have to be
  # adjusted because the task_select_attachment is being deleted too.
  options[:footer_buttons_attachments] = []
  options[:footer_prompt_attachments] = []
  options[:task_select_attachments] = []
end

def taskbot_update_headline_attachments(options)
  options[:headline_attachments][0]['pretext'].concat(' *empty*')
end

def taskbot_done_button_rebuild_attachments(options)
  return options[:org_attachments] unless options[:done_task_info][:ok]
  # Start with header attachments and add others.
  attachments =
    options[:header_attachments]
    .concat(options[:headline_attachments])
    .concat(options[:body_attachments])
    .concat(options[:footer_buttons_attachments])
    .concat(options[:footer_prompt_attachments])
    .concat(options[:task_select_attachments])
  attachments
end

def taskbot_done_button_response_text(options)
  props = options[:done_task_info]
  # Return error msg if Task or button not found.
  return props[:err_msg] unless props[:err_msg].empty?
  # Isolate the task number from the item description.
  (options[:p_hash][:button_actions].first['name'] == 'done and delete' ? 'Deleted: ' : 'Closed:    ')
    .concat("#{props[:tasknum]}) ~#{props[:task_description]}~ \n")
  # .concat("#{s.slice(0..s.index(') '))} ~#{s.slice(s.index(') ') + 2..-1)}~ \n")
  # .concat("Task #{options[:p_hash][:first_button_value][:command]}(##{options[:p_hash][:first_button_value][:chan_name]}) ")
  # .concat("Body_attch_idx: #{options[:task_body_idx]}  line_idx: #{options[:task_line_idx]}\n")
end

# Given the attachment number in the button payload, remove that attachment
# and write back the msg via chat_update
# Returns: api response{} from send_taskbot_update_msg()
def edit_and_send_taskbot_update_msg(options)
  if options[:attachments].empty? && options.key?(:attachment_id_to_remove)
    options[:attachments] = options[:p_hash][:url_params][:payload][:original_message][:attachments]
    # attachment_to_edit = attachments[attachment_id_to_remove].to_i - 1]
    options[:attachments].delete_at(options[:attachment_id_to_remove].to_i - 1)
  end
  update_msg_in_taskbot_channel(options)
end

# Returns: slack api response hash.
def update_msg_in_taskbot_channel(options)
  api_resp =
    options[:api_client]
    .chat_update(
      ts: options[:taskbot_msg_id],
      as_user: options[:as_user],
      channel: options[:taskbot_channel_id],
      text: options[:text],
      attachments: options[:attachments].to_json)
  options[:api_client].logger.error "\nSent taskbot msg UPDATE to: " \
    "#{options[:taskbot_username]} at dm_channel: " \
    "#{options[:taskbot_channel_id]}.  Msg title: #{options[:text]}. " \
    "Message ts Id: #{options[:taskbot_msg_id]}. " \
    "For member: #{options[:member_name]}\n"
  return api_resp if api_resp['ok']
  err_msg = "Error: From update_msg_in_taskbot_channel(API:client.chat_update) = '#{api_resp['error']}'"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, error: err_msg }
rescue Slack::Web::Api::Error => e # (not_authed)
  if e.message == 'message_not_found'
    api_resp = send_msg_to_taskbot_channel(options)
    remember_taskbot_msg_id(api_resp, options)
    return api_resp
  end
  options[:api_client].logger.error e
  err_msg = "\nFrom update_msg_in_taskbot_channel(API:client.chat_update) = " \
    "e.message: #{e.message}\n" \
    "channel_id: #{options[:channel]}  " \
    "Message ts Id: #{options[:taskbot_msg_id]}. " \
    "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, error: err_msg }
end

# Purpose: Break the taskbot report message into its component attachments.
# Inputs: options[:p_hash][:url_params][:payload] is the complete(yikes!)
#         taskbot report message that the user is looking at.
# Returns: options[:xxxx_attachments{}] fields are filled in.
def taskbot_burst_attachments(options)
  options[:org_text] = options[:p_hash][:url_params][:payload][:original_message][:text]
  options[:org_attachments] = options[:p_hash][:url_params][:payload][:original_message][:attachments]

  options[:header_attachments] = options[:org_attachments].slice(
    options[:p_hash][:button_callback_id][:header_idx] - 1,
      options[:p_hash][:button_callback_id][:header_num])

  options[:headline_attachments] =
    options[:org_attachments].slice(
      options[:p_hash][:button_callback_id][:header_idx],
      1)

  options[:body_attachments] =
    options[:org_attachments].slice(
      options[:p_hash][:button_callback_id][:body_idx] - 1,
      options[:p_hash][:button_callback_id][:body_num])

  options[:footer_buttons_attachments] =
    options[:org_attachments].slice(
      options[:p_hash][:button_callback_id][:footer_but_idx] - 1,
      options[:p_hash][:button_callback_id][:footer_but_num])

  options[:footer_prompt_attachments] =
    options[:org_attachments].slice(
      options[:p_hash][:button_callback_id][:footer_pmt_idx] - 1,
      options[:p_hash][:button_callback_id][:footer_pmt_num])

  options[:task_select_attachments] =
    options[:org_attachments].slice(
      options[:p_hash][:button_callback_id][:sel_idx] - 1,
      options[:org_attachments].size - options[:p_hash][:button_callback_id][:sel_idx] + 1)
end
