class GameState < ApplicationRecord
  before_create :do_before_create
  belongs_to :game
  has_many :guesses, dependent: :destroy
  belongs_to :user

private
  def do_before_create
    game = self.game
    if game && game.game_states.size == 2
      self.errors.add("game #{game.id} already has two states")
      raise :abort
    end
  end
end
