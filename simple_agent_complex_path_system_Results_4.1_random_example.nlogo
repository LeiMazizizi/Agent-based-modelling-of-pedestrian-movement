breed [builds build]
breed [people person]
undirected-link-breed [linkbuilds linkbuild]

breed [patchpages patchpage]
directed-link-breed [linkpatchpages linkpatchpage]

patches-own [route is-building? my-xorigin my-yorigin pageID ]
people-own [destx desty buildwho almost-there? travel-length angle-change prior-angle xcor-backStep ycor-backStep SD-distance original-angle-between-dest memory-last-patch-x memory-last-patch-y find-a-max-patch a-max-patch-x a-max-patch-y]
builds-own [build-degree frq-visited]

patchpages-own [  rank new-rank ; for the diffusion approach
  visits ; for the random-surfer approach

]

breed [ city-labels city-label ]
breed [ country-labels country-label ]
breed [ country-vertices country-vertex ]
breed [ river-labels river-label ]

globals [

  nest
  food
  building-set
  building-hit-pro ; the probability of an agent's hitting a building
  rv
  patch-value-mean
  ht-index



  travel-length-difference-list

  saved-building-from-file
  num-building-fromfile
  num-portal-fromfile

  total-rank max-rank
  patch-page-rank-list
  who-patch-page-rank-list

  people-hit-times
  people-miss-times
  hit-ratio

  route-ratio-list

  indicator-frq-degree

  data-envilope
  hotspots-data
  building-data
  street-data
  portal-data

  feature-building-data
  patch_num
]

extensions [
  gis
  py
  nw
  matrix
  csv
  stats] ;; The network extension is used in this model.

to-report travel-diff
  if length travel-length-difference-list > 0[
    report (sum travel-length-difference-list / length travel-length-difference-list)]
end
to-report travel-diff2
  report 1
end
to my-test
  let my1 [1 2 3]
  let my2 [2 3 4]

  show abs my1 - my2
end
to python-test
  py:setup py:python
  (py:run
    "import math"
    "mydata=[1,2,3]")

  ;; Transfer data to Netlogo environment:
  let m py:runresult "[math.factorial(i) for i in range(10)]"
  let n py:runresult "mydata" ;Not working
  show n

  ;; Transfer data to Python environment:
  py:set "xx" [1 2 3]
  (py:run
    "x=[_+1 for _ in xx]"
   )
  show py:runresult "x"
end

to-report report_num_paths
  let rv_h []

  ask patches with [route > 0] [set rv_h insert-item 0 rv_h route ]
  ifelse length rv_h > 0 [
  let avg_rvh mean rv_h
  let rv_h_greaterMean []

    foreach rv_h [x -> if x > avg_rvh [set rv_h_greaterMean insert-item 0 rv_h_greaterMean x] ]
    report length rv_h_greaterMean]
  [report 0]

end


to-report report-ht-index
  set rv []
  ;ask patches with [is-building? != true and route != 0] [set rv insert-item 0 rv route ]
  ask patches with [route != 0] [set rv insert-item 0 rv route ]
;  set rv sort-by > rv
  ifelse length rv > 0 [
  py:setup py:python
  py:set "pixels" rv
  (py:run
    "def htb(data):"
    "    outp = []  # array of break points"
    "    def htb_inner(data):"
    "        data_length = float(len(data))"
    "        data_mean = sum(data) / data_length"
    "        head = [_ for _ in data if _ > data_mean]"
    "        while len(head) > 1 and len(head)/data_length <= 0.40:"
    "            outp.append(data_mean)"
    "            return htb_inner(head)"
    "    htb_inner(data)"
    "    outp.sort(reverse=True)"
    "    return len(outp)+1,outp"
    "ht_index,outp=htb(pixels)"
  )

  let here-ht-index py:runresult "ht_index"
  let here-patch-value-mean py:runresult "outp"
  set patch-value-mean here-patch-value-mean
  report here-ht-index
  ][report 0]
