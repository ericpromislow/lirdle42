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
  # 6: I won, game over
  # 7: I lost, game over

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
      if params[:lie] && @other_state.user == @user
        # Do nothing
      else
        flash[:danger] = "You can't change someone else's game state"
        redirect_to request.referrer || root_url
        return
      end
    end
    gp = update_params
    theLie = params[:lie]
    splitWords = @game_state.candidateWords.split(':')
    if theLie
      # Remember here that @game_state is actually the other player's state
      # @user is the player who applied a lie to the other player's guess -> state
      # @other_state refers to this player's state
      # Remember here that `@other_state belongs to the current player
      if @other_state.state != 4
        flash[:error] = "Lying with an unexpected game state of #{@other_state.state}"
        redirect_to game_path(@game)
        return
      end
      lastGuess = @game_state.guesses[-1]
      scores = lastGuess.score.split(':').map(&:to_i)
      begin
        applyLie(scores, theLie, lastGuess)
      rescue
        flash[:error] = $!
        redirect_to game_path(@game)
        return
      end
      if @game_state.state == 5
        gp[:state] = 2
        @game_state.update_attribute(:state, 2)
        # TODO: Send a message to @other_user to refresh the state view
      else
        gp[:state] = 5
      end
      if @other_state.update(gp)
        @game_state, @other_state = @other_state, @game_state
      else
        flash[:error] = "Failed to update the game state"
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
          # TODO: Send a message to @other_user to regrab the game
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
          render :show, status: :ok, location: @game }
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
    head previous_words.include?(word) ?  :bad_request : :ok
  end

private
  def admin_or_own_state
    return if @user.admin?
    return if @game_state.user == @user
    if params[:lie]
      game = @game_state.game
      users = game.game_states.map(&:user)
      return if users.include?(@user.id)
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
    scores[position] = desiredColor
    guess.update_columns(liePosition: position, lieColor: desiredColor, score: scores.join(':'))
  end

  def set_game_state
    @game_state = GameState.find(params[:id])
  end

  def update_params
    params.permit(:state, :wordIndex, :finalWord)
  end
end
