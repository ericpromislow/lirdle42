class SessionsController < ApplicationController
  def new
  end

  def create
    emailField = params[:session][:email]
    user = (User.find_by(email: emailField.downcase) ||
      User.find_by(username: emailField) ||
      User.find_by("LOWER(username)= ? ", emailField.downcase))
    if user&.authenticate(params[:session][:password])
      log_in user
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      redirect_back_or(user)
      # Log the user in and redirect to the user's show page.
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
end
