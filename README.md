# A Q Implementation of Wordle (as a Mastermind Extension)

Clone this project and initialize the mm submodule

```sh
$ git clone git@github.com:psaris/wordle.git
$ git submodule update --init --recursive
```

Start q with the following command to see how an optimal initial word
is chosen as well as an example of playing the game interactively.
Running with multiple secondary threads `-s 4` allows the
computationally-heavy search for optimal guesses to run in parallel.

`q play.q -s 4`

## Wordle

Similar to Mastermind, the goal of Wordle is to discover the hidden
word (or 'code' in Mastermind parlance) in the least number of
guesses. At each step of Mastermind you are told how many pegs are
placed in the correct space and how many are the correct color, but
placed in the wrong space. Wordle adds a slight twist to the scoring
function. Instead, the game tells you the *actual* letters that are in
the correct place and the *actual* letters that are in the wrong
place. This reveals much more information and drastically simplifies
the search process.

Another difference between Mastermind and Wordle is that while every
possible Mastermind guess can be the actual solution, Wordle allows
you to guess words that are not in the solution space. How do I know?
The game solutions and all valid guesses are loaded by the web page
and are available by inspecting the page source and clicking on the
[main.7785bdf7.js][main] link (where the `7785bdf7` hash may change in
the future.

[main]:https://www.nytimes.com/games/wordle/main.7785bdf7.js

## Optimal Starting Word

Every step of the game solves the same problem: how can I reveal as
much *information* about the solution as possible. Intuitively,
choosing a word with rarely used letters is likely to reveal very
little information. But what combination of letters reveals the most
information? This fundamentally comes down to the distribution of
possible response. If we represent the three responses gray, yellow
and green as " YG", we can intuit that there will be approximately 243
(`3 xexp 5`) possible responses. In practice, there are only 238
responses because it is not possible to have all letters correct
except for one, which is the correct letter but in the wrong location.
Concretely, the following responses are not possible:

```q
"YGGGG"
"GYGGG"
"GGYGG"
"GGGYG"
"GGGGY"
```

A good guess would have all remaining codes distributed as evenly as
possible among the possible responses. If we could achieve this
perfect distribution, the first guess would narrow the total universe
of remaining codes from 2309 to 10 (`2309 % 238`) on the first
guess. How can we find this magic word? There are many algorithms to
chose from. One way is to choose the word that minimizes the maximum
size of each possible response set (`.mm.minimax`). This method was
introduced by Donald Knuth to solve the Mastermind game. Another way
is to choose the word that minimizes the average response set size
(`.mm.irving`). There is, in fact, an information-theoretic
calculation that measures how unevenly (or randomly) values are
distributed: *entropy*. When all responses to our guess are the same,
the entropy is 0. When all responses are evenly distributed, entropy
is maximized. So which word maximizes the response entropy?

First we load the mm and wordle libraries `mm/mm.q` and `wordle.q` and
replace the `.mm.score` function with a vectorized version of the
wordle scoring function `.wordle.scr`.

```q
q)\l mm/mm.q
q)\l wordle.q
.mm.score:.mm.veca .wordle.scr
```

Then we load all possible solutions from `answers.txt` and valid
guesses from `guesses.txt`. And finally, we call the `.mm.freqt`
function to generate the frequency table of all possible first
guesses.

```q
q)C:`u#asc upper read0 `:answers.txt
q)G:`u#asc C,upper read0 `:guesses.txt
q)show T:.mm.freqt[G;C]
score  | AAHED AALII AARGH AARTI ABACA ABACI ABACK ABACS ABAFT ABAKA ABAMP ABAND ABASE ABASH ABAS..
-------| ----------------------------------------------------------------------------------------..
"     "| 448   667   587   378   993   624   925   668   772   1134  896   753   422   702   805 ..
"    G"| 40    3     64    4     26    3     24    15    123   30    27    49    151   66    34  ..
"    Y"| 60          100   229         366   44    310   214         164   124   297   102   31  ..
"   G "| 175   56    34    40    92    56    62    78    15    30    19    87    45    72    92  ..
"   GG"| 21          7           2           30          5     2     11    12    33    10    3   ..
"   GY"| 29    10    2     26          36          14    2           4     6     17    13        ..
"   Y "| 303   308   76    114   159   107   147   124   82    80    108   184   158   235   237 ..
"   YG"| 10          2           4     1     6     7     13                5     49    5     23  ..
"   YY"| 63          13    94          51    6     28    18          15    24    72    39    19  ..
"  G  "|       39    73    70    187   159   159   104   158   213   195   180   80    117   124 ..
"  G G"|             13          6     3     15    2     28    5     4     9     38    11    18  ..
"  G Y"|             12    12          25    13    81    44          27    17    31    21    7   ..
"  GG "| 3     8     8     6     28    28    15    22    3     11    6     25    23    19    32  ..
"  GGG"|                                     13          4           7     3     6     11    1   ..
"  GGY"|                   4                       6     1                 1     4     3         ..
..
```

We can now demonstrate which words have the maximum entropy, thus
revealing the most information and maximizing our chance of shrinking
the set of remaining valid solutions.

```q
q)5#desc .mm.entropy each flip value T
SOARE| 4.079312
ROATE| 4.079072
RAISE| 4.074529
REAST| 4.067206
RAILE| 4.065415
```

This is the optimal starting word for the maximum entropy algorithm.
As we will see [below](#Best-Algorithm), each algorithm has its own
best starting word.

## Playing a Game

One game per day can be played on the official Wordle
[site][wordle]. But with our implementation, we can play as many times
as we want.

[wordle]:https://www.nytimes.com/games/wordle/index.html

### Computer-Driven

After loading the library and word list, we can define our first guess
`g`, algorithm `a` and let the algorithm play a random game.

```q
q)\l mm/mm.q
q)\l wordle.q
q)C:asc upper read0 `:answers.txt
q)G:asc C,upper read0 `:guesses.txt
q)g:"SOARE"
q)a:.mm.onestep `.mm.maxent
q).mm.summary each .mm.game[a;G;C;g] rand C
n    guess   score  
--------------------
2309 "SOARE" "  G G"
28   "GLITZ" "     "
8    "HEAVE" " GG G"
1    "PEACE" "GGGGG"
```

