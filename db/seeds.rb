# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Locality.create(name: "Olivos")
Locality.create(name: "Acassuso")
Locality.create(name: "Florida")
Locality.create(name: "San isidro")
Locality.create(name: "Martinez", insecure: true)
Locality.create(name: "Vicente López Partido")

app = Rpush::Gcm::App.new
app.name = "android_app"
app.auth_key = "AIzaSyAzvDbjBqR65YEVc21goUpVsm8jpH3aRIE"
app.connections = 1
app.save!


user_prefix = "user"
i = 0
n = 5

until i > n do
  name = user_prefix + (i+1).to_s
  email = name + "@hotmail.com"
  reg_id = name + "_" + (i+1).to_s
  user = User.create(name: name, email: email, password: "123456")
  user.devices << Device.new(registration_id: reg_id)
  user.save
  i=i+1
end