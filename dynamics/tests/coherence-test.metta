!(import! &self ../../core/helper)
!(import! &self "../../core/helpers.py")
!(import! &self ../../core/state)
!(import! &self ../../core/state_accessors)
!(import! &self ../../core/config)
!(import! &self ../../openpsi/config)
!(import! &self ../coherence)

;; Shared OpenPSI-shaped states for coherence tests.
(= (coherenceState)
    (motivation
        (0.2 0.8 0.5 0.5 0.5 0.5 0.5 0.5)
        (0.1 0.2 0.3 0.4 0.5 0.6)
    )
)

(= (coherenceTarget)
    (motivation
        (0.4 0.6 0.5 0.5 0.5 0.5 0.5 0.5)
        (0.2 0.3 0.3 0.4 0.5 0.6)
    )
)

;; calculateBlendFactor: alpha = ALPHA_0 * (1 - gInd) + BETA_0 * gTrans.
!(test
    (roundNum (calculateBlendFactor (coherenceState)) 6)
    0.2
)

;; calculateBlendFactor clips values below 0.0.
!(test
    (calculateBlendFactor
        (motivation
            (20.0 0.0 0.5 0.5 0.5 0.5 0.5 0.5)
            (0.1 0.2 0.3 0.4 0.5 0.6)
        )
    )
    0.0
)

;; calculateBlendFactor clips values above 1.0.
!(test
    (calculateBlendFactor
        (motivation
            (-10.0 10.0 0.5 0.5 0.5 0.5 0.5 0.5)
            (0.1 0.2 0.3 0.4 0.5 0.6)
        )
    )
    1.0
)

;; checkSelfModelDrift accepts drift at the threshold.
!(test
    (checkSelfModelDrift
        (motivation (0.0 0.0) (0.0 0.0))
        (motivation (0.3 0.4) (0.0 0.0))
        2.0
        1.0
    )
    True
)

;; checkSelfModelDrift rejects drift over the threshold.
!(test
    (checkSelfModelDrift
        (motivation (0.0 0.0) (0.0 0.0))
        (motivation (0.6 0.8) (0.0 0.0))
        1.1
        1.0
    )
    False
)

;; nextStateCalculator blends the current state toward the target state.
!(test
    (nextStateCalculator (coherenceState) (coherenceState) 0.35)
    (coherenceState)
)

!(test
    (nextStateCalculator (coherenceState) (coherenceTarget) 0.5)
    (motivation
        (0.3 0.7 0.5 0.5 0.5 0.5 0.5 0.5)
        (0.15 0.25 0.3 0.4 0.5 0.6)
    )
)

;; blendStatesHelper returns the candidate state when the target drift is allowed.
!(test
    (blendStatesHelper
        (coherenceState)
        (coherenceTarget)
        0.2
        0.02
        1.0
        10.0
    )
    (motivation
        (0.24 0.76 0.5 0.5 0.5 0.5 0.5 0.5)
        (0.12 0.22 0.3 0.4 0.5 0.6)
    )
)

;; blendStatesHelper also returns the candidate state once alpha reaches minAlpha.
!(test
    (blendStatesHelper
        (coherenceState)
        (coherenceTarget)
        0.02
        0.02
        1.0
        0.0
    )
    (nextStateCalculator (coherenceState) (coherenceTarget) 0.02)
)

;; blendStates is stable for an already-identical current and target state.
!(test
    (blendStates (coherenceState) (coherenceState) 1.0 0.0 0.5)
    (coherenceState)
)
