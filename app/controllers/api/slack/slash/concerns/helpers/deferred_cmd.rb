# /raydo delete 1 does not update taskbot channel?

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
   :post_comment, :taskbot_rpts].freeze
#
# if a member's taskbot lists could be changed, then we need to update em.
# Returns: [ {cmds} ]
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

DEFERRED_EVENT_CMD_FUNCS = [:message_event].freeze
# Route deferred command to proper handler.
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
def send_deferred_list_cmds(d_hash, parsed)
  #----------------------
  parsed[:am_hash_source] = :member_record
  #----------------------
  list_cmds = generate_list_commands(parsed, d_hash)
  chat_msgs = generate_task_list_msgs(parsed, list_cmds)
  chat_msgs.each do |msg|
    update_taskbot_channel(
      edit_taskbot_msg: msg[:edit_taskbot_msg],
      api_client: msg[:api_client],
      taskbot_username: msg[:taskbot_username],
      taskbot_channel_id: msg[:taskbot_channel_id],
      taskbot_user_id: msg[:taskbot_user_id],
      taskbot_api_token: msg[:taskbot_api_token],
      taskbot_msg_id: msg[:taskbot_msg_id],
      taskbot_msgs: msg[:taskbot_msgs],
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

# command = 'new weekly task 1 for dawn @dawnnova'
#----------------------------------------
# Team shadowhtracteam Member ray:
#   slack user_id: U0VLZ5P51
#   slack member name: ray
#   dm channel_id for dev-bot-4rnova: D18E3GH2P
#   slack_api_token: xoxp-29753209748-29713193171-42883411315-2e51ed8aee
#   bot_user_id:
#   bot_api_token: xoxb-42517920580-HXGx9p6Z5Ng6t6j5sTxbpiCl
# Team shadowhtracteam Member ray:
#   dm channel_id for dev-bot-4rnova: D18E3GH2P
#   slack_api_token:
#   bot_user_id:
#   bot_api_token:
# Team shadowhtracteam Member ray:
#   dm channel_id for dev-bot-4rnova: D18E3GH2P
#   slack_api_token:
#   bot_user_id:
#   bot_api_token:
#-------------------------------------
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
        taskbot_username: 'MiaDo Taskbot'
      }
    # ,
    # { type: 'all due',
    #  cmd: "taskbot_rpts @#{parsed[:mentioned_member_name]} team all due",
    #  bot_dm_channel_id: 'D18E3GH2P',
    #  bot_username: 'Taskbot'
    # }
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

# If delete: task has been deleted. Need to get impacted_member info from ??

# If append tasknum and the task[tasknum] being appended has an
#    assigned_member_id, update that assigned_member_id's list dm.
# If done, same as for append.
# If due, same as for append.

# If assign, always update the assigned_member_id's list dm.
# If unassign, same as assign.

# If redo tasknum, same as for add for new command and same as for delete for
# the task being deleted.

# Note: deferred_cmd[:impacted_task] is optional logic for here or has already
# been done.
#   {} means we did not look OR commented out the method call.
#   ListItem record means we have an updated task to process
#     that may require the taskbot list to be updated.

def determine_impacted_members(parsed, deferred_cmd)
  func = parsed[:func]
  # redo is such a special case, it is easier to handle it specially.
  return build_redo_impacted_members(parsed) if func == :redo
  impacted_task = deferred_cmd[:impacted_task] unless deferred_cmd[:impacted_task] == {}
  impacted_task = taskbot_list_item(parsed) if deferred_cmd[:impacted_task] == {}
  am_hash = am_hash_from_assigned_member_id(parsed, parsed[:assigned_member_id]) if impacted_task.nil?
  am_hash = am_hash_from_assigned_member_id(parsed, impacted_task[:assigned_member_id]) unless impacted_task.nil?
  # nil if MiaDo not installed by this member.
  return [] if am_hash.nil? || am_hash['bot_dm_channel_id'].nil?
  case func
  when :add, :assign, :unassign
    return build_one_impacted_member(parsed: parsed, am_hash: am_hash)
  when :append, :done, :due
    return [] if impacted_task.nil?
    return build_one_impacted_member(am_hash: am_hash)
  when :delete
    # delete command has already deleted the impacted task.
    return build_many_impacted_members(parsed) if parsed[:list_action_item_info].size > 1
    return build_one_impacted_member(impacted_task: impacted_task, am_hash: am_hash)
  end
  []
end

