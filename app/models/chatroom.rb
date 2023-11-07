class Chatroom < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :users, through: :messages
  validates :topic, presence: true, uniqueness: { case_sensitive: false }
  before_validation :sanitize, :slugify

  def to_param
    self.slug
  end

  def slugify
    self.slug = self
  end

  private def sanitize_for_mass_assignment(attributes)
    self.topic.strip!
  end
end
