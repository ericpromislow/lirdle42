require "test_helper"

require_relative '../helpers/guessing_test_helpers'
include GuessingTestHelpers

class FirstWinnerTest < ActionDispatch::IntegrationTest
  def setup
    @game = games(:game1)
    @user1 = users(:user1)
    @user2 = users(:user2)
    @gs1 = @game.game_states.create(user: @user1, finalWord: "madam", candidateWords: "fetus:madam:frown", state: 2)
    @gs2 = @game.game_states.create(user: @user2, finalWord: "block", candidateWords: "knell:molar:psalm", state: 2)
    # target block
    @gs1.guesses.create(word: "space", score: "0:0:0:2:0", liePosition: 4, lieColor: 1, guessNumber: 0)
    @gs1.guesses.create(word: "relic", score: "0:0:1:0:1", liePosition: 2, lieColor: 0, guessNumber: 1)
    @gs1.guesses.create(word: "deuce", score: "0:0:0:2:0", liePosition: 2, lieColor: 2, guessNumber: 2)
    # target madam
    @gs2.guesses.create(word: "triad", score: "0:0:0:2:1", liePosition: 0, lieColor: 2, guessNumber: 0)
    @gs2.guesses.create(word: "tonal", score: "0:0:0:2:0", liePosition: 4, lieColor: 2, guessNumber: 1)
    @gs2.guesses.create(word: "tidal", score: "0:0:2:2:0", liePosition: 3, lieColor: 0, guessNumber: 2)

    @colors = %w/grey yellow green/
  end

  test "guess with correct word moves to template 6 and second correct puts both in a tie" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"block" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show6'
    assert_select "h1", "You're a non-loser!"
    assert_select "span#result1", "You got it in 4 guesses!"
    assert_select "button#shareResults", "Copy to Clipboard"
    assert_select "p", "Waiting to see if #{ @user2.username } gets it this turn..."
    # targeting "block"
    expected = [
      { word: "space", score: "0:0:0:2:0", liePosition: 4, lieColor: 1, actualColor: 0 },
      { word: "relic", score: "0:0:1:0:1", liePosition: 2, lieColor: 0, actualColor: 1 },
      { word: "deuce", score: "0:0:0:2:0", liePosition: 2, lieColor: 2, actualColor: 0 },
      { word: "block", score: "2:2:2:2:2", isCorrect: true },
    ]
    verify_previous_perturbed_guesses(@user1.username, expected, true)

    log_in_as(@user2)
    post guesses_path, params: {game_state_id: @gs2.id, word:"madam" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show7'
    assert_select "h1", "It's a tie!"
    assert_select "span#result-tie", "You both got it in 4 guesses!"
    assert_select "button#shareResults", "Copy to Clipboard"
    expected = [
      { word: "triad", score: "0:0:0:2:1", liePosition: 0, lieColor: 2, actualColor: 0 },
      { word: "tonal", score: "0:0:0:2:0", liePosition: 4, lieColor: 2, actualColor: 0 },
      { word: "tidal", score: "0:0:2:2:0", liePosition: 3, lieColor: 0, actualColor: 2 },
      { word: "madam", score: "2:2:2:2:2", isCorrect: true },
    ]
    verify_previous_perturbed_guesses(@user2.username, expected, true)

    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show7'
    assert_select "h1", "It's a tie!"
    assert_select "span#result-tie", "You both got it in 4 guesses!"
    assert_select "button#shareResults", "Copy to Clipboard"
    expected = [
      { word: "space", score: "0:0:0:2:0", liePosition: 4, lieColor: 1, actualColor: 0 },
      { word: "relic", score: "0:0:1:0:1", liePosition: 2, lieColor: 0, actualColor: 1 },
      { word: "deuce", score: "0:0:0:2:0", liePosition: 2, lieColor: 2, actualColor: 0 },
      { word: "block", score: "2:2:2:2:2", isCorrect: true },
    ]
    verify_previous_perturbed_guesses(@user1.username, expected, true)
  end

  test "user1 with correct word moves to template 6 and user2 is wrong so they go to states 8 and 9 resp" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"block" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show6'
    assert_select "h1", "You're a non-loser!"
    assert_select "span#result1", "You got it in 4 guesses!"
    assert_select "button#shareResults", "Copy to Clipboard"
    assert_select "p", "Waiting to see if #{ @user2.username } gets it this turn..."
    # targeting "block"
    expected = [
      { word: "space", score: "0:0:0:2:0", liePosition: 4, lieColor: 1, actualColor: 0 },
      { word: "relic", score: "0:0:1:0:1", liePosition: 2, lieColor: 0, actualColor: 1 },
      { word: "deuce", score: "0:0:0:2:0", liePosition: 2, lieColor: 2, actualColor: 0 },
      { word: "block", score: "2:2:2:2:2", isCorrect: true },
    ]
    # puts response.body
    verify_previous_perturbed_guesses(@user1.username, expected, true)

    log_in_as(@user2)
    post guesses_path, params: {game_state_id: @gs2.id, word:"medal" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show9'
    assert_select "div.h1", "Sorry, you lost to #{ @user1.username }"
    assert_select "div.h2", "Your word was: #{ @gs1.finalWord }"
    # Targeting madam
    expected = [
      { word: "triad", score: "0:0:0:2:1", liePosition: 0, lieColor: 2, actualColor: 0 },
      { word: "tonal", score: "0:0:0:2:0", liePosition: 4, lieColor: 2, actualColor: 0 },
      { word: "tidal", score: "0:0:2:2:0", liePosition: 3, lieColor: 0, actualColor: 2 },
      { word: "medal", score: "2:0:2:2:0", isCorrect: false },
    ]
    verify_previous_perturbed_guesses(@user2.username, expected, true)

    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show8'
    assert_select "h1", "Congratulations, you won!"
    assert_select "span#result1", "You got it in 4 guesses!"
    assert_select "button#shareResults", "Copy to Clipboard"
    expected = [
      { word: "space", score: "0:0:0:2:0", liePosition: 4, lieColor: 1, actualColor: 0 },
      { word: "relic", score: "0:0:1:0:1", liePosition: 2, lieColor: 0, actualColor: 1 },
      { word: "deuce", score: "0:0:0:2:0", liePosition: 2, lieColor: 2, actualColor: 0 },
      { word: "block", score: "2:2:2:2:2", isCorrect: true },
    ]
    verify_previous_perturbed_guesses(@user1.username, expected, true)
  end

  test "user1 still not right, and user2 is correct so they go to states 9 and 8 resp" do
    log_in_as(@user1)
    post guesses_path, params: {game_state_id: @gs1.id, word:"fleck" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show3'
    assert_select "p", "Waiting for #{ @user2.username } to finish guessing a word."

    log_in_as(@user2)
    post guesses_path, params: {game_state_id: @gs2.id, word:"madam" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show8'
    assert_select "h1", "Congratulations, you won!"
    assert_select "span#result1", "You got it in 4 guesses!"
    assert_select "button#shareResults", "Copy to Clipboard"
    # Targeting madam
    expected = [
      { word: "triad", score: "0:0:0:2:1", liePosition: 0, lieColor: 2, actualColor: 0 },
      { word: "tonal", score: "0:0:0:2:0", liePosition: 4, lieColor: 2, actualColor: 0 },
      { word: "tidal", score: "0:0:2:2:0", liePosition: 3, lieColor: 0, actualColor: 2 },
      { word: "madam", score: "2:2:2:2:2", isCorrect: true },
    ]
    verify_previous_perturbed_guesses(@user2.username, expected, true)

    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show9'
    assert_select "div.h1", "Sorry, you lost to #{ @user2.username }"
    assert_select "div.h2", "Your word was: #{ @gs2.finalWord }"
    # targeting "block"
    expected = [
      { word: "space", score: "0:0:0:2:0", liePosition: 4, lieColor: 1, actualColor: 0 },
      { word: "relic", score: "0:0:1:0:1", liePosition: 2, lieColor: 0, actualColor: 1 },
      { word: "deuce", score: "0:0:0:2:0", liePosition: 2, lieColor: 2, actualColor: 0 },
      { word: "fleck", score: "0:2:0:2:2", isCorrect: false },
    ]
    verify_previous_perturbed_guesses(@user1.username, expected, true)
  end
end
