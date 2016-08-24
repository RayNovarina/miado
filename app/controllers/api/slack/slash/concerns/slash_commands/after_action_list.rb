# Some of our commands, such as 'add' display a confirmation msg when done But
# not a list. The syntax '/do<enter>' is a way to display the list that would
# have been displayed if the user wants the updated list displayed.
# Returns: [text, attachments] as slash_response() return values.
def after_action_list_command(parsed)
  # Fixup previous action list hash to look like a parsed hash.
  context = parsed[:previous_action_list_context]
  context[:button_callback_id] = parsed[:button_callback_id]
  context[:button_actions] = parsed[:button_actions]
  context[:err_msg] = ''
  context[:url_params] = parsed[:url_params]
  redisplay_action_list(context)
end
