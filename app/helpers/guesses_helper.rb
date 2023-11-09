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
end
