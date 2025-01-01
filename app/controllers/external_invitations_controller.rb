class ExternalInvitationsController < ApplicationController
  include SessionsHelper
  before_action :logged_in_user, only: %i[ create update destroy ]
  before_action :set_logged_in_user, only: %i[ create ]
  skip_before_action :verify_authenticity_token, only: %i[ update destroy ]# if :json_request

  def create
    id = params.dig(:user, :id) || params[:id]
    if !id
      msg = "No ID specified (see logs)"
      puts "QQQ: #{msg} -- params: #{params}"
      flash.now[:danger] = msg
      Rails.logger.error(msg)
      redirect_to root_url
      return
    end
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
    code = params[:id] || params[:code]
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
    status = SessionsHelper.status
    #@@ debugger
    if !status.dig(inviter.id, :loggedIn)
      msg = "#{ inviter.username } isn't logged in"
      puts "QQQ User #{msg}"
      flash[:danger] = msg
      redirect_to root_url
      return
    end
    if inviter.in_game
      msg = "#{ inviter.username } is in another game - try later?"
      puts "QQQ User #{msg}"
      flash[:danger] = msg
      redirect_to root_url
      return
    end
    # TODO: !
    # Clear the invitation details

    # Next: grab a temporary name
    username = ExternalInvitationsHelper::AdjectiveNounGenerator.new.generate

    # Create the temporary user
    #@@ debugger
    user = User.create(username: username, email: "#{username}@lirdle42.com", is_temporary: true, password: "temp")
    log_in user

    msg = duplicate_create_invitations(user, inviter)
    if msg
      flash[:danger] = msg
    else
      # TODO: get the waiting-for-x essage
    end
    redirect_to root_url
  end

  def update

  end

  def destroy

  end
private
  def duplicate_create_invitations(user, inviter)
    from_id = user.id
    to_id = inviter.id
    from_user = user
    to_user = inviter
    # debugger
    if !from_user || !to_user
      return 'Incomplete invitation'
    elsif from_user != current_user
      return "Third-party invitation not supported"
    else
      # clear_old_invitations(from_id, to_id, from_user, to_user)
      oicount = Invitation.where(to: to_id).count
      if oicount > 0
        return "#{ to_user.username } is currently considering an invitation from someone else."
      else
        oicount = Invitation.where(to: from_id).count
        if oicount > 0
          return "#{ from_user.username } has an invitation to another game."
        else
          oicount = Invitation.where(from: to_id).count
          if oicount > 0
            return "#{ to_user.username } has already invited someone else."
          else
            i_params = { from: from_id, to: to_id }
            invitation = Invitation.new(i_params)
            if !invitation.save
              return "Failed to save the invitation: #{ invitation.errors.full_messages }"
            end
            Rails.logger.debug("QQQ: Created invitation #{invitation.id}")
            ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitation',
              message: { id: invitation.id, from: from_user.id, to: to_user.id,
                toUsername: to_user.username,
                fromUsername: from_user.username,
              } }
          end
        end
      end
    end
  end

end
