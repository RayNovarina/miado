
=begin
  1) order flow CRM
  2) Brent & shipping info @tony | ​*Assigned:*​ @tony
  3) Kendra todo invoices @tony | ​*Assigned:*​ @tony
  4) CSM leads in @tony | ​*Assigned:*​ @tony
  5) SMP @tony | ​*Assigned:*​ @tony
  6) NEXT/APTA June @Tony | ​*Assigned:*​ @tony
  7) example newsletter @tony | ​*Assigned:*​ @tony
  8) 1 @tony | ​*Assigned:*​ @tony
=end

  def list_command(_command, debug)
    text = "<##{params['channel_id']}|#{params['channel_name']}> to-do list"
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
    slash_response(text, attachments, debug)
  end
