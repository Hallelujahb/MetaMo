
(: AppraisalComonad Type)
(: appraisalComonad (-> Symbol Symbol AppraisalComonad))

(: DecisionMonad Type)
(: decisionMonad (-> Symbol Symbol Symbol DecisionMonad))

(: DecisionResult Type)
(: decisionResult (-> ActionType Expression DecisionResult))

(: TranslationFunctor Type)
(: translationFunctor (-> Expression Expression TranslationFunctor))

(= (appraisalExtractSymbol (appraisalComonad $extractFn $appraiseFn))
    $extractFn
)

(= (appraisalMapSymbol (appraisalComonad $extractFn $appraiseFn))
    $appraiseFn
)

(= (appraisalAppraiseSymbol (appraisalComonad $extractFn $appraiseFn))
    $appraiseFn
)

(= (decisionUnitSymbol (decisionMonad $unitFn $decideFn $scoreFn))
    $unitFn
)

(= (decisionMapSymbol (decisionMonad $unitFn $decideFn $scoreFn))
    $decideFn
)

(= (decisionDecideSymbol (decisionMonad $unitFn $decideFn $scoreFn))
    $decideFn
)

(= (decisionScoreSymbol (decisionMonad $unitFn $decideFn $scoreFn))
    $scoreFn
)

(= (decisionAction (decisionResult $action $deltaG))
    $action
)

(= (decisionDeltaG (decisionResult $action $deltaG))
    $deltaG
)

(= (extract $appraisal $state)
    (extractWith $appraisal $state)
)

(= (extractWith (appraisalComonad $extractFn $appraiseFn) $state)
    (eval ($extractFn $state))
)

(= (appraise $appraisal $state $stimulus)
    (appraiseWith $appraisal $state $stimulus)
)

(= (appraiseWith (appraisalComonad $extractFn $appraiseFn) $state $stimulus)
    (eval ($appraiseFn $state $stimulus))
)

(= (unit $decision $state)
    (unitWith $decision $state)
)

(= (unitWith (decisionMonad $unitFn $decideFn $scoreFn) $state)
    (eval ($unitFn $state))
)

(= (decide $decision $state $candidates)
    (decideWith $decision $state $candidates)
)

(= (decideWith (decisionMonad $unitFn $decideFn $scoreFn) $state $candidates)
    (eval ($decideFn $state $candidates))
)

(= (scoreCandidate $decision $state $candidate)
    (scoreCandidateWith $decision $state $candidate)
)

(= (scoreCandidateWith (decisionMonad $unitFn $decideFn $scoreFn) $state $candidate)
    (eval ($scoreFn $state $candidate))
)

(= (translationGoalMatrix (translationFunctor $goalTranslation $modTranslation))
    $goalTranslation
)

(= (translationModulatorMatrix (translationFunctor $goalTranslation $modTranslation))
    $modTranslation
)

(= (validateTranslationFunctor (translationFunctor $goalTranslation $modTranslation))
    (matrixIsSquare $goalTranslation)
)

(= (simulatePeer (translationFunctor $goalTranslation $modTranslation) (motivation $goals $modulators))
    (motivation
        (clipVector (matrixVectorDot $goalTranslation $goals) 0.0 1.0)
        (clipVector (matrixVectorDot $modTranslation $modulators) 0.0 1.0)
    )
)
