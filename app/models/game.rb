class Game < ApplicationRecord
  has_many :guesses
  has_one :chatroom
end