#   impacted_task{} = nil means we looked up task and we won't process it or it
#                   doesn't require the taskbot list be updated.
#   impacted_task{} = ListItem record info means we have an updated task to
#                   process that may require the taskbot list to be updated.
CMD_FUNCS_IGNORED_IF_TASK_HAS_NO_ASSIGNED_MEMBER = [:append, :done, :due].freeze
# CMD_FUNCS_WE_ALWAYS_GET_impacted_task_FOR = [:assign, :unassign].freeze
def taskbot_list_item(parsed)
  return impacted_task_if_no_assigned_member(parsed) if CMD_FUNCS_IGNORED_IF_TASK_HAS_NO_ASSIGNED_MEMBER.include?(parsed[:func])
  # add, assign and unassign commands include the name of the impacted member,
  # don't need to ask db. delete and redo commands have already deleted the
  # impacted task.
  return parsed[:list_action_item_info][0] if parsed[:func] == :delete || parsed[:func] == :redo || parsed[:func] == :done
  nil
end

#   impacted_task{} = nil means we looked up task and we won't process it or it
#                   doesn't require the taskbot list be updated.
#   impacted_task{} = ListItem record info means we have an updated task to
#                   process that may require the taskbot list to be updated.
def impacted_task_if_no_assigned_member(parsed)
  # Taskbot channel done_and_delete button command has already deleted the
  # impacted task.
  return parsed[:list_action_item_info][0] if parsed[:button_actions].any? && parsed[:button_actions].first['name'] == 'done and delete'
  task = ListItem.where(id: parsed[:list][parsed[:task_num] - 1]).first
  unless task.nil?
    return nil if parsed[:func] == :redo && parsed[:assigned_member_id].nil? &&
                  task.assigned_member_id.nil?
    return nil if task.assigned_member_id.nil?
    return { db_id: task.id, assigned_member_id: task.assigned_member_id }
  end
  nil
end

def am_hash_from_assigned_member_id(parsed, assigned_member_id)
  return am_hash_from_member_record(parsed, assigned_member_id) if parsed[:am_hash_source] == :member_record
  parsed[:ccb].members_hash[assigned_member_id]
end

# 'bot_dm_channel_id']
# 'slack_user_name'],
# 'slack_user_id']
# 'slack_user_api_token']
# 'bot_api_token']
# 'bot_dm_channel_id']
# 'bot_user_id']
# 'bot_msg_id']
def am_hash_from_member_record(parsed, assigned_member_id)
  mcb = Member.find_from(
    source: :slack,
    slack_team_id: parsed[:url_params]['team_id'],
    slack_user_id: assigned_member_id)
  return nil if mcb.nil?
  { 'mcb' => mcb,
    'bot_dm_channel_id' => mcb.bot_dm_channel_id,
    'slack_user_name' => mcb.slack_user_name,
    'slack_user_id' => mcb.slack_user_id,
    'slack_user_api_token' => mcb.slack_user_api_token,
    'bot_api_token' => mcb.bot_api_token,
    'bot_user_id' => mcb.bot_user_id,
    'bot_msgs' => mcb.bot_msgs_json
  }
end

# Inputs: am_hash, OPTIONAL: parsed
def build_one_impacted_member(options)
  impacted_member =
    { name: options[:parsed][:assigned_member_name],
      id: options[:parsed][:assigned_member_id] } if options.key?(:parsed)
  impacted_member =
    { name: options[:am_hash]['slack_user_name'],
      id: options[:am_hash]['slack_user_id'] } unless options.key?(:parsed)

  impacted_member[:member_mcb] = options[:am_hash]['mcb']
  impacted_member[:member_tcb] = options[:am_hash]['tcb']
  impacted_member[:slack_user_api_token] = options[:am_hash]['slack_user_api_token']
  impacted_member[:taskbot_api_token] = options[:am_hash]['bot_api_token']
  impacted_member[:taskbot_channel_id] = options[:am_hash]['bot_dm_channel_id']
  impacted_member[:taskbot_user_id] = options[:am_hash]['bot_user_id']
  impacted_member[:taskbot_msg_id] = options[:am_hash]['bot_msg_id']
  impacted_member[:taskbot_msgs] = options[:am_hash]['bot_msgs']
  [impacted_member[:id], impacted_member]
end

def build_many_impacted_members(parsed)
  impacted_members = []
  parsed[:list_action_item_info].each do |task_info|
    am_hash = am_hash_from_assigned_member_id(parsed, task_info[:assigned_member_id])
    next if impacted_members.include?(am_hash['slack_user_id'])
    impacted_member_id, impacted_member = build_one_impacted_member(am_hash: am_hash)
    impacted_members << impacted_member_id
    impacted_members << impacted_member
  end
  impacted_members
