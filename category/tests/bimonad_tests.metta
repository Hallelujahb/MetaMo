!(import! &self ../../core/helper)
!(import! &self "../../core/helpers.py")
!(import! &self ../bimonad)

!(import! &self ../../core/state)
!(import! &self ../../core/config)
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

(= (identityDamping $state $deltaG)
    $deltaG
)

(= (identityBoundary $state)
    $state
)

(= (identityProject $state)
    $state
)

(= (alwaysContractive $bimonad $state $referenceState $stimulus $candidates)
    True
)

(= (alwaysSafe $state)
    True
)

(= (richAppraise (motivation $goals ($m1 $m2 $m3 $m4 $m5 $m6)) (stimulus $novelty $conduciveness $risk $effort))
    (motivation
        $goals
        (clipVector (vectorAdd ($m1 $m2 $m3 $m4 $m5 $m6) ($novelty $conduciveness 0.0 0.0 0.0 0.0)) 0.0 1.0)
    )
)

(= (consensusState)
    (motivation
        (0.25 0.75 0.5 0.5 0.5 0.5 0.5 0.5)
        (0.125 0.25 0.375 0.5 0.625 0.75)
    )
)

(= (candidateSet)
    (
        (action act1 (0.25 0.25 0.0 0.0 0.0 0.0 0.0 0.0) 0.25 (0.125 0.125 0.0 0.0 0.0 0.0 0.0 0.0))
        (action act2 (0.5 0.75 0.0 0.0 0.0 0.0 0.0 0.0) 0.25 (-0.125 0.125 0.0 0.0 0.0 0.0 0.0 0.0))
    )
)

!(test
    (candidateConsensusScore 4.0 2.0)
    2.5
)

!(test
    (decisionContext
        (metaMoPseudoBimonad
            (appraisalComonad identityExtract simpleAppraise)
            (decisionMonad identityUnit constantDecide simpleScore)
            identityDamping
            identityBoundary
            identityProject
            alwaysContractive
            alwaysSafe
        )
        (motivation (0.25 0.75) (0.125 0.25))
        (stimulus 0.125 0.125 0.0 0.0)
    )
    (motivation (0.25 0.75) (0.25 0.375))
)

!(test
    (transitionState
        (computeTransition
            (metaMoPseudoBimonad
                (appraisalComonad identityExtract simpleAppraise)
                (decisionMonad identityUnit constantDecide simpleScore)
                identityDamping
                identityBoundary
                identityProject
                alwaysContractive
                alwaysSafe
            )
            (motivation (0.25 0.75) (0.125 0.25))
            (stimulus 0.125 0.125 0.0 0.0)
            ()
        )
    )
    (motivation (0.375 0.625) (0.25 0.375))
)

!(test
    (applyConservativeFallback
        (motivation (0.25 0.75) (0.125 0.25))
        (motivation (0.75 0.25) (0.625 0.75))
    )
    (motivation (0.5 0.5) (0.375 0.5))
)

!(test
    (consensusAction
        (metaMoPseudoBimonad
            (appraisalComonad identityExtract richAppraise)
            (decisionMonad identityUnit constantDecide simpleScore)
            identityDamping
            identityBoundary
            identityProject
            alwaysContractive
            alwaysSafe
        )
        (consensusState)
        (consensusState)
        (stimulus 0.125 0.125 0.0 0.0)
        (candidateSet)
    )
    (action act2 (0.5 0.75 0.0 0.0 0.0 0.0 0.0 0.0) 0.25 (-0.125 0.125 0.0 0.0 0.0 0.0 0.0 0.0))
)

!(test
    (transitionState
        (consensusTransitionDefault
            (metaMoPseudoBimonad
                (appraisalComonad identityExtract richAppraise)
                (decisionMonad identityUnit constantDecide simpleScore)
                identityDamping
                identityBoundary
                identityProject
                alwaysContractive
                alwaysSafe
            )
            (consensusState)
            (consensusState)
            (stimulus 0.125 0.125 0.0 0.0)
            (candidateSet)
        )
    )
    (motivation
        (0.125 0.875 0.5 0.5 0.5 0.5 0.5 0.5)
        (0.25 0.375 0.375 0.5 0.625 0.75)
    )
)
