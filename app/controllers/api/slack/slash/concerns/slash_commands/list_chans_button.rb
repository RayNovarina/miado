# Returns: [text, attachments]
def button_lists(parsed, list_of_records)
  return button_my_tasks_display(parsed, list_of_records) if parsed[:list_scope] == :one_member
  button_team_display(parsed, list_of_records) # if parsed[:channel_scope] == :team
end

def button_my_tasks_display(parsed, list_of_records)
  text, attachments = my_tasks_header_button_action(parsed, list_of_records)
  list_ids = one_chan_body(parsed, text, attachments, list_of_records)
  # list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

# Returns [text, attachments]
def my_tasks_header_button_action(parsed, _list_of_records, _add_chan_name = false)
  rpt_type = "`Your #{parsed[:list_scope] == :team ? 'team\'s ' : ''}current (open) tasks in this channel:`"
  rpt_headline = "#{parsed[:response_headline]}\n\n#{rpt_type}"
  text = ''
  attachments = [
    { text: '',
      fallback: 'Do not view list',
      callback_id: 'add task',
      color: 'ffffff',
      actions: [
        { name: 'list',
          text: 'Team Open Tasks',
          type: 'button',
          value: 'team'
        }
      ]
    },
    { pretext: rpt_headline,
      text: '',
      color: 'ffffff',
      mrkdwn_in: ['pretext']
    }
  ]
  [text, attachments]
end

def button_team_display(parsed, list_of_records)
  text, attachments = team_header_button_action(parsed, list_of_records)
  list_ids = one_chan_body(parsed, text, attachments, list_of_records)
  # list_chan_footer(parsed, context, list_of_records, text, attachments)
  [text, attachments, list_ids]
end

# Returns [text, attachments]
def team_header_button_action(parsed, _list_of_records, _add_chan_name = false)
  rpt_type = "`Your #{parsed[:list_scope] == :team ? 'team\'s ' : ''}current (open) tasks in this channel:`"
  rpt_headline = "#{parsed[:response_headline]}\n\n#{rpt_type}"
  text = ''
  attachments = [
    { text: '',
      fallback: 'Do not view list',
      callback_id: 'add task',
      color: 'ffffff',
      actions: [
        { name: 'list',
          text: 'My Open Tasks',
          type: 'button',
          value: '@me'
        }
      ]
    },
    { pretext: rpt_headline,
      text: '',
      color: 'ffffff',
      mrkdwn_in: ['pretext']
    }
  ]
  [text, attachments]
end
