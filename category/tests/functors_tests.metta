!(import! &self ../../core/helper)
!(import! &self ../../core/state)
!(import! &self "../../core/helpers.py")
!(import! &self ../functors)


(= (identityExtract $state)
    $state
)

(= (simpleAppraise (motivation ($g1 $g2) ($m1 $m2)) (stimulus $novelty $conduciveness $risk $effort))
    (motivation ($g1 $g2) (clipVector (vectorAdd ($m1 $m2) ($novelty $conduciveness)) 0.0 1.0))
)

(= (identityUnit $state)
    $state
)

(= (constantDecide $state $candidates)
    (decisionResult (action act1 (0.25 0.75) 0.25 (0.125 -0.125)) (0.125 -0.125))
)

(= (simpleScore $state (action $actionId $goalCorrelations $riskEstimate $deltaG))
    (+ (sum $goalCorrelations) (sum (motivationGoals $state)))
)

!(test
    (extract
        (appraisalComonad identityExtract simpleAppraise)
        (motivation (0.25 0.75) (0.125 0.25))
    )
    (motivation (0.25 0.75) (0.125 0.25))
)

!(test
    (appraise
        (appraisalComonad identityExtract simpleAppraise)
        (motivation (0.25 0.75) (0.125 0.25))
        (stimulus 0.125 0.125 0.0 0.0)
    )
    (motivation (0.25 0.75) (0.25 0.375))
)

!(test
    (decisionAction
        (decide
            (decisionMonad identityUnit constantDecide simpleScore)
            (motivation (0.25 0.75) (0.125 0.25))
            ()
        )
    )
    (action act1 (0.25 0.75) 0.25 (0.125 -0.125))
)


!(test
    (validateTranslationFunctor
        (translationFunctor
            ((1.0 0.0) (0.0 1.0))
            ((1.0 0.0) (0.0 1.0))
        )
    )
    True
)

!(test
    (simulatePeer
        (translationFunctor
            ((1.0 0.0) (0.0 1.0))
            ((1.0 0.0) (0.0 1.0))
        )
        (motivation (0.25 0.75) (0.125 0.25))
    )
    (motivation (0.25 0.75) (0.125 0.25))
)
