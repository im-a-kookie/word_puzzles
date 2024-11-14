# Word Puzzles

A simple Flutter Project that provides a few random word puzzles (currently: a version of Boggle, and NYTimes Spelling Bee).

Mostly just made this to learn a bit about Flutter/Dart, and this definitely isnt the right way to do a lot of what I've done (it's a bit messy, but hey, now I actually know how to make things less messy next time).

The only really notable aspect of this project is the grid creation and solution algorithm.

# Dictionary

Word selection is relatively important. Extensive word lists increase difficulty, sometimes prohibitively, by including bizarre and made up words like Bowow, Pharisaicalnesses, and Brunch. Conversely, scant lists end up rejecting and not scoring many seemingly valid words, leading to frustration. The current word list, is probably too extensive.

The word list is constructed into a progressive tree, using a Dart version of [my C# implementation](https://github.com/im-a-kookie/Find-a-Word). This allows letter sequences to be queried extremely efficiently for validity, and for the puzzle generation algorithm to very quickly determine the available letters that will continue a valid sequence.

# Random Walks and DFS

Letters are inserted into the grid via depth first random walks. The algorithm presents two main modes. In the first, a predetermined series of letters (aka a chosen word) is inserted. In the second, letters are selected randomly. All randomized steps use a simple seeded RNG (LCG), allowing deterministic puzzle generation consistently across all platforms (e.g using the current day to provide a "daily challenge.")
# Solutions

Solving is very similar to generating. For each letter, we simply walk through every connected letter, adding all valid words to a set of solutions. During this process, each cell is flagged, indicating the number of words that begin with it, and the number of words that use it. By tracking these flags during gameplay, we can provide hints to the player, about which letters can still be used to start or make words.

# Sanitization

Due to the chaotic random nature of grid generation, and the abundance of certain spelling patterns in English, it's fairly common for grids to contain profanities and other offensive terms. Due to aggressive optimizations in grid generation, puzzles can be generated in just a handful of milliseconds. Removing offensive words is therefore fairly straight forward. A separate list of such terms is provided (this was a terrible day to have eyes), and puzzles are simply rejected and regenerated if the solution set contains any of these words.