end

# same as for add for new command and same as for delete for
# the task being deleted. So the delete could impact one member and the
# add could impact another.
def build_redo_impacted_members(parsed)
  deleted_member_id = parsed[:list_action_item_info][0][:assigned_member_id]
  added_member_id = parsed[:assigned_member_id]
  return [] if deleted_member_id.nil? && added_member_id.nil?
  return build_redo_both_tasks(parsed) unless deleted_member_id.nil? ||
                                              added_member_id.nil?
  return build_redo_only_deleted_task(parsed) unless deleted_member_id.nil?
  build_redo_only_added_task(parsed)
end

def build_redo_both_tasks(parsed)
  deleted_task_member = build_many_impacted_members(parsed)
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
  build_many_impacted_members(parsed)
end

def build_redo_only_added_task(parsed)
  added_task_hash = am_hash_from_assigned_member_id(parsed, parsed[:assigned_member_id])
  build_one_impacted_member(parsed: parsed, am_hash: added_task_hash)
end

=begin
  Form Params
  channel_id	C0VNKV7BK
  channel_name	general
  command	/do
  response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
  team_domain	shadowhtracteam
  team_id	T0VN565N0
  text	list me
  token	3ZQVG7rk4p7EZZluk1gTH3aN
  user_id	U0VLZ5P51
  user_name	ray
=end
def generate_task_list_msgs(parsed, list_cmds)
  chat_msgs = []
  list_cmds.each do |cmd_hash|
    chat_msgs << { member_mcb: cmd_hash[:member_mcb],
                   member_tcb: cmd_hash[:member_tcb],
                   taskbot_channel_id: cmd_hash[:taskbot_channel_id],
                   taskbot_user_id: cmd_hash[:taskbot_user_id],
                   taskbot_msg_id: cmd_hash[:taskbot_msg_id],
                   # api_client: make_web_client(cmd_hash[:taskbot_api_token])
                   api_client: make_web_client(cmd_hash[:slack_user_api_token])
                 }
    if cmd_hash[:type] == 'edit msg'
      chat_msgs.last[:edit_taskbot_msg] = true
      chat_msgs.last[:after_action_list_context] = after_action_list_context(parsed)
    else
      text, attachments, _response_options, list_cmd_after_action_list_context =
        taskbot_rpts_command(parsed, type: cmd_hash[:type],
                                     member_name: cmd_hash[:member_name],
                                     member_id: cmd_hash[:member_id])
      text = "`MiaDo ERROR: #{parsed[:err_msg]}`" unless parsed[:err_msg].empty?
      chat_msgs.last[:edit_taskbot_msg] = false
      chat_msgs.last[:text] = text
      chat_msgs.last[:attachments] = attachments
      chat_msgs.last[:taskbot_username] = cmd_hash[:taskbot_username]
      chat_msgs.last[:taskbot_msgs] = cmd_hash[:taskbot_msgs]
      chat_msgs.last[:member_name] = cmd_hash[:member_name]
      chat_msgs.last[:member_id] = cmd_hash[:member_id]
      chat_msgs.last[:after_action_list_context] = list_cmd_after_action_list_context
    end
  end
  chat_msgs
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

# Returns: api response{} from send_taskbot_update_msg()
def edit_taskbot_msg_for_taskbot_done_button(options)
  options[:text] =
    options[:p_hash][:url_params][:payload][:original_message][:text]
    .concat("#{options[:p_hash][:button_actions].first['name'] == 'done and delete' ? 'Deleted: ' : ''}" \
            "~#{options[:p_hash][:button_callback_id]['task_desc']}~\n")
  options[:attachments] = []
  options[:attachment_id_to_remove] = options[:p_hash][:url_params][:payload][:attachment_id]
  options[:taskbot_msg_id] = options[:p_hash][:url_params][:payload]['message_ts']
  edit_and_send_taskbot_update_msg(options)
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
  send_taskbot_update_msg(options)
end

=begin
# Flow 1: Deletes all msgs in bot dm channel.
#         requires im_history, chat:write:bot scopes.
def update_via_im_history(options)
  options[:message_source] = :im_history
  clear_taskbot_msg_channel(options)
  api_resp = send_taskbot_msg(options)
  update_taskbot_ccb_channel(options, 'msg_update')
  update_ccb_channel(api_resp, options)
  api_resp
end

