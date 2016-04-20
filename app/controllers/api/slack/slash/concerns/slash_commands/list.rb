def list_command(debug)
  params = @view.url_params
  text, attachments = process_list_cmd(params)
  text.concat("\n`Original command: `  ").concat(params[:text]) if debug
  slash_response(text, attachments, debug)
end

=begin
  Form Params
  channel_id	C0VNKV7BK
  channel_name	general
  command	/do
  response_url	https://hooks.slack.com/commands/T0VN565N0/36163731489/YAHWUMXlBdviTE1rBILELuFK
  team_domain	shadowhtracteam
  team_id	T0VN565N0
  text	add
  token	3ZQVG7rk4p7EZZluk1gTH3aN
  user_id	U0VLZ5P51
  user_name	ray
=end

def process_list_cmd(params)
  # parsed_cmd = parse_slash_cmd(:list, params)
  list = ListItem.where(channel_id: params[:channel_id])
  text = "<##{params['channel_id']}|#{params['channel_name']}> to-do list" \
         "#{list.empty? ? ' (empty)' : ''}"
  attachments = []
  list.each_with_index do |item, index|
    # { text: '1) rev 1 spec @susan /jun15 | *Assigned* to @susan | *Due* Tues. Jun 15',
    #  mrkdwn_in: ['text']
    # }
    attachments << {
      text: "#{index + 1}) #{item.description}",
      mrkdwn_in: ['text']
    }
  end
  [text, attachments]
end

=begin
  1) order flow CRM
  2) Brent & shipping info @tony | ​*Assigned:*​ @tony
  3) Kendra todo invoices @tony | ​*Assigned:*​ @tony
  4) CSM leads in @tony | ​*Assigned:*​ @tony
  5) SMP @tony | ​*Assigned:*​ @tony
  6) NEXT/APTA June @Tony | ​*Assigned:*​ @tony
  7) example newsletter @tony | ​*Assigned:*​ @tony
  8) 1 @tony | ​*Assigned:*​ @tony

  attachments = [
      { text: '1) rev 1 spec @susan /jun15 | *Assigned* to @susan | *Due* Tues. Jun 15',
        mrkdwn_in: ['text']
      },
      { text: '2) order flow CRM',
        mrkdwn_in: ['text']
      },
      { text: '3) Brent & shipping info | *Assigned* to @tony',
        mrkdwn_in: ['text']
      },
      { text: '4) Kendra todo invoices | *Assigned* to @tony',
        mrkdwn_in: ['text']
      },
      { text: '5) CSM leads in | *Assigned* to @dawn',
        mrkdwn_in: ['text']
      },
      { text: '6) SMP @tony | *Assigned* to @tony',
        mrkdwn_in: ['text']
      },
      { text: '7) NEXT/APTA /jun | *Assigned* to @susan | *Due* Mon. Jun 1',
        mrkdwn_in: ['text']
      },
      { text: '8) example newsletter | *Assigned* to @tony',
        mrkdwn_in: ['text']
      }
  ]
=end
