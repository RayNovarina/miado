# Inputs: parsed
# Returns: [text, attachments]
#          parsed[:err_msg] if needed.
#-----------------------------------
# Generate a variety of lists/reports formatted for the taskbot channel.
# Note: we don't know what channel these reports are being run on. We just
# run the list commands.
# url_params and parsed[:ccb] is the context of the member issuing the slash cmd.
# context is the parsed{} for the list command/report we want.
# Example:
#   Member john:
#   >list team
#   >assign 1 @jane
# John sends a taskbot msg to Jane's channel.
def taskbot_rpts_command(parsed, options = nil)
  url_params = {
    channel_id: parsed[:ccb].slack_channel_id,
    channel_name: parsed[:ccb].slack_channel_name,
    response_url: parsed[:url_params][:response_url],
    team_domain: parsed[:url_params][:team_domain],
    team_id: parsed[:ccb].slack_team_id,
    token: parsed[:url_params][:token],
    user_id: parsed[:ccb].slack_user_id,
    user_name: parsed[:url_params][:user_name],
    text: "list @#{options[:member_name]} all due_first"
  }
  context = parse_slash_cmd(url_params, parsed[:ccb], parsed[:ccb].after_action_parse_hash)
  return ["`MiaDo ERROR: #{context[:err_msg]}`", nil] unless context[:err_msg].empty?
  # context[:debug] = true
  # Note: this prevents the list_command from resaving an after action hash to
  #       the channel. We are just getting a list report.
  context[:display_after_action_list] = true
  list_command(context)
end
