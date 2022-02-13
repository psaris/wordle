/ redefine the mastermind scoring functions
.mm.scr:{[c;g]
 g[w:(i:group e:g=c) 1b]:" ";    / identify and skip where equal
 i@:where count[c]>i:g ? c i 0b; / identify where misplaced
 s:@[" G" e;i except w;:;"Y"];   / generate score
 s}
.mm.score:.mm.veca .mm.scr
