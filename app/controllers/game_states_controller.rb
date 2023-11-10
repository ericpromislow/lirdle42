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

  # PATCH/PUT /games/1 or /games/1.json
  def update
    # debugger
    @game = @game_state.game
    if !@game
      flash[:danger] = "No game found"
      redirect_to request.referrer || root_url
      return
    end
    set_game_variables(@game)
    if !@user.admin && @game_state.playerID != @user.id
      if params[:lie] && @other_state.playerID == @user.id
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
        render 'games/show'
        return
      end
      lastGuess = @game_state.guesses[-1]
      scores = lastGuess.score.split(':').map(&:to_i)
      applyLie(scores, theLie, lastGuess)
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
      render 'games/show'
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
        render 'games/show'
        return
      end
    end
    respond_to do |format|
      if @game_state.update(gp)
        format.html { render 'games/show' }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game_state.errors, status: :unprocessable_entity }
      end
    end
  end

private
  def admin_or_own_state
    return if @user.admin?
    return if @game_state.playerID == @user.id
    if params[:lie]
      game = @game_state.game
      gsA = GameState.find(game.gameStateA)
      gsB = GameState.find(game.gameStateB)
      return if [gsA.playerID, gsB.playerID].include?(@user.id)
    end

    $stderr.puts("QQQ: This isn't your part of the game!!")
    flash[:danger] = "Ummm that's cheating"
    redirect_to request.referrer || root_url
  end

  def applyLie(scores, radioButtonLieValue, guess)
    buttonParts = radioButtonLieValue.split(':')
    position = buttonParts[0].to_i
    currentColor = buttonParts[1].to_i
    desiredColor = buttonParts[2].to_i
    delta = (desiredColor + 3 - currentColor) % 3
    scores[position] = desiredColor
    guess.update_columns(liePosition: position, lieDirection: delta, score: scores.join(':'))
  end

  def set_game_state
    @game_state = GameState.find(params[:id])
  end

  def update_params
    params.permit(:state, :wordIndex, :finalWord)
  end
end
