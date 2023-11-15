class Game < ApplicationRecord
  has_many :game_states, dependent: :destroy
  has_one :chatroom
end
