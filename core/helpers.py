import numpy as np

G_IND, G_TRANS, G_HELP, G_CURIO, G_NOVEL, G_SELF, G_ETHIC, G_SOC = range(8)
M_VALENCE, M_AROUSAL, M_APPROACH, M_RESOLUTION, M_THRESHOLD, M_SECURING = range(6)
 
def list_difference(arr1, arr2):
    a = np.asarray(arr1, dtype=float)
    b = np.asarray(arr2, dtype=float)

    if a.shape != b.shape:
        raise ValueError("arr1 and arr2 must have the same shape")
     
    return (a - b).tolist()

def norm(arr):
    return float(np.linalg.norm(arr))

def calculate_norm_difference(arr1, arr2):
    a = np.asarray(arr1, dtype=float)
    b = np.asarray(arr2, dtype=float)

    if a.shape != b.shape:
        raise ValueError("arr1 and arr2 must have the same shape")
    return float(np.sum(np.square(a - b)))


def normalize_vector(arr):
    a = np.asarray(arr)
    n = np.linalg.norm(a)
    return (a / n).tolist() if n > 0 else a.tolist()


# --- array operations ---

def split(arr, indices_or_sections):
    res = np.split(np.asarray(arr), indices_or_sections)
    return [x.tolist() for x in res]
     
    
def sum_array(arr):
    return float(np.sum(arr))

def prod_array(arr):
    return float(np.prod(arr))

def mean_array(arr):
    return float(np.mean(arr))

def std_array(arr):
    return round(float(np.std(arr)), 2)

def var_array(arr):
    return float(np.var(arr))

def dot_array(arr1, arr2):

    a = np.asarray(arr1)
    b = np.asarray(arr2)

    if a.shape != b.shape:
        raise ValueError("arr1 and arr2 must have the same shape")
    
    return float(np.dot(a, b))


# --- additional helper functions ---

def vector_add(arr1, arr2):
    a = np.asarray(arr1, dtype=float)
    b = np.asarray(arr2, dtype=float)

    if a.shape != b.shape:
        raise ValueError("arr1 and arr2 must have the same shape")

    return (a + b).tolist()

def average_arrays(arr1, arr2):
    a = np.asarray(arr1, dtype=float)
    b = np.asarray(arr2, dtype=float)

    if a.shape != b.shape:
        raise ValueError("arr1 and arr2 must have the same shape")

    return ((a + b) / 2.0).tolist()

def clip_vector(arr, min_value=0.0, max_value=1.0):
    return np.clip(np.asarray(arr, dtype=float), min_value, max_value).tolist()

def matrix_is_square(matrix):
    m = np.asarray(matrix, dtype=float)
    return str(m.ndim == 2 and m.shape[0] == m.shape[1]).lower()

def matrix_vector_dot(matrix, vector):
    m = np.asarray(matrix, dtype=float)
    v = np.asarray(vector, dtype=float)

    if m.ndim != 2:
        raise ValueError("matrix must be 2D")
    if m.shape[1] != v.shape[0]:
        raise ValueError("matrix columns must match vector length")

    return np.dot(m, v).tolist()

def abs_number(value):
    return abs(float(value))

def exp_number(value):
    return float(np.exp(float(value)))

def sigmoid_number(value):
    x = float(value)
    return float(1.0 / (1.0 + np.exp(-x)))

def probe_vector(delta, step=0.01, threshold=1e-6):
    d = np.asarray(delta, dtype=float)
    probe = np.where(np.abs(d) > threshold, np.sign(d) * step, step)
    return probe.tolist()

def weighted_average_arrays(arr1, arr2, weight1, weight2):
    a = np.asarray(arr1, dtype=float)
    b = np.asarray(arr2, dtype=float)
    total_weight = float(weight1) + float(weight2)

    if np.isclose(total_weight, 0.0):
        return (a + b) / 2.0

    return ((a * float(weight1)) + (b * float(weight2))) / total_weight

def parallel_merge_goals(goals_a, goals_b, coherence_correction=0.05):
    ga = np.asarray(goals_a, dtype=float)
    gb = np.asarray(goals_b, dtype=float)

    if ga.shape != gb.shape:
        raise ValueError("goal vectors must have the same shape")

    weight_a = ga[G_IND]
    weight_b = gb[G_IND]

    base_g = weighted_average_arrays(ga, gb, weight_a, weight_b)
    disagreement_g = np.abs(ga - gb)
    consensus_g = base_g.copy()

    safety_goal_idx = np.array([G_IND, G_HELP, G_ETHIC])
    exploratory_goal_idx = np.array([G_TRANS, G_CURIO, G_NOVEL, G_SELF])

    consensus_g[safety_goal_idx] = np.maximum(ga[safety_goal_idx], gb[safety_goal_idx])
    consensus_g[exploratory_goal_idx] = np.minimum(ga[exploratory_goal_idx], gb[exploratory_goal_idx])
    consensus_g[G_SOC] = min(base_g[G_SOC], ga[G_SOC], gb[G_SOC])

    goal_correction_scale = np.ones_like(base_g)
    goal_correction_scale[safety_goal_idx] = 1.5
    goal_correction_scale[exploratory_goal_idx] = 1.0
    goal_correction_scale[G_SOC] = 0.8

    goal_correction = np.clip(coherence_correction * disagreement_g * goal_correction_scale, 0.0, 1.0)
    merged_g = base_g + goal_correction * (consensus_g - base_g)
    return merged_g.tolist()

def parallel_merge_modulators(mod_a, mod_b, goals_a, goals_b, coherence_correction=0.05):
    ma = np.asarray(mod_a, dtype=float)
    mb = np.asarray(mod_b, dtype=float)
    ga = np.asarray(goals_a, dtype=float)
    gb = np.asarray(goals_b, dtype=float)

    if ma.shape != mb.shape:
        raise ValueError("modulator vectors must have the same shape")

    weight_a = ga[G_IND]
    weight_b = gb[G_IND]

    base_m = weighted_average_arrays(ma, mb, weight_a, weight_b)
    disagreement_m = np.abs(ma - mb)
    consensus_m = base_m.copy()

    caution_mod_idx = np.array([M_THRESHOLD, M_SECURING])
    exploratory_mod_idx = np.array([M_AROUSAL, M_APPROACH])
    shared_mod_idx = np.array([M_VALENCE, M_RESOLUTION])

    consensus_m[caution_mod_idx] = np.maximum(ma[caution_mod_idx], mb[caution_mod_idx])
    consensus_m[exploratory_mod_idx] = np.minimum(ma[exploratory_mod_idx], mb[exploratory_mod_idx])
    consensus_m[shared_mod_idx] = (ma[shared_mod_idx] + mb[shared_mod_idx]) / 2.0

    mod_correction_scale = np.ones_like(base_m)
    mod_correction_scale[caution_mod_idx] = 1.5
    mod_correction_scale[exploratory_mod_idx] = 1.0
    mod_correction_scale[shared_mod_idx] = 0.8

    mod_correction = np.clip(coherence_correction * disagreement_m * mod_correction_scale, 0.0, 1.0)
    merged_m = base_m + mod_correction * (consensus_m - base_m)
    return merged_m.tolist()

def softmax(arr):
    a = np.asarray(arr)
    exp_a = np.exp(a - np.max(a))
    
    sum_exp = exp_a.sum()
    if sum_exp == 0:
        return []
    # no round 
    return (exp_a / sum_exp).tolist()   

def round_number(value, digits=0):
    return round(float(value), digits)