# Flow 2: Deletes all msgs in bot dm channel.
#         requires chat:write:bot scope.
def update_via_rtm_data(options)
  options[:message_source] = :rtm_data
  options[:bot_api_token] = options[:p_hash][:ccb].bot_api_token
  clear_taskbot_msg_channel(options)
  api_resp = send_taskbot_msg(options)
  update_ccb_channel(api_resp, options)
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
  api_resp = send_taskbot_msg(options)
  update_ccb_channel(api_resp, options)
  update_taskbot_channel(api_resp, options)
  api_resp
end

# Flow 5: No msg delete, Update the single bot dm msg in place.
#         requires chat:write:bot scope.
def update_via_update_msg(options)
  api_resp = send_taskbot_msg(options) if options[:taskbot_msg_id].nil?
  api_resp = send_taskbot_update_msg(options) unless options[:taskbot_msg_id].nil?
  # Now that we know the taskbot msg id, save it for all members.
  # NOTE!! probably flawed logic because ccb for this user will have the msg
  # id in members_hash of one or more other members. Other member can then send
  # a taskbot msg to the same Other member but have nil in their ccb. MsgId
  # needs to propagate to all other members, also on reinstall.
  remember_taskbot_msg_id(api_resp, options)
  update_ccb_channel(api_resp, options)
  api_resp
end

# Flow 6: misc experiments.
def update_experiments(options)
  # delete_taskbot_msg(options) unless options[:taskbot_msg_id].nil?
  # blank_taskbot_msg(options) unless options[:taskbot_msg_id].nil?
  # api_resp = send_taskbot_msg(options)
  # Now that we know the taskbot msg id, save it for all members.
  # remember_taskbot_msg_id(api_resp, options)
  # update_ccb_channel(api_resp, options)
  # api_resp
end
=end

# Flow 3: Deletes all msgs in bot dm channel.
#         requires chat:write:bot scope.
def update_via_member_record(options)
  options[:message_source] = :member_record
  clear_taskbot_msg_channel(options)
  api_resp = send_taskbot_msg(options)
  remember_taskbot_msg_id(api_resp, options)
  update_taskbot_ccb_channel(options, 'msg_update')
  update_ccb_channel(api_resp, options)
  update_member_record(options)
  api_resp
end

# p_hash[:ccb] --> channel of the member who typed in the slash cmd that caused
# us to be here.
def update_ccb_channel(api_resp, options)
  return if options[:p_hash][:ccb].nil?
  options[:p_hash][:ccb].update(
    taskbot_msg_to_slack_id: api_resp['ok'] ? options[:member_id] : "*failed*: #{api_resp['error']}",
    taskbot_msg_date: DateTime.current)
end

def update_channel_activity(cb, activity_type, after_action_parse_hash = nil)
  return cb.update(last_activity_type: activity_type,
                   last_activity_date: DateTime.current) if after_action_parse_hash.nil?
  cb.update(after_action_parse_hash: after_action_parse_hash,
            last_activity_type: activity_type,
            last_activity_date: DateTime.current)
end

# p_hash[:tcb] --> taskbot channel of the member who we just wrote a msg to.
def update_taskbot_ccb_channel(options_or_parsed, activity_type)
  taskbot_ccb = options_or_parsed[:member_tcb] if options_or_parsed.key?(:member_tcb)
  taskbot_ccb = options_or_parsed[:tcb] if options_or_parsed.key?(:tcb)
  taskbot_ccb ||= find_or_create_taskbot_channel(options_or_parsed)
  # Persist the channel.list_ids[] for the next transaction.
  # after_action_parse_hash: { 'after_action_list_context' => options_or_parsed[:after_action_list_context] },
  update_channel_activity(taskbot_ccb, activity_type, options_or_parsed[:after_action_list_context])
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

# {
#                "text": "`Current tasks list for @suemanley1 in all Team channels (Open)`",
#                "username": "MiaDo Taskbot",
#                "bot_id": "B18E3GGJF",
#                "type": "message",
#                "subtype": "bot_message",
#                "ts": "1468010494.521738"
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
  options[:member_mcb].update(
    bot_msgs_json: options[:taskbot_msgs],
    last_activity_type: 'update_taskbot_msgs',
    last_activity_date: DateTime.current)
end

