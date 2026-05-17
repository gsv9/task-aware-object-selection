from detector import detect_objects

from filter import compute_similarity

from reasoner import spatial_score

from metrics import start_timer, stop_timer


#
# TASK-AWARE PRIOR BOOSTS
#

TASK_PRIORS = {

    "step on something": {
        "bench": 0.20,
        "chair": 0.15,
        "bed": 0.10,
        "couch": 0.10
    },

    "sit comfortably": {
        "chair": 0.20,
        "couch": 0.20,
        "bed": 0.15,
        "bench": 0.10
    },

    "place flowers": {
        "vase": 0.25,
        "cup": 0.15,
        "bowl": 0.15,
        "potted plant": 0.10
    },

    "get potatoes out of fire": {
        "spatula": 0.30,
        "spoon": 0.20,
        "knife": 0.15,
        "fork": 0.10
    },

    "water a plant": {
        "watering can": 0.35,
        "bottle": 0.20,
        "cup": 0.15,
        "bowl": 0.10,
        "vase": 0.10,
        "sink": 0.10,
        "potted plant": 0.10
    },

    "get lemon out of tea": {
        "spoon": 0.25,
        "fork": 0.15,
        "spatula": 0.10,
        "cup": 0.10
    },

    "dig a hole": {
        "shovel": 0.35,
        "knife": 0.20,
        "spoon": 0.15,
        "fork": 0.10,
        "baseball bat": 0.10
    },

    "open a bottle of beer": {
        "bottle opener": 0.40,
        "knife": 0.20,
        "fork": 0.10,
        "spoon": 0.10,
        "bottle": 0.10
    },

    "open a parcel": {
        "cutter": 0.40,
        "scissors": 0.25,
        "knife": 0.20
    },

    "serve wine": {
        "wine glass": 0.30,
        "bottle": 0.20,
        "cup": 0.10
    },

    "pour sugar": {
        "cup": 0.15,
        "bowl": 0.15,
        "spoon": 0.20
    },

    "smear butter": {
        "knife": 0.25,
        "spatula": 0.20,
        "spoon": 0.15,
        "fork": 0.10
    },

    "extinguish a fire": {
        "fire extinguisher": 0.45,
        "bottle": 0.25,
        "cup": 0.10
    },

    "pound a carpet": {
        "carpet beater": 0.40,
        "baseball bat": 0.30,
        "tennis racket": 0.20,
        "sports ball": 0.10,
    

    }
}


#
# MINIMUM CONFIDENCE THRESHOLD
#

MIN_ACCEPTABLE_SCORE = 0.20


def run_pipeline(image_path, task_query):

    print("\n===== PIPELINE START =====")

    print(f"Image : {image_path}")

    print(f"Task  : {task_query}")

    start = start_timer()

    #
    # OBJECT DETECTION
    #

    detections = detect_objects(image_path)

    #
    # HANDLE EMPTY DETECTIONS
    #

    if len(detections) == 0:

        print("\nNo objects detected.")

        return []

    #
    # EXTRACT LABELS
    #

    labels = [obj.label for obj in detections]

    #
    # SEMANTIC SIMILARITY
    #

    scores = compute_similarity(
        task_query,
        labels
    )

    #
    # TASK SCORE + PRIOR BOOST
    #

    task_lower = task_query.lower()

    for obj, score in zip(detections, scores):

        boosted_score = float(score)

        #
        # APPLY TASK PRIORS
        #

        for task_key in TASK_PRIORS:

            if task_key in task_lower:

                if obj.label in TASK_PRIORS[task_key]:

                    boosted_score += (
                        0.7 *
                        TASK_PRIORS[task_key][obj.label]
                    )

        #
        # CLAMP SCORE
        #

        boosted_score = min(
            boosted_score,
            1.0
        )

        obj.task_score = boosted_score

    #
    # SPATIAL REASONING
    #

    max_spatial = 0.0

    for obj in detections:

        obj.spatial_score = spatial_score(
            obj,
            detections
        )

        if obj.spatial_score > max_spatial:

            max_spatial = obj.spatial_score

    #
    # NORMALIZE SPATIAL SCORES
    #

    if max_spatial > 0:

        for obj in detections:

            obj.spatial_score = (
                obj.spatial_score / max_spatial
            )

    #
    # FINAL SCORE
    #

    for obj in detections:

        combined_score = (
            0.97 * obj.task_score +
            0.03 * obj.spatial_score
        )

        obj.final_score = (
            combined_score +
            0.05 * obj.confidence
        )

    #
    # SORT DETECTIONS
    #

    detections.sort(
        key=lambda x: x.final_score,
        reverse=True
    )

    #
    # PRINT RESULTS
    #

    print("\n===== FINAL RESULTS =====")

    for i, obj in enumerate(detections):

        print(
            f"#{i+1} "
            f"{obj.label} | "
            f"task={obj.task_score:.3f} | "
            f"spatial={obj.spatial_score:.3f} | "
            f"confidence={obj.confidence:.3f} | "
            f"final={obj.final_score:.3f}"
        )

    #
    # TOP OBJECT
    #

    top_object = detections[0]

    #
    # VALID TASK OBJECT CHECK
    #

    valid_task_object = False

    for task_key in TASK_PRIORS:

        if task_key in task_lower:

            if top_object.label in TASK_PRIORS[task_key]:

                valid_task_object = True

                break

    #
    # REJECTION CONDITION
    #

    if (
        top_object.final_score < MIN_ACCEPTABLE_SCORE
        or
        not valid_task_object
    ):

        print("\n===== RESULT =====")

        print(
            "No suitable object detected."
        )

    else:

        print("\n===== TOP OBJECT =====")

        print(
            f"{top_object.label.upper()} "
            f"selected "
            f"(score={top_object.final_score:.3f})"
        )

    #
    # LATENCY
    #

    latency = stop_timer(start)

    print(
        f"\nInference latency: "
        f"{latency:.4f} sec"
    )

    return detections