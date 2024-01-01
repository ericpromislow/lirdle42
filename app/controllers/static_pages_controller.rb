class StaticPagesController < ApplicationController
  def home
    @user = current_user
    @waiting_users = get_waiting_users
    if @user
      active_invitations = Invitation.where(to: @user.id)
      if active_invitations.count > 0
        inv = active_invitations.first
        @globalInvitationMessage = { chatroom: 'main', type: 'invitation',
          message: { id: inv.id, from: inv.from, to: inv.to,
            toUsername: @user.username,
            fromUsername: User.find(inv.from).username,
          } }
      else
        active_invitations = Invitation.where(from: @user.id)
        if active_invitations.count > 0
          inv = active_invitations.first
          @globalInvitationMessage = { chatroom: 'main', type: 'invitation',
            message: { id: inv.id, from: inv.from, to: inv.to,
              toUsername: User.find(inv.to).username,
              fromUsername: @user.username,
            } }
         elsif @user.in_game
           redirect_to game_path(@user.game_state.game)
         end
      end
    end
  end

  def help
  end

  def about
  end

  def contact
  end
private
  def get_waiting_users
    User.where(waiting_for_game: true).order('LOWER(username)').filter do |user|
      (current_user && current_user.id == user.id) || !user.in_game
    end
  end
end
