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
  # 3: choose a lie
  # 4: I won, game over
  # 5: I lost, game over

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
    gp = update_params
    splitWords = @game_state.candidateWords.split(':')
    if @game_state.state == 0
      if gp[:finalWord]
        gp[:state] = 1
      elsif @game_state.wordIndex >= splitWords.size - 1
        gp[:finalWord] = splitWords[-1]
        gp[:state] = 1
      end
    end
    respond_to do |format|
      if @game_state.update(gp)
        set_game_variables(@game)
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
