# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Locality.create(name: "Olivos")

creator = User.new(name: "creator", email: "creator@email.com", password: "123456", password_confirmation: "123456")
creator.devices << Device.new(registration_id: "creator_123")
creator.save

user1 = User.new(name: "user1", email: "user1@email.com", password: "123456", password_confirmation: "123456")
user1.devices << Device.new(registration_id: "user1_123")
user1.save

user2 = User.new(name: "user2", email: "user2@email.com", password: "123456", password_confirmation: "123456")
user2.devices << Device.new(registration_id: "user2_123")
user2.save

group = Group.new(name: "group1")
group.creator = creator
group.members << user1
group.members << user2
group.save