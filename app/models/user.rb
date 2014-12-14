class User < ActiveRecord::Base
  has_secure_password
  before_create :generate_token
  validates :email, presence: true
  validates :email, uniqueness: true
  has_many :frequencies
  has_many :localities,through: :frequencies
  has_many :devices
  has_and_belongs_to_many :custom_secure_localities, class_name: "Locality", join_table: "custom_secure_localities", foreign_key: "user_id"
  has_and_belongs_to_many :custom_insecure_localities, class_name: "Locality", join_table: "custom_insecure_localities", foreign_key: "user_id"

  private
  def generate_token
    self.token = SecureRandom.uuid
  end
end
