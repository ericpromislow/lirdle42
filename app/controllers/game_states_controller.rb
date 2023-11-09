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
    if @game_state.playerID != @user.id
      flash[:danger] = "You can't change someone else's game state"
      redirect_to request.referrer || root_url
      return
    end
    set_game_variables(@game)
    gp = update_params
    splitWords = @game_state.candidateWords.split(':')
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

    $stderr.puts("QQQ: This isn't your part of the game!!")
    flash[:danger] = "Ummm that's cheating"
    redirect_to request.referrer || root_url
  end

  def set_game_state
    @game_state = GameState.find(params[:id])
  end

  def update_params
    params.permit(:state, :wordIndex, :finalWord)
  end
end
