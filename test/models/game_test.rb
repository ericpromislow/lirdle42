require "test_helper"

class GameTest < ActiveSupport::TestCase
  def setup
    @user1 = users(:user1)
    @user2 = users(:user2)
  end
  test "the models make sense" do
    game = Game.create()
    gs1 = GameState.create(game: game, playerID: @user1.id, finalWord: "knell")
    gs2 = GameState.create(game: game, playerID: @user2.id, finalWord: "baton")
    game.update_columns(gameStateA: gs1, gameStateB: gs2)
    assert_equal 0, gs1.guesses.size
    assert_equal 0, gs2.guesses.size
    gs1.guesses << Guess.create(word: "fanta", score: "00100", liePosition: 0, lieDirection: -1, marks:"BBBTL", guessNumber: 0)
    gs1.guesses << Guess.create(word: "vouch", score: "00000", liePosition: 0, lieDirection: -1, marks:"BBBTL", guessNumber: 1)
    gs2.guesses << Guess.create(word: "aging", score: "10010", liePosition: 0, lieDirection: -1, marks:"BBBTL", guessNumber: 0)
    gs1.reload
    gs2.reload
    assert_equal 2, gs1.guesses.size
    assert_equal 1, gs2.guesses.size
  end
end
