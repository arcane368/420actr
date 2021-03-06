globals [
  number_of_words_internal ;; Counter for the number of words that still has to be added. Seperate from number_of_words so that it can be decremented when a new word is added.
  newx ;; The coordinates the recall agent 'looks' ahead at to see if it is an appropriate location to move to.
  newy
]

patches-own [
  p_energy      ;;amount of energy this patch contains represented by intensity of colour - salience 
  w_length      ;; word length - Shorter words are GREEN, Longer words will turn RED
]

turtles-own [
  stay_length ;; how much time should this agent be stuck on this patch
  on_new_patch ;; so it knows to move on after it adds enough energy to one patch
  x_last_visited ;; keep track if we've gone through all patches already
  y_last_visited
]

breed [inputter]
breed [recaller]

;; Setup procedures

to setup
  clear-all
  setup-patches
  setup-turtles
  set number_of_words_internal number_of_words ;; The number of words that still has to be added is set to the slider number_of_words
  random-seed 4356653
  reset-ticks
end

to setup-patches 
  ask patches [
    set p_energy 0
    set w_length 0      ;; placeholder to initialize, should never access if energy=0
  ]
  
end

to setup-turtles
  if not Articulatory_Suppression [     ;; ifelse statement for Articulatory Suppression
    create-recaller 1 [set color yellow set shape "circle"] ;; recalls words
  ]
  create-inputter 1 [set color blue] ;; adds words
  ask turtles [
    set heading 90 ;; turn to right
  ]
  ask recaller [
    set on_new_patch true ;; so the recaller will start off by checking the patch it's sitting on
  ]

end





;; Runtime procedures moving turtle to patch, turtle visits to patch and adding energy to patch. The recaller will move every tick (and words will keep decaying each tick), but
;; words be added less frequently (based on time_between_new_words)

to go
  update_patch_colour
  if ticks mod time_between_new_words = 0 ;; Every time a number of ticks equal to time_between_new_words has passed, a new word will be added
  [
    move_inputter_serial
  ]
  move_recaller_serial
  
  decay_patches
  tick
end

;; Removes energy from patches to represent words fading from memory. Decay rate is based on the global decay rate, the global phonological similarity, and the length of the word
;; itself (longer words decay faster).

to decay_patches
  ask patches [
    ifelse (p_energy > 0) [
      ;; decrease the energy, by a rate porportional to the patch's word length and the phonological similarity of the words in general
      set p_energy p_energy - (energy_decay_rate * w_length * phonological_similarity)
    ]
    [ 
      set p_energy 0 ;; set to 0 if it goes negative
      set w_length 0
    ]
  ]
end

;; Procedure for the turtle/agent that adds new words. While there are still words to be added (number_of_words_internal), it will add either a short or long word randomly
;; with the odds determined by the length_bias slider. Whenever a word is added, number_of_words_internal is decremented by one.

to move_inputter_serial
  ask inputter [
    if (number_of_words_internal > 0) [ ;; if there are words yet to be added
      ifelse (random 100 > length_bias) [
        ;; depending on bias, we will either put a short word...
        set w_length short_length
        set plabel (word p_energy " " short_length)
      ]
      [
        ;; or the other case is a long word
        set w_length long_length
        set plabel (word p_energy " " long_length)
      ]
      ;; set initial energy of patches by slider
      set p_energy energy_at_creation
      move_serial
      
      set number_of_words_internal number_of_words_internal - 1
    ]
  ]
end


;; Moves a turtle to the right across the screen, or jumps to the start of the next row if it's at the end of a row

to move_serial
  ifelse xcor = max-pxcor ;; if reaches end of row
  [
    setxy min-pxcor ycor - 1 ;; go to next row
  ]
  [
    forward 1 ;; otherwise, continue forward
  ]
end

;; Sets the patch labels and colour based on the word length and colour. Short words are green, long words are red.
;; Brightness is determined based on the energy of the patch relative to the maximum energy a patch can have, with
;; higher energy resulting in a brighter colour.

to update_patch_colour
  ask patches [
    set plabel (word p_energy " " w_length) ;; label each patch with energy and word length
    ifelse (p_energy) <= 0 [
      ;; no energy is black
      set pcolor black
    ]
    [
      ifelse (w_length = short_length) [ 
        ;; short words are green
        set pcolor (((scale-color green p_energy 0 word_maximum_energy) - (green - 5)) * 0.5) + green - 5;; darker when less energy
      ]
      [ ;; long words are red
        set pcolor (((scale-color red p_energy 0 word_maximum_energy) - (red - 5)) * 0.5) + red - 5
      ]
    ]
  ]
end

;; Procedure for moving the turtle/agent responsible for rehearsing words held in the phonological loop.

