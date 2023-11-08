class Game < ApplicationRecord
  has_many :guesses, dependent: :destroy
  has_one :chatroom
end
