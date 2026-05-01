
(: boundOpenPsiModulator (-> Number Number))

(= (boundOpenPsiModulator $value)
    (eval (sigmoidNum (* 4.0 (- $value 0.5))))
)

(= (openPsiArousalFeedback $arousal)
    (eval (sigmoidNum (* (- $arousal 0.5) 5.0)))
)

(= (openPsiTransScale $gTrans)
    (eval (expNum (- $gTrans 0.5)))
)

(= (openPsiIndScale $gInd)
    (eval (expNum (- $gInd 0.5)))
)

(= (openPsiBenignNovelty $novelty $risk)
    (* $novelty (- 1.0 $risk))
)

(= (openPsiDemandingContext $effort $risk)
    (/ (+ $effort $risk) 2.0)
)

(= (openPsiDeltaValence $conduciveness $benignNovelty $risk $effort)
    (+ (+ (* 0.75 $conduciveness) (* 0.25 $benignNovelty))
       (* -1 (+ (* 0.55 $risk) (* 0.15 $effort))))
)

(= (openPsiDeltaArousal $novelty $arousalFeedback $risk $effort)
    (+ (+ (* $novelty (+ 1.0 (* 0.5 $arousalFeedback))) (* 0.15 $risk))
       (* -1 (* 0.35 $effort)))
)

(= (openPsiDeltaApproach $benignNovelty $conduciveness $risk)
    (+ (+ (* 0.65 $benignNovelty) (* 0.35 $conduciveness))
       (* -1 (* 0.75 $risk)))
)

(= (openPsiDeltaResolution $conduciveness $effort $risk)
    (+ (+ (* 0.55 $conduciveness) (* 0.35 $effort))
       (* 0.20 $risk))
)

(= (openPsiDeltaThreshold $risk $demandingContext $conduciveness)
    (+ (+ (* 0.70 $risk) (* 0.25 $demandingContext))
       (* -1 (* 0.15 $conduciveness)))
)

(= (openPsiDeltaSecuring $risk $effort $benignNovelty $conduciveness)
    (+ (+ (* 0.80 $risk) (* 0.20 $effort))
       (* -1 (+ (* 0.30 $benignNovelty) (* 0.10 $conduciveness))))
)

(= (openPsiNextValence $valence $deltaValence)
    (boundOpenPsiModulator (+ $valence $deltaValence))
)

(= (openPsiNextArousal $arousal $deltaArousal $transScale)
    (boundOpenPsiModulator (+ $arousal (* $deltaArousal $transScale)))
)

(= (openPsiNextApproach $approach $deltaApproach $transScale)
    (boundOpenPsiModulator (+ $approach (* $deltaApproach $transScale)))
)

(= (openPsiNextResolution $resolution $deltaResolution)
    (boundOpenPsiModulator (+ $resolution $deltaResolution))
)

(= (openPsiNextThreshold $threshold $deltaThreshold $indScale)
    (boundOpenPsiModulator (+ $threshold (* $deltaThreshold $indScale)))
)

(= (openPsiNextSecuring $securing $deltaSecuring $indScale)
    (boundOpenPsiModulator (+ $securing (* $deltaSecuring $indScale)))
)
