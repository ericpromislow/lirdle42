# Create a main sample user.
User.create!(username: "joe",
  email: "joe@joe.com",
  password:              "secret",
  admin: true,
  password_confirmation: "secret",
  activated: true,
  activated_at: Time.zone.now
)

require 'faker'
# Generate a bunch of additional users.
99.times do |n|
  first_name = Faker::Name.first_name
  last_name = Faker::Name.last_name
  domain_name = Faker::Internet.domain_name.sub('.example','.org').sub('.test', '.com')
  email = "#{first_name[0].downcase}#{last_name.downcase}@#{domain_name}"
  password = "secret"
  User.create!(username: "#{first_name} #{last_name}",
    email: email,
    activated: true,
    activated_at: Time.zone.now,
    password:              password,
    password_confirmation: password)
end
