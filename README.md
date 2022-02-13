# A Q Implementation of Wordle (as a Mastermind Special Case)

Clone this project and initialize the mastermind submodule

```
$ git clone git@github.com:psaris/wordle.git
$ git submodule update --init --recursive
```

Start q with the following command to see how an optimal initial word
is chosen as well as an example of playing the game interactively.

`q play.q`

## Interactive Play

One game per day can be played on the official wordle
[site][wordle]. But with our implementation, we can play as many times
as we want.

[wordle]:https://www.nytimes.com/games/wordle/index.html


```q
q)\l mm/mm.q
q)\l wordle.q
q)C:asc upper read0 `:answers.txt
q)G:asc C,upper read0 `:guesses.txt
q)g:"SOARE"
q)f:`.mm.maxent
q)a:.mm.stdin .mm.onestep f
q).mm.summary each .mm.game[a;C;G;g] rand C
n    guess   score  
--------------------
2309 "SOARE" "  G G"
guess (HINT DELTA): DELTA
n  guess   score  
------------------
28 "DELTA" " G  Y"
guess (HINT FINCH): FINCH
n guess   score  
-----------------
3 "FINCH" "   G "
guess (HINT PEACE): PEACE
n    guess   score  
--------------------
2309 "SOARE" "  G G"
28   "DELTA" " G  Y"
3    "FINCH" "   G "
1    "PEACE" "GGGGG"
```

