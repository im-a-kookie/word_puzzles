# Word Puzzles

A simple Flutter Project that provides a few random word puzzles (currently: a version of Boggle, and NYTimes Spelling Bee).

Mostly just made this to learn a bit about Flutter/Dart, and this definitely isnt the right way to do a lot of what I've done (it's a bit messy, but hey, now I actually know how to make things less messy next time).

The only really notable aspect of this project is the grid creation and solution algorithm.

# Dictionary

Word selection is relatively important for this game. If the word list is too extensive, then it becomes prohibitively difficult to find all of the words, as solutions begin to include a variety of frustrating and made up words, like Bowow, Pharisaicalnesses, and Brunch. On the other hand, if the list is too narrow, then many seemingly valid words may be rejected and unscored, which can be frustrating.

To attempt to solve this, several word lists were obtained from a variety of sources, and filtered based on word occurrences. The resulting list, of words that are found in a variety of different lists, is then constructed into a progressive tree, using a similar approach to [the C# implemenation here](https://github.com/im-a-kookie/Find-a-Word). This allows letter sequences to be queried extremely efficiently for validity, and for the puzzle generation algorithm to very quickly determine the available letters that will continue a valid sequence.

# Random Walks and DFS

Next, a random square in the grid is chosen, and the algorithm performs a random walk, inserting letters with each step. This uses DFS. In each step, the algorithm exhaustively searches the 8 cardinal directions, placing letters into empty squares, or using preexisting letters from those squares. A valid step creates a sequence of letters that exists in the dictionary tree. A valid walk is one which reaches a letter that terminates a word.

The algorithm presents two main modes. In the first, the sequence of letters is predetermined, allowing a preselected word to be inserted. In the second, letters are randomly selected when empty cells are reached. The second mode is necessary for completely filling a grid, but the first mode can be used to seed the grid with some interesting words of predetermined length.

Note that all randomized steps use a simple seeded RNG (LCG), meaning that puzzle generation is completely deterministic. Nominally, this means puzzles can be generated consistently across all devices and platforms using fixed seeds (such as the current date or time, to provide an e.g "daily challenge").

# Solutions

Finally, once all squares of the grid have been filled with a letter, the grid is solved using a similar approach. Depth first, every letter is visited, and an exhaustive directed walk is performed, stepping to every neighbor, and every neighbor of every neighbor. This finds every word that is hidden in the grid, providing the list of solutions. This is necessary, as the random insertion of letters tends to randomly create additional words. Furthermore, during this step, every cell can be marked with flags indicating (1) how many words begin with this letter, and (2) how many words require this letter to be solved.

By tracking these flags during gameplay, we can provide hints to the player, about which letters can still be used to start or make words.

# Sanitization

Due to the chaotic random nature of grid generation, and the abundance of certain spelling patterns in English, it's fairly common for grids to contain profanities and other offensive terms. Due to aggressive optimizations in grid generation, puzzles can be generated in just a handful of milliseconds. Removing offensive words is therefore fairly straight forward. A separate list of such terms is provided (this was a terrible day to have eyes), and puzzles are simply rejected and regenerated if the solution set contains any of these words.
