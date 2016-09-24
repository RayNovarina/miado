def new_parse_hash(params, ccb, previous_action_parse_hash)
  p_hash = make_parse_hash
  # Initialize to defaults.
  p_hash[:previous_action_list_context] = context_from_ccb_hash(previous_action_parse_hash)
  slash_cmd_from_buttons(params, p_hash) if params.key?('payload')
  p_hash[:original_command], p_hash[:debug] = check_for_debug(params)
  p_hash[:slash_cmd_name] = params[:command]
  p_hash[:command] = String.new(p_hash[:original_command])
  p_hash[:cmd_splits] = p_hash[:command].split(' ')
  p_hash[:url_params] = params
  p_hash[:ccb] = ccb
  p_hash
end

# Returns: url_params{}
def slash_cmd_from_buttons(url_params, p_hash)
  payload = JSON.parse(url_params[:payload])
  url_params[:command], url_params[:text] = slash_text_from_button_action(payload, p_hash[:previous_action_list_context])
  p_hash[:button_callback_id] = payload['callback_id']
  p_hash[:button_actions] = payload['actions']
  p_hash[:expedite_deferred_cmd] = true
end

=begin
payload
{ "actions":
  [ { "name": "current",
      "value":"current"
    }
  ],
  "callback_id": "add task",
  "team": { "id": "T0VN565N0",
            "domain": "shadowhtracteam"
          },
  "channel": { "id": "C0VNKV7BK",
               "name":"general"
             },
  "user":{ "id": "U0VLZ5P51",
           "name": "ray"
         },
  "action_ts":  "1471889255.440177",
  "message_ts": "1471887983.000005",
  "attachment_id": "1",
  "token": "eUPXYEyP40qAztzCdmDANPHt",
  "response_url": "https:\/\/hooks.slack.com\/actions\/T0VN565N0\/71765025092\/PqNOdvwhqVPZbAJGhQwIG0Zo"
}
=end
# Returns: [ url_params[:command], url_params[:text] ]
def slash_text_from_button_action(payload, previous_action_list_context)
  command = '/do' if previous_action_list_context.empty?
  command = previous_action_list_context[:slash_cmd_name] unless previous_action_list_context.empty?
  text = ''
  text = text_from_add_task(payload) if payload['callback_id'] == 'add task'
  text = text_from_taskbot_done(payload) if payload['callback_id'] == 'task is done'
  [command, text]
end

def text_from_add_task(_payload)
  ''
end

# //HACK
def text_from_taskbot_done(payload)
  "done #{payload['actions'][0]['value']}"
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
    expedite_deferred_cmd: false,
    err_msg: '',
    ccb: nil,
    mcb: nil,
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
    url_params: {}
  }
end

def context_from_ccb_hash(previous_action_parse_hash)
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
    response_headline: context['response_headline'],
    button_callback_id: context['button_callback_id'],
    button_actions: context['button_actions'],
    slash_cmd_name: context['slash_cmd_name'],
    open_option: context['open_option'],
    done_option: context['done_option'],
    due_option: context['due_option']
  }
end

def save_after_action_list_context(parsed, context, list_ids = nil)
  parsed[:after_action_list_context] = after_action_list_context(context, list_ids)
  # Trim what we store to db, store, restore it.
  parsed[:url_params] = {}
  parsed[:ccb] = nil
  parsed[:mcb] = nil
  @view.channel.after_action_parse_hash = parsed
  @view.channel.last_activity_type = "slash_command - #{parsed[:func]}"
  @view.channel.last_activity_date = DateTime.current
  ok = @view.channel.save
  parsed[:url_params] = params
  parsed[:ccb] = @view.channel
  return if ok
  parsed[:err_msg] = '  Error: Saving after action context.'
end

def after_action_list_context(context, list_ids)
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
    due_option: context[:due_option]
  }
end
