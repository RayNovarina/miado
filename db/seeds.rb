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

# Create a Member user with a valid email address/gravatar
test_user = User.create!(
  name:     'Test User',
  email:    'ray.novarina@wemeus.com',
  password: 'password',
  confirmed_at: Date.today,
  role:     :member
)

# Create Regular Users
5.times do
  User.create!(
    name:     Faker::Name.name,
    email:    Faker::Internet.email,
    password: 'password',
    confirmed_at: Date.today,
    role:     :member
  )
end
users = User.all

# Create Teams 10
puts 'Seeding Teams'
10.times do
  Team.create!(
    user:   users.sample,
    name:   Faker::Company.name,
    url:    Faker::Internet.url
  )
end
teams = Team.all

# Create ListItems 50
puts "\n\n*************** seeding List Items ****************"
# 50.times do
#  event = Event.create!(
#    registered_application:  registered_applications.sample,
#    name:  Faker::SlackEmoji.activity
#  )
#  event.update_attribute(:created_at, rand(10.minutes..1.year).ago)
# end

puts 'Seed finished'
puts "#{User.count} users created"
puts "'Test user' (credentials):   '#{test_user.name}' (#{test_user.email}/#{test_user.password})"
puts "'Admin user' (credentials):  '#{admin_user.name}' (#{admin_user.email}/#{admin_user.password})"
puts "#{Team.count} Teams created"
# puts "#{Event.count} Events created"
