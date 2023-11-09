class GameState < ApplicationRecord
  belongs_to :game
  has_many :guesses, dependent: :destroy
end
