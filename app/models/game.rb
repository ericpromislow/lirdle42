class Game < ApplicationRecord
  # before_destroy :destroy_game_states
  has_many :game_states, dependent: :destroy
  has_one :chatroom


  def delete
    self.game_states.destroy_all
    super
  end

  # private
  # def destroy_game_states
  #   self.game_states.destroy_all
  # end
end
