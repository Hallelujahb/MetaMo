
(: TransitionResult Type)
(: transitionResult (-> ActionType MotivationalState TransitionResult))

(: BestCandidateResult Type)
(: bestCandidateResult (-> Number ActionType BestCandidateResult))

(: MetaMoPseudoBimonad Type)
(: metaMoPseudoBimonad
   (-> AppraisalComonad DecisionMonad Symbol Symbol Symbol Symbol Symbol MetaMoPseudoBimonad))

(= (transitionAction (transitionResult $action $nextState))
    $action
)

(= (transitionState (transitionResult $action $nextState))
    $nextState
)

(= (bestCandidateScore (bestCandidateResult $score $action))
    $score
)

(= (bestCandidateAction (bestCandidateResult $score $action))
    $action
)

(= (bimonadAppraisal (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn))
    $appraisal
)

(= (bimonadDecision (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn))
    $decision
)

(= (bimonadDampingSymbol (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn))
    $dampingFn
)

(= (bimonadBoundarySymbol (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn))
    $boundaryFn
)

(= (bimonadProjectSymbol (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn))
    $projectFn
)

(= (bimonadContractiveSymbol (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn))
    $contractiveFn
)

(= (bimonadSafeRegionSymbol (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn))
    $safeFn
)

;; decisionContext
;; Build the post-appraisal state that the decision monad should score.
(= (decisionContext
        (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn)
        $state
        $stimulus
   )
    (eval ($boundaryFn (appraise $appraisal $state $stimulus)))
)

;; stateFromDelta
;; Apply a proposed goal update inside the same stabilization path used by the main transition.
(= (stateFromDelta
        (metaMoPseudoBimonad $appraisal $decision $dampingFn $boundaryFn $projectFn $contractiveFn $safeFn)
        $decisionState
        $proposedDeltaG
   )
    (let* (
        ($dampedDeltaG (eval ($dampingFn $decisionState $proposedDeltaG)))
        ($nextGoals (eval (clipVector (vectorAdd (motivationGoals $decisionState) $dampedDeltaG) 0.0 1.0)))
        ($nextState (motivation $nextGoals (motivationModulators $decisionState)))
    )
        (eval ($projectFn $nextState))
    )
)

;; computeTransition
;; Compute one appraisal/decision transition before runtime validation.
(= (computeTransition $bimonad $state $stimulus $candidates)
    (let* (
        ($decisionState (decisionContext $bimonad $state $stimulus))
        ($decisionResult (decide (bimonadDecision $bimonad) $decisionState $candidates))
        ($action (decisionAction $decisionResult))
        ($nextState (stateFromDelta $bimonad $decisionState (decisionDeltaG $decisionResult)))
    )
        (transitionResult $action $nextState)
    )
)

;; localReferenceState
;; Build a nearby state to probe local contractivity without depending on another subsystem.
(= (localReferenceState $state $nextState)
    (let* (
        ($goalProbe (probeVector (listDifference (motivationGoals $nextState) (motivationGoals $state)) 0.01 1e-6))
        ($modProbe (probeVector (listDifference (motivationModulators $nextState) (motivationModulators $state)) 0.01 1e-6))
        ($probeGoals (clipVector (vectorAdd (motivationGoals $state) $goalProbe) 0.0 1.0))
        ($probeMods (clipVector (vectorAdd (motivationModulators $state) $modProbe) 0.0 1.0))
    )
        (motivation $probeGoals $probeMods)
    )
)

;; applyConservativeFallback
;; Shrink the transition toward the current state when runtime checks fail.
(= (applyConservativeFallback $currentState $nextState)
    (motivation
        (eval (clipVector (averageArrays (motivationGoals $currentState) (motivationGoals $nextState)) 0.0 1.0))
        (eval (clipVector (averageArrays (motivationModulators $currentState) (motivationModulators $nextState)) 0.0 1.0))
    )
)

(= (candidateConsensusScore $scoreA $scoreB)
    (- (/ (+ $scoreA $scoreB) 2.0)
       (* 0.25 (absNumber (- $scoreA $scoreB))))
)

(= (candidateConsensusValue $bimonad $context1 $context2 $candidate)
    (candidateConsensusScore
        (eval (scoreCandidate (bimonadDecision $bimonad) $context1 $candidate))
        (eval (scoreCandidate (bimonadDecision $bimonad) $context2 $candidate))
    )
)

(= (bestCandidateLoop $context1 $context2 $currentBest $currentScore $remaining $bimonad)
    (if (== $remaining ())
        (bestCandidateResult $currentScore $currentBest)
        (let* (
            (($head $rest) (decons $remaining))
            ($headScore (candidateConsensusValue $bimonad $context1 $context2 $head))
        )
            (if (> $headScore $currentScore)
                (bestCandidateLoop $context1 $context2 $head $headScore $rest $bimonad)
                (bestCandidateLoop $context1 $context2 $currentBest $currentScore $rest $bimonad)
            )
        )
    )
)

