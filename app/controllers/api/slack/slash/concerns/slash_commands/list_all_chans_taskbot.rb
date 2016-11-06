# Returns: [text, attachments{}, list_ids[]]
def all_channels_taskbot_format(parsed, _context, list_of_records)
  options = { parsed: parsed, num_tasks: list_of_records.length,
              channel_scope: parsed[:channel_scope]
            }
  # updates: options[:text, :attachments, :header_attch_idx, header_num_attch]
  options.merge!(all_chans_taskbot_header(options))
  # updates: options[:attachments, :body_attch_idx, body_num_attch, :list_ids]
  options.merge!(all_chans_taskbot_body(options, list_of_records))
  # updates: options[:attachments, :footer_buttons_attch_idx, footer_num_attch]
  options.merge!(all_chans_taskbot_footer(options))
  [options[:text], options[:attachments], options[:list_ids]]
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
    end
    # list_add_item_to_taskbot_display_list(parsed, attachments, attachments.size - 1, item, index + 1)
    list_add_item_to_display_list(
      parsed, options[:attachments], options[:attachments].size - 1, item, index + 1) # in list.rb
    list_ids << item.id
  end
  { attachments: options[:attachments], body_attch_idx: body_attch_idx,
    body_num_attch: options[:attachments].size + 1 - body_attch_idx,
    list_ids: list_ids }
end

# Inputs: options{parsed, attachments}
# Returns: hash of options{} fields to add, update:
#          attachments, footer_buttons_attch_idx, footer_num_attch
def all_chans_taskbot_footer(options)
  taskbot_footer_attachments, footer_buttons_attch_idx, footer_num_attch =
    list_button_taskbot_footer_replacement(options)
  options[:attachments].concat(taskbot_footer_attachments)
  { attachments: options[:attachments],
    footer_buttons_attch_idx: footer_buttons_attch_idx,
    footer_num_attch: footer_num_attch }
end

# Bottom of report buttons.
# Inputs: options{parsed, cmd, attachments, caller_id, body_attch_idx, list_ids}
# Returns: [taskbot_footer_attachments, footer_buttons_attch_idx, footer_num_attch]
def list_button_taskbot_footer_replacement(options)
  footer_buttons_attch_idx = options[:attachments].length + 1
  taskbot_footer_attachments =
    [{ text: '',
       fallback: 'Taskbot list',
       callback_id: { id: 'taskbot',
                      caller_id: options[:caller_id] || 'taskbot',
                      body_attch_idx: options[:body_attch_idx],
                      body_num_attch: options[:body_num_attch],
                      footer_buttons_attch_idx: footer_buttons_attch_idx,
                      footer_num_attch: 1,
                      footer_prompt_attch_idx: nil,
                      footer_prompt_attch: nil,
                      task_select_attch_idx: nil,
                      task_select_num_attch: nil,
                      tasks: nil # options[:list_ids].to_json
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
    taskbot_footer_attachments.first[:actions] <<
      { name: 'picklist',
        text: 'Mark Task as Done',
        style: 'primary',
        type: 'button',
        value: { id: 'done' }.to_json
      }
  end
  unless options[:parsed][:button_actions].any? &&
         options[:cmd] == 'toggle' &&
         options[:parsed][:first_button_value][:id] == 'done and delete'
    taskbot_footer_attachments.first[:actions] <<
      { name: 'picklist',
        text: 'Delete Task',
        type: 'button',
        value: { id: 'done and delete' }.to_json,
        style: 'danger'
      }
  end
  [taskbot_footer_attachments, footer_buttons_attch_idx,
   taskbot_footer_attachments.size]
end

# Inputs: options{parsed, cmd, caller_id}
#         cmd CRUD operators:
#             'new':    Create or replace existing selection buttons.
#             'delete': Remove specified task selection button and refresh
#                       current Task
# selection button strip attachments.
# Returns: [task_select_attachments, task_select_num_attch]
def task_select_buttons_replacement(options)
  return task_select_new(options) if options[:cmd] == 'new'
  return task_select_delete(options) if options[:cmd] == 'delete'
end

# Inputs: options{parsed, caller_id}
# Returns: [task_select_attachments, task_select_num_attch]
def task_select_new(options)
  parsed = options[:parsed]
  button_name = parsed[:first_button_value][:id]
  button_style = 'primary' if parsed[:first_button_value][:id] == 'done'
  button_style = 'danger' if parsed[:first_button_value][:id] == 'done and delete'
  task_select_attachments = []
  task_select_attachments <<
    { text: '',
      fallback: 'Task select buttons',
      callback_id: { id: 'taskbot',
                     caller_id: options[:caller_id] || 'taskbot footer'
                   }.to_json,
      color: parsed[:first_button_value][:id] == 'done' ? '#00B300' : '#FF8080', # slack blue: '#3AA3E3', css light_green: #90EE90
      attachment_type: 'default',
      actions: [
        { name: button_name,
          text: '1',
          type: 'button',
          style: button_style,
          value: {}.to_json
        },
        { name: button_name,
          text: '2',
          type: 'button',
          style: button_style,
          value: {}.to_json
        },
        { name: button_name,
          text: '3',
          type: 'button',
          style: button_style,
          value: {}.to_json
        },
        { name: button_name,
          text: '4',
          type: 'button',
          style: button_style,
          value: {}.to_json
        },
        { name: button_name,
          text: '5',
          type: 'button',
          style: button_style,
          value: {}.to_json
        }
      ]
    }
  [task_select_attachments, task_select_attachments.size]
end

def task_select_delete(options)

end
