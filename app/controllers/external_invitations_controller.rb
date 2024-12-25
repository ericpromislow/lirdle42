class ExternalInvitationsController < ApplicationController
  before_action :logged_in_user, only: %i[ create update destroy ]
  before_action :set_logged_in_user, only: %i[ create ]
  skip_before_action :verify_authenticity_token, only: %i[ update destroy ]# if :json_request

  def create
    id = params[:id]
    @user = User.find_by(id: id)
    if @user
      # idn = id.to_i
      # idx = 10 ** (Math.log10(idn).floor + 1) - idn
      @user.create_invite_digest
      # x = new_external_invitations_url
      # puts x
      url = "#{ root_url }join?code=#{id}_#{@user.invite_token}"
      flash[:info] = "Send them '#{url}' - this link expires in 2 hours"
    else
      flash.now[:danger] = "User not found (see logs)"
      Rails.logger.error("Can't find user id #{ id }")
    end
    redirect_to root_url
  end

  def edit
    # if logged in do something else
    code = params[:id]
    if code.nil?
      flash[:danger] = "No entry code supplied"
      redirect_to root_url
      return
    end
    # debugger
    code = code.sub(/^code=/, '')
    id, token = code.split('_', 2)
    idn = id.to_i
    puts "QQQ: invite-controller: edit: id: #{id} idn:#{idn}, (#{idn.class}), token:#{token}"
    inviter = User.find_by(id: idn)
    if !inviter
      puts "QQQ: Can't find user with id #{id}"
      flash[:danger] = "Invalid user given for this invite (id #{id})"
      redirect_to root_url
      return
    end
    puts "QQQ: inviter:  #{ inviter.id }"
    puts "QQQ: invite-controller: inviter's invite_digest: #{ inviter.invite_digest }"
    puts "QQQ: invite-controller: inviter's invite_token: #{ token }"
    if !inviter.authenticated?(:invite, token)
      puts "QQQ: Inviter key is invalid."
      flash[:danger] = "Invitation from #{inviter.username} isn't valid"
      redirect_to root_url
      return
    end
    if inviter.invite_sent_at < 2.hours.ago
      puts "QQQ: Invitation expired"
      flash[:danger] = "Invitation from #{inviter.username} expired at #{inviter.invite_sent_at}"
      redirect_to root_url
      return
    end
    # Is our invitee still logged in?

    ### TODO: Add a loggedin table -- just a list of IDs with created_at
    # Next: grab a temporary name
    # Create the temporary user
    # Log them in as temporary -- so they can't invite others
    # They *can* be invited to play with other people
    # They have no email address
    # If they haven't played for an hour they get logged out (and deleted)
    redirect_to root_url
  end

  def update

  end

  def destroy

  end
private

end