end


to create-cut-buildings
  if feature-building-data != 0 [
    let count-h 0
;    ask builds [ foreach feature-building-data [fbd -> if (gis:contains? fbd self) = false [set count-h count-h + 1 die] ] ]
    ask builds [ if (gis:contains? feature-building-data self) = false [set count-h count-h + 1 die] ]
    set building-hit-pro []
    ask builds [set build-degree count builds set building-hit-pro insert-item 0 building-hit-pro who]
    show length building-hit-pro
    ask people [;; set the destx and desty from breed builds
      if length building-hit-pro != 0 [

        let this-index random length building-hit-pro

        let this-dest turtle (item this-index building-hit-pro)

        set buildwho [who] of this-dest

        set destx [xcor] of this-dest
        set desty [ycor] of this-dest
        set original-angle-between-dest towards patch destx desty
        facexy destx desty
        set prior-angle heading
        ;    show (list destx desty)

      ]
    ]

  ]
end

to setup
  ifelse num-building-fromfile != 0 [
    clear-all

      show "# of builds:"
  show count builds
  ][
  clear-all
  ]
  set patch-page-rank-list []
  set who-patch-page-rank-list []
  set people-hit-times 0
  set people-miss-times 0
  set hit-ratio 0.0


  set travel-length-difference-list []




  ifelse building-network? = TRUE [

      create-network ] ;; Creates a social network if networks is true. Otherwise just creates a set of unconnected turtles.
  [randomBuilding ]

  if saved-building-from-file != 0 [show "Run" reset-building-from-file]

  ;  set food (list foodxy1 foodxy2 foodxy3 foodxy4)
  ask patches [
    set pcolor bg-color
    set route 0
    set my-xorigin -1
    set my-yorigin -1
  ]


    let nesttemp [ (list xcor ycor) ] of builds
    show "nesttemp:"
    show nesttemp
    show length nesttemp

    set nest nesttemp


  create-agents nest

  reset-ticks
end

to randomBuilding
  set building-set []
  let num-b-temp num-building - 1
  let dj true
  while [dj]
    [
      if num-b-temp = 0 [set dj false]
      ;      show dj

      let ran-pxcor random max-pxcor
      let ran-pycor random max-pycor

      if saved-building-from-file != 0 [
        let p-f item num-b-temp saved-building-from-file
        set ran-pxcor item 0 p-f
        set ran-pycor item 1 p-f
      ]
      set building-set insert-item 0 building-set list ran-pxcor ran-pycor
      ;      ifelse empty? building-set [set building-set insert-item 0 building-set list ran-pxcor ran-pycor]
      ;      []
      ;      show building-set
      ask patch ran-pxcor ran-pycor [
        sprout 1 [
          set color white
          set shape "house"
          let this-size random 5
;          set size this-size * 2
          set size 2

          ask patch-here
          [
            ;            show pxcor
            ;            show pycor
            set is-building? true
            ;        set pcolor yellow
            ;            ask neighbors [set is-building? true]
            set my-xorigin ran-pxcor
            set my-yorigin ran-pycor
          ]
          ask patches in-radius this-size [
            set is-building? true
            set my-xorigin ran-pxcor
            set my-yorigin ran-pycor
          ]
;          stamp
;          die
        ]
      ]
      set num-b-temp num-b-temp - 1
      ;      show num-b-temp
  ]
end

to go
  ;  if all? turtles [abs(xcor - destx)<= 2  and abs(ycor - desty)<= 2]
  ;  if all? turtles [
  ;    [my-xorigin] of patch-ahead 1 = destx and [my-yorigin] of patch-ahead 1 = desty or abs(xcor - destx)<= 2  and abs(ycor - desty)<= 2]
  ;;    abs(xcor - destx)<= 2  and abs(ycor - desty)<= 2]
  ;  [stop]

  if ticks >= num-ticks [stop]
  if ticks mod 100 = 0 [
    set ht-index report-ht-index

    render-patch
    set patch_num report_num_paths
;    set people-hit-times 0
;    set  people-miss-times 0
  ]

  if people-hit-times != 0[
    set hit-ratio people-hit-times / (people-hit-times + people-miss-times )]
