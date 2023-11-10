module GamesHelper
  def getTargetWords
    if !@targetWords
      # $stderr.puts "QQQ: Need to read targetwords..."
      @targetWords = IO.read('db/words/words.txt').split("\n").sort
    end
    @targetWords
  end
end
