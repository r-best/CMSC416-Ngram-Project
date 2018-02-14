# CMSC416-Ngram-Project

A program that generates sentences from training data by constructing N-grams and choosing words for its sentences based on N-gram probability.

## Usage
`perl ngram.pl N M filenames`
* N - The value of N in "N-gram", i.e. for N = 3 each word in the generated sentences will be chosen using the 2 words preceding it
* M - How many sentences to generate, the more the merrier as the sentence generation is the easy part, it's calculating the N-grams and probabilities that takes time
* filenames - The rest of the arguments are filenames to use as training data
  * If you use a directory all files in that directory will be used as training data
