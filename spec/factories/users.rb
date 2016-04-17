FactoryGirl.define do
  sequence :name do |n|
    "Test#{n} Last"
  end
end

FactoryGirl.define do
  factory :user, class: 'User' do
    name
    email { Faker::Internet.email }
    password '12345678'
    password_confirmation '12345678'
    confirmed_at Date.today
  end
end
