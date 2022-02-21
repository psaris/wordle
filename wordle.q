\d .wordle

/ wordle scoring function
scr:{[g;c]
 g[w:(i:group e:g=c) 1b]:" ";    / identify and skip where equal
 i@:where count[c]>i:g ? c i 0b; / identify where misplaced
 s:@[" G" e;i except w;:;"Y"];   / generate score
 s}

/ hard mode: removes (g)uess and impossible choices from unused (G)uesses
filtG:{[G;g;s]
 G@:where G[;i]~\:g i:where e:"G"=s;                     / exact matches
 G@:where (all g[where "Y"=s] in) peach G[;where not e]; / misplaced letters
 G _: G?g;                                               / drop current guess
 G}
