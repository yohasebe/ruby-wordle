# Word-lists for Wordle

Lists of 5-letter English words and a Ruby script that generate lists of *n*-letter words

----

### Lists of English Words of 5 Letters (useful to solve Wordle)

`word-lists/5/word-list-uniq`

A list of five-letter words consisting of five different letters, generated using a script and the original word list.

`word-lists/5/word-list` 

A list of five-letter words, generated using a ruby script and the original word list.

----

### Original List of English Words

`word-lists/word-list-original.txt` 

A word list used to generate more useful word lists above. It is based on dictionary files used in [Ruby Lemmatizer](https://github.com/yohasebe/lemmatizer). Add as many words you like to this file as needed . 

----

### Ruby Script

`filter-sript.rb`

A filter script to generate *n*-letter word lists (`word-list.txt` and `word-list-uniq.txt`)

The default *n* value is 5. Change `NUM_LETTERS` if necessary, and execute the following command in the same directory where the script is located. A directory (with the same title as the number specified in the script) will be created automatically.

```
ruby filter-script.rb
```

----

### Author

Yoichiro HASEBE

### License

MIT
