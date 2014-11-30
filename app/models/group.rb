class Group < ActiveRecord::Base
  belongs_to :creator, class_name: "User",
           foreign_key: "user_id"
  has_and_belongs_to_many :members, class_name: "User", join_table: "users_groups", foreign_key: "group_id"
end
