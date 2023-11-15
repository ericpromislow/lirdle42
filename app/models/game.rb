class Game < ApplicationRecord
  has_many :game_states, dependent: :destroy
  has_one :chatroom

  def playerA
    id = (GameState.find(self.gameStateA))&.playerID
    id && User.find(id)
  end

  def playerB
    id = (GameState.find(self.gameStateB))&.playerID
    id && User.find(id)
  end

  def get_other_player_state(playerID)
    gsA = GameState.find(self.gameStateA)
    gsB = GameState.find(self.gameStateB)
    gsA.playerID == playerID ? gsB : gsA
  end

  def get_other_state(gs)

  end
end
