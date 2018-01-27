(in-package :ccl)

;; l is the partial solution (including the current candidate) found
;; so far by the search-engine.



(* 
   (?if (apply #'< l)) ;note, the "less than" binary relation/operator on l, *not* rl
  "Result in ascending order")

;TRY FOR INSTANCE ONE OF THESE: '4-1 '4-Z15A '4-27A 
(* 
 (?IF (LET ((SUBSET (PW::POSN-MATCH (PWGL-VALUE :CHORD) L)))
        (AND (SETP SUBSET :KEY #'MOD12)
             (MEMBER (SC-NAME SUBSET) '#.(CCL::ALL-SUBS '4-1))))) 
 "SC IDENTITY")
 
(* ?1 
   (?if (not (member ?1 (rest rl)))) 
   "No duplicates")

(* ?1 
   (?if (not (member (mod12 ?1) (rest rl) :key #'mod12))) 
   "no octaves")

(* ?1 
   (?if (not (member (mod12 ?1) (rest rl) :key #'mod12)))
   "No pitch class duplicates")

(* ?1  (= (length l) (cur-slen)) 
   (?if (sym-chord? l)) 
   "symmetry")

(* ?1 
   (?if (and (setp l :key #'mod12)
             (member (sc-name l) (pwgl-value :all-subs)))) 
   "SC")

(* ?1 
   (?if (if (grace-note-p ?1)
            (or (<= 23 (m ?1) 58) (<= 71 (m ?1) 102))
          (<= 59 (m ?1) 70)))
   "ranges")

(* ?1 (not (grace-note-p ?1)) 
   (?if (let ((ms (m ?1 :l t :l-filter #'(lambda (n) (not (grace-note-p n)))))) 
          (setp ms :key #'mod12)))
   "normal note setp")

(* ?1 
   (?if
     (if (grace-note-p ?1)
         (setf (color ?1) :red)
         (setf (color ?1) :blue))) 
    "red for harp and blue for voice")

(* ?1 
   (?if 
    (if (grace-note-p ?1)
	(setf (chan ?1) 1)
	(setf (chan ?1) 2))) 
   "channels for instruments")

(* ?1 
   (?if 
    (setf (vel ?1)
	  (cond ((e ?1 "six") 127)
             ((e ?1 "seven") 50)
             (t 64)))) 
   "velocity for the groups")

(* ?1 
   (?if (member (mod (m ?1) 12) '(0 2 4 5 7 9 11)))
   "use the ionian mode")

(* ?1 :harmony 
  (?if (setp (m ?1))) 
  "no harm pitch repetitions")

(* ?1 :harmony 
  (?if (setp (m ?1 :data-access :harm-int)))
   "no harm int repetitions")

(* ?1  :harmony
    (?if (let ((ints (m ?1 :complete? t :data-access :harm-int)))
            (?incase ints (member ints '((4 4) (5 6)) :test #'equal))))
       "3 voice harm int rule")

(* ?1 :harmony 
 (?if (let ((ms (m ?1 :complete? t)))
        (if ms 
         (add-expression 'group (give-bass-item ?1) :info (sc-name ms))
         ())))
   "analyse harmonic scs")

(* ?1 :harmony
   (?if 
    (every #'(lambda (n) 
               (cond ((> (partnum n) (partnum ?csv)) (< (m n) (m ?csv)))
                     ((< (partnum n) (partnum ?csv)) (> (m n) (m ?csv)))
                     (T T))) (m ?1 :object t)))
   "no part-crossings")

; harmonic
(* ?1  :harmony
   (?if (let ((h-midis (m ?1)))
          (and (setp h-midis :key #'mod12)
               (member (sc-name h-midis) '#.(ccl::all-subs '(6-20))))))
   "harm SC rule")

(* ?1  :harmony
   (?if (let ((ms (m ?1 :complete? t)))
          (?incase ms (sym-chord? (sort< (m ?1))))))
   "symmetric chord")

; voice-leading
(* ?1 :harmony
   (?if (every #'(lambda (n) 
                   (cond ((> (partnum n) (partnum ?csv)) (< (m n) (m ?csv)))
                         ((< (partnum n) (partnum ?csv)) (> (m n) (m ?csv)))
                         (T T))) (m ?1 :object t)))
   "no voice-crossings")

(* ?1 :harmony 
   (?if (let ((int (first (m ?1 :data-access :int :complete? t))))
          (?incase int (> int 0))))
   "no unisons and voice crossings")

(* ?1 :harmony 
   (?if (let ((int (first (m ?1 :data-access :int :complete? t))))
          (?incase int (member int '(0 3 4 7 8 9 12 15 16)))))
   "allowed intervals between the two voices")

(* ?1 :harmony 
   (?if (let ((vl (matrix-access (m ?1 :vl-matrix t :complete? t) :h)))
          (?incase vl
              (destructuring-bind ((up1 up2) (down1 down2)) vl
                (?incase (> (abs (- up1 up2)) 2)
                  (<= (abs (- down1 down2)) 2))))))
   "if the upper voice leaps, lower voice must use stepwise movement")

(* ?1 :harmony
   (?if (let ((vl (matrix-access (m ?1 :vl-matrix t :complete? t) :h)))
          (?incase vl
              (destructuring-bind ((up1 up2) (down1 down2)) vl
                (?incase (and (member (- up2 down2) '(7 12))
                         (> (abs (- up1 up2)) 2))
                    (/= (signum (- up1 up2)) (signum (- down1 down2))))))))
   "no hidden parallel fifths or octaves UNLESS the upper voice uses stepwise movement")

(* ?1  :parts '(1 3)
   (?if (setf (vel ?1) 60)) 
    "set sop/bass vel")

(* ?1 :chord :parts 2
   (?if (dolist (n (notes ?1))
           (setf (vel n) 30))) 
    "set chord vel")

(* ?1 :chord :parts '(1 3)
    (?if (let ((ints (m ?1 :data-access :harm-int)))
           (if ints
             (and (not (member  1 ints)) (apply #'>= ints))
              t)))
       "no min seconds and ascending chord ints rule, parts 1,3")

(* ?1 :chord 
   (?if  (when (m ?1 :complete? t)
           (dolist (n (notes ?1))
             (if (< (midi n) 60)
                 (setf (clef-number n) 1)         
               (setf (clef-number n) 0))))) 
   "assign notes below 60 to bass clef")

(* ?1 :chord 
   (?if 
    (let ((ms (m ?1 :complete? t)) vel)
      (when ms
        (setq vel
              (case (length ms)
                (6 127)(5 117)(4 107)(3 97)(2 87)(t 77)))
        (dolist (n (notes ?1)) (setf (vel n) vel))))) 
   "set velocity")

(* ?1 :chord
    (?if (let ((ms (m ?1 :complete? t)))
           (?incase ms
	     (and (setp ms :key #'mod12)
                  (member (sc-name ms) '#.(ccl::all-subs '(4-27a)))))))
   "harm rule")

(* ?1 :chord
    (?if (let ((ints (m ?1 :data-access :harm-int)))
           (?incase ints
             (and (not (member  1 ints))
                  (apply #'>= ints)))))
       "no sharp int/asc harm ints rule")

(* ?1 :chord
    (?if (let ((ms (m ?1 :complete? t)))
           (?incase ms
	     (and (setp ms :key #'mod12)
                  (member (sc-name ms) '#.(ccl::all-subs '(6-Z47B)))))))
   "chord rule")

(* ?1 :chord
   (?if (let ((ints (m ?1 :data-access :harm-int)))
          (?incase ints
              (and (every #'(lambda (int) (<= 5 int 11)) ints) 
                   (apply #'>= ints)))))
   "harm-int between 5 and 11")

(* ?1 :chord 
   (?if 
    (when (m ?1 :complete? t)
        (dolist (n (notes ?1))
          (if (and (< (midi n) 60) (grace-note-p ?1))
              (setf (clef-number n) 1)         
            (setf (clef-number n) 0))))) 
   "assign midis below 60 to bass clef for grace notes")

(* ?1 :score-sort  
   (?if (let ((ms (m ?1 :rl 3)))  
          (not (member (sc-name ms) '(3-10 3-11a 3-11b 3-12)))))
   "no score-sort triads")

(* ?1 :score-sort  
   (?if (let ((ms (m ?1 :rl 7)))  
          (not (member (mod12 (m ?1)) (rest ms) :key #'mod12))))
   "score-sort mod12 repetition")

(* ?1 :parts 1  (e ?1 :fermata)
   (?if (member (mod (m ?1) 12) '(0 7)))
   "in the cadence, the upper voice must end with either C or G")

(* ?1 :parts 2  (e ?1 :fermata)
   (?if (= (mod (m ?1) 12) 0))
   "in the cadence, the lower voice must end with a C")

#|
(* ?1 (not (grace-note-p ?1)) 
   (?if (let ((ms (m ?1 :l 3 :l-filter #'(lambda (n) (not (grace-note-p n)))))) 
          (not (member (sc-name ms) '(3-10 3-11a 3-11b 3-12)))))
   "normal note scs")
|#

(* ?1 ?2 
   (?if (< ?1 ?2)) 
   "ascending")

(* ?1 ?2 
   (?if (member (mod12 (- ?2 ?1)) '(5 6)))
   "mod12 Interval rule")

(* ?1 ?2 
   (?if (member (- ?2 ?1) '(5 6))) 
      "Interval rule")

(* ?1 ?2 
   (?if (member (- ?2 ?1) '(1 2 3 4 5 7 8 9))) 
   "harm ints") 

(* ?1 ?2 
   (?if (unique-int? (mod12 (- ?2 ?1)) (rest rl) :key #'mod12)) 
   "no (modulo 12) interval duplicates")

(* ?1 ?2                     ;;PM-part
  (?if (/= ?1 ?2))         ;;Lisp-code part
  "No equal adjacent values")

(* ?1 ?2                          ;;PM-part
  (?if (/= (m ?1) (m ?2))) ;;Lisp-code part
  "no adjacent melodic pitch dups")

(* ?1 ?2
  (?if (member (- (m ?2) (m ?1)) '(1 -1 2 -2))) 
  "melodic interval")

(* ?1 ?2 :harmony 
  (?if (not (equal (m ?1) (m ?2)))) 
  "no adjacent harmonic pitch dups")

(* ?1 ?2 
   (?if (abs (- ?2 ?1)))
   "prefer large intervals") 

(* ?1 ?2 
   (?if (- (abs (- ?2 ?1))))
   "prefer small intervals")

(* ?1 ?2 
   (?if (< (- ?2 ?1) 12)) 
   "intervals inside octave")

(* ?1 ?2 
   (?if (member (- (m ?2) (m ?1)) '(1 -1 2 -2))) 
   "mel interval")

(* ?1 ?2 
   (?if (member (- ?2 ?1) '(1 -1 2 -2))) 
   "interval")

(* ?1 ?2 :parts '(1 3)
    (?if (member (- (m ?2) (m ?1)) '(-1 -2 1 2 -3 -4 3 4)))
    "mel int rule for parts 1 and 3")

; melodic
(* ?1 ?2 
   (?if (< (abs (- (m ?2) (m ?1))) 8))
   "max mel int rule")

(* ?1 ?2   
   (?if 
    (if (and (grace-note-p ?1) (grace-note-p ?2))
       (member (abs (- (m ?2) (m ?1))) '(0))
       (member (abs (- (m ?2) (m ?1))) '(1 2 5 7))))
   "grace int rule")

(* ?1 ?2  
   (?if (member (abs (- (m ?2) (m ?1))) '(1 2 5 7))) 
   "mel int rule")

(* ?1 ?2 :harmony
   (?if (let ((ints1 (m ?1 :data-access :harm-int))
              (ints2 (m ?2 :data-access :harm-int :complete? t)))
          (?incase ints2  (not (equal ints1 ints2)))))
   "no adjacent equal chord ints")

(* ?1 ?2 :harmony
   (?if (let ((ints1 (m ?1 :data-access :harm-int))
              (ints2 (m ?2 :data-access :harm-int :complete? t)))
          (?incase ints2  (not (equal ints1 ints2)))))
   "no adjacent equal chord ints")

(* ?1 ?2 :harmony  
   (?if (?incase (m ?2 :complete? t)
            (let* ((sop1 (m ?1 :data-access :max)) (sop2 (m ?2 :data-access :max))
                   (bas1 (m ?1 :data-access :min)) (bas2 (m ?2 :data-access :min)))
              (and (/= (mod12 sop1) (mod12 bas2)) 
                   (/= (mod12 sop2) (mod12 bas1))))))
   "no sop/bas mod12 cross-relation")

(* ?1 ?2 :harmony  
   (?if (let* ((p1 1) (p2 6)
               (m11 (m ?1 :parts p1)) (m12 (m ?2 :parts p1)) 
               (m21 (m ?1 :parts p2)) (m22 (m ?2 :parts p2)))
          (?incase (and m11 m12 m21 m22)
            (and (/= (mod12 m11) (mod12 m22)) 
                 (/= (mod12 m12) (mod12 m21))))))
   "no mod12 cross-relation in parts p1+p2")
  
(* ?1 ?2 :harmony 
   (?if (?incase (m ?2 :complete? t)
          (let* ((sop1 (m ?1 :data-access :max)) (sop2 (m ?2 :data-access :max))
                 (bas1 (m ?1 :data-access :min)) (bas2 (m ?2 :data-access :min))
                 (sopint (- sop2 sop1)) (basint (- bas2 bas1)))
            (?incase  (or (and (plusp sopint) (plusp basint))
                          (and (minusp sopint) (minusp basint)))
              (or (<= (abs sopint) 1) (<= (abs basint) 1))))))
   "no jumps in parallel sop-bass movements")

(* ?1 ?2 :harmony
   (?if (let ((int1 (first (m ?1 :data-access :int :complete? t)))
              (int2 (first (m ?2 :data-access :int :complete? t))))
          (?incase (and int1 int2)
              (?incase (= int1 7) (not (= int2 7))))))
   "no parallel fifths")

(* ?1 ?2 :harmony 
   (?if (let ((int1 (first (m ?1 :data-access :int :complete? t)))
              (int2 (first (m ?2 :data-access :int :complete? t))))
          (?incase (and int1 int2)
              (?incase (= int1 12) (not (= int2 12))))))
   "no parallel octaves")



(* ?1 ?2 :chord   
  (?if (let ((m1 (m ?1 :data-access :min)) (m2 (m ?2 :data-access :min)))
     (?incase (and m1 m2) (member (- m2 m1) '(0 5 6 4)))))
   "multipart bass int rule")

(* ?1 ?2 :chord 
   (?if (let ((m1 (m ?1 :data-access :max)) (m2 (m ?2 :data-access :max :complete? t)))
     (?incase (and m1 m2) (member (- m2 m1) (if (e ?2 "jump") '(8) '(8 -1))))))
   "multipart top int rule")

(* ?1 ?2 (?if (<= (abs (- (m ?2) (m ?1))) 23)) 
  "max interval")

(* ?1 ?2 (and (grace-note-p ?1) (not (grace-note-p ?2)))
   (?if (<= (abs (- (m ?2) (m ?1))) 13)) 
   "max interval for grace-normal")

(* ?1 ?2 :parts 1 
   (?if (not (member (abs (- (m ?2) (m ?1))) '(6))))
   "no tritone in the upper part")

(* ?1 ?2 
   (?if (<= (abs (- (m ?2) (m ?1))) 9))
   "melodic leaps smaller or equal than major sixth")

(* ?1 ?2 :parts 1 
   (?if (/= (m ?1) (m ?2)))
   "no repetitions in the upper part")



(* ?1 ?2  (e ?2 :fermata)
   (?if (<= (abs (- (m ?2) (m ?1))) 2))
   "the cadence must be approached with stepwise movement")


;; note: Laurson dissertation states: It is important to note that a
;; pattern can contain only one wild card at a time.

(* ?1 * ?2
   (?if (/= (mod12 (m ?1)) (mod12 (m ?2))))
   "mel duplicate rule")

(* ?1 * ?2 
  (?if (/= ?1 ?2))
   "no pitch-class dups")

(* ?1 * ?2  :harmony (m ?2 :complete? t)
   (?if 
    (not (equal (m ?1) (m ?2))))
   "no chord duplicates, note the 2-wildcard case")

(* ?1 ?2 ?3 (zerop (mod (1- (notenum ?1)) 3))
   (?if (eq-SC? '(3-5a 3-5b) (list (m ?1) (m ?2) (m ?3))))
   "set-classes of adjacent 3-note groups")

(* ?1 ?2 * ?3 ?4 :pm-overlap 1
   (?if (/= (mod12 (- ?2 ?1)) (mod12 (- ?4 ?3)))) 
   "no (modulo 12) interval duplicates")

(* ?1 ?2 ?3 ?4 :chord 
   (?if (let ((m1 (m ?1 :data-access :max)) (m2 (m ?2 :data-access :max)) 
              (m3 (m ?3 :data-access :max)) (m4 (m ?4 :data-access :max :complete? t)))
          (?incase (and m1 m2 m3 m4)
              (member (sc-name (list m1 m2 m3 m4)) '#.(ccl::all-subs '(6-Z47B))))))
   "multipart top int rule")

(* ?1 ?2 ?3 ?4 :chord 
   (?if (let ((m1 (m ?1 :data-access :min)) (m2 (m ?2 :data-access :min)) 
              (m3 (m ?3 :data-access :min)) (m4 (m ?4 :data-access :min :complete? t)))
          (?incase (and m1 m2 m3 m4)
              (member (sc-name (list m1 m2 m3 m4)) '#.(ccl::all-subs '(6-Z47B))))))
   "multipart bottom int rule")

(* ?1 ?2 ?3  
   (?if (not (member (sc-name (list (m ?1)(m ?2)(m ?3))) '(3-10 3-11a 3-11b 3-12)))) 
   "no triads at all")

(* ?1 ?2 ?3 ?4 
   (?if (eq-sc? '(4-1 4-3 4-6 4-7 4-8 4-9 4-10 4-23) (m ?1)(m ?2)(m ?3)(m ?4))) 
   "scs")

(* ?1 ?2 ?3 
   (?if (let ((int1 (- (m ?2) (m ?1)))
              (int2 (- (m ?3) (m ?2))))
          (?incase (>= (abs int1) 6)
            (and (< (abs int2) 3)
                 (not (= (signum int1) (signum int2)))))))
   "if the melody leaps more thaa augmented fourth, balance with stepwise contrary motion")

;; index rules
(i1 i2 i4 i6 
  (?if (eq-SC? '(4-1) i1 i2 i4 i6)) 
  "index rule")

(i4
 (?if (let ((subset (pw::posn-match (pwgl-value :chord) l)))
        (sym-chord? subset) ))
 "symmetric chord") 

(i1 i2 i11 i12 
    (?if (= (+ (mod12 (- i2 i1)) (mod12 (- i12 i11))) 12)) 
    "complement int.pairs (indexes 1-2/11-12)")

(i3 i4 i9 i10 
    (?if (= (+ (mod12 (- i4 i3)) (mod12 (- i10 i9))) 12)) 
    "complement int.pairs (index 3-4/9-10)")

(i5 i6 i7 i8 
    (?if (= (+  (mod12 (- i6 i5)) (mod12 (- i8 i7))) 12)) 
    "complement int.pairs (index 5-6/7-8)")

(i1 i2 i3 i4 i5 i6
    (?if (eq-set  
          '(|6-1| |6-8| |6-14A| |6-14B| |6-20| |6-32| )    
          i1 i2 i3 i4 i5 i6)) 
    "6-card scs without tritones = tritone in the middle") 

(i7 i8 i9 i10 i11 i12
    (?if (eq-set 
          '(|6-1| |6-8| |6-14A| |6-14B| |6-20| |6-32| )       
          i7 i8 i9 i10 i11 i12)) 
    "6-card scs w/o tritones = tritone in the middle")
(i1 
 (?if 
  (setf (staff (read-key i1 :part)) (make-instance 'piano-staff)))
 "piano-staff") 

;;; hightlights:
;;; (1) :or
;;; (2) ?1 * ?2
;;; (3) reading the plist of an expression

;***********************************************************************************************
;rules about tonality and harmonic progression
;***********************************************************************************************

(* ?1
   (?if (member (mod12 (m ?1)) '(0 2 4 5 7 9 11)))
   "Scale of C-major")

(* ?1 :harmony
   (?if (?incase (m ?1 :complete? t)
            (let ((sop (m ?1 :data-access :max :object t))
                  (bass (m ?1 :data-access :min)))
              (let ((degree (e sop :group)))
                (case (getf (plist degree) :degree) 
                  ;; using the keyword like this is for convenience only,
                  ;; we could also compare the print-symbol of the expressions
                  (:I (member (mod bass 12) '(0 4 7)))
                  (:IV (member (mod bass 12) '(5 9 0)))
                  (:V (member (mod bass 12) '(7 11 2))))))))
   "Harmonic pitches. Degrees are written in the plist of the expressions (can be accessed with Shift+I)")

;***********************************************************************************************
; rules about the alberti bass
;***********************************************************************************************

(:or
 (?1 * ?2 :beat :parts '((1 "Left-hand"))
     (?if
      (let ((ints1 (m ?1 :data-access :int :complete? t))
            (ints2 (m ?2 :data-access :int :complete? t)))
        (?incase (and ints1 ints2)
            (every #'(lambda(x y) (and (= (signum x) (signum y)) (<= 0 (abs (- x y)) 1))) ints1 ints2))))
     "mimic the arpeggiated; max deviation = 1")

 (?1 * ?2 :beat :parts '((1 "Left-hand"))
     (?if
      (let ((ints1 (m ?1 :data-access :int :complete? t))
            (ints2 (m ?2 :data-access :int :complete? t)))
        (?incase (and ints1 ints2)
            (every #'(lambda(x y) (and (= (signum x) (signum y)) (<= 0 (abs (- x y)) 2))) ints1 ints2))))
     "mimic the arpeggiated; max deviation = 2")
"mimic the arpeggiated figure established in the first beat")

(* ?1 :beat :parts '((1 "Left-hand"))
   (?if
    (let ((ints (m ?1 :data-access :int :complete? t)))
      (?incase ints (not (apply #'= (mapcar #'abs ints))))))
   "No tremolando")

(* ?1 ?2 :beat :parts '((1 2))
   (?if (let ((m1 (first (m ?1)))
              (m2 (first (m ?2))))
          (?incase (and m1 m2) (<= 0 (abs (- m2 m1)) 4))))
   "Small intervals (<= fifth) between the first notes of consecutive figures")


 ("favor ascending intervals"
  ((* ?1 ?2  (?if (let ((iv (- (m ?2) (m ?1))))
                    (if (plusp iv) 1 0))))))

 ("favor repeats"
  ((* ?1 ?2 (?if (let ((iv (abs (- (m ?1) (m ?2)))))
                   (case iv
                     (0 (random 100))
                     (t (random 10))))))))

 ("favor perfect fourths"
  ((* ?1 ?2 (?if (let ((iv (abs (- (m ?1) (m ?2)))))
                   (case iv
                     (5 1)
                     (t 0)))))))

 ("favor small intervals"
  ((* ?1 ?2 (?if (let ((iv (abs (- (m ?1) (m ?2)))))
                   (if (zerop iv)
                       -100
                     (- iv)))))))
 
 ("favor big intervals"
  ((* ?1 ?2 (?if (let ((iv (abs (- (m ?1) (m ?2)))))
                   iv)))))

 ("favor scale-wise motion"
  ((* ?1 ?2 (?if (let ((iv (abs (- (m ?2) (m ?1)))))
                   (if (<= 1 iv 2)
                       100
                     0))))
   (* ?1 ?2 ?3 (?if (let ((iv1 (- (m ?2) (m ?1)))
                          (iv2 (- (m ?3) (m ?2))))
                      (if (and (= (signum iv1) (signum iv2))
                               (and (<= 1 (abs iv1) 2) 
                                    (<= 1 (abs iv2) 2)))
                          100
                        0)))))))



(* ?1 (e ?1 "6/2")
   (?if (let* ((pos (e ?1 "6/2" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(1 0)))
          (eq-subcontour? ref-cont (contour midis))))
   "6/2")

(* ?1 (e ?1 "6/3")
   (?if (let* ((pos (e ?1 "6/3" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(2 0 1)))
          (eq-subcontour? ref-cont (contour midis))))
   "6/3")

(* ?1 (e ?1 "6/4")
   (?if (let* ((pos (e ?1 "6/4" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(3 0 2 1)))
          (eq-subcontour? ref-cont (contour midis))))
   "6/4")

(* ?1 (e ?1 "6/5")
   (?if (let* ((pos (e ?1 "6/5" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(4 0 3 1 2)))
          (eq-subcontour? ref-cont (contour midis))))
   "6/5")

(* ?1 (e ?1 "6/6")
   (?if (let* ((pos (e ?1 "6/6" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(5 0 4 1 3 2)))
          (eq-subcontour? ref-cont (contour midis))))
   "6/6")

(* ?1 (e ?1 "6/7")
   (?if (let* ((pos (e ?1 "6/7" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(6 0 5 1 4 2 3)))
          (eq-subcontour? ref-cont (contour midis))))
   "6/7")

(* ?1 (e ?1 "7/2")
   (?if (let* ((pos (e ?1 "7/2" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(0 1)))
          (eq-subcontour? ref-cont (contour midis))))
   "7/2")

(* ?1 (e ?1 "7/3")
   (?if (let* ((pos (e ?1 "7/3" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(1 2 0)))
          (eq-subcontour? ref-cont (contour midis))))
   "7/3")

(* ?1 (e ?1 "7/4")
   (?if (let* ((pos (e  ?1 "7/4" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(1 2 0 3)))
          (eq-subcontour? ref-cont (contour midis))))
   "7/4")

(* ?1 (e ?1 "7/5")
   (?if (let* ((pos (e  ?1 "7/5" :pos))
               (midis (m ?1 :l  pos))
               (ref-cont '(2 3 1 4 0)))
          (eq-subcontour? ref-cont (contour midis))))
   "7/5") 


;;; very domain specific rules


;========================================================
;; assumes part order: 1 sop 2 rest 3 bass 4 midv
;========================================================
; melodic 
;ints
;R1
(* ?1 ?2 :parts '(1 3) 
   (?if (<= (abs (-  (m ?2) (m ?1))) 9)) "max 9 mel int")

;R2
(* ?1 ?2 ?3  :parts '(1 3) 
   (?if (let ((disallowed-ints '((1 1) (-1 -1) ;; same dir 1s
                                 (5 2)(-5 -2)(2 5)(-2 -5)  
                                 (-2 7)(2 -7)(-7 2)(7 -2)(-5 7)(5 -7)(7 -5)(-7 5)))) ;; 3-9 same dir 5 + 2 
          (not (member (list (- (m ?2) (m ?1)) (- (m ?3) (m ?2))) disallowed-ints :test #'equal)))) 
  "disallowed-2ints") 

;R3
(* ?1 ?2 ?3  :parts '(1 3) 
   (?if (not (eq-sc? '(3-11a 3-11b) (m ?1) (m ?2) (m ?3)))) 
   "disallowed 3card mel sets")

;R4
(* ?1 ?2 ?3 ?4  :parts '(1 3) 
   (?if (eq-sc? 
         '(4-27a 4-21 4-24 4-27b 4-19b 4-z15a 4-3 4-9 4-23 4-13b 4-11b 4-16a 4-14b 4-4a 4-12a 4-18a 4-5b 4-4b 4-8 4-16b
          4-14a 4-10 4-z15b 4-6 4-5a 4-11a 4-12b 4-1 4-7 4-2a 4-2b 4-13a)
         (m ?1) (m ?2) (m ?3) (m ?4))) 
   "allowed 4card mel sets")

;R5
(* ?1 ?2 ?3 ?4 ?5 :parts '(1 3) 
   (?if (eq-sc? 
           '(5-28b 5-13b 5-14a 5-33 5-26a 5-28a 5-z38b 5-9a 5-29a 5-z37 5-21b 5-30b 5-7a 5-16b 5-10a 5-23b 5-6a 5-7b 5-23a
             5-29b 5-4b 5-31b 5-2a 5-20b 5-z18a 5-4a 5-16a 5-z38a 5-9b 5-5b 5-6b 5-z12 5-20a 5-z18b 5-10b 5-14b 5-z36a 5-5a
             5-26b 5-1 5-2b 5-3b 5-3a 5-8)
           (m ?1) (m ?2) (m ?3) (m ?4) (m ?5))) 
  "allowed 5card mel sets")

;============================
;              repetion
;R6
(* ?1 :parts '(1 3) 
   (?if (let ((size 5)) (setp (m ?1 :rl size) :key #'mod12))) 
   "no pc mel repet") 

;R7
(* ?1 ?2 :parts '(1 3) 
   (?if (let ((size 7))
          (unique-cell2?  (m ?2) (m ?1) (rest (m ?2 :rl (1+ size))))))
   "no 2 cell mel repet")

;R8
(* ?1 ?2 ?3 :parts '(1 3) 
   (?if (let ((size 10)) 
          (unique-cell3?  (m ?3) (m ?2) (m ?1) (rest (m ?3 :rl (1+ size)))))) 
   "no 3 cell mel repet")

;R9
(* ?1 :parts '(1 3) 
    (?if (setp (m ?1 :rl t :l-filter #'(lambda (n) (>= (durt n) 1.0))))) 
    "no long note (>= 1 second) dups") 

;============================
;                  vlead
;R10
(* ?1 ?2 ?3 :harmony   :parts 1 
   (?if (let* ((sop1 (m ?1 :parts 1)) (sop2 (m ?2 :parts 1)) (sop3 (m ?3 :parts 1))
               (midv1 (m ?1 :parts 4)) (midv2 (m ?2 :parts 4)) (midv3 (m ?3 :parts 4)))
          (not (= (-  sop1 midv1) (- sop2 midv2) (- sop3 midv3)))))
   "no exact parallel movements between sop and midv")

;R11
(* ?1 ?2 ?3 :harmony   :parts 3
   (?if (let* ((mid1 (m ?1 :parts 4)) (mid2 (m ?2 :parts 4)) (mid3 (m ?3 :parts 4))
               (bass1 (m ?1 :parts 3)) (bass2 (m ?2 :parts 3)) (bass3 (m ?3 :parts 3)))
          (not (= (- mid1 bass1) (- mid2 bass2) (- mid3 bass3)))))
   "no exact parallel movements between midv and bass")

;R12
(* ?1 ?2 :harmony    :parts 1
  (?if (let*((p1 1) (p2 3)
             (m11 (m ?1 :parts p1)) (m12 (m ?2 :parts p1)) 
             (m21 (m ?1 :parts p2)) (m22 (m ?2 :parts p2)))
      (?incase (and m11 m12 m21 m22)
        (and (/= (mod12 m11) (mod12 m22)) 
             (/= (mod12 m12) (mod12 m21))))))
   "no mod12 cross-relation in sop/bass parts")

;R13
(* ?1 ?2 :harmony  :parts 1
   (?if (let* ((max-jump-int 1) 
               (sop1 (m ?1 :parts 1)) (sop2 (m ?2 :parts 1))       
               (bass1 (m ?1 :parts 3)) (bass2 (m ?2 :parts 3)) 
               (sop-int (- sop1 sop2)) (bass-int (- bass1 bass2)))
          (?incase (or (and (plusp bass-int) (plusp sop-int))     
                  (and (minusp bass-int) (minusp sop-int)))  
            (not (> (min (abs bass-int) (abs sop-int))  max-jump-int)))))
   "no bass-soprano jumps in same direction")

;R14
(* ?1 ?2 ?3 :harmony  :parts 1
   (?if (let* ((sop1 (m ?1 :parts 1)) (sop2 (m ?2 :parts 1)) (sop3 (m ?3 :parts 1))
               (bass1 (m ?1 :parts 3)) (bass2 (m ?2 :parts 3)) (bass3 (m ?3 :parts 3))
               (sop-int1 (- sop2 sop1)) (sop-int2 (- sop3 sop2))
               (bass-int1 (- bass2 bass1)) (bass-int2 (- bass3 bass2)))
          (not (parallel-movements? (list sop-int1 bass-int1) (list sop-int2 bass-int2)))))
   "no-3chord-parallel-movements")

;==============================
;   chords
;R15
(* ?1 :harmony  :parts 1
   (?if (let* ((sop (m ?1 :parts 1)) (mid (m ?1 :parts 4)) (bass (m ?1 :parts 3))
               (midis (list sop mid bass)))
           (and (setp midis :key #'mod12) 
                (not (eq-sc? '(3-11a 3-11b) midis)))))
   "allowed sop-midv-bass sets")

;===================================
; harmonic rules
(* ?1 :harmony
   (?if (setp (m ?1) :key #'mod12)) 
   "no unis nor octaves")

(* ?1 :harmony  :parts '(1 2)
   (?if (let* ((midis (sort< (m ?1)))
               (ints (m ?1 :data-access :harm-int)))
          (and (or (every #'(lambda (n) (member n '(1 3 7))) ints) 
                   (every #'(lambda (n) (member n '(1 3))) ints)
                   (every #'(lambda (n) (member n '(5 6))) ints))
               (not (>max-cnt-int? midis '((1 1))))
               (proper-low-reg-ch? midis)))) 
   "harm ints")

#|
; for 'unis' case: 
; replace "no unis nor octaves" and "harm ints" with following rules:

(* ?1 :harmony
   (?if (not (octaves? (m ?1))))
   "no octaves (unis allowed)")

(* ?1 :harmony :parts '(1 2)
   (?if (let* ((midis (sort< (remove-duplicates (m ?1))))
               (ints (pw::x->dx midis)))
                 (and (or (every #'(lambda (n) (member n '(1 3 7))) ints) 
                          (every #'(lambda (n) (member n '(1 3))) ints)
                          (every #'(lambda (n) (member n '(5 6))) ints))
                      (not (>max-cnt-int? midis '((1 1))))
                      (proper-low-reg-ch? midis))))
   "harm ints (unis allowed)")
|#
;====================================
; voice cross rules
(* ?1 :harmony :parts 1
  (?if (let* ((sop (m ?1 :parts 1)) (bas (m ?1 :parts 3))
              (chshigh (m ?1 :parts 2 :data-access :max)) (chslow (m ?1 :parts 2 :data-access :min)))
         (> sop chshigh chslow bas)))
 "chs betw sop and bass, sop highest")

(* ?1 :harmony :parts 2
  (?if (let* ((bas (m ?1 :parts 3)) (chsmin (m ?1 :parts 2 :data-access :min)))
         (> chsmin bas)))
 "chs higher than bass")

(* ?1 :harmony :parts 3
  (?if (let* ((bass (m ?1 :parts 3)) (mid (m ?1 :parts 4)))
         (<= bass mid)))
 "midv higher than bass")


#|
; HSG rules still missing
"find-chs?"
;----------- category
;R17
"not 3 adjacent chs with a single cat"
;----------- mel reduction (arc-lens, skyline)
; mel-red  tolerance 0 because partial solution !

;R18
"no partial arc len dups inside window"
;R19
"no skyline dups inside window and max-skyline-jump 4"
|# 
