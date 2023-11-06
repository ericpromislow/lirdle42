class SessionsController < ApplicationController
  def new
  end

  def create
    emailField = params[:session][:email]
    user = (User.find_by(email: emailField.downcase) ||
      User.find_by(username: emailField) ||
      User.find_by("LOWER(username)= ? ", emailField.downcase))
    if user && user.authenticate(params[:session][:password])
      if user.activated? || user.inactive_logins > 1
        user.update_attribute(:inactive_logins, user.inactive_logins - 1) if !user.activated?
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      else
        # Shouldn't go below 0
        flash[:info] = "You need to activate your account to continue logging in. Please check your email at #{ user.email }"
        log_in user
        UserMailer.account_activation(user).deliver_now
      end
      redirect_back_or(root_url)
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    if current_user
      # False if the same user was active in two windows and then tried to log out from both -- just end the session
      current_user.update_columns(waiting_for_game: false)
    end
    log_out if logged_in?
    redirect_to root_url
  end
end
