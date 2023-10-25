class User < ApplicationRecord
  # For temporary users, assign email of +++TEMP+++<invitee email>, username=ADJ-NOUN, password=random-16-bytes

  attr_accessor :activation_token, :remember_token
  before_save :do_before_save
  before_create :do_create_activation_digest
  validates :username, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :email, presence: true, length: { maximum: 150 },
    format: { with: /.+@.+\.\w/ }, uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, length: { minimum: 4 }, allow_nil: true

  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  def authenticated?(attribute, token)
    return false if token.nil?
    digest = self.send("#{attribute}_digest")
    return false if digest.nil?
    # Does encrypting a_remember_token match the current remember_digest?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(self.remember_token))
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def User.digest(raw_password)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(raw_password, cost: cost)
  end

  def User.new_token
    SecureRandom.urlsafe_base64
  end

  private

  def do_before_save
    if self.is_temporary.nil?
      self.is_temporary = false
    end
    self.email.downcase!
  end

  def do_create_activation_digest
    self.inactive_logins = ApplicationHelper::NUM_FREE_LOGINS - 1
  end

end
