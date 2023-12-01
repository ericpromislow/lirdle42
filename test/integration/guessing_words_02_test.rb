require "test_helper"

class GuessingWords02Test < ActionDispatch::IntegrationTest
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

  def convertWordsAndGuesses(words, scores)
    convert = { b: 'grey', y: 'yellow', g: 'green' }
    words.zip(scores).map do |word, score|
      score2 = score.split('').map {|s| convert.fetch(s.to_sym) }
      word.split('').zip(score2)
    end
  end

  def verify_expected_board(words, scores, boxSize, expected_filled_count, total_count, pending_guess='')
    words_and_scores = convertWordsAndGuesses(words, scores).flatten(1)
    assert_equal expected_filled_count, words_and_scores.size
    assert_select 'div.letter-box.filled-box', count: expected_filled_count + pending_guess.size
    assert_select 'div.letter-box', count: total_count
    count = 0
    assert_select 'div.letter-box.filled-box' do |elements|
      words_and_scores.each_with_index do |exp, i|
        elt = elements[i]
        assert_equal elt.text.strip, exp[0]
        assert_includes elt.classes, "background-#{ exp[1] }"
        assert_includes elt.classes, boxSize
        assert_includes elt.classes, "filled-box"
        count += 1
      end
    end
    assert_equal expected_filled_count, count
  end

  test "partial guesses come back uncolored" do
    log_in_as(@user1)
    patch game_state_path(@gs1, pending_guess: "ab")
    log_in_as(@user2)
    patch game_state_path(@gs2, pending_guess: "xy")

    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show2'
    verify_expected_board(%w/space relic deuce/, %w/bbbgy bbbby bbggb/, "small1", 15, 30, 'ab')
  end

  test "After 3 guesses with lies back in state 2 see 3 rows of text and 3 blank rows" do
    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show2'
    verify_expected_board(%w/space relic deuce/, %w/bbbgy bbbby bbggb/, "small1", 15, 30)

    log_in_as(@user2)
    get game_path(@game)
    assert_template 'games/_show2'
    verify_expected_board(%w/triad tonal tidal/, %w/gbbgy bbbgg bbgbb/, "small1", 15, 30)
  end

  test 'When players are looking at the lie board, they see previous guesses and lies' do
    log_in_as(@user1)
    get game_path(@game)
    # target word: block
    post guesses_path, params: {game_state_id: @gs1.id, word:"boxer" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show3'

    # Once both players have posted a guess, they should see the lie screen
    log_in_as(@user2)
    get game_path(@game)
    # target word: madam
    post guesses_path, params: {game_state_id: @gs2.id, word:"dairy" }
    assert_redirected_to game_path(@game)
    follow_redirect!
    assert_template 'games/_show4'

    # user2 sees user1's guess: 'boxer' guessing 'block'
    actual_scores = [2, 1, 0, 0, 0]
    expected = [
      %w/nbsp nbsp x e r/,
      %w/nbsp o nbsp nbsp nbsp/,
      %w/b nbsp nbsp nbsp nbsp/,
    ]
    verify_radio_buttons(actual_scores, expected)
    #TODO: verify different text when there are no previous guesses
    # targeting "block"
    expected = [
      { word: "space", score: "0:0:0:2:0", liePosition: 4, lieColor: 1, actualColor: 0 },
      { word: "relic", score: "0:0:1:0:1", liePosition: 2, lieColor: 0, actualColor: 1 },
      { word: "deuce", score: "0:0:0:2:0", liePosition: 2, lieColor: 2, actualColor: 0 },
    ]
    verify_previous_perturbed_guesses(@user1.username, expected)
    # @gs1.guesses.create(word: "space", score: "0:0:0:2:0", liePosition: 4, lieColor: 1, guessNumber: 0)
    # @gs1.guesses.create(word: "relic", score: "0:0:1:0:1", liePosition: 2, lieColor: 0, guessNumber: 1)
    # @gs1.guesses.create(word: "deuce", score: "0:0:0:2:0", liePosition: 2, lieColor: 2, guessNumber: 2)

    # user1 sees user2's guess: 'dairy' targeting 'madam'
    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show4'

    actual_scores = [1, 2, 0, 0, 0]
    expected = [
      %w/nbsp nbsp i r y/,
      %w/d nbsp nbsp nbsp nbsp/,
      %w/nbsp a nbsp nbsp nbsp/,
    ]
    verify_radio_buttons(actual_scores, expected)
    # targeting madam
    expected = [
      { word: "triad", score: "0:0:0:2:1", liePosition: 0, lieColor: 2, actualColor: 0 },
      { word: "tonal", score: "0:0:0:2:0", liePosition: 4, lieColor: 2, actualColor: 0 },
      { word: "tidal", score: "0:0:2:2:0", liePosition: 3, lieColor: 0, actualColor: 2 },
    ]
    verify_previous_perturbed_guesses(@user2.username, expected)

  end

  test "After 8 guesses verify there are 8 filled things with one blank row" do
    # target block
    @gs1.guesses << Guess.create(word: "truck", score: "0:0:0:2:1", liePosition:4, lieColor: 1, guessNumber: 3)
    @gs1.guesses << Guess.create(word: "flock", score: "0:2:2:2:2", liePosition:3, lieColor: 1, guessNumber: 4)
    @gs1.guesses << Guess.create(word: "clock", score: "0:2:2:2:2", liePosition:2, lieColor: 1, guessNumber: 5)
    @gs1.guesses << Guess.create(word: "fuzzy", score: "0:0:0:0:0", liePosition:1, lieColor: 2, guessNumber: 6) #*
    @gs1.guesses << Guess.create(word: "madam", score: "0:0:0:0:0", liePosition:0, lieColor: 1, guessNumber: 7) #*

    # target madam
    @gs2.guesses << Guess.create(word: "dadas", score: "1:2:0:2:0", liePosition:0, lieColor: 2, guessNumber: 3)
    @gs2.guesses << Guess.create(word: "dadah", score: "1:2:0:2:0", liePosition:1, lieColor: 0, guessNumber: 4)
    @gs2.guesses << Guess.create(word: "radar", score: "0:2:2:2:0", liePosition:4, lieColor: 1, guessNumber: 5)
    @gs2.guesses << Guess.create(word: "fuzzy", score: "0:0:0:0:0", liePosition:2, lieColor: 2, guessNumber: 6) #*
    @gs2.guesses << Guess.create(word: "block", score: "0:0:0:0:0", liePosition:3, lieColor: 1, guessNumber: 7) #*

    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show2'
    verify_expected_board(%w/space relic deuce truck flock clock fuzzy madam/,
                          %w/bbbgy bbbby bbggb bbbgy bggyg bgygg bgbbb ybbbb/, "small1",
                          40, 45)

    log_in_as(@user2)
    get game_path(@game)
    assert_template 'games/_show2'
    verify_expected_board(%w/triad tonal tidal dadas dadah radar fuzzy block/,
                          %w/gbbgy bbbgg bbgbb ggbgb ybbgb bgggy bbgbb bbbyb /, "small1",
                          40, 45)

  end
  test "After 15 guesses verify we have a smaller box" do
    # target block
    @gs1.guesses << Guess.create(word: "truck", score: "0:0:0:2:1", liePosition:4, lieColor: 1, guessNumber: 3)
    @gs1.guesses << Guess.create(word: "flock", score: "0:2:2:2:2", liePosition:3, lieColor: 1, guessNumber: 4)
    @gs1.guesses << Guess.create(word: "clock", score: "0:2:2:2:2", liePosition:2, lieColor: 1, guessNumber: 5)
    @gs1.guesses << Guess.create(word: "fuzzy", score: "0:0:0:0:0", liePosition:1, lieColor: 2, guessNumber: 6) #*
    @gs1.guesses << Guess.create(word: "madam", score: "0:0:0:0:0", liePosition:0, lieColor: 1, guessNumber: 7) #*
    7.times do |i|
      @gs1.guesses << Guess.create(word: "madam", score: "0:0:0:0:0", liePosition:0, lieColor: 1, guessNumber: 8 + i)
    end

    # target madam
    @gs2.guesses << Guess.create(word: "dadas", score: "1:2:0:2:0", liePosition:0, lieColor: 2, guessNumber: 3)
    @gs2.guesses << Guess.create(word: "dadah", score: "1:2:0:2:0", liePosition:1, lieColor: 0, guessNumber: 4)
    @gs2.guesses << Guess.create(word: "radar", score: "0:2:2:2:0", liePosition:4, lieColor: 1, guessNumber: 5)
    @gs2.guesses << Guess.create(word: "fuzzy", score: "0:0:0:0:0", liePosition:2, lieColor: 2, guessNumber: 6) #*
    @gs2.guesses << Guess.create(word: "block", score: "0:0:0:0:0", liePosition:3, lieColor: 1, guessNumber: 7) #*
    7.times do |i|
      @gs2.guesses << Guess.create(word: "block", score: "0:0:0:0:0", liePosition:3, lieColor: 1, guessNumber: 8 + i)
    end

    log_in_as(@user1)
    get game_path(@game)
    assert_template 'games/_show2'
    words = %w/space relic deuce truck flock clock fuzzy madam/ + ["madam"] * 7
    scores = %w/bbbgy bbbby bbggb bbbgy bggyg bgygg bgbbb ybbbb/ + ["ybbbb"] * 7
    verify_expected_board(words, scores, "small2", 15 * 5, 16 * 5)

    log_in_as(@user2)
    get game_path(@game)
    assert_template 'games/_show2'
    words = %w/triad tonal tidal dadas dadah radar fuzzy block/ + ["block"] * 7
    scores = %w/gbbgy bbbgg bbgbb ggbgb ybbgb bgggy bbgbb bbbyb/ + ["bbbyb"] * 7
    verify_expected_board(words, scores, "small2", 15 * 5, 16 * 5)

  end

  def verify_radio_buttons(actual_scores, expected)
    numMatches = 0
    assert_select 'form div.row div.letter-row-container' do |buttonContainerRows|
      assert_equal 3, buttonContainerRows.size
      buttonContainerRows.each_with_index do |buttonContainerRow, row_num|
        assert_select(buttonContainerRow, 'div.letter-row') do |buttonContainers|
          assert_equal 5, buttonContainers.size
          buttonContainers.each_with_index do |buttonContainer, i|
            expectedCharacter = expected[row_num][i]
            if expectedCharacter == 'nbsp'
              assert_select(buttonContainer, %Q<div.letter-box.filled-box.background-#{ @colors[row_num] }>) do
                numMatches += 1
                assert_select 'span' do |spanElt|
                  numMatches += 1
                  assert_equal 0, spanElt[0].text.gsub(/[[:space:]]/, '').size
                end
              end
              assert_select(buttonContainer, %Q<input[type="radio"][name="game_state[lie]"]>) do |radioButton|
                rbVal = radioButton[0].attribute('value').text
                # if "#{ i }:#{ actual_scores[i] }:#{ row_num }:#{ @colors[row_num] }" != rbVal
                #   debugger
                # end
                assert_equal "#{ i }:#{ actual_scores[i] }:#{ row_num }:#{ @colors[row_num] }", rbVal
              end
            else
              assert_select(buttonContainer, %Q<div.letter-box.filled-box.background-#{ @colors[row_num] }>) do
                numMatches += 1
                assert_select 'span' do |spanElt|
                  numMatches += 1
                  assert_equal expectedCharacter, spanElt[0].text
                end
              end
              assert_select(buttonContainer, %Q<input[type="radio"][name="game_state[lie]"]>, count: 0)
            end
          end
        end
      end
    end
  end

  def verify_previous_perturbed_guesses(username, guesses)
    if guesses.size == 0
      assert_select 'div.previous-guesses h2', count: 0
      return
    end
    guessPieces = []
    guesses.each do | guess |
      word, score, liePosition, lieColor, actualColorNum = [ guess[:word], guess[:score], guess[:liePosition], guess[:lieColor], guess[:actualColor] ]
      scores = score.split(':')
      word.split('').each_with_index do | theLetter, col_num |
        newGuessPiece = { letter: theLetter }
        scoreColor = scores[col_num].to_i
        if liePosition == col_num
          visibleColor = @colors[lieColor]
          actualColor = @colors[actualColorNum]
          newGuessPiece[:classes] = [ "background-#{visibleColor}", "actual#{actualColor}" ]
        else
          visibleColor = @colors[scoreColor]
          newGuessPiece[:classes] = [ "background-#{visibleColor}" ]
        end
        guessPieces << newGuessPiece
      end
    end
    assert_select 'div.previous-guesses' do |previousGuesses|
      assert_select 'h2', %Q<Previous guesses with lies for #{ username }:>
      assert_select 'div#game-board div.letter-row-container div.letter-row div.letter-box.filled-box' do | elements |
        assert_equal guessPieces.size, elements.size
        guessPieces.zip(elements).each_with_index do | pair, i|
          guessPiece, elt = pair
          assert_equal elt.text.strip, guessPiece[:letter]
          guessPiece[:classes].each do | cls |
            # if !elt.classes.include?(cls)
            #   debugger
            # end
            assert_includes elt.classes, cls
          end
        end
      end
    end
  end
end
