#
class TeamPolicy < ApplicationPolicy
  # Permission to view a list of teams.
  # If authorized? request from controller we assume that record = @teams[]
  # Else could be permission to display link, i.e. policy(Team)
  def index?
    return false unless user.present?
    # Only check for user if record is an array of Team objs
    return true if (defined? record.length).nil? || record.empty?
    record.first.user == user
  end
end
