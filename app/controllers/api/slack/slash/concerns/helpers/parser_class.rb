def new_parse_hash(params, ccb, previous_action_parse_hash)
  p_hash = make_parse_hash
  # Initialize to defaults.
  p_hash[:previous_action_list_context] = context_from_ccb_hash(previous_action_parse_hash)
  slash_cmd_from_buttons(params, p_hash) if params.key?('payload')
  slash_cmd_from_event(params, p_hash) if params.key?('event')
  p_hash[:original_command], p_hash[:debug] = check_for_debug(params)
  p_hash[:slash_cmd_name] = params[:command]
  p_hash[:command] = String.new(p_hash[:original_command])
  p_hash[:cmd_splits] = p_hash[:command].split
  p_hash[:url_params] = params
  p_hash[:ccb] = ccb
  p_hash
end

# Returns: url_params{}
def slash_cmd_from_buttons(url_params, p_hash)
  url_params[:command] = '/do'
  url_params[:text] = ''
  p_hash[:button_callback_id] = JSON.parse(url_params[:payload][:callback_id]).with_indifferent_access
  p_hash[:button_callback_id][:payload_action_ts] = url_params[:payload]['action_ts']
  p_hash[:button_callback_id][:payload_message_ts] = url_params[:payload]['message_ts']
  p_hash[:button_callback_id][:payload_attachment_id] = url_params[:payload]['attachment_id']
  p_hash[:button_actions] = url_params[:payload][:actions]
  p_hash[:first_button_value] = JSON.parse(url_params[:payload][:actions].first[:value]).with_indifferent_access
  p_hash[:expedite_deferred_cmd] = true
end

# Returns: url_params{}
def slash_cmd_from_event(url_params, p_hash)
  url_params[:command] = '/do'
  url_params[:text] = ''
  p_hash[:event_type] = url_params[:event]['type']
  p_hash[:expedite_deferred_cmd] = true
end

def make_parse_hash
  { original_command: nil,
    command: nil,
    slash_cmd_name: nil,
    debug: false,
    cmd_splits: [],
    is_taskbot_channel: false,
    team_option: false,
    all_option: false,
    open_option: false,
    due_option: false,
    due_first_option: false,
    done_option: false,
    taskbot_rpt: false,
    expedite_deferred_cmd: false,
    err_msg: '',
    ccb: nil,
    mcb: nil,
    tcb: nil,
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
    response_headline: nil,
    button_callback_id: nil,
    button_actions: [],
    first_button_value: nil,
    event_type: '',
    url_params: {}
  }
end

def context_from_ccb_hash(previous_action_parse_hash)
  return {} if previous_action_parse_hash.nil? ||
               previous_action_parse_hash['after_action_list_context'].nil? ||
               (context = previous_action_parse_hash['after_action_list_context']).empty?
  { list: context['list'],
    list_scope: context['list_scope'].nil? ? '' : context['list_scope'].to_sym,
    channel_scope: context['channel_scope'].nil? ? '' : context['channel_scope'].to_sym,
    list_owner: context['list_owner'].nil? ? '' : context['list_owner'].to_sym,
    list_owner_name: context['list_owner_name'],
    mentioned_member_id: context['mentioned_member_id'],
    mentioned_member_name: context['mentioned_member_name'],
    all_option: context['all_option'],
    func: context['func'].to_sym,
    original_command: context['original_command'],
    response_headline: context['response_headline'],
    button_callback_id: context['button_callback_id'],
    button_actions: context['button_actions'],
    slash_cmd_name: context['slash_cmd_name'],
    open_option: context['open_option'],
    done_option: context['done_option'],
    due_option: context['due_option'],
    taskbot_rpt: context['taskbot_rpt']
  }
end

def save_after_action_list_context(parsed, context, list_ids = nil)
  parsed[:after_action_list_context] = after_action_list_context(context, list_ids)
  # Trim what we store to db, store, restore it.
  parsed[:url_params] = {}
  parsed[:ccb], parsed[:mcb], parsed[:tcb], parsed[:api_client_bot], parsed[:api_client_user] = nil
  @view.channel.after_action_parse_hash = parsed
  @view.channel.last_activity_type =
    "#{parsed[:button_actions].any? ? 'button_action' : 'slash_command'} - #{parsed[:func]}"
  @view.channel.last_activity_date = DateTime.current
  parsed[:button_actions] = []
  ok = @view.channel.save
  parsed[:url_params] = params
  parsed[:ccb] = @view.channel
  return if ok
  parsed[:err_msg] = '  Error: Saving after action context.'
end

def after_action_list_context(context, list_ids = nil)
  { list: list_ids || context[:list_ids] || [],
    list_scope: context[:list_scope],
    channel_scope: context[:channel_scope],
    list_owner: context[:list_owner],
    list_owner_name: context[:list_owner_name],
    mentioned_member_id: context[:mentioned_member_id],
    mentioned_member_name: context[:mentioned_member_name],
    all_option: context[:all_option],
    func: context[:func],
    original_command: context[:original_command],
    button_callback_id: context[:button_callback_id],
    button_actions: context[:button_actions],
    slash_cmd_name: context[:slash_cmd_name],
    response_headline: context[:response_headline],
    open_option: context[:open_option],
    done_option: context[:done_option],
    due_option: context[:due_option],
    taskbot_rpt: context[:taskbot_rpt]
  }
end
