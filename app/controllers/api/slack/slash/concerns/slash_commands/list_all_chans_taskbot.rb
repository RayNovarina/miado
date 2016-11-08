# Returns: [text, attachments{}, list_ids[], response_options{}]
def all_channels_taskbot_format(parsed, _context, list_of_records)
  options = { parsed: parsed, num_tasks: list_of_records.length,
              channel_scope: parsed[:channel_scope],
              caller_id: 'list: taskbot',
              attachment_info: []
            }
  # updates: options[:text, :attachments, :header_attch_idx, header_num_attch]
  options.merge!(all_chans_taskbot_header(options))
  # updates: options[:attachments, :body_attch_idx, body_num_attch, :list_ids, attachment_info]
  options.merge!(all_chans_taskbot_body(options, list_of_records))
  # updates: options[:attachments, :footer_buttons_attch_idx, footer_buttons_num_attch]
  options.merge!(all_chans_taskbot_footer(options))
  [options[:text],
   options[:attachments],
   options[:list_ids],
   parsed[:first_button_value].nil? ? nil : parsed[:first_button_value][:resp_options]]
end

# Inputs: options{parsed, channel_scope, num_tasks}
# Returns: hash of options{} fields to add, update:
#          text, attachments, header_attch_idx, header_num_attch
def all_chans_taskbot_header(options)
  text = ''
  attachments, header_attch_idx, header_num_attch =
    list_button_taskbot_header_replacement( # in list_button_taskbot.rb
      parsed: options[:parsed], rpt_headline: format_all_chans_taskbot_header(options))
  { text: text, attachments: attachments, header_attch_idx: header_attch_idx,
    header_num_attch: header_num_attch }
end

# Convert text header for @taskbot display.
# Inputs: options{parsed, channel_scope, num_tasks}
def format_all_chans_taskbot_header(options)
  parsed = options[:parsed]
  empty_text = ' *empty*' if options[:num_tasks] == 0
  empty_text = '' unless options[:num_tasks] == 0
  channel_text = 'all channels' if options[:channel_scope] == :all_channels
  channel_text = "##{parsed[:url_params]['channel_name']}" if options[:channel_scope] == :one_channel
  member_text = "TEAM's current" if parsed[:mentioned_member_name].nil?
  member_text = "@#{parsed[:mentioned_member_name]}'s current" unless parsed[:mentioned_member_name].nil?
  options_text = ''
  options_text.concat('Open') if parsed[:open_option]
  options_text.concat(', ') if parsed[:open_option] && parsed[:due_option] && parsed[:done_option]
  options_text.concat(' and ') if parsed[:open_option] && parsed[:due_option] && !parsed[:done_option]
  options_text.concat('Due') if parsed[:due_option]
  options_text.concat(' and ') if (parsed[:open_option] || parsed[:due_option]) && parsed[:done_option]
  options_text.concat('Done') if parsed[:done_option]
  "#{debug_headers(parsed)}" \
  "`#{member_text} (#{options_text}) tasks in #{channel_text}:`#{empty_text}"
  # rpt_type = "`Your #{parsed[:list_owner_name] == 'team' ? 'team\'s ' : ''}current (open) tasks in All channels:`\n"
end

