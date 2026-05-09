!(import! &self ../../core/helper)
!(import! &self "../../core/helpers.py")
!(import! &self ../../core/state)
!(import! &self ../../core/state_accessors)
!(import! &self ../../core/config)
!(import! &self ../../openpsi/config)
!(import! &self ../../category/functors)
!(import! &self ../decision)

;; Unit Tests

;; Test magusUnit returns state unchanged
!(test
    (magusUnit (motivation (0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5) (0.5 0.5 0.5 0.5 0.5 0.5)))
    (motivation (0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5) (0.5 0.5 0.5 0.5 0.5 0.5))
)

;; Test overgoal support for individuation-leaning goal
!(test
    (magusOvergoalSupport gHelp 0.9 0.1)
    (+ 0.5 (* 0.5 0.9))
)

;; Test overgoal support for transcendence-leaning goal
!(test
    (magusOvergoalSupport gCurio 0.1 0.9)
    (+ 0.5 (* 0.5 0.9))
)

;; Test overgoal support for dual-drive goal
!(test
    (magusOvergoalSupport gSelf 0.8 0.6)
    (+ 0.5 (* 0.25 (+ 0.8 0.6)))
)

;; Test magusScore returns a number for a valid candidate
!(test
    (> (magusScore
        (motivation (0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5) (0.5 0.5 0.5 0.5 0.5 0.5))
        (action act1 (0.0 0.0 0.25 0.5 0.3 0.1 0.2 0.15) 0.1 (0.0 0.0 0.05 0.1 0.05 0.0 0.0 0.0))
    ) -100.0)
    True
)

;; Test magusDecide returns a DecisionResult with best action
!(test
    (actionId (decisionAction
        (magusDecide
            (motivation (0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5) (0.5 0.5 0.5 0.5 0.5 0.5))
            (
                (action act1 (0.0 0.0 0.1 0.1 0.1 0.1 0.1 0.1) 0.1 (0.0 0.0 0.01 0.01 0.01 0.0 0.0 0.0))
                (action act2 (0.0 0.0 0.5 0.5 0.5 0.5 0.5 0.5) 0.05 (0.0 0.0 0.05 0.05 0.05 0.0 0.0 0.0))
            )
        )
    ))
    act2
)

;; Test magusDecision constructs a valid DecisionMonad
!(test
    (unit (magusDecision) (motivation (0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5) (0.5 0.5 0.5 0.5 0.5 0.5)))
    (motivation (0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5) (0.5 0.5 0.5 0.5 0.5 0.5))
)

;; Behavioral Logic Tests

;; Test Curiosity-Ethics Conflict Penalty
;; act1: high ethics, high curiosity (conflict)
;; act2: high ethics, low curiosity (no conflict)
;; act2 should be preferred even if act1 has slightly higher correlations overall.
!(test
    (actionId (decisionAction
        (magusDecide
            (motivation (0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5) (0.5 0.5 0.5 0.5 0.5 0.5))
            (
                (action conflict_act (0.0 0.0 0.0 0.8 0.0 0.0 -0.8 0.0) 0.01 (0.0 0.0 0.0 0.08 0.0 0.0 -0.08 0.0))
                (action safe_act (0.0 0.0 0.0 0.1 0.0 0.0 0.8 0.0) 0.01 (0.0 0.0 0.0 0.01 0.0 0.0 0.08 0.0))
            )
        )
    ))
    safe_act
)