to move_recaller_serial
  ask recaller [
    ;; if new patch, we determine how long to stay here
    if (p_energy > 0 and stay_length <= 0 and on_new_patch) [
        set stay_length w_length / 2 ;; stay on this patch for word length/2 ticks (if this is a new patch, stay_length hasn't been set already, and the patch has energy)
      ]
    
    ifelse (stay_length > 0 and p_energy <= word_maximum_energy) [
      ;; add energy to this patch
      set p_energy p_energy + energy_to_add
      if p_energy > word_maximum_energy [set p_energy word_maximum_energy]
      set stay_length stay_length - 1 ;; decreases stay time
      set on_new_patch false ;; tells the turtle not to see this as a new word once stay_length runs out
      set x_last_visited xcor ;; saving the location so the turtle 'remembers' where it was last
      set y_last_visited ycor
    ]
    [ 
      ;; else we are moving on to the next patch..
      set newx xcor
      set newy ycor
      set_dest_serial ;; move once, to start
      
      ;; second condition to avoid infinite loop - makes sure that the patch has energy, and stops looking ahead once it reaches the patch it was just on 
      while [[p_energy] of patch newx newy <= 0 and not (x_last_visited = newx and y_last_visited = newy)]
      [set_dest_serial] ;; looks one more patch ahead if nothing here
      
      ;; finally, move recaller to the next legitimate location
      setxy newx newy
      set on_new_patch true
    ]
  ]
end

;; looks at the patches in 'front' of itself, rather than moving ahead and checking if the patch it's on has energy. Prevents decay of stored words while the turtle is
;; trying to find a new word

to set_dest_serial
  ifelse (newx >= max-pxcor) ;; if reaches end of row
    [
      set newx min-pxcor ;; starts looking at the beginning of the next row down
      set newy (newy - 1) mod (min-pycor - 1)
    ]
    [
      set newx (newx + 1)
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
374
31
1199
225
-1
-1
81.5
1
15
1
1
1
0
1
1
1
0
9
-1
0
1
1
1
ticks
5.0

SLIDER
8
125
354
158
energy_decay_rate
energy_decay_rate
0
15
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
8
212
254
245
number_of_words
number_of_words
0
100
13
1
1
NIL
HORIZONTAL

SLIDER
182
254
354
287
long_length
long_length
6
15
7
1
1
NIL
HORIZONTAL

SLIDER
7
254
178
287
short_length
short_length
0
5
3
1
1
NIL
HORIZONTAL

SLIDER
8
292
178
325
length_bias
length_bias
0
100
50
1
1
NIL
HORIZONTAL

BUTTON
30
24
191
71
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
221
25
322
71
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
169
354
202
energy_to_add
energy_to_add
0
50
20
1
1
NIL
HORIZONTAL

BUTTON
263
212
353
245
Add words
set number_of_words_internal number_of_words
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
377
254
642
396
Words in memory
Time
Words
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Short" 1.0 0 -13840069 true "" "plot count patches with [p_energy > 0 and w_length = short_length]"
"Long" 1.0 0 -2674135 true "" "plot count patches with [p_energy > 0 and w_length = long_length]"

SLIDER
7
82
354
115
word_maximum_energy
word_maximum_energy
0
500
200
50
1
NIL
HORIZONTAL

SWITCH
94
377
288
410
Articulatory_Suppression
Articulatory_Suppression
1
1
-1000

SLIDER
182
292
354
325
time_between_new_words
time_between_new_words
1
50
25
1
1
NIL
HORIZONTAL

SLIDER
8
329
178
362
energy_at_creation
energy_at_creation
0
500
50
1
1
NIL
HORIZONTAL

SLIDER
182
330
354
363
phonological_similarity
phonological_similarity
1
5
1
0.5
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is our take of modeling Baddeley & Hitch's model's phonological loop in a Netlogo-friendly way.

## HOW IT WORKS

The blue arrow shows where the next memory trace is about to be stored, and the yellow circle is the articulatory rehearsal component that revives the memory traces. The sliders can adjust many of the system's properties such as decay rate, energy increase rate, and so on. 

## HOW TO USE IT

1. Adjust the slider parameters (see below), or use the default settings.
2. Press the SETUP button.
3. Press the GO button to begin the simulation.
4. Look at the monitor to see the Total Amount of Words currently in memory

Parameters: 

- word_maximum_energy: 	The maximum amount of energy a word can contain. Higher values increase the effect of rehearsing a word on negating decay.

- energy_decay_rate: 	How fast a memory trace decays.

- energy_to_add: 		The amount of energy added to a word during rehersal.

- number_of_words: 	The number of words that will be added to memory.

- short_length: 		Defines length for short words. Longer words will decay faster.

- long_lenth: 		Defines length for long words

- length_bias: 		Used to bias word lengths; lower = more short words, higher = more long words

- time_between_new_words:	How much delay between adding each word

- energy_at_creation:	How much energy does each memory trace start with. The closer this is to word_maximum_energy, the less effect repetition of a word in memory will have.

- phonological_similarity:The degree to which the words 'sound' the same. Increases challenge of memorization.

Notes: 

- Add words button when clicked will add number_of_words more words to the model.
- The Articulatory Suppression switch removes the rehersal turtle.

## THINGS TO NOTICE

Notice that longer words stay in memory for less amount of time then the short words.
This is because shorter words can be rehersed more often in memory, gaining more enery than longer words and hence can stay in memory longer. If the base energy is set to the maximum energy, then the additional rehearsal of the first few words when words are being added more slowly will be less effective, and the model will not show a serial position effect (or at least not as strongly).

## THINGS TO TRY

Try changing the parameters around to test different combinations of word lengths (ie. majority longer words).

What kind of results do you expect to see? Are the results different than when compared to the default values?

## EXTENDING THE MODEL

- instead of sliders, more formulae could be used from the models
- instead of simulating lengths of words, lists of actual words can be imported, and also would make phrenological similarity more straightforward to implement
- base values could be fine tuned so that the output matches empirical data


## NETLOGO FEATURES

Note the use of breeds to model two different kinds of “turtles”: rehersal-loop (yellow circle) and word-inserter (blue arrow). 

Note the use of patches to model a word. THe first set of interger(s) displayed on a patch refer to the current energy that word has , and the 2nd set of interger(s) displayed refers to the length of the word.

Red patches are long words and Green patches are short words. As energy decreases the patches fade to black (decayed)


## CREDITS AND REFERENCES

An ACT-R/PM Model of the Articulatory Loop
Huss, David and Byrne, David
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
