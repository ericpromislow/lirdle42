class Guess < ApplicationRecord
  include GuessesHelper
  belongs_to :game_state
end
