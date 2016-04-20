puts "Seeding database:\n"
puts 'Seeding Users, Teams, Members, Channels, ListItems'

# Create an admin user
admin_user = User.create!(
  name:     'Admin User',
  email:    'admin@example.com',
  password: 'password',
  confirmed_at: Date.today,
  role:     :admin
)

=begin
# Create a Member user with a valid email address/gravatar
test_user = User.create!(
  name:     'Test User',
  email:    'ray.novarina@wemeus.com',
  password: 'password',
  confirmed_at: Date.today,
  role:     :member
)

# Create Regular Users
3.times do
  User.create!(
    name:     Faker::Name.name,
    email:    Faker::Internet.email,
    password: 'password',
    confirmed_at: Date.today,
    role:     :member
  )
end
# Remove admin user from list that we later use to link to teams.
users = User.where('id > 1')

extra_channels_names = %w(leads developement numbers marketing)

# Create Teams
puts "\n\n******************** seeding Teams ************"
8.times do
  team = Team.create!(user:   users.sample,
                      name:   Faker::Company.name,
                      url:    Faker::Internet.url,
                      created_at: rand(10.minutes..1.year).ago,
                      slack_team_id: Faker::Number.number(10),
                      api_token: Faker::Number.number(10))
  team.channels =
    [Channel.create!(name: 'general', slack_id: Faker::Number.number(6),
                     team: team),
     Channel.create!(name: 'random', slack_id: Faker::Number.number(6),
                     team: team),
     Channel.create!(name: 'due-dates', slack_id: Faker::Number.number(6),
                     team: team),
     Channel.create!(name: 'issues', slack_id: Faker::Number.number(6),
                     team: team),
     Channel.create!(name: 'weekly-call', slack_id: Faker::Number.number(6),
                     team: team)
    ]
  if [true, false].sample
    team.channels <<
      Channel.create!(name: extra_channels_names.sample,
                      slack_id: Faker::Number.number(6),
                      team: team)
  end
  team.save!
end
teams = Team.all

# Create Members 50
puts "\n\n******************** seeding Members ************"
50.times do
  member =
    Member.create!(
      real_name: Faker::Name.name,
      team: teams.sample,
      slack_user_id: Faker::Number.number(10)
    )
  member.name = member.real_name.split(' ')[0].downcase
  channel =
    Channel.create!(name: '@'.concat(member.name),
                    slack_id: Faker::Number.number(6),
                    team: member.team)
  member.channel_id = channel.id
  member.save!
end
channels = Channel.all

# Create ListItems 200
puts "\n\n*************** seeding List Items ****************"
200.times do
  item = ListItem.create!(
    channel:  channels.sample,
    description:  Faker::SlackEmoji.activity,
    created_at: rand(1.minutes..2.weeks).ago
  )
  item.due_date = rand(-2.weeks..-1.day).seconds.ago if [true, false].sample
  item.member_id = item.channel.team.members.sample if [true, false].sample
  item.save!
end
=end

puts 'Seed finished'
puts "#{User.count} users created"
# puts "'Test user' (credentials):   '#{test_user.name}' (#{test_user.email}/#{test_user.password})"
puts "'Admin user' (credentials):  '#{admin_user.name}' (#{admin_user.email}/#{admin_user.password})"
puts "#{Team.count} Teams created"
puts "#{Member.count} Members created"
puts "#{Channel.count} Channels created"
puts "#{ListItem.count} List items created"
