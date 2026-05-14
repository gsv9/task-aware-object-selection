from data_types import DetectionResult

from reasoner import spatial_score

from metrics import start_timer, stop_timer


#
# FUTURE INTEGRATION:
#
# detections =
# detector.detect_objects(image)
#
# task_scores =
# filter.compute_similarity(task, labels)
#


def run_pipeline(image_path, task_query):

    print("\n===== PIPELINE START =====")

    print(f"Image : {image_path}")

    print(f"Task  : {task_query}")

    start = start_timer()

    #
    # MOCK OBJECTS
    #

    detections = [

        DetectionResult(
            label="knife",
            confidence=0.91,
            bbox=(10, 20, 120, 180),
            task_score=0.92
        ),

        DetectionResult(
            label="apple",
            confidence=0.88,
            bbox=(140, 40, 220, 160),
            task_score=0.78
        ),

        DetectionResult(
            label="laptop",
            confidence=0.95,
            bbox=(400, 300, 600, 500),
            task_score=0.11
        )
    ]

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

    for obj in detections:

        obj.spatial_score = (
            obj.spatial_score / max_spatial
        )

    #
    # FINAL SCORE
    #

    for obj in detections:

        obj.final_score = (
            0.6 * obj.task_score +
            0.4 * obj.spatial_score
        )

    #
    # SORT OBJECTS
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
            f"final={obj.final_score:.3f}"
        )

    #
    # TOP OBJECT
    #

    top_object = detections[0]

    print("\n===== TOP OBJECT =====")

    print(
        f"{top_object.label.upper()} "
        f"selected for task"
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