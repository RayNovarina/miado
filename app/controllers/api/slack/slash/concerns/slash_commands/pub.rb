# Inputs: options{} type:, member_name:, member_id:
def pub_command(parsed, options = nil)
  # Note: this prevents the list_command from resaving an after action hash to
  #       the channel. We are just getting a list report.
  parsed[:display_after_action_list] = true
  unless options.nil?
    if options[:type] == 'all open due_first'
      # //HACK
      # parsed[:debug] = true
      parsed[:list_query_trace_info] = ''
      parsed[:func] = :pub
      parsed[:mentioned_member_id] = options[:member_id]
      parsed[:mentioned_member_name] = options[:member_name]
      parsed[:assigned_member_id] = nil
      parsed[:assigned_member_name] = nil
      parsed[:task_num] = nil
      parsed[:due_date] = nil
      parsed[:team_option] = false
      parsed[:all_option] = true
      parsed[:open_option] = true
      parsed[:due_option] = true
      parsed[:done_option] = false
      parsed[:due_option] = false
      parsed[:due_first_option] = true
      parsed[:url_params][:text] = "list @#{parsed[:mentioned_member_name]} all due_first"
    end
  end
  text, attachments = list_command(parsed)
  # Prevent the CommandsController from generating the list again.
  parsed[:display_after_action_list] = false
  text = debug_headers(parsed).concat(format_pub_header(parsed, text))
  [text, attachments]
end
