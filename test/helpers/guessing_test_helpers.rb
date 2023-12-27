module GuessingTestHelpers

  def verify_radio_buttons(actual_scores, expected)
    #XXX: This needs to be rewritten
    return
    numMatches = 0
    assert_select 'form div.row div.letter-row-container' do |buttonContainerRows|
      assert_equal 3, buttonContainerRows.size
      buttonContainerRows.each_with_index do |buttonContainerRow, row_num|
        assert_select(buttonContainerRow, 'div.letter-row') do |buttonContainers|
          assert_equal 5, buttonContainers.size
          buttonContainers.each_with_index do |buttonContainer, i|
            expectedCharacter = expected[row_num][i]
            if expectedCharacter == 'nbsp'
              assert_select(buttonContainer, %Q<div.letter-box.filled-box.background-#{ @colors[row_num] }>) do
                numMatches += 1
                assert_select 'span' do |spanElt|
                  numMatches += 1
                  assert_equal 0, spanElt[0].text.gsub(/[[:space:]]/, '').size
                end
              end
              assert_select(buttonContainer, %Q<input[type="radio"][name="game_state[lie]"]>) do |radioButton|
                rbVal = radioButton[0].attribute('value').text
                # if "#{ i }:#{ actual_scores[i] }:#{ row_num }:#{ @colors[row_num] }" != rbVal
                #   debugger
                # end
                assert_equal "#{ i }:#{ actual_scores[i] }:#{ row_num }:#{ @colors[row_num] }", rbVal
              end
            else
              assert_select(buttonContainer, %Q<div.letter-box.filled-box.background-#{ @colors[row_num] }>) do
                numMatches += 1
                assert_select 'span' do |spanElt|
                  numMatches += 1
                  assert_equal expectedCharacter, spanElt[0].text
                end
              end
              assert_select(buttonContainer, %Q<input[type="radio"][name="game_state[lie]"]>, count: 0)
            end
          end
        end
      end
    end
  end

  def verify_previous_perturbed_guesses(username, guesses, gameOver=false)
    if guesses.size == 0
      assert_select 'div.previous-guesses h2', count: 0
      return
    end
    guessPieces = []
    guesses.each do | guess |
      word, score, liePosition, lieColor, actualColorNum = [ guess[:word], guess[:score], guess[:liePosition], guess[:lieColor], guess[:actualColor] ]
      scores = score.split(':')
      word.split('').each_with_index do | theLetter, col_num |
        newGuessPiece = { letter: theLetter }
        scoreColor = scores[col_num].to_i
        if liePosition == col_num
          visibleColor = @colors[lieColor]
          actualColor = @colors[actualColorNum]
          newGuessPiece[:classes] = [ "background-#{visibleColor}", "actual#{actualColor}" ]
        else
          visibleColor = @colors[scoreColor]
          newGuessPiece[:classes] = [ "background-#{visibleColor}" ]
        end
        guessPieces << newGuessPiece
      end
    end
    assert_select 'div.previous-guesses' do |previousGuesses|
      assert_select 'h2', gameOver ? 'Your guesses:' : %Q<Previous guesses with lies for #{ username }:>
      assert_select previousGuesses, 'div#game-board div.letter-row-container div.letter-row div.letter-box.filled-box' do | elements |
        assert_equal guessPieces.size, elements.size
        guessPieces.zip(elements).each_with_index do | pair, i|
          guessPiece, elt = pair
          assert_equal elt.text.strip, guessPiece[:letter]
          guessPiece[:classes].each do | cls |
            # if !elt.classes.include?(cls)
            #   debugger
            # end
            assert_includes elt.classes, cls
          end
        end
      end
    end
  end
end
