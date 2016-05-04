def new_parse_hash(params, previous_action_parse_hash)
  p_hash = make_parse_hash
  p_hash[:original_command], p_hash[:debug] = check_for_debug(params)
  # Initialize() to defaults.
  p_hash[:command] = String.new(p_hash[:original_command])
  p_hash[:cmd_splits] = p_hash[:command].split(' ')
  p_hash[:url_params] = params
  p_hash[:previous_action_list_context] = context_from_channel_hash(p_hash, previous_action_parse_hash)
  p_hash
end

def make_parse_hash
  { original_command: nil,
    command: nil,
    debug: false,
    cmd_splits: [],
    team_option: false,
    all_option: false,
    open_option: false,
    due_option: false,
    done_option: false,
    err_msg: '',
    previous_action_list_context: {},
    # For current action
    list_scope: nil,
    channel_scope: nil,
    list_owner: nil,
    list_owner_name: nil,
    list: nil,
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

def context_from_channel_hash(p_hash, previous_action_parse_hash)
  # Deserialize Channel.previous_action fields of interest.
  return {} if previous_action_parse_hash.nil?
  context_s = previous_action_parse_hash['after_action_list_context']
  # First hash item is list[ids]. Pluck it out first because we don't handle
  # embedded array properly.
  ids_array = value_array(context_s.slice(context_s.index('=>') + 2, context_s.index(']') - context_s.index('=>') - 1))
  # Skip the first hash item of '[....],'
  context_s_splits = context_s.slice(context_s.index(']') + 3, context_s.length - context_s.index(']') - 4).split(', ')
  { list: ids_array,
    list_scope: hash_value(context_s_splits[0]),
    channel_scope: hash_value(context_s_splits[1]),
    list_owner: hash_value(context_s_splits[2]),
    list_owner_name: hash_value(context_s_splits[3]),
    mentioned_member_id: hash_value(context_s_splits[4]),
    mentioned_member_name: hash_value(context_s_splits[5])
  }
end

def save_after_action_list_context(parsed, context, list_ids = nil)
  parsed[:after_action_list_context] = {
    list: list_ids || context[:list_ids],
    list_scope: context[:list_scope],
    channel_scope: context[:channel_scope],
    list_owner: context[:list_owner],
    list_owner_name: context[:list_owner_name],
    mentioned_member_id: context[:mentioned_member_id],
    mentioned_member_name: context[:mentioned_member_name]
  }
  @view.channel.after_action_parse_hash = parsed
  return if @view.channel.save
  parsed[:err_msg] = '  Error: Saving after action context.'
end
