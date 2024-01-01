class GameStatesController < ApplicationController
  before_action :logged_in_user
  before_action :set_game_state
  before_action :set_logged_in_user
  before_action :admin_or_own_state

  ###
  # Game States
  # 0: start picking a word
  # 1: one player has picked a word, waiting for the other
  # 2: guess the word
  # 3: guessed a valid word, waiting for other to guess
  # 4: pick a lie
  # 5: wait for other to pick a lie
  # 6: I won, waiting for other player's next result
  # 7: It's a tie
  # 8: I won, other player lost
  # 9: I lost
  # 10: I conceded before play started
  # 11: My opponent conceded before play started
  # 12: I conceded after play started
  # 13: My opponent conceded after play started

  def show
    @game = @game_state.game
    redirect_to game_path(@game)
  end

  # PATCH/PUT /games/1 or /games/1.json
  def update
    @game = @game_state.game
    if !@game
      flash[:danger] = "No game found"
      redirect_to request.referrer || root_url
      return
    end
    set_game_variables(@game)
    if !@user.admin && @game_state.user != @user
      flash[:danger] = "You can't change someone else's game state"
      redirect_to request.referrer || root_url
      return
    end
    gp = update_params
    if gp[:concede]
      @user.update_attribute(:waiting_for_game, true)
      @other_player.update_attribute(:waiting_for_game, true)
      if @game_state.state < 2
        @game_state.update_attribute(:state, 10)
        @other_state.update_attribute(:state, 11)
      else
        @game_state.update_attribute(:state, 12)
        @other_state.update_attribute(:state, 13)
      end
      ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'concessionBeforeStart',
        message: { id: @game.id, from: @user.id, to: @other_player.id,
          fromUsername: @user.username,
          toUsername: @other_player.username,
          fromGameState: @game_state.id,
          toGameState: @other_state.id,
        } }
      respond_to do |format|
        format.html {
          redirect_to game_path(@game) }
        format.json {
          # render :show, status: :ok, location: @game }
          render json: { status: true }
        }
      end
      return
    end
    theLie = params[:lie]
    splitWords = @game_state.candidateWords.split(':')
    if theLie
      # my @game_state contains the word I picked for the other player, but my guesses, scores, etc.
      if @game_state.state != 4
        flash[:error] = "Lying with an unexpected game state of #{@game_state.state}"
        redirect_to game_path(@game)
        return
      end
      lastGuess = @other_state.guesses[-1]
      scores = lastGuess.score.split(':').map(&:to_i)
      begin
        applyLie(scores, theLie, lastGuess)
      rescue
        flash[:error] = $!
        redirect_to game_path(@game)
        return
      end
      if @other_state.state == 5
        gp[:state] = 2
        @other_state.update_attribute(:state, 2)
        tell_player_to_reload_game(@game_state.user.id, @other_state.user.id, @game.id)
      else
        gp[:state] = 5
      end
      if !@game_state.update(gp)
        flash[:error] = "Failed to update the game state"
        Rails.logger.debug("Error updating game state: #{ gp.errors.full_messages }")
      end
      redirect_to game_path(@game)
      return
    else
      if @game_state.state == 0
        if gp[:finalWord]
          gp[:state] = 1
        else
          wordIndex = gp[:wordIndex].to_i || @game_state.wordIndex + 1
          if wordIndex >= splitWords.size
            gp[:finalWord] = splitWords[-1]
            gp[:state] = 1
          elsif gp[:wordIndex].nil?
            gp[:wordIndex] = wordIndex
          end
        end
        if gp[:state] == 1 && @other_state.state == 1
          gp[:state] = 2
          @other_state.update_attribute(:state, 2)
          tell_player_to_reload_game(@game_state.user.id, @other_state.user.id, @game.id)
        end
      elsif @game_state.state == 4
        flash[:error] = "You need to pick a lie"
        redirect_to game_path(@game)
        return
      end
    end
    respond_to do |format|
      if @game_state.update(gp)
        format.html {
          redirect_to game_path(@game) }
        format.json {
          # render :show, status: :ok, location: @game }
          render json: { status: true }
        }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game_state.errors, status: :unprocessable_entity }
      end
    end
  end

  def is_duplicate_guess
    word = params[:word]
    if !word
      Rails.logger.info("is_duplicate_guess: word: #{word}")
      head :bad_query
      return
    end
    previous_words = @game_state.guesses.map(&:word)
    render json: { status: previous_words.include?(word) }
  end

private
  def admin_or_own_state
    return if @user.admin?
    return if @game_state.user == @user
    if params[:lie]
      game = @game_state.game
      users = game.game_states.map(&:user)
      return if users.include?(@user)
    end

    # $stderr.puts("QQQ: game_states_controller: admin_or_own_state: This isn't your part of the game!!")
    flash[:danger] = "Ummm that's cheating"
    redirect_to request.referrer || root_url
  end

  def applyLie(scores, radioButtonLieValue, guess)
    buttonParts = radioButtonLieValue.split(':')
    position = buttonParts[0].to_i
    currentColor = buttonParts[1].to_i
    if scores[position] != currentColor
      $stderr.puts "QQQ: Invalid lie #{ radioButtonLieValue }"
      raise "Invalid lie #{ radioButtonLieValue }"
    end
    desiredColor = buttonParts[2].to_i
    guess.update_columns(liePosition: position, lieColor: desiredColor)
  end

  def set_game_state
    @game_state = GameState.find(params[:id])
  end

  def update_params
    params.permit(:concede, :state, :wordIndex, :finalWord, :pending_guess)
  end
end
