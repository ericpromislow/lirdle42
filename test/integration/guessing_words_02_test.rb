require "test_helper"

class GuessingWords02Test < ActionDispatch::IntegrationTest
  def setup
    @user1 = users(:user1)
    @user2 = users(:user2)
    @game = Game.create
    @gs1 = GameState.create(game: @game, playerID: @user1.id, finalWord: "block", candidateWords: "block:molar:psalm", state: 2)
    @gs2 = GameState.create(game: @game, playerID: @user2.id, finalWord: "madam", candidateWords: "fetus:madam:frown", state: 2)
    @game.update_columns(gameStateA: @gs1.id, gameStateB: @gs2.id)
    # target block
    @gs1.guesses << Guess.create(word: "space", score: "00020", liePosition: 4, lieColor: 1, guessNumber: 0)
    @gs1.guesses << Guess.create(word: "relic", score: "00101", liePosition: 2, lieColor: 0, guessNumber: 1)
    @gs1.guesses << Guess.create(word: "deuce", score: "00020", liePosition: 2, lieColor: 2, guessNumber: 2)
    # target madam
    @gs2.guesses << Guess.create(word: "triad", score: "00021", liePosition: 0, lieColor: 2, guessNumber: 0)
    @gs2.guesses << Guess.create(word: "tonal", score: "00020", liePosition: 4, lieColor: 2, guessNumber: 1)
    @gs2.guesses << Guess.create(word: "tidal", score: "00200", liePosition: 3, lieColor: 0, guessNumber: 2)
  end

  def convertWordsAndGuesses(words, scores)
    convert = { b: 'grey', y: 'yellow', g: 'green' }
    words.zip(scores).map do |word, score|
      score2 = score.split('').map {|s| convert.fetch(s.to_sym) }
      word.split('').zip(score2)
    end
  end

  def verify_expected_board(words, scores, boxSize, expected_filled_count, total_count)
    words_and_scores = convertWordsAndGuesses(words, scores).flatten(1)
    assert_equal expected_filled_count, words_and_scores.size
    assert_select 'div.letter-box.filled-box', count: expected_filled_count
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

  test "After 8 guesses verify there are 8 filled things with one blank row" do
    # target block
    @gs1.guesses << Guess.create(word: "truck", score: "00021", liePosition:4, lieColor: 1, guessNumber: 3)
    @gs1.guesses << Guess.create(word: "flock", score: "02222", liePosition:3, lieColor: 1, guessNumber: 4)
    @gs1.guesses << Guess.create(word: "clock", score: "02222", liePosition:2, lieColor: 1, guessNumber: 5)
    @gs1.guesses << Guess.create(word: "fuzzy", score: "00000", liePosition:1, lieColor: 2, guessNumber: 6) #*
    @gs1.guesses << Guess.create(word: "madam", score: "00000", liePosition:0, lieColor: 1, guessNumber: 7) #*

    # target madam
    @gs2.guesses << Guess.create(word: "dadas", score: "12020", liePosition:0, lieColor: 2, guessNumber: 3)
    @gs2.guesses << Guess.create(word: "dadah", score: "12020", liePosition:1, lieColor: 0, guessNumber: 4)
    @gs2.guesses << Guess.create(word: "radar", score: "02220", liePosition:4, lieColor: 1, guessNumber: 5)
    @gs2.guesses << Guess.create(word: "fuzzy", score: "00000", liePosition:2, lieColor: 2, guessNumber: 6) #*
    @gs2.guesses << Guess.create(word: "block", score: "00000", liePosition:3, lieColor: 1, guessNumber: 7) #*

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
    @gs1.guesses << Guess.create(word: "truck", score: "00021", liePosition:4, lieColor: 1, guessNumber: 3)
    @gs1.guesses << Guess.create(word: "flock", score: "02222", liePosition:3, lieColor: 1, guessNumber: 4)
    @gs1.guesses << Guess.create(word: "clock", score: "02222", liePosition:2, lieColor: 1, guessNumber: 5)
    @gs1.guesses << Guess.create(word: "fuzzy", score: "00000", liePosition:1, lieColor: 2, guessNumber: 6) #*
    @gs1.guesses << Guess.create(word: "madam", score: "00000", liePosition:0, lieColor: 1, guessNumber: 7) #*
    7.times do |i|
      @gs1.guesses << Guess.create(word: "madam", score: "00000", liePosition:0, lieColor: 1, guessNumber: 8 + i)
    end

    # target madam
    @gs2.guesses << Guess.create(word: "dadas", score: "12020", liePosition:0, lieColor: 2, guessNumber: 3)
    @gs2.guesses << Guess.create(word: "dadah", score: "12020", liePosition:1, lieColor: 0, guessNumber: 4)
    @gs2.guesses << Guess.create(word: "radar", score: "02220", liePosition:4, lieColor: 1, guessNumber: 5)
    @gs2.guesses << Guess.create(word: "fuzzy", score: "00000", liePosition:2, lieColor: 2, guessNumber: 6) #*
    @gs2.guesses << Guess.create(word: "block", score: "00000", liePosition:3, lieColor: 1, guessNumber: 7) #*
    7.times do |i|
      @gs2.guesses << Guess.create(word: "block", score: "00000", liePosition:3, lieColor: 1, guessNumber: 8 + i)
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
end