;  plot-routes
;  plot-build-visits

  ask people [
    if who >= ticks [ stop ] ;; delay initial departure

    let this-buildwho buildwho
    if memory-last-patch-x = 0 and memory-last-patch-y = 0 [set memory-last-patch-x -1 set memory-last-patch-y -1]

    let d-x [xcor] of turtle this-buildwho
    let d-y [ycor] of turtle this-buildwho

    let distance-here (d-x - xcor) * (d-x - xcor) + (d-y - ycor) * (d-y - ycor)
    let distance-here-dest sqrt distance-here

    ifelse distance-here-dest <= speed * 1.5
    [

      if length building-hit-pro != 0 [
;        show "AHA-1"
        let this-index random length building-hit-pro

        let this-dest-who item this-index building-hit-pro


        let this-dest-who-destx [xcor] of turtle this-dest-who
        let this-dest-who-desty [ycor] of turtle this-dest-who
        ifelse this-dest-who = this-buildwho [ ; 两次获得的目的地ID相同或距离太近

          set this-index int this-index + 0.5 * length building-hit-pro
          if this-index >= length building-hit-pro [set this-index this-index - length building-hit-pro]
          set this-dest-who item this-index building-hit-pro
          set buildwho this-dest-who
          let this-destx  [xcor] of  turtle this-dest-who
          let this-desty  [ycor] of  turtle this-dest-who
          set travel-length-difference-list insert-item 0 travel-length-difference-list (abs (travel-length - SD-distance))
          set destx this-destx
          set desty this-desty
          set SD-distance distancexy destx desty
          set original-angle-between-dest towards patch destx desty
;
          if travel-length > 0[

          ]

          set travel-length 0.0
          set angle-change 0.0
;          set almost-there? false
;          show "AHA-2"
          ;          show "gl 1"
        ][
          set buildwho this-dest-who
          let this-destx  [xcor] of  turtle this-dest-who
          let this-desty  [ycor] of  turtle this-dest-who
          set travel-length-difference-list insert-item 0 travel-length-difference-list ((abs travel-length - SD-distance))
          set destx this-destx
          set desty this-desty
          set SD-distance distancexy destx desty
          set original-angle-between-dest towards patch destx desty

          set travel-length 0.0
          set angle-change 0.0
;          set almost-there? false
          ;        show "gl 2"
;          show "AHA-3"
        ]
        ;        show [who] of this-dest

    ]
      ; the frq-visited of destination build + 1
      ask turtle this-buildwho [set frq-visited frq-visited + 1
;        show frq-visited
      ]

    ]
    [
      ifelse random-walk = true [
        rt random 360
        fd 1
        set route route + 1
      ]

      [let got-route? find-route distance-here-dest ; find a route around firstly

;      ifelse speed-here = speed [ show "move >1 steps"
      set find-a-max-patch got-route?
      ifelse got-route?  [set people-hit-times people-hit-times + 1] [set people-miss-times people-miss-times + 1]


      repeat speed [
        let from-page pageID
;        set prior-angle heading
        set xcor-backStep xcor
        set ycor-backStep ycor

        set memory-last-patch-x pxcor
        set memory-last-patch-y pycor

        fd 1
        set route route + 1
;        set travel-length travel-length + 1
        set travel-length travel-length + (distancexy xcor-backStep ycor-backStep)
        set angle-change angle-change + abs (heading - prior-angle)
        set prior-angle heading
;        set pcolor gray - route * 1.3



        let to-page pageID
        if from-page != to-page [


        ]

      ]


        facexy destx desty
    ]
  ]
  ]

  tick

end
to-report find-route [distance-local]
  ;  let next-jump-to
  let pt patch-here
  let got-route-h? false

  let memory-last-patch-x-here memory-last-patch-x
  let memory-last-patch-y-here memory-last-patch-y



  let head-range min list distance-local head-distance

  if any? patches with [route != 0 and pxcor != [pxcor] of pt and pycor != [pycor] of pt and pxcor != memory-last-patch-x-here and pycor != memory-last-patch-y-here] in-cone head-range head-angle-max [
    set got-route-h? true

    let patch-this-n patches with [route != 0 and pxcor != [pxcor] of pt and pycor != [pycor] of pt and pxcor != memory-last-patch-x-here and pycor != memory-last-patch-y-here] in-cone head-range head-angle-max with-max [route]
    let patch-this min-one-of patch-this-n [distance myself]

    ;    show [route] of patch-this
    let pxc-pthis [pxcor] of patch-this
    let pyc-pthis [pycor] of patch-this
    ;    show pxc-pthis
    ;    show pyc-pthis
;    set prior-angle heading
    set heading towards patch pxc-pthis pyc-pthis

    set a-max-patch-x pxc-pthis
    set a-max-patch-y pyc-pthis

  ]


report got-route-h?
end


to correct-path

  let dj true
  let counting 0
  while [dj]
  [
    if counting > 10 [stop]
    set counting counting + 1
    ;    show counting
    ifelse patch-ahead 1 != nobody [

      ifelse [is-building?] of patch-ahead 1 = true [
        ;        let xhere patch-ahead 1
        ifelse ([pxcor] of patch-ahead 1 - destx)*([pxcor] of patch-ahead 1 - destx) +  ([pycor] of patch-ahead 1 - desty)* ([pycor] of patch-ahead 1 - desty)<= 4

        ;        ifelse ([my-xorigin] of patch-ahead 1 - destx)*([my-xorigin] of patch-ahead 1 - destx) +  ([my-yorigin] of patch-ahead 1 - desty)* ([my-yorigin] of patch-ahead 1 - desty)<= 2
        [stop]
        [let this-random random 100
          if this-random >= 50 [rt 50]
          if this-random < 50  [lt 50]]
      ][stop]
    ][let this-random random 100
      if this-random >= 50 [rt 50]
      if this-random < 50  [lt 50]
      ;      show 2
    ]
  ]
;  let d-x item 0 [xcor] of builds with [who = buildwho]
;  let d-y item 0 [ycor] of builds with [who = buildwho]

  let d-x  [xcor] of turtle buildwho
  let d-y  [ycor] of turtle buildwho

  show (d-x - xcor)*(d-x - xcor) + (d-y - ycor)*(d-y - ycor)

end
;to correct-path
;    if patch-at 0 -1 = nobody
;        [ rt 100 ]
;     if patch-at 0 1 = nobody
;        [ lt 100 ]
;end
;; turtle procedure; wiggle a random amount, averaging zero turn
to wiggle [angle]
  rt random-float angle
  lt random-float angle
end

to create-agents-old [here-nest]
  let temp 0
  create-people number-of-agents [
    set color red
    set size 2
    set almost-there? false
;    let this-nest item (temp mod 4) here-nest
    let this-nest one-of here-nest
    setxy item 0 this-nest item 1 this-nest
    set temp temp + 1
    set travel-length 0.0
    set angle-change 0.0


    ;    let this-dest item (temp mod 4) food
    ;    set destx item 0 this-dest
    ;    set desty item 1 this-dest
    ifelse building-network? = false [
      let this-dest one-of building-set
      set destx item 0 this-dest
      set desty item 1 this-dest
      facexy destx desty
      set prior-angle heading
      ;    show (list destx desty)

    ]
    [;; set the destx and desty from breed builds
      if length building-hit-pro != 0 [
        let this-index random length building-hit-pro

        let this-dest turtle item this-index building-hit-pro

        set buildwho [who] of this-dest

        set destx [xcor] of this-dest
        set desty [ycor] of this-dest
        set original-angle-between-dest towards patch destx desty
        facexy destx desty
        set prior-angle heading

      ]
    ]
  ]

end

to create-agents [here-nest]
  let temp 0
  create-people number-of-agents [
    set color red
    set size 2
    set almost-there? false


    let this-nest one-of here-nest
;    let this-nest item (temp mod 4) here-nest

    setxy item 0 this-nest item 1 this-nest
    set temp temp + 1
    set travel-length 0.0
    set angle-change 0.0


    ;    let this-dest item (temp mod 4) food
;    set destx item 0 this-dest
;    set desty item 1 this-dest
          let this-index1 random length building-hit-pro
;     let this-dest builds with [who = item this-index building-hit-pro]
      let this-dest1 turtle item this-index1 building-hit-pro
      set destx [xcor] of this-dest1
      set desty [ycor] of this-dest1
    set buildwho [who] of this-dest1

    ifelse num-building-fromfile != 0 [
      ;; set the destx and desty from breed builds


        set building-hit-pro []
        ask builds [
        repeat build-degree [set building-hit-pro insert-item 0 building-hit-pro who]

      ]
;    ]

      let this-index random length building-hit-pro
;     let this-dest builds with [who = item this-index building-hit-pro]
      let this-dest turtle item this-index building-hit-pro
      set destx [xcor] of this-dest
      set desty [ycor] of this-dest

      while [ (destx = pxcor) and (desty = pycor) ]
      [
        set this-index random length building-hit-pro
        ;     let this-dest builds with [who = item this-index building-hit-pro]
        set this-dest turtle item this-index building-hit-pro
        set destx [xcor] of this-dest
        set desty [ycor] of this-dest
      ]

        set buildwho [who] of this-dest

        set original-angle-between-dest towards patch destx desty
        facexy destx desty
        set prior-angle heading
        ;    show (list destx desty)

    ]
    [
      ifelse building-network? = false [
      let this-dest one-of building-set
      set destx item 0 this-dest
      set desty item 1 this-dest
      facexy destx desty
      set prior-angle heading
      ;    show (list destx desty)

      ][]
   ]
  ]