(= (bestCandidate $context1 $context2 $candidates $bimonad)
    (let* (
        (($head $rest) (decons $candidates))
        ($headScore (candidateConsensusValue $bimonad $context1 $context2 $head))
    )
        (bestCandidateLoop $context1 $context2 $head $headScore $rest $bimonad)
    )
)

;; consensusAction
;; Select a shared action by combining the two subsystem evaluations over the same candidate set.
(= (consensusAction $bimonad $stateA $stateB $stimulus $candidates)
    (let* (
        ($contextA (decisionContext $bimonad $stateA $stimulus))
        ($contextB (decisionContext $bimonad $stateB $stimulus))
        ($bestResult (bestCandidate $contextA $contextB $candidates $bimonad))
    )
        (bestCandidateAction $bestResult)
    )
)


(= (consensusTargetState $bimonad $stateA $stateB $stimulus $action $coherenceCorrection)
    (let* (
        ($contextA (decisionContext $bimonad $stateA $stimulus))
        ($contextB (decisionContext $bimonad $stateB $stimulus))
        ($targetA (stateFromDelta $bimonad $contextA (actionDeltaG $action)))
        ($targetB (stateFromDelta $bimonad $contextB (actionDeltaG $action)))
    )
        (parallelMerge $targetA $targetB $coherenceCorrection)
    )
)

;; consensusTransition
;; Build a coupled consensus action and consensus target state from the same shared candidate set.
(= (consensusTransition $bimonad $stateA $stateB $stimulus $candidates $coherenceCorrection)
    (let* (
        ($action (consensusAction $bimonad $stateA $stateB $stimulus $candidates))
        ($targetState (consensusTargetState $bimonad $stateA $stateB $stimulus $action $coherenceCorrection))
    )
        (transitionResult $action $targetState)
    )
)

(= (consensusTransitionDefault $bimonad $stateA $stateB $stimulus $candidates)
    (consensusTransition $bimonad $stateA $stateB $stimulus $candidates 0.05)
)

;; parallelMerge
;; Combine two proposed states into one by merging their goals and modulators separately.
(= (parallelMerge $stateA $stateB $coherenceCorrection)
    (motivation
        (eval (clipVector
            (parallelMergeGoals (motivationGoals $stateA) (motivationGoals $stateB) $coherenceCorrection)
            0.0
            1.0
        ))
        (eval (clipVector
            (parallelMergeModulators
                (motivationModulators $stateA)
                (motivationModulators $stateB)
                (motivationGoals $stateA)
                (motivationGoals $stateB)
                $coherenceCorrection
            )
            0.0
            1.0
        ))
    )
)

;; checkLaxDistributiveLaw
;; Validates the First Principle: Modular Appraisal-Decision Interface
(= (checkLaxDistributiveLaw $bimonad $state $stimulus $candidates)
    (let* (
        ;; Path 1: Appraise then Decide -> stabilized D(Psi(X))
        ($decisionState1 (decisionContext $bimonad $state $stimulus))
        ($decisionResult1 (decide (bimonadDecision $bimonad) $decisionState1 $candidates))
        ($finalState1 (stateFromDelta $bimonad $decisionState1 (decisionDeltaG $decisionResult1)))

        ;; Path 2: Decide then Appraise -> stabilized Psi(D(X))
        ($decisionResult2 (decide (bimonadDecision $bimonad) $state $candidates))
        ($decidedState2 (stateFromDelta $bimonad $state (decisionDeltaG $decisionResult2)))
        ($finalState2 (decisionContext $bimonad $decidedState2 $stimulus))
        
        ;; Calculate the controlled distortion distance
        ($distortion (motivationStateDistance $finalState1 $finalState2))
    )
        (if (<= $distortion (eval (LAX_DISTRIBUTIVE_DELTA)))
            True
            False
        )
    )
)

(= (step $bimonad $state $stimulus $candidates)
    (let* (
        ($transition (computeTransition $bimonad $state $stimulus $candidates))
        ($action (transitionAction $transition))
        ($nextState (transitionState $transition))
        ($referenceState (localReferenceState $state $nextState))
        
        ($laxOk (checkLaxDistributiveLaw $bimonad $state $stimulus $candidates))
        ($contractiveOk (eval ((bimonadContractiveSymbol $bimonad) $bimonad $state $referenceState $stimulus $candidates)))
        ($safeOk (eval ((bimonadSafeRegionSymbol $bimonad) $nextState)))
        ($stableState
            (if (and $laxOk (and $contractiveOk $safeOk))
                $nextState
                (applyConservativeFallback $state $nextState)
            )
        )
    )
        (transitionResult $action $stableState)
    )
)