### Interactive
Alternatively, we can change the algorithm to prompt us for our own
guess (while hinting at the algorithm's suggestion).

```q
q)a:.mm.stdin .mm.onestep `.mm.maxent
q).mm.summary each .mm.game[a;G;C;g] rand C
n    guess   score  
--------------------
2309 "SOARE" "  YY "
guess (HINT GLITZ): GLITZ
GLITZ
n  guess   score  
------------------
28 "GLITZ" "     "
guess (HINT HEAVE): HEAVE
HEAVE
n guess   score  
-----------------
8 "HEAVE" " GG G"
guess (HINT PEACE): PEACE
PEACE
n    guess   score  
--------------------
2309 "SOARE" "  G G"
28   "GLITZ" "     "
8    "HEAVE" " GG G"
1    "PEACE" "GGGGG"
```

## Best Algorithm

There are many algorithms to finding the best word at each step.  The
following are included in the `mm` library.
- `.mm.minimax`
- `.mm.irving`
- `.mm.maxent`
- `.mm.maxgini`
- `.mm.maxparts`


### Caching

Each algorithm has different performance characteristics.  In order to
measure the distribution and average number of guess required to win,
we will apply the algorithm across all possible codes.  To make this
process more efficient, we first cache the scoring function by
converting it into a nested dictionary.

```q
.mm.score:.mm.scr/:[;C!C] peach G!G
```

### Best First Guess

We can now use the `.mm.best` function to scan all possible options
for the best first algorithm-dependent code.  The first code for
`.mm.minimax`, for example, is "ARISE".

```q
q).mm.best[`.mm.minimax;G;C]
"ARISE"
```

### Minimum Maximum Size

Running through all games,`.mm.mimimax` can get the correct answer in
one shot (because it starts with a word from the code list).  The
downside is that it may take up to 6 attempts -- with an average of
3.575574 attempts.

```q
q)show h:.mm.hist (count .mm.game[.mm.onestep[`.mm.minimax];G;C;"ARISE"]::) peach C
1| 1
2| 53
3| 982
4| 1164
5| 107
6| 2
q)value[h] wavg key h
3.575574
```

### Minimum Expected Size

The `.mm.irving` (minimum expected size) algorithm starts with a
non-viable code, but guarantees a solution in 5 attempts and an even
better average of 3.48246 attempts.

```q
q)show h:.mm.hist (count .mm.game[.mm.onestep[`.mm.irving];G;C;"ROATE"]::) peach C
2| 55
3| 1124
4| 1091
5| 39
q)value[h] wavg key h
3.48246
```

### Maximum Entropy

The information theoretic maximum entropy `.mm.maxent` can't get the
answer in one attempt and has a worst-case scenario of 6 attempts. But
it wins with an average 3.467302 attempts -- beating the previous two
cases.

```q
q)show h:.mm.hist (count .mm.game[.mm.onestep[`.mm.maxent];G;C;"SOARE"]::) peach C
2| 45
3| 1206
4| 993
5| 64
6| 1
q)value[h] wavg key h
3.467302
```

### Maximum Number of Parts
Finally, we try the `.mm.maxparts` algorithm and observe that it has the
best average seen so far: 3.433088.

```q
q)show h:.mm.hist (count .mm.game[.mm.onestep[`.mm.maxparts];G;C;"TRACE"]::) peach C
1| 1
2| 75
3| 1228
4| 935
5| 68
6| 2
q)value[h] wavg key h
3.433088
```

## Hard Mode

Reviewing the interactive play from [above](#Interactive) shows the
first three guesses have very few letters in common.  This very
efficiently narrowed the remaining options such that the fourth guess
could only have been a single word. First-time players of Wordle,
however, typically continue to use letters revealed to be correct.
This is intuitive but sub-optimal -- at least in the first few
guesses.

Wordle allows users to enable 'hard mode', which forces players to use
this sub-optimal approach of using the letters that have been revealed
to be correct.  Specifically, any letter marked green must be used
again in exactly the same place and any letter marked yellow must be
used again but not necessarily in the same place.  Hard mode limits
the allowed guesses, thus slowing the information-gathering process
and increasing the average number of guesses required to find the
code.

To enable 'hard mode', we can redefine the `.mm.filtG` function with
the Wordle variant `.wordle.filtG`.

```q
.mm.filtG:.wordle.filtG
```

Replaying the above game, we can see that the code was found in three
guesses instead of four.  Wonderful!

```q
q).mm.summary each .mm.game[a;G;C;g] "PEACE"
n    guess   score  
--------------------
2309 "SOARE" "  G G"
28   "PLAGE" "G G G"
1    "PEACE" "GGGGG"
```

But running the game across all codes reveals how the extra constraint
adds to the difficulty of the game. In one case, the algorithm can't
even win in 6 guesses -- the maximum allowed on the Wordle site -- and
the average number of guesses per game has jumped to 4.614985.

```q
q)show h:.mm.hist (count .mm.game[.mm.onestep[`.mm.maxent];G;C;"SOARE"]::) peach C
2| 3
3| 86
4| 822
5| 1285
6| 112
7| 1
q)value[h] wavg key h
4.614985
```
