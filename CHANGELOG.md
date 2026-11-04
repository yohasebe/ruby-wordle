# Changelog

## 1.0.0

- Changed: The solver takes each guess with its colors on one line (`crane xyxxg`) and supports `undo`, `reset` and `all`.
- Changed: `ruby-wordle solve GUESS:COLORS ...` prints the candidates without prompting.
- Changed: The solver shows the turns as tiles and groups the candidates into common and other words, updated in place on a terminal.
- Changed: The solver ends when a guess gets all green and asks whether to solve another.
- Changed: The solver ranks the next guess by the expected number of words left instead of listing a random sample.
- Changed: The game shows the board and a keyboard with the colors of every letter tried, updated in place on a terminal.
- Changed: After a game, `s` copies the result as emoji squares to the clipboard.
- Changed: In the game, `?` shows only how many words still fit, and `hint letter` reveals one letter; the answer is never shown during the game, and a game with hints is marked `(assisted)`.
- Changed: Ruby 3.2 or later is required; input uses Reline.
- Changed: Tiles use fixed colors that look the same in every terminal theme.
- Changed: Colors are turned off with `--no-color`, a non-empty `NO_COLOR`, or when the output is not a terminal.
- Changed: The installed gem includes only the 5-letter word lists. Use the repository for the source lists and `rake wordlists`.
- Fixed: Repeated letters are colored as in Wordle, and the solver handles them exactly.
- Fixed: The game no longer picks answers that cannot be typed or are not in the word list.
- Fixed: End of input and Ctrl-C exit cleanly.
