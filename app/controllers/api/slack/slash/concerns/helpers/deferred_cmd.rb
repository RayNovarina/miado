
def after_action_deferred_logic(def_cmds)
  Thread.new do
    send_after_action_deferred_cmds(def_cmds)
  end
end


CMD_FUNCS_IGNORED_BY_AFTER_ACTION_DEFERRED = [:help, :list, :pub].freeze
#
# if a member's taskbot lists could be changed, then we need to update em.
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

# 1) generate list commands array.
# 2) clear taskbot channel of task lists to be replaced. or replace em?
# 3) generate new task lists.
# 4) post new lists into taskbot channel.
def send_after_action_deferred_cmds(cmds)
  cmds.each do |d_hash|
    parsed = d_hash[:p_hash]
    list_cmds = generate_list_commands(parsed, d_hash)
    chat_msgs = generate_task_list_msgs(parsed, list_cmds)
    chat_msgs.each_with_index do |msg, index|
      if index == 0
        resp = clear_taskbot_msg_channel(api_client: msg[:api_client],
                                         taskbot_channel_id: msg[:taskbot_channel_id])
        unless resp == 'ok'
          msg[:text] = "`MiaDo ERROR: clear_taskbot_msgs failed with '#{resp}'`"
          msg[:attachments] = nil
        end
      end
      send_taskbot_msg(api_client: msg[:api_client],
                       taskbot_username: msg[:taskbot_username],
                       taskbot_channel_id: msg[:taskbot_channel_id],
                       text: msg[:text],
                       attachments: msg[:attachments])
    end
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
  list_cmds = []
  determine_impacted_members(parsed, deferred_cmd).each do |i_item|
    # impacted_member = ['id string', {impacted_member_hash}
    next unless i_item.respond_to?(:to_hash)
    list_cmds <<
      { type: 'all open due_first',
        member_name: i_item[:name],
        member_id: i_item[:id],
        slack_user_api_token: i_item[:slack_user_api_token],
        taskbot_channel_id: i_item[:taskbot_channel_id],
        taskbot_username: 'MiaDo Taskbot'
      }
    # ,
    # { type: 'all due',
    #  cmd: "pub @#{parsed[:mentioned_member_name]} team all due",
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
  am_hash = parsed[:ccb].members_hash[parsed[:assigned_member_id]] if impacted_task.nil?
  am_hash = parsed[:ccb].members_hash[impacted_task[:assigned_member_id]] unless impacted_task.nil?
  # taskbot_channel_id will be nil if MiaDo not installed by this member.
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
  if CMD_FUNCS_IGNORED_IF_TASK_HAS_NO_ASSIGNED_MEMBER.include?(parsed[:func])
    task = ListItem.where(id: parsed[:list][parsed[:task_num] - 1]).first
    unless task.nil?
      return nil if parsed[:func] == :redo && parsed[:assigned_member_id].nil? &&
                    task.assigned_member_id.nil?
      return nil if task.assigned_member_id.nil?
      return { db_id: task.id, assigned_member_id: task.assigned_member_id }
    end
  end
  # add, assign and unassign commands include the name of the impacted member,
  # don't need to ask db. delete and redo commands have already deleted the
  # impacted task.
  return parsed[:list_action_item_info][0] if parsed[:func] == :delete || parsed[:func] == :redo
  nil
end

# Inputs: am_hash, OPTIONAL: parsed
def build_one_impacted_member(options)
  impacted_member =
    { name: options[:parsed][:assigned_member_name],
      id: options[:parsed][:assigned_member_id] } if options.key?(:parsed)
  impacted_member =
    { name: options[:am_hash]['slack_user_name'],
      id: options[:am_hash]['slack_user_id'] } unless options.key?(:parsed)

  impacted_member[:slack_user_api_token] = options[:am_hash]['slack_user_api_token']
  impacted_member[:taskbot_channel_id] = options[:am_hash]['bot_dm_channel_id']
  [impacted_member[:id], impacted_member]
