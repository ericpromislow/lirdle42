require "test_helper"

class GuessesControllerTest < ActionDispatch::IntegrationTest
  include GuessesHelper

  setup do
    @user = users(:user1)
  end
  test "all zeros" do
    score = calculate_score("abcde", "fghij")
    assert_equal [0, 0, 0, 0, 0], score
    assert !is_correct_score(score)
  end

  test "all twos" do
    score = calculate_score("abcde", "abcde")
    assert_equal [2, 2, 2, 2, 2], score
    assert is_correct_score(score)
  end

  test "mixed, no dupes" do
    score = calculate_score("abcde", "cdxye")
    assert_equal [0, 0, 1, 1, 2], score
    assert !is_correct_score(score)
  end

  test "mixed, with dupes" do
    score = calculate_score("clock", "block")
    assert_equal [0, 2, 2, 2, 2], score
    assert !is_correct_score(score)
  end

  test "succeeds on a valid word" do
    log_in_as(@user)
    get is_valid_word_path(word: 'motel')
    assert_response :success
  end

  test "rejects an invalid word" do
    log_in_as(@user)
    get is_valid_word_path(word: 'fqxtk')
    assert_response :not_found
  end

  test "rejects a word that's too short" do
    log_in_as(@user)
    get is_valid_word_path(word: 'fork')
    assert_response :not_found
  end

  test "rejects a word that's too long" do
    log_in_as(@user)
    get is_valid_word_path(word: 'motels')
    assert_response :not_found
  end
end
