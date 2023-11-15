require "test_helper"

class GameTest < ActiveSupport::TestCase
  def setup
    @user1 = users(:user1)
    @user2 = users(:user2)
  end
  test "the models make sense" do
    game = Game.create()
    game.game_states.create(user: @user1, finalWord: "knell")
    game.game_states.create(user: @user2, finalWord: "baton")
    gs1 = game.game_states[0]
    gs2 = game.game_states[1]
    assert_equal 0, gs1.guesses.size
    assert_equal 0, gs2.guesses.size
    gs1.guesses.create(word: "fanta", score: "00100", liePosition: 0, lieColor: 2, marks:"BBBTL", guessNumber: 0)
    gs1.guesses.create(word: "vouch", score: "00000", liePosition: 0, lieColor: 2, marks:"BBBTL", guessNumber: 1)
    gs2.guesses.create(word: "aging", score: "10010", liePosition: 0, lieColor: 0, marks:"BBBTL", guessNumber: 0)
    gs1.reload
    gs2.reload
    assert_equal 2, gs1.guesses.size
    assert_equal 1, gs2.guesses.size
  end
end
