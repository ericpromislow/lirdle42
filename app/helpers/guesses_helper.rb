module GuessesHelper
  def calculate_score(word, targetWord)
    wordA = word.split('')
    targetWordA = targetWord.split('')
    scores = [0] * 5
    wordA.each_with_index do |letter, i|
      if targetWordA[i] == letter
        scores[i] = 2
        wordA[i] = targetWordA[i] ="*"
      end
    end
    wordA.each_with_index do |letter, i|
      next if letter == '*'
      posn = targetWordA.index(letter)
      if posn
        scores[i] = 1
        targetWordA[posn] ="*"
      end
    end
    scores
  end

  def is_correct_score(score)
    score.all? {|x| x == 2}
  end

  def getAllWords
    if !@allWords
      # $stderr.puts "QQQ: Need to read words..."
      @allWords = (IO.read('db/words/words.txt').split("\n") + IO.read('db/words/other-words.txt').split("\n")).sort
    end
    @allWords
  end

end
