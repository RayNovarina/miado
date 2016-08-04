def new_parse_hash(params, ccb, previous_action_parse_hash)
  p_hash = make_parse_hash
  p_hash[:original_command], p_hash[:debug] = check_for_debug(params)
  # Initialize() to defaults.
  p_hash[:command] = String.new(p_hash[:original_command])
  p_hash[:cmd_splits] = p_hash[:command].split(' ')
  p_hash[:url_params] = params
  p_hash[:ccb] = ccb
  p_hash[:previous_action_list_context] = context_from_ccb_hash(p_hash, previous_action_parse_hash)
  p_hash
end

def make_parse_hash
  { original_command: nil,
    command: nil,
    debug: false,
    cmd_splits: [],
    is_taskbot_channel: false,
    team_option: false,
    all_option: false,
    open_option: false,
    due_option: false,
    done_option: false,
    err_msg: '',
    ccb: nil,
    previous_action_list_context: {},
    # For current action
    list_scope: nil,
    channel_scope: nil,
    list_owner: nil,
    list_owner_name: nil,
    list: [],
    list_info: nil,
    list_query_trace_info: '',
    requires_mentioned_member: false,
    mentioned_member_id: nil,
    mentioned_member_name: nil,
    mentioned_member_name_begin_pos: nil,
    mentioned_member_name_end_pos: nil,
    assigned_member_id: nil,
    assigned_member_name: nil,
    display_after_action_list: false,
    after_action_list_context: {},
    requires_due_date: false,
    due_date: nil,
    due_date_begin_pos: nil,
    due_date_end_pos: nil,
    due_date_string: nil,
    requires_task_num: false,
    task_num: nil,
    func: nil,
    trace_syntax: '',
    url_params: {}
  }
end

def context_from_ccb_hash(_p_hash, previous_action_parse_hash)
  return {} if previous_action_parse_hash.nil?
  context = previous_action_parse_hash['after_action_list_context']
  { list: context['list'],
    list_scope: context['list_scope'].to_sym,
    channel_scope: context['channel_scope'].to_sym,
    list_owner: context['list_owner'].to_sym,
    list_owner_name: context['list_owner_name'],
    mentioned_member_id: context['mentioned_member_id'],
    mentioned_member_name: context['mentioned_member_name'],
    all_option: context['all_option'],
    func: context['func'].to_sym,
    original_command: context['original_command'],
    open_option: context['open_option'],
    done_option: context['done_option'],
    due_option: context['due_option']
  }
end

def save_after_action_list_context(parsed, context, list_ids = nil)
  parsed[:after_action_list_context] = {
    list: list_ids || context[:list_ids] || [],
    list_scope: context[:list_scope],
    channel_scope: context[:channel_scope],
    list_owner: context[:list_owner],
    list_owner_name: context[:list_owner_name],
    mentioned_member_id: context[:mentioned_member_id],
    mentioned_member_name: context[:mentioned_member_name],
    all_option: context[:all_option],
    func: context[:func],
    original_command: context[:original_command],
    open_option: context[:open_option],
    done_option: context[:done_option],
    due_option: context[:due_option]
  }
  # Trim what we store to db, store, restore it.
  parsed[:url_params] = {}
  parsed[:ccb] = nil
  @view.channel.after_action_parse_hash = parsed
  @view.channel.last_activity_type = "slash_command - #{parsed[:func]}"
  @view.channel.last_activity_date = DateTime.current
  ok = @view.channel.save
  parsed[:url_params] = params
  parsed[:ccb] = @view.channel
  return if ok
  parsed[:err_msg] = '  Error: Saving after action context.'
end
