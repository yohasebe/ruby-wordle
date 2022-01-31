# Ruby-Wordle

A set of ruby scripts to generate word-lists and solve Wordle

⬜️⬜️⬜️⬜️⬜️ \
⬜️⬜️⬜️🟨🟨 \
⬜️🟩⬜️🟩⬜️ \
🟩🟩⬜️🟩🟩 \
🟩🟩🟩🟩🟩

----

### Installation

```
> gem install ruby-wordle
```

----

### Wordle Solver

**Usage Example**

```plain-text
> ruby-worldle-solver

STEP 1) 🟩 Input letters and positions using alphabets and dots. Then press Enter
           [e.g. s...h]
        ＞ .r..e
STEP 2) 🟨 Input pairs of a position (starting from 1) and a letter. Then press Enter.
           [e.g. 1g 2e 5a]
        ＞ 3e 4e 4r
STEP 3) ⬛︎ Input letters not used in the word. Then Press Enter.
           [e.g. ieagh]
        ＞ hotlquypic
------------------------------------------------
arage, arake, arase, brake, brame, brave, braze, 
drake, drame, drave, erade, erase, frame, frase, 
fraze, grade, grame, grane, grave, graze
------------------------------------------------
```

In the result list, basic words consisting of 5 different letters are printed in red 🟥 while basic words having the same letters used more than once are printed in blue 🟦

----

### Word Lists

#### Word List Generator Script

🟢 `lib/ruby-wordle/script-filter.rb`

A ruby script to generate *n*-letter word lists (`word-list.txt` and `word-list-uniq.txt`)

The default *n* value is 5. Change `NUM_LETTERS` if necessary, and run the script as follows. A directory will be created automatically with the title having the number specified in the script (e.g. `word-lists/5-letters`, `word-lists/6-letters`) and resulting word lists will be stored in that directory.

----

#### Lists of English Words of 5 Letters (useful to solve Wordle)

🟡 `word-lists/5-letters/word-list.txt`

A list of five-letter words, generated from the original word list.

🟡 `word-lists/5-letters/word-list-uniq-letters.txt`

A list of five-letter words consisting of five different letters, generated from the original word list.

🟡 `word-lists/5-letters/word-list-basic.txt`

A list of five-letter words, generated from the basic word list.

🟡 `word-lists/5-letters/word-list-basic-uniq-letters.txt`

A list of five-letter words consisting of five different letters, generated from the basic word list.

----

#### Original/Basic Lists of English Words

⚪️ `word-lists/word-list-original.txt`

A large word list based on `words_alpha.txt` in [dwyl/english-words](https://github.com/dwyl/english-words), containing more than 370,000 items.

⚪️ `word-lists/word-list-basic.txt`

A smaller word list containing about 13,000 basic English words.

----

### Author

Yoichiro HASEBE

----

### License

MIT
