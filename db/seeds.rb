# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Locality.create(name: "Olivos")
Locality.create(name: "Martinez", unsecure: true)

app = Rpush::Gcm::App.new
app.name = "android_app"
app.auth_key = "123"
app.connections = 1
app.save!