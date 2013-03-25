globals [
  max_p_energy ;; constant for how numerical value of patch energy
  number_of_words_internal
]

patches-own [
  p_energy      ;;amount of energy this patch contains represented by intensity of colour - salience 
  ;;times-visited ;; tracks times the patch was visited
  w_length      ;; word length - Shorter words are GREEN, Longer words will turn RED
  ;;l_position    ;; order in which it has been put into the list
  
]

turtles-own [
  stay_length ;; how much time should this agent be stuck on this patch
  on_new_patch ;; so it knows to move on after it adds enough energy to one patch
]

breed [inputters inputter]
breed [recallers recaller]

;; Setup procedures

to setup
  clear-all
  setup-patches
  setup-turtles
  set max_p_energy 100
  set number_of_words_internal number_of_words
  random-seed 4356653
  reset-ticks
end

to setup-patches 
  ask patches [
    set p_energy 0
    ;;set times-visited 0 ;;intially none of words (i.e. patches) were rehearsed by articulator (i.e. turtle)
    set w_length 0      ;; placeholder to initialize, should never access if energy=0
    ;;set l_position 0    ;; placeholder to initialize, should never access if energy=0
  ]
  
end

to setup-turtles
  create-inputters 1 [set color blue] ;; adds words
  create-recallers 1 [set color yellow set shape "circle"] ;; recalls words
  ask turtles [
    facexy max-pxcor ycor ;; face the right
  ]
  ask recallers [
    set on_new_patch true
    back 2 ;; put recaller behind inputter at the beginning
  ]
  
end





;; Runtime procedures moving turtle to patch, turtle visits to patch and adding energy to patch

to go
  update_patch_colour
  move_inputter_serial
  move_recaller_serial
  
  decay_patches
  tick
end

to decay_patches
  ask patches [
    ifelse (p_energy > 0) [
      set p_energy p_energy - (energy_decay_rate * w_length)
    ]
    [ 
      set p_energy 0 ;; set to 0 if it goes negative
      set w_length 0
    ]
  ]
end

to move_serial
  ifelse xcor = max-pxcor ;; if reaches end of row
  [
    setxy min-pxcor ycor - 1 ;; go to next row
  ]
  [
    forward 1
  ]
end

to move_inputter_serial
  ask inputters [
    if (number_of_words_internal > 0) [
      ifelse (random 100 < length_bias) [
        ask patch-here [set w_length min_length] ;; depending on bias, short word, or..
        set plabel (word p_energy " " min_length)
      ]
      [
        set w_length max_length ;; long word
        set plabel (word p_energy " " max_length)
      ]
      ask patch-here [set p_energy max_p_energy]
      move_serial
      
      set number_of_words_internal number_of_words_internal - 1
    ]
  ]
end

to update_patch_colour
  ask patches [
    set plabel (word p_energy " " w_length)
    ifelse (p_energy) <= 0 [
      set pcolor black
    ]
    [
      ifelse (w_length = min_length) [ ;; short words are green
        set pcolor (scale-color green p_energy 0 max_p_energy);; stuff green after darkens it
      ]
      [ ;; long words are red
        set pcolor (scale-color red p_energy 0 max_p_energy)
      ]
    ]
  ]
end

to move_recaller_serial
  ask recallers [
    if (p_energy > 0 and stay_length <= 0 and on_new_patch) [ ;; if new patch, we determine how long to stay here
        set stay_length w_length / 2 ;; stay on this patch for word length/2 ticks
      ]
    
    ifelse (stay_length > 0 and p_energy <= max_p_energy) [
      ask patch-here [set p_energy p_energy + energy_to_add]
      if p_energy > max_p_energy [ set p_energy max_p_energy]
      set stay_length stay_length - 1
      set on_new_patch false
    ]
    [
      ;; if we're not staying, then move ahead one
      move_serial
      while [p_energy <= 0] ;; will equal to 0 in next tick
      [move_serial] ;; keep moving if nothing here
      
      set on_new_patch true
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
547
10
961
445
5
5
36.73
1
10
1
1
1
0
1
1
1
-5
5
-5
5
0
0
1
ticks
30.0

SLIDER
52
115
245
148
energy_decay_rate
energy_decay_rate
0
20
2
1
1
NIL
HORIZONTAL

SLIDER
61
168
233
201
number_of_words
number_of_words
0
100
10
1
1
NIL
HORIZONTAL

SLIDER
61
208
233
241
max_length
max_length
0
20
7
1
1
NIL
HORIZONTAL

SLIDER
62
251
234
284
min_length
min_length
0
20
2
1
1
NIL
HORIZONTAL

SLIDER
61
300
233
333
length_bias
length_bias
0
100
52
1
1
NIL
HORIZONTAL

SLIDER
61
345
233
378
input_disparity
input_disparity
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
103
57
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
127
24
190
57
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
60
395
232
428
energy_to_add
energy_to_add
0
20
10
1
1
NIL
HORIZONTAL

BUTTON
252
171
342
204
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
268
252
533
402
Words in memory
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Short" 1.0 0 -13840069 true "" "plot count patches with [p_energy > 0 and w_length = min_length]"
"Long" 1.0 0 -2674135 true "" "plot count patches with [p_energy > 0 and w_length = max_length]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
