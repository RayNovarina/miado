
def write_new_lists(_debug)
  api_resp = { ok: true }
  lists_from_server.each do |list|
    api_resp = @view.slack_client.web_client
                    .files_upload(
                      channels: 'D0XTWH508',
                      title: list[:title],
                      content: list_to_upload_content(list),
                      filetype: 'markdown')
    next if api_resp['ok']
  end
  api_resp['ok'] ? 'ok' : 'err: write_new_lists'
end

def list_to_upload_content(list)
  content_string = ''
  list[:lines].each do |line|
    content_string.concat(pad_upload_line(line))
  end
  content_string
end

def pad_upload_line(str)
  length = 135
  (str + ' ' * length)[0, length]
end

def lists_from_server
  [
    { title: 'My Tasks',
      lines: ['1) CSM leads in',
              '2) order flow CRM',
      ]
    },
    { title: 'All Tasks',
      lines: ['1) rev 1 spec @susan /jun15 | *Assigned* to @susan | *Due* Tues. Jun 15',
              '2) order flow CRM | *Assigned* to @dawn | *Due* Mon. Jun 14',
              '3) Brent & shipping info | *Assigned* to @tony',
              '4) Kendra todo invoices | *Assigned* to @tony',
              '5) CSM leads in | *Assigned* to @dawn'
      ]
    },
    { title: 'Due Dates',
      lines: ['Mon. Jun 14(in 6 days): order flow CRM'
      ]
    }

=begin
    ,
    { title: 'Issues',
      lines: ['1) rev 1 spec @susan /jun15 | *Assigned* to @susan | *Due* Tues. Jun 15',
              '2) order flow CRM'
      ]
    },
    { title: 'Numbers',
      lines: ['1) rev 1 spec @susan /jun15 | *Assigned* to @susan | *Due* Tues. Jun 15',
              '2) order flow CRM'
      ]
    },
    { title: 'To Be Read',
      lines: ['1) rev 1 spec @susan /jun15 | *Assigned* to @susan | *Due* Tues. Jun 15',
              '2) order flow CRM'
      ]
    }
=end
  ]
end

=begin
def write_new_lists(command, debug)
  list_resp = list_command(command, debug)
  text = "\n`Original command: `  "
         .concat(command).concat("\n")
         .concat(list_resp[:text])
  api_resp = @view.slack_client.web_client
                  .chat_postMessage(
                    channel: 'D0XTWH508',
                    text: text,
                    attachments: list_resp[:attachments])
  api_resp['ok'] ? 'ok' : 'err: write_new_lists'
end
=end
