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
show T:.mm.freqt[G;C]
-1 "let's find the optimal starting word based on the maximum entropy";
show S:desc .mm.entropy each flip value T

-1 "by using the .mm.game function, we can play wordle against a random word";
-1 "we'll start the game off with the optimal word found above";

g:string first key S
f:`.mm.maxent
a:.mm.stdin .mm.onestep f
show .mm.summary each .mm.game[a;G;C;g] rand C

\

.mm.score:.mm.scr/:[;C!C] peach G!G
/ generate histogram of each guess-choosing function
.mm.hist (count .mm.game[.mm.onestep[`.mm.minimax];G;C;"ARISE"]::) peach C
.mm.hist (count .mm.game[.mm.onestep[`.mm.irving];G;C;"ROATE"]::) peach C
.mm.hist (count .mm.game[.mm.onestep[`.mm.maxent];G;C;"SOARE"]::) peach C
.mm.hist (count .mm.game[.mm.onestep[`.mm.maxparts];G;C;"TRACE"]::) peach C
.mm.hist (count .mm.game[.mm.onestep[`.mm.maxgini];G;C;"ROATE"]::) peach C

/ playing wordle against an unknown word (and receiving hints along the way)

a:.mm.best[f]
GC:(G;C)
a . GC:.mm.filt . GC,("ROATE";"Y YY ")
a . GC:.mm.filt . GC,("STRAP";" YYY ")
a . GC:.mm.filt . GC,("ADMIT";"Y   Y")
a . GC:.mm.filt . GC,("ULTRA";"GGGGG")
