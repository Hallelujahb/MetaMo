;; Coherence dynamics helpers
;;
;; These functions operate on MotivationalState values:
;;   (motivation $goals $modulators)
;;
;; Required definitions are provided by the core/OpenPSI modules used by tests:
;;   ../../core/helper
;;   ../../core/state
;;   ../../core/state_accessors
;;   ../../core/config
;;   ../../openpsi/config
;;
;; Typical usage:
;;   (blendStates currentState targetState 1.0 0.25 0.5)

;; calculateBlendFactor
;;
;; Compute the base blend factor for a motivational state from the OpenPSI
;; individuation and transcendence goals.
;;
;; Formula:
;;   alpha = ALPHA_0 * (1.0 - gInd) + BETA_0 * gTrans
;;
;; The result is clipped to [0.0, 1.0].
;;
;; Parameters:
;;   $state - a motivation state with GoalIndex atoms for gInd and gTrans.
;;
;; Returns:
;;   Number in [0.0, 1.0].
;;
;; Example:
;;   (calculateBlendFactor
;;     (motivation (0.2 0.8 0.5 0.5 0.5 0.5 0.5 0.5)
;;                 (0.1 0.2 0.3 0.4 0.5 0.6)))
;;   => 0.2
(= (calculateBlendFactor $state)
    (let* (
      ($gInd (getGoal $state gInd))
      ($gTrans (getGoal $state gTrans))
      ($alpha (+ (* (ALPHA_0) (- 1.0 $gInd)) (* (BETA_0) $gTrans)))
    )
     (npClip $alpha 0.0 1.0) 
    )
)


;; checkSelfModelDrift
;;
;; Estimate whether the transition from one motivational state to another
;; stays within an allowed self-model drift bound.
;;
;; The drift approximation is:
;;   lipschitzConstant * motivationStateDistance(currentState, nextState)
;;
;; Parameters:
;;   $currentState       - current motivation state.
;;   $nextState          - candidate next motivation state.
;;   $lipschitzConstant  - multiplier used to approximate model drift.
;;   $maxAllowedDrift    - maximum allowed approximated drift.
;;
;; Returns:
;;   True when approximated drift is <= maxAllowedDrift, otherwise False.
;;
;; Example:
;;   (checkSelfModelDrift
;;     (motivation (0.0 0.0) (0.0 0.0))
;;     (motivation (0.3 0.4) (0.0 0.0))
;;     2.0
;;     1.0)
;;   => True
(= (checkSelfModelDrift $currentState $nextState $lipschitzConstant $maxAllowedDrift)
    (let* (
       ($distanceMoved (motivationStateDistance $currentState $nextState))
       ($approximatedDrift (* $lipschitzConstant $distanceMoved))
    )
      (<= $approximatedDrift $maxAllowedDrift)
    )
)

;; nextStateCalculator
;; Build an alpha-weighted next-state candidate by blending $currState toward $targetState.
;; Formula: (1 - alpha)*currState + alpha*targetState
;; Parameters:
;;   $currState    - the current state to blend from.
;;   $targetState  - the desired target state to blend toward.
;;   $alpha        - blend factor in [0.0, 1.0].
;;
;; Returns:
;;   A motivation state.
;;
;; Example:
;;   (nextStateCalculator
;;     (motivation (0.2 0.8) (0.1 0.2))
;;     (motivation (0.6 0.4) (0.9 0.8))
;;     0.5)
;;   ==> (motivation (0.4 0.6) (0.5 0.5))
(= (nextStateCalculator $currState $targetState $alpha)
    (let* (
        ($nAlpha (- 1.0 $alpha))
        ($newGoals    (vectorAdd (scaleArray (motivationGoals    $currState)   $nAlpha)
                                 (scaleArray (motivationGoals    $targetState) $alpha)))
        ($newMods     (vectorAdd (scaleArray (motivationModulators $currState)   $nAlpha)
                                 (scaleArray (motivationModulators $targetState) $alpha)))
    )
        (motivation $newGoals $newMods)
    )
)


;; blendStatesHelper
;;
;; Recursive worker for blendStates.
;; At each step it computes:
;;   candidate = (1 - alpha)*currentState + alpha*targetState
;; and checks the drift from currentState to that candidate.
;; If the drift is within bounds, OR alpha has fallen to the minimum,
;; the candidate is returned. Otherwise alpha is halved and we recurse.
;;
;; NOTE: $currentState is always the FIXED original state.
;;       The blend is always computed from it, not from a rolling candidate.
;;       This mirrors: while True: next = (1-α)*current + α*target; if ok: return
;;
;; Parameters:
;;   $currentState      - original (fixed) state, used for both blending and drift checks.
;;   $targetState       - desired target state.
;;   $alpha             - current blend factor.
;;   $minAlpha          - minimum alpha threshold (terminates search).
;;   $lipschitzConstant - multiplier used by checkSelfModelDrift.
;;   $maxAllowedDrift   - maximum allowed approximated drift.
;;
;; Returns:
;;   A motivation state accepted by the drift / min-alpha criteria.
;;
;; Example:
;;   (blendStatesHelper currentState targetState 0.2 0.02 1.0 0.1)
(= (blendStatesHelper $currentState $targetState $alpha $minAlpha $lipschitzConstant $maxAllowedDrift)
    (let* (
        ($candidate  (nextStateCalculator $currentState $targetState $alpha))
        ($driftOk    (checkSelfModelDrift $currentState $candidate $lipschitzConstant $maxAllowedDrift))
        ($nextAlpha  (* $alpha 0.5))
    )
        (if (or $driftOk (<= $alpha $minAlpha))
            $candidate
            (blendStatesHelper $currentState $targetState $nextAlpha $minAlpha $lipschitzConstant $maxAllowedDrift)
        )
    )
    
)


;; blendStates
;;
;; Public entry point for coherence-preserving state blending.
;; Calculates a base alpha from the current state, derives a minimum alpha
;; threshold, then delegates to blendStatesHelper.
;;
;; Matches python blend_states(current, target, lipschitz_constant=1.0,
;;                              max_allowed_drift=0.1, min_alpha_scale=0.25)
;;
;; Parameters:
;;   $currentState       - current motivation state.
;;   $targetState        - desired target motivation state.
;;   $lipschitzConstant  - multiplier used by checkSelfModelDrift.
;;   $maxAllowedDrift    - maximum allowed approximated drift.
;;   $minAlphaScale      - scale applied to base alpha to derive minAlpha.
;;
;; Returns:
;;   A motivation state accepted by the coherence checks.
;;
;; Example:
;;   (blendStates currentState targetState 1.0 0.25 0.5)
(= (blendStates $currentState $targetState $lipschitzConstant $maxAllowedDrift $minAlphaScale)
    (let* (
        ($baseAlpha (calculateBlendFactor $currentState))
        ($minAlpha  (* $minAlphaScale $baseAlpha))
    )
        (blendStatesHelper $currentState $targetState $baseAlpha $minAlpha $lipschitzConstant $maxAllowedDrift)
    )
)
