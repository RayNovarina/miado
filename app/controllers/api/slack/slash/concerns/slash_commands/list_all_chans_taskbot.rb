# Purpose: Completely rebuild and replace existing taskbot reports msg.
# Returns: [text, attachments{}, list_ids[], response_options{}]
def all_channels_taskbot_format(parsed, _context, list_of_records)
  options = { parsed: parsed, num_tasks: list_of_records.length,
              channel_scope: parsed[:channel_scope],
              caller_id: 'list: taskbot',
              attachment_info: [],
              prompt_msg: parsed[:prompt_msg]
            }
  # updates: options[:text, :attachments, :header_attch_idx, header_num_attch]
  options.merge!(all_chans_taskbot_header(options))
  # updates: options[:attachments, :body_attch_idx, body_num_attch, :list_ids #, attachment_info]
  options.merge!(all_chans_taskbot_body(options, list_of_records))
  # updates: options[:attachments, :footer_buttons_attch_idx, footer_buttons_num_attch, :footer_prompt_attch_idx, footer_prompt_num_attch]
  options.merge!(all_chans_taskbot_footer(options))
  # NOTE: any remaining attachments in the existing message, i.e. select
  #       buttons, are not written back.
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
      # options[:attachment_info].last[:channel_last_tasknum] = index unless options[:attachment_info].empty?
      # options[:attachment_info] << {
      #  type: 'body', attch_idx: options[:attachments].length,
      #  channel_txt_begin: 0,
      #  channel_txt_len: options[:attachments].last[:text].length,
      #  channel_1st_tasknum: index + 1,
      #  channel_last_tasknum: 0,
      #  channel_name: item.channel_name
      #  # task_info: []
      # }
    end
    # list_add_item_to_taskbot_display_list(parsed, attachments, attachments.size - 1, item, index + 1)
    list_add_item_to_display_list( # in list.rb
      parsed, options[:attachments], options[:attachments].size - 1, item, index + 1) # in list.rb
    # task_text_len = list_add_item_to_display_list(
    #  parsed, options[:attachments], options[:attachments].size - 1, item, index + 1) # in list.rb
    list_ids << item.id
    # options[:attachment_info].last[:task_text_info] << { len: task_text_len }
  end
  # options[:attachment_info].last[:channel_last_tasknum] = list_ids.size unless options[:attachment_info].empty?
  { attachments: options[:attachments], body_attch_idx: body_attch_idx,
    body_num_attch: options[:attachments].size + 1 - body_attch_idx,
    list_ids: list_ids, num_tasks: list_ids.size
  }
end

# Inputs: options{parsed, attachments, num_tasks}
# Returns: hash of options{} fields to add, update:
#          attachments, footer_buttons_attch_idx, footer_buttons_num_attch
def all_chans_taskbot_footer(options)
  # NOTE: footer buttons and/or footer prompts are optional.
  # Do the prompt attachments first, we need idx field for footer_attachments.
  footer_prompt_attachments, footer_prompt_num_attch =
    list_button_taskbot_footer_prompt_replacement(options)
  taskbot_footer_attachments, footer_buttons_attch_idx, footer_buttons_num_attch =
    list_button_taskbot_footer_replacement(options)
  # Update the button caller_id info for the footer_buttons now that we know
  # the postion of the footer_prompt attachments, if any.
  footer_prompt_attch_idx =
    list_button_taskbot_update_footer_attachments(
      options, footer_prompt_num_attch, taskbot_footer_attachments,
      footer_buttons_attch_idx, footer_buttons_num_attch)
  options[:attachments].concat(taskbot_footer_attachments) unless footer_buttons_num_attch.nil?
  options[:attachments].concat(footer_prompt_attachments) unless footer_prompt_num_attch.nil?
  { attachments: options[:attachments],
    footer_buttons_attch_idx: footer_buttons_attch_idx,
    footer_buttons_num_attch: footer_buttons_num_attch,
    footer_prompt_attch_idx: footer_prompt_attch_idx,
    footer_prompt_num_attch: footer_prompt_num_attch
  }
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
                      sel_idx: options[:task_select_attch_idx] || nil
                    }.to_json,
       color: 'ffffff',
       attachment_type: 'default',
       actions: [
       ]
    }]
  # If in toggle mode, Add button unless we clicked the other one.
  # Otherwise, add the button.
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

def task_footer_new_button(_options, props)
  { name: 'picklist',
    text: props[:text],
    style: props[:style] || 'default',
    type: 'button',
    value: { id: props[:id] }.to_json
  }
end

# Inputs: options{parsed, caller_id, :select_list_info}
# Returns: [task_select_attachments, task_select_num_attch]
def task_select_buttons_replacement(options)
  parsed = options[:parsed]
  options[:button_name] = parsed[:first_button_value][:id]
  options[:button_style] = 'primary' if options[:button_name] == 'done'
  options[:button_style] = 'danger' if options[:button_name] == 'done and delete'
  task_select_attachments_from_select_list_info(options)
end

=begin
    { name: 'general',
      options: [{ tasknum: 1},{ tasknum: 2},{ tasknum: 3}]
    },
    { name: 'issues',
      options: [{ tasknum: 4}]
    }
