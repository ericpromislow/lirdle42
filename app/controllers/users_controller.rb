class UsersController < ApplicationController
  # Does these before_actions in order of appearance here:
  before_action :set_user, only: %i[ show edit update destroy start_waiting end_waiting]
  before_action :logged_in_user, only: %i[ index edit update destroy start_waiting end_waiting]
  before_action :allow_admins_only, only: %i[ destroy index ]
  before_action :correct_user, only: %i[ edit update start_waiting  end_waiting ]

  # GET /users or /users.json
  def index
    # TODO: List only activated users eventually who are also logged in
    @users = User.order('LOWER(username)').paginate(:page => params[:page], :per_page => 10)
  end

  def waiting_users
    users = User.where(waiting_for_game: true).select(:id, :username, :email).order('LOWER(username)')
    # users = users.map do |user|
    #   u = { id: user.id, username: user.username}
    #   if user.image&.attached?
    #     # debugger
    #     u[:image_url] = nil
    #   else
    #     gravatar_id  = Digest::MD5::hexdigest(user.email)
    #     gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=40"
    #     u[:image_url] = gravatar_url
    #   end
    #   u
    # end
    # # debugger
    ActionCable.server.broadcast 'main', chatroom: 'main', type: 'waitingUsers', message: users.to_a
    head :ok
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = "Welcome, #{ @user.username }"
      redirect_to root_url
    else
      flash[:error] = "errors"
      render 'new'
    end

    # respond_to do |format|
    #   if @user.save
    #     flash[:success] = "Welcome, #{ @user.username }"
    #     redirect_to @user #, notice: "User was successfully created."
    #     # format.json { render :show, status: :created, location: @user }
    #   else
    #     render 'new'
    #     # format.html { render :new, status: :unprocessable_entity }
    #     # format.json { render json: @user.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    # From users/_edit, the form has a :user param
    # But from the erb, it doesn't
    waiting_params = params.permit(:waiting_for_game)
    if waiting_params.has_key?(:waiting_for_game)
      return update_waiting_for_game(waiting_params)
    end
    waiting_params = params.require(:user).permit(:waiting_for_game)
    if waiting_params.has_key?(:waiting_for_game)
      return update_waiting_for_game(waiting_params)
    end
    if @user.update(updatable_params)
      image_field = params[:user][:image]
      if image_field
        begin
          @user.image.attach(image_field)
        rescue # SQLite3::BusyException => ex
          puts "Error trying to attach image: #{ $! }"
          flash[:error] = "Error accessing image database. Please try later."
        end
      end
      flash[:success] = "User #{@user.username} was successfully updated."
      redirect_to root_url
    else
      flash[:error] = "User #{@user.username} not updated: #{ @user.errors.full_messages }"
      render 'edit'
    end
    # respond_to do |format|
    #   if @user.update(user_params)
    #     format.html { redirect_to user_url(@user), notice: "User #{@user.username}  was successfully updated." }
    #     format.json { render :show, status: :ok, location: @user }
    #   else
    #     format.html { render :edit, status: :unprocessable_entity }
    #     format.json { render json: @user.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  def update_waiting_for_game(waiting_params)
    if !@user.update(waiting_params)
      flash[:error] = "User #{@user.username} not updated: #{ @user.errors.full_messages }"
    end
    redirect_to root_url
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    if @user == current_user
      flash[:error] = "User #{ @user.username } can't delete themselves"
    else
      @user.destroy
      flash[:success] = "User #{ @user.username } is swimming with the fishes"
    end
    redirect_to root_url
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "Please log in"
      redirect_to login_url
    end
  end

  # Only allow a list of trusted parameters through.
  def  user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :admin, :image)
  end

  def updatable_params
    params.require(:user).permit(:username, :password, :password_confirmation, :image)
  end

  def correct_user
    u = User.find(params[:id])
    if !current_user?(u) && !current_user.admin
      flash[:danger] = "You can't update user #{ u.username }"
      redirect_to root_url
    end
  end

  def current_user?(user)
    user && user == current_user
  end

  def allow_admins_only
    if !current_user&.admin
      flash[:danger] = 'not for you'
      redirect_to(root_url)
    end
  end
end