end

def build_many_impacted_members(parsed)
  impacted_members = []
  parsed[:list_action_item_info].each do |task_info|
    am_hash = parsed[:ccb].members_hash[task_info[:assigned_member_id]]
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
  added_task_hash = parsed[:ccb].members_hash[parsed[:assigned_member_id]]
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
  added_task_hash = parsed[:ccb].members_hash[parsed[:assigned_member_id]]
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
  # url_params = {}.merge(parsed[:url_params])
  # previous_action_parse_hash = nil # parsed[:ccb].after_action_parse_hash
  chat_msgs = []
  list_cmds.each do |cmd_hash|
    # url_params[:text] = cmd_hash[:cmd]
    # parsed_list_cmd = parse_slash_cmd(url_params, parsed[:ccb], previous_action_parse_hash)
    # return [err_resp(url_params, "`MiaDo ERROR: #{parsed_list_cmd[:err_msg]}`", nil), p_hash] unless parsed_list_cmd[:err_msg].empty
    # text, attachments = process_cmd(parsed_list_cmd)
    text, attachments =
      pub_command(parsed, type: cmd_hash[:type],
                          member_name: cmd_hash[:member_name],
                          member_id: cmd_hash[:member_id])
    text = "`MiaDo ERROR: #{parsed[:err_msg]}`" unless parsed[:err_msg].empty?
    chat_msgs << { text: text, attachments: attachments,
                   taskbot_username: cmd_hash[:taskbot_username],
                   taskbot_channel_id: cmd_hash[:taskbot_channel_id],
                   api_client: make_web_client(cmd_hash[:slack_user_api_token])
                 }
  end
  chat_msgs
end

# Returns: text status msg. 'ok' or err msg.
def send_taskbot_msg(options)
  begin
    api_resp =
      options[:api_client]
      .chat_postMessage(as_user: false,
                        username: options[:taskbot_username],
                        channel: options[:taskbot_channel_id],
                        text: options[:text],
                        attachments: options[:attachments])
    # options[:api_client].logger.error "\nSent taskbot msg to: " \
    puts "\nSent taskbot msg to: " \
      "#{options[:taskbot_username]} at dm_channel: " \
      "#{options[:taskbot_channel_id]}.  Msg title: #{options[:text]}\n"
    return 'ok' if api_resp.key?('ok')
    err_msg = 'Error occurred on Slack\'s API:client.im.history'
    options[:api_client].logger.error(err_msg)
    return err_msg
  rescue Slack::Web::Api::Error => e # (not_authed)
    options[:api_client].logger.error e
    options[:api_client].logger.error "\ne.message: #{e.message}\n" \
      "channel_id: #{options[:channel]}  " \
      "token: #{options[:api_client].token.nil? ? '*EMPTY!*' : options[:api_client].token}\n"
    return "ERROR: #{e.message}\n" \
  end
end

# Returns: text status msg. 'ok' or err msg.
def clear_taskbot_msg_channel(options)
  clear_channel_msgs(type: :direct,
                     api_client: options[:api_client],
                     channel_id: options[:taskbot_channel_id],
                     time_range: { start_ts: 0, end_ts: 0 },
                     exclude_bot_msgs: false)
end

# new member or a name change. Use background task to add member, update
# the ccb.members hash for all channels for this team.
def new_member_deferred_logic(p_hash, new_members_hash, new_member_name)
  # ccb = p_hash[:ccb]
  # m_hash = new_members_hash[new_member_name]
  # Thread.new do
  #  if Member.find_by_slack(view.user, ccb[:slack_team_id], m_hash[:slack_user_id]).nil?
  #    # new member, not a name change.
  #  else # name change. Update all team channels with updated members hash.
  #    Channel.set(members: new_members_hash)
  #           .where(user: view.user, slack_team_id: ccb[:slack_team_id],
  #                  slack_user_id: m_hash[:slack_user_id])
  #  end
  # end
end