end


to reset-building-from-file
  let num-b-temp 0

  foreach saved-building-from-file [x -> ask build num-b-temp [ set xcor item 0 x set ycor item 1 x
    set build-degree item 2 x] set num-b-temp num-b-temp + 1 ]

  mark-builds-on-patches "n"
  display
end

to create-network ;; Includes procedures for four kinds of networks.

  if network-type = "random" [ ;; Creates one random network (Erdös-Renyi random network).
    create-builds num-building ;; Create number-of-building turtles.
    repeat (network-param * count builds) / 2 [ ;; Divide by two (because a link connects two turtles).
      ask one-of builds [

        let here-link one-of other builds with [ not linkbuild-neighbor? myself ]
        if here-link != nobody [
          create-linkbuild-with one-of other builds with [ not linkbuild-neighbor? myself ] ];; Ask a random turtle to create link with another random turtle.
      ]

    ]
  ]

  if network-type = "small-world" [ ;; Creates a Watts-Strogatz small-world network (high clustering coefficient). Uses the algorithm from NetLogo network extension (https://ccl.northwestern.edu/netlogo/docs/nw.html).
                                    ;    nw:generate-watts-strogatz turtles links num-building network-param 0.1 [ fd 10 ] ;; Structure: turtle-breed link-breed num-nodes neighborhood-size rewire-probability optional-command-block
    nw:generate-watts-strogatz builds linkbuilds num-building network-param 0.1 [ fd 10 ] ;; Structure: turtle-breed link-breed num-nodes neighborhood-size rewire-probability optional-command-block

  ]

  if network-type = "preferential" [ ;; Creates a scale-free network with hubs (preferential attachment). This is the Barabási–Albert network model. Uses the algorithm from NetLogo network extension (https://ccl.northwestern.edu/netlogo/docs/nw.html).
    nw:generate-preferential-attachment builds linkbuilds num-building network-param [ fd 10 ;; Structure: turtle-breed link-breed num-nodes min-degree optional-command-block
                                                                                             ;      repeat 3 [
                                                                                             ;        ;   layout-spring turtles links 0.2 4.0 500 ;; Layout procedure (mainly cosmetic).
                                                                                             ;        display  ;; For smooth animation.
                                                                                             ;      ]
    ]
  ]


  if network-type = "KE" [ ;; Creates a scale-free network with high clustering, the Klemm-Eguíluz model.
                           ;; The following algorithm is adapted with permission from Fernando Sancho Caparrini's "Complex Networks Toolbox", see http://www.cs.us.es/~fsancho/?e=162#KE for details and a conceptual model.
                           ;    clear-all
    create-builds network-param [ ;; The algorithm begins with an initial set of turtles. The number of initial turtles is defined by network-param. (This is m0 in the original KE algorithm.)
                                  ;      set color red
    ]
    ask builds [
      create-linkbuilds-with other builds
    ]
    let active builds with [self = self]
    let no-active no-turtles
    repeat (num-building - network-param) [
      create-builds 1 [
        set color white
        foreach shuffle (sort active) [ [ac] ->
          ifelse (random-float 1 < mu or count no-active = 0)
          [
            create-linkbuild-with ac
          ]
          [
            let cut? false
            while [not cut?] [
              let nodej one-of no-active
              let kj [count my-linkbuilds] of nodej
              let S sum [count my-linkbuilds] of no-active
              if (kj / S) > random-float 1 [
                create-linkbuild-with nodej
                set cut? true
              ]
            ]
          ]
        ]
        set active (turtle-set active self)
        let cut? false
        while [not cut?] [
          let nodej one-of active
          let kj [count my-linkbuilds] of nodej
          let S sum [1 / (count my-linkbuilds)] of active
          let P (1 / (kj * S))
          if P > random-float 1 [
            set no-active (turtle-set no-active nodej)
            set active active with [self != nodej]
            set cut? true
          ]
        ]
      ]
  ]]

  if network-type = "evenly-random"[
    create-builds num-building
  ]



  mark-builds-on-patches "r"
end

to mark-builds-on-patches [is-randomxy]

  set building-hit-pro []

  ask builds [
    if is-randomxy = "r" [
          setxy random-xcor random-ycor]
    set color white
    set shape "house"
;    set frq-visited 0
    ; calculate degree of this building
    ;    show my-linkbuilds
    let this-size count my-linkbuilds
    repeat this-size [
      set building-hit-pro insert-item 0 building-hit-pro who
    ]
    if num-building-fromfile = 0 [
      if this-size = 0 [set this-size count builds set building-hit-pro insert-item 0 building-hit-pro who] ; if evenly-random is selected
      set build-degree this-size]
    set label build-degree
    set label-color red

    ;    show building-hit-pro
    ;    let this-size 5
    ;    show count my-trajs
;    set size this-size
    set size 3
    ;    set size this-size * 2
    let ran-pxcor 0
    let ran-pycor 0
    ask patch-here
          [
            set is-building? true
            set my-xorigin pxcor
            set my-yorigin pycor
            set ran-pxcor pxcor
            set ran-pycor pycor
    ]

    ask patches in-radius (this-size / 2) [
      set is-building? true
      set my-xorigin ran-pxcor
      set my-yorigin ran-pycor
    ]

  ]
  ask linkbuilds [hide-link]
end

to hide-buildings
  ask builds [hide-turtle]
end
to show-buildings
  ask builds [show-turtle]
end
to hide-agents
  ask people [hide-turtle]
end
to show-agents
  ask people [show-turtle]
end

to-report calculate-breaks [mylist num-classes]
  let min-value min mylist
  let max-value max mylist
  let interval ((max-value - min-value) / num-classes)
  let breaks []
  set num-classes num-classes - 1
  repeat num-classes [
    set min-value min-value + interval
    set breaks lput min-value breaks
  ]
  set breaks reverse breaks
  report breaks
end

to render-patch
  let render-color [ 15 15 45 45 65 65 95 95 102 102 ]
  let render-color-equal [15 45 65 95 102]
;  print "patch-value-mean:"
;  print patch-value-mean
  ifelse ht-index = 1 [
    let mylist []
    ask patches with [route != 0] [set mylist insert-item 0 mylist route ]
    let class-values-list calculate-breaks mylist 5

;    print "class-values-list:"
;    print class-values-list

    let is-first? true
    let color-index 0
    foreach class-values-list [this-mean ->
      if is-first? = true [
        set is-first?  false
        ask patches with [route >= this-mean ] [set pcolor item color-index render-color-equal]
        set color-index color-index + 1]

      ask patches with [route < this-mean and route > 0] [set pcolor item color-index render-color-equal]
      set color-index color-index + 1

  ]]

  [if ht-index >= 2 [
    let is-first? true
    let color-index 0
    foreach patch-value-mean [this-mean ->
      if is-first? = true [
        set is-first?  false
        ask patches with [route >= this-mean ] [set pcolor item color-index render-color]
      set color-index color-index + int 10 / ht-index]

      ask patches with [route < this-mean and route > 0] [set pcolor item color-index render-color]
      set color-index color-index + int 10 / ht-index

    ]

  ]]

end


  ;;;;;;;;;;;;;Plot Part:;;;;;;;;;;;;;;;;;;;;;;;;;
to plot-build-visits
;  if ticks mod 50 = 0 [
  clear-all-plots

  let fv []
  ask builds [set fv insert-item 0 fv frq-visited]
  set fv sort-by > fv
;  set-histogram-num-bars length bd
;  show "Building degree"
;  show bd
  let index-h 0
  foreach fv [
;    show index-h
;    show item index-h bd
    set-current-plot "#Visits of buildings"
;    clear-plot
    plotxy index-h item index-h fv
    set-current-plot "Log #visits of buildings"
;    clear-plot
    let new-i index-h + 1
    let log-y item index-h fv
    if log-y != 0 [
      plotxy log new-i 10 log log-y 10
    ]
    set index-h index-h + 1

  ]
end

to plot-routes
  clear-plot
  if ticks mod 50 = 0 [
;  clear-all-plots
;  set-current-plot "Routes value"

  set rv []
  ask patches with [is-building? != true] [set rv insert-item 0 rv route ]
  set rv sort-by > rv
;  show rv

  let index-h 0
  foreach rv [
      set-current-plot "Routes value"
;clear-plot
;      set-current-plot-pen "rv-pen"
      plotxy index-h item index-h rv
;      set-current-plot-pen "rv-log-pen"

      set-current-plot "Routes Value Log"
;clear-plot
      let new-i index-h + 1
      let log-y item index-h rv
      if log-y != 0 [
        plotxy log new-i 10 log log-y 10]
  set index-h index-h + 1]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
261
10
673
423
-1
-1
4.0
1
20
1
1
1
0
0
0
1
0
100
0
100
1
1
1
ticks
30.0

BUTTON
187
52
250
85
NIL
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

INPUTBOX
13
139
168
199
number-of-agents
100.0
1
0
Number

BUTTON
186
89
249
122
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
13
208
168
268
num-building
100.0
1
0
Number

SLIDER
14
276
186
309
head-angle-max
head-angle-max
0
180
62.0
1
1
NIL
HORIZONTAL

INPUTBOX
17
14
172
74
num-ticks
10000.0
1
0
Number

SLIDER
13
312
185
345
head-distance
head-distance
0
50
12.0
1
1
NIL
HORIZONTAL

SWITCH
688
13
840
46
building-network?
building-network?
0
1
-1000

CHOOSER
691
55
829
100
network-type
network-type
"random" "small-world" "preferential" "KE" "evenly-random"
2

SLIDER
689
109
861
142
network-param
network-param
1
20
5.0
0.1
1
NIL
HORIZONTAL

SLIDER
689
148
861
181
mu
mu
0
1
0.92
0.01
1
NIL
HORIZONTAL

CHOOSER
15
82
153
127
bg-color
bg-color
0 5
0

BUTTON
178
13
253
46
go once
go
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
898
188
1098
338
Building degree
NIL
NIL
0.0
20.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "let max-degree max [count linkbuild-neighbors] of builds\nplot-pen-reset  ;; erase what we plotted before\n;set-plot-y-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar\n;set-plot-x-range 0 (count builds / 2)\nhistogram [count linkbuild-neighbors] of builds"

BUTTON
280
433
386
466
Hide Buildings
hide-buildings
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
280
471
387
504
Show Buildings
show-buildings
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
13
350
185
383
speed
speed
1
20
1.0
1
1
NIL
HORIZONTAL

BUTTON
508
453
612
486
NIL
render-patch
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
691
347
891
497
Distance-difference
NIL
NIL
0.0
10.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "if ticks mod 10 = 0 [\nclear-plot\n;set rv []\n  ;;ask patches with [is-building? != true and route > 0] [set rv insert-item 0 rv route ]\n  ;ask patches with [route > 0] [set rv insert-item 0 rv route ]\n\n  ;set rv sort-by > rv\n  ;let index-h 0\n  ;foreach rv [\n   \n  ;    let new-i index-h + 1\n  ;    let log-y item index-h rv\n  ;    ;if log-y != 0 [\n  ;      plotxy log new-i 10 log log-y 10\n  ;      ;]\n  ;set index-h index-h + 1]\n  \n  let routes-here travel-length-difference-list\n  if length routes-here > 0 [\n  let max-route max routes-here\n  let min-route min routes-here\n  \n  let degree min-route\n  while [degree < max-route] [\n  let count-here 0\n  foreach routes-here [ x -> if x > degree [set count-here count-here + 1] ]\n  \n  if count-here > 0 and degree > 0\n    [ plotxy  degree\n              count-here / length routes-here]\n  set degree degree + (max-route - min-route) / 100\n]\n  ]\n  ]"

PLOT
691
190
891
340
mean-distance-difference
ticks
mean-distance-difference
0.0
10.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if length travel-length-difference-list > 0 [\nplotxy ticks (sum travel-length-difference-list / length travel-length-difference-list)\n]\n"

MONITOR
803
210
882
255
distance-diff
sum travel-length-difference-list / length travel-length-difference-list
2
1
11

BUTTON
395
473
492
506
NIL
hide-agents
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
391
432
494
465
NIL
show-agents
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
14
387
140
420
random-walk
random-walk
0
1
-1000

PLOT
900
347
1100
497
update-his-routes-plot
Accumulated affordances
# of patches
0.0
1000.0
0.0
4000.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if ticks mod 100 = 0 [clear-plot\n  set rv []\n  ;ask patches with [is-building? != true and route != 0] [set rv insert-item 0 rv route ]\n  ask patches with [route != 0] [set rv insert-item 0 rv route ]\nset-plot-x-range min rv max rv\nset-plot-y-range 0 4000\n\nset-histogram-num-bars 10\n\nhistogram rv]"

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

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

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

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="num-ticks">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-building">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-param">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="head-angle-max">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leader-wiggle-angle">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="route-decay">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="building-network?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mu">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bg-color">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decay-rate-route">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="head-distance">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
