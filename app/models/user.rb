class User < ActiveRecord::Base
  has_secure_password
  before_create :generate_token
  validates :email, presence: true
  validates :email, uniqueness: true
  has_many :frequencies
  has_many :localities,through: :frequencies

  private
  def generate_token
    self.token = SecureRandom.uuid
  end
end
