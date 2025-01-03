class InvitationsController < ApplicationController
# class InvitationsController < ActionController::API
#   include ActionController::MimeResponds
  before_action :cor, only: %i[  destroy update ]
  before_action :logged_in_user, only: %i[ create update destroy ]
  skip_before_action :verify_authenticity_token, only: %i[ update destroy ]# if :json_request
  def create
    i_params = invitation_params
    from_id = i_params[:from]
    to_id = i_params[:to]
    from_user = User.find(from_id) rescue nil
    to_user = User.find(to_id) rescue nil
    # debugger
    if !from_user || !to_user
      flash[:danger] = 'Incomplete invitation'
    elsif from_user != current_user
      flash[:danger] = "Third-party invitation not supported"
    else
      clear_old_invitations(from_id, to_id, from_user, to_user)
      oicount = Invitation.where(to: to_id).count
      if oicount > 0
        flash[:danger] = "#{ to_user.username } is currently considering an invitation from someone else."
      else
        oicount = Invitation.where(to: from_id).count
        if oicount > 0
          flash[:danger] = "#{ from_user.username } has an invitation to another game."
        else
          oicount = Invitation.where(from: to_id).count
          if oicount > 0
            flash[:danger] = "#{ to_user.username } has already invited someone else."
          else
            invitation = Invitation.new(i_params)
            if invitation.save
              ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitation',
                                                     message: { id: invitation.id, from: from_id, to: to_id,
                                                                toUsername: to_user.username,
                                                                fromUsername: from_user.username,
                                                     } }
              # debugger
              respond_to do |format|
                format.html {
                  head :ok
                }
                format.js {
                  head :ok
                }
              end
              return
            else
              flash[:danger] = "Failed to save the invitation: #{ invitation.errors.full_messages }"
            end
          end
        end
      end
    end
    redirect_to request.referrer || root_url
  end
  def update
    begin
      do_update
    rescue
      $stderr.puts "What happen?"
    end
  end

  def do_update
    invitation = Invitation.find(params[:id])
    originator_id = params[:originator]
    to_user = User.find(invitation.to)
    if originator_id.to_i != to_user.id
      head :not_acceptable
    else
      reason = params[:reason]
      from_id = invitation.from
      from_user = User.find(from_id)
      invitation.destroy!
      if reason == 'declined' || reason == 'accepted'
        ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationEnding',
                                               message: { id: invitation.id, from: from_id, to: originator_id,
                                                          toUsername: to_user.username,
                                                          fromUsername: from_user.username,
                                                          message: reason
                                               } }
        head :ok
        return
      end
    end
    head :bad_request
  end

  def destroy
    #@@ debugger
    # Rails.logger.debug("QQQ >> destroy invitation")
    cuser = current_user
    if !cuser
      flash.now[:danger] = "Not logged in"
      head :forbidden
      return
    end
    invitation_id = params[:id]
    Rails.logger.debug("QQQ: Looking to delete invitation #{invitation_id}")
    invitation = Invitation.find(invitation_id)
    if !invitation
      flash.now[:danger] = "Can't find the invitation"
      head :not_found
      return
    end
    # Rails.logger.debug("QQQ >> destroy invitation #{ invitation.id }")
    if ![invitation.from, invitation.to].include?(cuser.id)
      flash.now[:danger] = 'forbidden'
      head :forbidden
      return
    end
    to_id = invitation.to
    from_id = invitation.from
    from_user = User.find(from_id)
    to_user = User.find(to_id)
    Rails.logger.debug("QQQ >> from: #{ from_id}, to: #{to_id}, -destroy")
    invitation.destroy
    # Rails.logger.debug("QQQ >> +destroy")
    # puts "QQQ: flash: #{ params[:flash] }, reason: #{ params[:reason] }"
    if params[:flash] || params[:reason] == 'cancelled'
      # Rails.logger.debug("QQQ >> reason is cancelled")
      ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationCancelled',
                                             message: { id: invitation_id, from: from_id, to: to_id,
                                                        toUsername: to_user.username,
                                                        fromUsername: from_user.username,
                                                        message: params[:flash]
                                             } }
      head :ok
      return
    elsif params[:reason] == 'accepted'
      # Rails.logger.debug("QQQ >> reason is accepted")
      # Rails.logger.debug("*** accepting invitation #{ JSON.dump({ chatroom: 'main', type: 'invitationAccepted',
      #   message: { id: invitation_id, to: from_id, game_id: params[:game_id]
      #   } })}")
      ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationAccepted',
                                             message: { id: invitation_id, to: from_id, game_id: params[:game_id]
                                             } }
    else
      puts "Ignoring reason #{ params[:reason] }" if !params[:reason].blank?
    end
    head :ok

  end
private
  def invitation_params
    p1 = params.permit(:from, :to, :authenticity_token, :commit)
    { from: p1[:from], to: p1[:to] }
  end
  def cor
    headers["Access-Control-Allow-Origin"]  = "*"
    headers["Access-Control-Allow-Methods"] = %w{GET POST PUT DELETE}.join(",")
    headers["Access-Control-Allow-Headers"] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token}.join(",")
    #head(:ok) if request.request_method == "DELETE" && ENV['RAILS_ENV'] != 'test'
  end

  DeadInvitations = 60
  LiveInvitationInterval = 15

  def clear_old_invitations(from_id, to_id, from_user, to_user)
    Invitation.where(updated_at: ..DeadInvitations.minutes.ago).find_each do |inv|
      inv_from_user = User.find(inv.from) rescue nil
      inv_to_user = User.find(inv.to) rescue nil
      ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationCancelled',
        message: { id: inv.id, from: inv.from, to: to_id,
          toUsername: (inv_to_user.username rescue ''),
          fromUsername: (inv_from_user.username rescue ''),
        } }
      inv.destroy
    end
    # Clear anything from the current user (the 'from')
    Invitation.where(from:from_id).find_each do |inv|
      # Delete any existing invitations that the current user has sent to others, including
      # the current invitee

      inv_to_user = User.find(inv.to) rescue nil
      ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationCancelled',
        message: { id: inv.id, from: from_id, to: inv.to,
          toUsername: (inv_to_user.username rescue ''),
          fromUsername: from_user.username,
        } }
      inv.destroy
    end
    # Delete older invitations that the target might have received
    Invitation.where(to:to_id, updated_at: ..LiveInvitationInterval.minutes.ago).find_each do |inv|
      inv_from_user = User.find(inv.from) rescue nil
      if inv_from_user
        ActionCable.server.broadcast 'main', { chatroom: 'main', type: 'invitationCancelled',
          message: { id: inv.id, from: inv.from, to: to_id,
            toUsername: to_user.username,
            fromUsername: inv_from_user.username,
          } }
      end
      inv.destroy
    end
  end

end
