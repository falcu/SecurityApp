class User < ActiveRecord::Base
  has_secure_password
  before_create :generate_token

  private
  def generate_token
    self.token = SecureRandom.uuid
  end
end