# Inputs: options{parsed, attachments}, list_of_records}
# Returns: hash of options{} fields to add, update:
#          attachments, body_attch_idx, body_num_attch, list_ids
def all_chans_taskbot_body(options, list_of_records)
  parsed = options[:parsed]
  body_attch_idx = options.key?(:attachments) ? options[:attachments].length + 1 : 1
  list_ids = []
  current_channel_id = ''
  list_of_records.each_with_index do |item, index|
    unless current_channel_id == item.channel_id
      current_channel_id = item.channel_id
      options[:attachments] << {
        color: 'f8f8f8',
        text: "---- ##{item.channel_name} channel ----------",
        mrkdwn_in: ['text']
      }
      options[:attachment_info].last[:channel_last_tasknum] = index unless options[:attachment_info].empty?
      options[:attachment_info] << {
        type: 'body', attch_idx: options[:attachments].length,
        channel_txt_begin: 0,
        channel_txt_len: options[:attachments].last[:text].length,
        channel_1st_tasknum: index + 1,
        channel_last_tasknum: 0,
        channel_name: item.channel_name
        # task_info: []
      }
    end
    # list_add_item_to_taskbot_display_list(parsed, attachments, attachments.size - 1, item, index + 1)
    list_add_item_to_display_list(
      parsed, options[:attachments], options[:attachments].size - 1, item, index + 1) # in list.rb
    # task_text_len = list_add_item_to_display_list(
    #  parsed, options[:attachments], options[:attachments].size - 1, item, index + 1) # in list.rb
    list_ids << item.id
    # options[:attachment_info].last[:task_text_info] << { len: task_text_len }
  end
  options[:attachment_info].last[:channel_last_tasknum] = list_ids.size unless options[:attachment_info].empty?
  { attachments: options[:attachments], body_attch_idx: body_attch_idx,
    body_num_attch: options[:attachments].size + 1 - body_attch_idx,
    list_ids: list_ids, num_tasks: list_ids.size
  }
end

# Inputs: options{parsed, attachments, num_tasks}
# Returns: hash of options{} fields to add, update:
#          attachments, footer_buttons_attch_idx, footer_buttons_num_attch
def all_chans_taskbot_footer(options)
  taskbot_footer_attachments, footer_buttons_attch_idx, footer_buttons_num_attch =
    list_button_taskbot_footer_replacement(options)
  options[:attachments].concat(taskbot_footer_attachments) unless footer_buttons_num_attch.nil?
  { attachments: options[:attachments],
    footer_buttons_attch_idx: footer_buttons_attch_idx,
    footer_buttons_num_attch: footer_buttons_num_attch }
end

# Bottom of report buttons.
# Inputs: options{parsed, cmd, attachments, caller_id, body_attch_idx, num_tasks}
# Returns: [taskbot_footer_attachments, footer_buttons_attch_idx, footer_buttons_num_attch]
def list_button_taskbot_footer_replacement(options)
  return [[], nil, nil] if options[:num_tasks] == 0
  footer_buttons_attch_idx = options[:attachments].length + 1
  taskbot_footer_attachments =
    [{ text: '',
       fallback: 'Taskbot list',
       callback_id: { id: 'taskbot',
                      caller: options[:caller_id] || 'list: taskbot',
                      header_idx: options[:header_attch_idx],
                      header_num: options[:header_num_attch],
                      body_idx: options[:body_attch_idx],
                      body_num: options[:body_num_attch],
                      footer_but_idx: footer_buttons_attch_idx,
                      footer_but_num: 1,
                      footer_pmt_idx: options[:footer_prompt_attch_idx] || nil,
                      footer_pmt_num: options[:footer_prompt_num_attch] || nil,
                      sel_idx: options[:task_select_attch_idx] || nil,
                      sel_num: options[:task_select_num_attch] || nil,
                      num_tasks: options[:num_tasks]
                    }.to_json,
       color: 'ffffff',
       attachment_type: 'default',
       actions: [
       ]
    }]
  # Add button unless we clicked the other one.
  unless options[:parsed][:button_actions].any? &&
         options[:cmd] == 'toggle' &&
         options[:parsed][:first_button_value][:id] == 'done'
    taskbot_footer_attachments.first[:actions] << task_footer_new_button(
      options, text: 'Mark Task as Done', style: 'primary', id: 'done')
  end
  unless options[:parsed][:button_actions].any? &&
         options[:cmd] == 'toggle' &&
         options[:parsed][:first_button_value][:id] == 'done and delete'
    taskbot_footer_attachments.first[:actions] << task_footer_new_button(
      options, text: 'Delete Task', style: 'danger', id: 'done and delete')
  end
  [taskbot_footer_attachments, footer_buttons_attch_idx,
   taskbot_footer_attachments.size]
end

def task_footer_new_button(options, props)
  { name: 'picklist',
    text: props[:text],
    style: props[:style],
    type: 'button',
    value: { id: props[:id],
             ba_info: task_footer_button_attch_info(options)
           }.to_json
  }
end

