
def parse_slash_cmd(_func, params)
  command, _debug = check_for_debug(params)
  { command: command,
    assigned_member_id: nil,
    assigned_members_name: nil,
    due_date: nil
  }
end
