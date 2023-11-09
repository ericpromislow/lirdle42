class GuessesController < ApplicationController
  include GuessesHelper

  before_action :logged_in_user
  before_action :set_logged_in_user
  def initialize
    # TODO: Replace this with the full list or a database lookup
    super
    @words ||= (IO.read('db/words/words.txt').split("\n") + IO.read('db/words/other-words.txt').split("\n")).sort
  end
  def create
    if !params[:game_state_id]
      Rails.logger.info("GuessesController#create - no game-state given in #{ params }")
      flash[:danger] = "Invalid request: no game-state"
      redirect_to root_url
      return
    end
    gs = GameState.find(params[:game_state_id]) rescue nil
    if !gs
      Rails.logger.info("GuessesController#create - no game-state given in #{ params[:game_state_id] }")
      flash[:danger] = "Invalid request: invalid game-state"
      redirect_to root_url
      return
    elsif gs.playerID != @user.id
      Rails.logger.info("GuessesController#create - current user: #{ @user.id }, game-state belongs to #{ gs.playerID }")
      flash[:danger] = "Invalid request: unexpected user"
      redirect_to root_url
      return
    end
    game = Game.find(gs.game_id)
    if !game
      Rails.logger.info("GuessesController#create - can't find game #{ gs.game_id }")
      flash[:danger] = "How did you do this?"
      redirect_to root_url
      return
    end
    @game = game
    set_game_variables(game)
    word = params[:word]
    if !word
      Rails.logger.info("GuessesController#create - no word given in #{ params[:word] }")
      flash[:danger] = "Invalid request: no guess supplied"
      render 'games/show'
      return
    elsif !@words.include?(word)
      Rails.logger.info("GuessesController#create - invalid word #{ word }")
      flash[:danger] = "Not a valid word: #{ word }"
      render 'games/show'
      return
    elsif is_already_guessed(word)
      Rails.logger.info("GuessesController#create - duplicate word #{ word }")
      flash[:danger] = %Q/You already tried "#{ word }"/
      render 'games/show'
      return
    end
    guess = build_guess_object(word, gs)
    gs.guesses << guess
    gs.state = 3
    gs.save
    @game_state.reload
    render 'games/show'
  end

  private

  def admin_or_own_state
    return if @user.admin?
    return if @game_state.playerID == @user.id

    $stderr.puts("QQQ: This isn't your part of the game!!")
    flash[:danger] = "Ummm that's cheating"
    redirect_to request.referrer || root_url
  end

  def build_guess_object(word, gs)
    playerID = gs.playerID
    otherPlayerState = gs.game.get_other_player_state(playerID)
    targetWord = otherPlayerState.finalWord
    score = calculate_score(word, targetWord)
    gs = Guess.create(word: word, score: score, liePosition: -1, marks: "", isCorrect: is_correct_score(score),
                      guessNumber: gs.guesses.size)
    return gs
  end

  def is_already_guessed(word)
    @game_state.guesses.any?{|guess| guess.word == word}
  end

  def set_game_state
    @game_state = GameState.find(params[:id])
  end
end