=end
# Inputs: options: {:select_list_info],button_name: button_name, button_style}
# Returns: [task_select_attachments, task_select_num_attch]
def task_select_attachments_from_select_list_info(options)
  task_select_attachments = []
  options[:select_row_num] = 0
  options[:group] = []
  # Slack supports up to 5 buttons per attachment. So we make a select buttons
  # attachment{} for each group of 5 buttons.
  options[:select_list_info][:select_lists].each do |sel_list|
    # New select_list, new channel.
    sel_list[:options].each do |sel_option|
      options[:group] << sel_option[:value]
      # { slack_channel_name: sel_list[:name],
      #   tasknum: sel_option[:tasknum]
      # }
      next unless options[:group].size == 5
      # Max line of 5 buttons - same channel.
      task_select_attachments << task_select_new_attachment(options)
      options[:select_row_num] += 1
      options[:group] = []
    end
  end
  # Flush remaining buttons to a new button strip.
  task_select_attachments << task_select_new_attachment(options) unless options[:group].empty?
  [task_select_attachments, task_select_attachments.size]
end

# Up to 5 buttons per attachment.
# Inputs: options: { :task_select_attch_idx, :select_row_num,
#                    :group, :button_name, :button_style, :slack_channel_name
#                  }
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
                     sel_idx: options[:task_select_attch_idx],
                     select_row_num: options[:select_row_num]
                   }.to_json,
      color: options[:parsed][:first_button_value][:id] == 'done' ? '#00B300' : '#FF8080', # slack blue: '#3AA3E3', css light_green: #90EE90
      attachment_type: 'default',
      actions: [
      ]
    }
  options[:group].each do |props|
    options[:tasknum] = props[:tasknum]
    options[:slack_channel_name] = props[:slack_channel_name]
    task_select_attachment[:actions] << task_select_new_button(options)
  end
  task_select_attachment
end

def task_select_new_button(options)
  { name: options[:button_name],
    text: options[:tasknum].to_s,
    type: 'button',
    style: options[:button_style],
    value: { command: options[:tasknum].to_s,
             chan_name: options[:slack_channel_name]
           }.to_json
  }
end

# Inputs: options{parsed, :prompt_msg}
# Returns: [footer_prompt_attachments, footer_prompt_attch]
def list_button_taskbot_footer_prompt_replacement(options)
  return [nil, nil] if options[:prompt_msg].nil?
  footer_prompt_attachments =
    [pretext: options[:prompt_msg], mrkdwn_in: ['pretext']]
  [footer_prompt_attachments, footer_prompt_attachments.size]
end

# Update the button caller_id info for the footer_buttons now that we know
# the postion of the footer_prompt attachments, if any.
# Inputs: options{}, etc.
# Returns: footer_prompt_attch_idx, updates taskbot_footer_attachments[]
def list_button_taskbot_update_footer_attachments(
      options, footer_prompt_num_attch, taskbot_footer_attachments,
      footer_buttons_attch_idx, footer_buttons_num_attch)
  return nil if footer_prompt_num_attch.nil?
  return options[:attachments].length + 1 if footer_buttons_num_attch.nil?
  footer_prompt_attch_idx = footer_buttons_attch_idx + footer_buttons_num_attch
  taskbot_footer_attachments.each do |footer_attch|
    list_button_footer_update_footer_indexes(
      footer_attch,
      footer_prompt_attch_idx,
      footer_prompt_num_attch)
  end
  footer_prompt_attch_idx
end

def list_button_footer_update_footer_indexes(footer_attch,
                                             footer_prompt_attch_idx,
                                             footer_prompt_num_attch)
end

=begin
if footer_prompt_num_attch.nil?
  footer_prompt_attch_idx = nil
elsif footer_buttons_num_attch.nil?
  footer_prompt_attch_idx = options[:attachments].length + 1
else # have footer button attachments.
  footer_prompt_attch_idx = footer_buttons_attch_idx + footer_buttons_num_attch
end
options[:task_select_attachments].each do |task_sel_attch|
  update_footer_attachment_indexes(task_sel_attch, options[:body_attachments])
end


# HACK: assume just one footer button attachment.
unless footer_prompt_num_attch.nil?
  taskbot_footer_attachments[0][:callback_id][:footer_pmt_idx] =
    footer_prompt_attch_idx
    # callback_id_as_json_org = attachment['callback_id']
    callback_id_as_hash = JSON.parse(attachment['callback_id']).with_indifferent_access

    callback_id_as_hash['body_num'] = body_attachments.size
    callback_id_as_hash['footer_but_idx'] =
      callback_id_as_hash['body_idx'] + callback_id_as_hash['body_num']
    callback_id_as_hash['footer_pmt_idx'] =
      callback_id_as_hash['footer_but_idx'] + callback_id_as_hash['footer_but_num']
    callback_id_as_hash['sel_idx'] =
      callback_id_as_hash['footer_pmt_idx'] + callback_id_as_hash['footer_pmt_num']
    # callback_id_as_json = callback_id_as_hash.to_json
    attachment['callback_id'] = callback_id_as_hash.to_json
end
=end
