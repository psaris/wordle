-1 "worlde is extremely similar to mastermind.";
-1 "first we load the mastermind library,";
\l mm/mm.q

-1 "then we redefine the scoring function,";

\l wordle.q

-1 "load all possible codes (answers),";
C:`u#asc upper read0 `:answers.txt   / possible 'codes'
-1 "and finally all valid guesses.";
G:`u#asc C,upper read0 `:guesses.txt / possible 'guesses'

-1 "by generating a frequency distribution of scores,";
-1"we can determine an optimal first word.";
-1 "note: this can take a minute . . .";
show T:.mm.freqt[C;G]
-1 "let's find the optimal starting word based on the maximum entropy";
show S:desc .mm.entropy each flip value T

-1 "by using the .mm.game function, we can play wordle against a random word";
-1 "we'll start the game off with the optimal word found above";

g:string first key S
f:`.mm.maxent
a:.mm.stdin .mm.onestep f
show .mm.summary each .mm.game[a;C;G;g] rand C

\

/.mm.score:C!G!/:C .mm.scr/:\: G
/ generate histogram of each guess-choosing function
.mm.hist (count .mm.game[.mm.onestep[`.mm.minimax];C;G;"ARISE"]::) peach C
.mm.hist (count .mm.game[.mm.onestep[`.mm.irving];C;G;"ROATE"]::) peach C
.mm.hist (count .mm.game[.mm.onestep[`.mm.maxent];C;G;"SOARE"]::) peach C
.mm.hist (count .mm.game[.mm.onestep[`.mm.maxparts];C;G;"TRACE"]::) peach C
.mm.hist (count .mm.game[.mm.onestep[`.mm.maxgini];C;G;"ROATE"]::) peach C

/ playing wordle against an unknown word (and receiving hints along the way)

a:.mm.best[f]
CG:(C;G)
a . CG:.mm.filt . CG,("ROATE";"Y YY ")
a . CG:.mm.filt . CG,("STRAP";" YYY ")
a . CG:.mm.filt . CG,("ADMIT";"Y   Y")
a . CG:.mm.filt . CG,("ULTRA";"GGGGG")
