class GameState < ApplicationRecord
  before_create :do_before_create
  # before_destroy :do_before_destroy_guesses, prepend: true
  belongs_to :game
  has_many :guesses, dependent: :destroy
  belongs_to :user

  def delete
    self.guesses.destroy_all
    super
  end

private
  def do_before_create
    game = self.game
    if game && game.game_states.size == 2
      self.errors.add("game #{game.id} already has two states")
      raise :abort
    end
  end

  # def do_before_destroy_guesses
  #   self.guesses.destroy_all
  # end
end
