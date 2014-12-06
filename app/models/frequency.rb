class Frequency < ActiveRecord::Base
  belongs_to :user
  belongs_to :locality
end
