# A Q Implementation of Wordle (as a Mastermind Special Case)

Clone this project and initialize the mastermind submodule

```
$ git clone git@github.com:psaris/wordle.git
$ git submodule update --init --recursive
```

Start q with the following command to see how an optimal initial word
is chosen as well as an example of playing the game interactively.
Running with multiple secondary threads `-s 4` allows the
computationally heavy search for optimal guesses run in parallel.

`q play.q -s 4`

## The game

Just like mastermind, the goal of wordle is to discover the hidden
word (or 'code' in mastermind parlance) in the least number of
guesses. At each step of mastermind you are told how many pegs are
placed in the correct space and how many are the correct color, but
placed in the wrong space. Wordle adds a slight twist to the scoring
function. Instead, the game tells you the *actual* letters that are in
the correct place and the *actual* letters that are in the wrong
place. This reveals much more information and drastically simplifies
the search process.

Another difference between mastermind and wordle is that while every
possible mastermind guess can be the actual solution, wordle allows
you to guess words that are not in the solution space. How do I know?
The game solutions and all valid guesses are loaded by the web page
and are available by inspecting the page source and clicking on the
[main.7785bdf7.js][main] link (where the `7785bdf7` hash may be
different for each person.

[main]:https://www.nytimes.com/games/wordle/main.7785bdf7.js

## Optimal starting word

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

A good guess would have all remaining responses be distributed as
evenly as possible among the possible responses. If we could achieve
this perfect distribution, the first guess would narrow the total
universe of possible solutions from 2309 to 10 (`2309 % 238`) on the
first guess. How can we find this magic word? There are many
algorithms to chose from. One way is to choose the word that minimizes
the maximum size of each possible response set. This method was
introduced by Donald Knuth to solve the mastermind game (see
[.mm.minimax][minimax]). Another way is to choose the word that
minimizes the average response set size (see
[.mm.irving][irving]). There is, in fact, an information-theoretic
calculation that measures how unevenly (or randomly) values are
distributed: *entropy*. When all responses to our guess are the same,
the entropy is 0. When all responses are evenly distributed entropy is
maximized. So which word maximizes the response entropy?

[minimax]:https://github.com/psaris/mm/blob/6f647a2d6835638ede14cd948882ffba6930058c/mm.q#L31
[irving]:https://github.com/psaris/mm/blob/6f647a2d6835638ede14cd948882ffba6930058c/mm.q#L32

First we load the mastermind library `mm/mm.q` and overwrite the
scoring function by loading `wordle.q`.  Then we load all possible
solutions (`answers.txt`) and valid guesses (`guesses.txt`). Finally,
we call the `.mm.freqt` function to generate the frequency table of
all possible first guesses.

```q
q)\l mm/mm.q
q)\l wordle.q
q)C:asc upper read0 `:answers.txt
q)G:asc C,upper read0 `:guesses.txt
q)show T:.mm.freqt[C;G]
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

Now we can demonstrate which words have the maximum entropy, thus
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

## Interactive Play

One game per day can be played on the official wordle
[site][wordle]. But with our implementation, we can play as many times
as we want.

[wordle]:https://www.nytimes.com/games/wordle/index.html

After loading the library and word list, we can define our first guess
`g`, algorithm `a` and let the algorithm play a random game.

```q
q)\l mm/mm.q
q)\l wordle.q
q)C:asc upper read0 `:answers.txt
q)G:asc C,upper read0 `:guesses.txt
q)g:"SOARE"
q)a:.mm.onestep `.mm.maxent
q).mm.summary each .mm.game[a;C;G;g] rand C
n    guess   score  
--------------------
2309 "SOARE" "  G G"
28   "GLITZ" "     "
8    "HEAVE" " GG G"
1    "PEACE" "GGGGG"
```

Alternatively, we can change the algorithm to prompt us for our own
solution (while hinting at the optimal guess).

```q
q)a:.mm.stdin .mm.onestep `.mm.maxent
q).mm.summary each .mm.game[a;C;G;g] rand C
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

Note that you can choose among any of the following functions to pick
the best guess:
- `.mm.minimax`
- `.mm.irving`
- `.mm.maxent`
- `.mm.maxgini`
- `.mm.maxparts`
