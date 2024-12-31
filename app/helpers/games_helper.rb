module GamesHelper
  include SessionsHelper
  def getTargetWords
    if !@targetWords
      # $stderr.puts "QQQ: Need to read targetwords..."
      @targetWords = IO.read('db/words/words.txt').split("\n").sort
    end
    @targetWords
  end

  def join_game(user, gameID)
    status = SessionsHelper.status
    status[user.id] ||= { loggedIn: true }
    status[user.id][:gameID] = gameID
  end

  def leave_game(user)
    status = SessionsHelper.status
    status[user.id] ||= { loggedIn: true }
    status[user.id][:inGame] = nil
  end
end