# Returns: text status msg. 'ok' or err msg.
def clear_taskbot_msg_channel(options)
  api_resp =
    clear_channel_msgs(message_source: options[:message_source],
                       type: :direct,
                       api_client: options[:api_client],
                       bot_api_token: options[:taskbot_api_token],
                       bot_msgs: options[:taskbot_msgs],
                       channel_id: options[:taskbot_channel_id],
                       time_range: { start_ts: 0, end_ts: 0 },
                       exclude_bot_msgs: false)
  options[:api_client].logger.error "\nCleared taskbot channel for: " \
       "#{options[:taskbot_username]} at dm_channel: " \
       "#{options[:taskbot_channel_id]}. " \
       "For member: #{options[:member_name]}\n"
  return api_resp if api_resp['ok']
  err_msg = "ERROR: clear_taskbot_msgs failed with '#{api_resp}"
  options[:api_client].logger.error(err_msg)
  { 'ok' => false, error: err_msg }
end

# Returns: slack api response hash.
def send_taskbot_msg(options)
  api_resp =
    options[:api_client]
    .chat_postMessage(
      as_user: 'true',
      username: options[:taskbot_username],
      channel: options[:taskbot_channel_id],
      text: options[:text],
      attachments: options[:attachments])
  options[:api_client].logger.error "\nSent taskbot msg to: " \
    "#{options[:taskbot_username]} at dm_channel: " \
    "#{options[:taskbot_channel_id]}.  Msg title: #{options[:text]}. " \
    "For member: #{options[:member_name]}\n"
  return api_resp if api_resp['ok']
  err_msg = "Error: From send_taskbot_msg(API:client.chat_postMessage) = '#{api_resp['error']}'"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, error: err_msg }
rescue Slack::Web::Api::Error => e # (not_authed)
  options[:api_client].logger.error e
  err_msg = "\nFrom send_taskbot_msg(API:client.chat_postMessage) = " \
    "e.message: #{e.message}\n" \
    "channel_id: #{options[:channel]}  " \
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
    api_resp = send_taskbot_msg(options)
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
  parsed[:mcb] = Member.find_from(
    source: :slack,
    slack_user_id: parsed[:url_params][:user_id],
    slack_team_id: parsed[:url_params][:team_id])
  parsed[:api_client_user] = make_web_client(parsed[:ccb].slack_user_api_token)
  parsed[:api_client_bot] = make_web_client(parsed[:ccb].bot_api_token)
  parsed[:button_callback_id] = parsed[:ccb].after_action_parse_hash['button_callback_id']
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
  attachments = list_button_taskbot_headline_replacement(parsed, text_msg) # in list_button_taskbot.rb
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
  send_channel_msg(
    api_client: parsed[:api_client_user],
    username: 'taskbot',
    channel_id: slack_channel_id,
    text: headline,
    attachments: attachments
  )
end

# Returns: slack api response hash.
def send_channel_msg(options)
  api_resp =
    options[:api_client]
    .chat_postMessage(
      as_user: 'true',
      username: options[:username],
      channel: options[:channel_id],
      text: options[:text],
      attachments: options[:attachments])
  options[:api_client].logger.error "\nSent channel msg to: " \
    "#{options[:taskbot_username]} at dm_channel: " \
    "#{options[:channel_id]}.  Msg title: #{options[:text]}. " \
    "For member: #{options[:member_name]}\n"
  return api_resp if api_resp['ok']
  err_msg = "Error: From send_channel_msg(API:client.chat_postMessage) = '#{api_resp['error']}'"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, error: err_msg }
rescue Slack::Web::Api::Error => e # (not_authed)
  options[:api_client].logger.error e
  err_msg = "\nFrom send_channel_msg(API:client.chat_postMessage) = " \
    "e.message: #{e.message}\n" \
    "channel_id: #{options[:channel]}  " \
    "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, 'error' => err_msg }
end

# Returns: slack api response hash.
def send_taskbot_update_msg(options)
  api_resp =
    options[:api_client]
    .chat_update(
      ts: options[:taskbot_msg_id],
      as_user: 'true',
      channel: options[:taskbot_channel_id],
      text: options[:text],
      attachments: options[:attachments].to_json)
  options[:api_client].logger.error "\nSent taskbot msg UPDATE to: " \
    "#{options[:taskbot_username]} at dm_channel: " \
    "#{options[:taskbot_channel_id]}.  Msg title: #{options[:text]}. " \
    "Message ts Id: #{options[:taskbot_msg_id]}. " \
    "For member: #{options[:member_name]}\n"
  return api_resp if api_resp['ok']
  err_msg = "Error: From update_taskbot_msg(API:client.chat_update) = '#{api_resp['error']}'"
  options[:api_client].logger.error(err_msg)
  return { 'ok' => false, error: err_msg }
rescue Slack::Web::Api::Error => e # (not_authed)
  if e.message == 'message_not_found'
    api_resp = send_taskbot_msg(options)
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
  return { 'ok' => false, error: err_msg }
end
