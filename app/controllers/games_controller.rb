class GamesController < ApplicationController
  include GamesHelper
  before_action :set_game, only: %i[ show edit destroy ]
  before_action :logged_in_user, only: %i[ index create edit show destroy ]
  before_action :set_logged_in_user, only: %i[ index create edit show destroy ]
  before_action :must_be_admin, only: %i[index]
  before_action :admin_or_in_game, only: %i[ edit show destroy ]

  # GET /games or /games.json
  def index
    # $stderr.puts "QQQ in index-game"
    @games = Game.all.paginate(:page => params[:page], :per_page => 10)
  end

  # GET /games/1 or /games/1.json
  def show
    set_game_variables(@game)
    #render partial: "games/show#{@game_state.state}", locals: { other_player: @other_player, gameState: @game_state, user: @user }
  end

  # # GET /games/new
  # def new
  #   @game = Game.new
  # end

  # GET /games/1/edit
  def edit
  end

  # POST /games or /games.json
  def create
    gp = create_params
    if ![gp[:playerA], gp[:playerB]].include?(@user.id.to_s) && !@user.admin
      flash[:danger] = "Can't create a game for others"
      redirect_to root_url
      return
    end
    userA = User.find(gp[:playerA])
    userB = User.find(gp[:playerB])
    if !userA || !userB
      flash[:danger] = "Can't create a game for non-existent players"
      redirect_to root_url
      return
    end
    # TODO: Record all old games in a history database
    userA.game_state&.destroy()
    userB.game_state&.destroy()

    @game = Game.create()
    if !@game.save
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { errors: @game.errors, status: :unprocessable_entity } }
      return
    end
    targetWords = getTargetWords
    tw1 = targetWords.sample(6)
    tw_for_a = tw1[0..2].join(':')
    tw_for_b = tw1[3..5].join(':')
    @game.game_states.create(state: 0, user: userA, candidateWords: tw_for_a, wordIndex: 0)
    @game.game_states.create(state: 0, user: userB, candidateWords: tw_for_b, wordIndex: 0)

    if @game.save
      join_game(userA, @game.id)
      join_game(userB, @game.id)
      respond_to do |format|
        format.html {
          redirect_to game_url(@game), notice: "Game was successfully created." }
        format.json {
          render json: { status: :created, location: @game } }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @game.errors, status: :unprocessable_entity } }
      end
    end
  end

  # DELETE /games/1 or /games/1.json
  def destroy
    @game.game_states.each { |gs| leave_game(gs.user) }
    @game.destroy

    respond_to do |format|
      format.html { redirect_to games_url, notice: "Game was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_game
    @game = Game.find(params[:id])
  end

  def must_be_admin
    if !@user.admin
      flash[:danger] = "Admin only"
      redirect_to request.referrer || root_url
    end
  end

  # Only allow a list of trusted parameters through.
  def create_params
    params.permit(:playerA, :playerB)
  end
end