# Note: source of body_attachment_info array differs:
#       IF we are being generated from a report, then get from
#       options[:attachment_info] as rpt is generated and persist on
#       button value.
#       IF picklist button click, we already have the info embedded in the
#       button value.
def task_footer_button_attch_info(options)
  return options[:parsed][:first_button_value][:ba_info] if options[:parsed][:first_button_value] &&
                                                            options[:parsed][:first_button_value][:ba_info]
  return options[:attachment_info].map { |attachment_info|
           { c_name: attachment_info[:channel_name],
             t_1st: attachment_info[:channel_1st_tasknum],
             t_last: attachment_info[:channel_last_tasknum]
            }
         } if options[:attachment_info]
  []
end

# Inputs: options{parsed, cmd, caller_id}
#         cmd CRUD operators:
#             'new':    Create or replace existing selection buttons.
#             'delete': Remove specified task selection button and refresh
#                       current Task
# selection button strip attachments.
# Returns: [task_select_attachments, task_select_num_attch]
def task_select_buttons_replacement(options)
  return [[], nil] if options[:num_tasks] == 0
  return task_select_new(options) if options[:cmd] == 'new'
  return task_select_delete(options) if options[:cmd] == 'delete'
end

# Inputs: options{parsed, caller_id, num_tasks}
# Returns: [task_select_attachments, task_select_num_attch]
def task_select_new(options)
  parsed = options[:parsed]
  options[:button_name] = parsed[:first_button_value][:id]
  options[:button_style] = 'primary' if parsed[:first_button_value][:id] == 'done'
  options[:button_style] = 'danger' if parsed[:first_button_value][:id] == 'done and delete'
  task_select_attachments = []
  # Slack supports up to 5 buttons per attachment. So we make a select buttons
  # attachment{} for each group of 5 buttons.
  groups = (1..options[:num_tasks]).to_a.in_groups_of(5, false)
  options[:task_select_num_attachments] = groups.size
  groups.each do |group|
    options[:group] = group
    options[:task_select_attachments] = task_select_attachments
    options[:sel_block] = task_select_attachments.size
    task_select_attachments << task_select_new_attachment(options)
  end
  [task_select_attachments, task_select_attachments.size]
end

def task_select_new_attachment(options)
  task_select_attachment =
    { text: '',
      fallback: 'Task select buttons',
      callback_id: { id: 'taskbot',
                     caller: options[:caller_id] || nil,
                     header_idx: options[:header_attch_idx],
                     header_num: options[:header_attch_idx],
                     body_idx: options[:body_attch_idx],
                     body_num: options[:body_num_attch],
                     footer_but_idx: options[:footer_buttons_attch_idx] || nil,
                     footer_but_num: options[:footer_buttons_num_attch] || nil,
                     footer_pmt_idx: options[:footer_prompt_attch_idx] || nil,
                     footer_pmt_num: options[:footer_prompt_num_attch] || nil,
                     sel_idx: options[:task_select_attch_idx] || nil,
                     sel_num: options[:task_select_num_attachments] || nil,
                     sel_block: options[:sel_block],
                     num_but: options[:group].size
                   }.to_json,
      color: options[:parsed][:first_button_value][:id] == 'done' ? '#00B300' : '#FF8080', # slack blue: '#3AA3E3', css light_green: #90EE90
      attachment_type: 'default',
      actions: [
      ]
    }
  options[:group].each do |tasknum|
    options[:tasknum] = tasknum
    options[:slack_channel_name] =
      channel_name_from_attachment_info(options[:body_attch_info], tasknum)
    task_select_attachment[:actions] << task_select_new_button(options)
  end
  task_select_attachment
end

def channel_name_from_attachment_info(attachment_info, tasknum)
  attachment_info.each do |info|
    return info[:c_name] if tasknum <= info[:t_last]
    '*unknown*'
  end
end

def task_select_new_button(options)
  # body_info: options[:body_attch_info],
  { name: options[:button_name],
    text: options[:tasknum].to_s,
    type: 'button',
    style: options[:button_style],
    value: { command: options[:tasknum].to_s,
             chan_name: options[:slack_channel_name]
           }.to_json
  }
end

def task_select_delete(options)

end
