from ultralytics import YOLO
from data_types import DetectionResult

import cv2
import os


# ------------------------------------------------------------
# LOAD BOTH MODELS
# ------------------------------------------------------------

# COCO pretrained model
base_model = YOLO("yolo26n.pt")

# Custom affordance model
custom_model = YOLO("../weights/best.pt")


# ------------------------------------------------------------
# DETECTION FUNCTION
# ------------------------------------------------------------

def detect_objects(image_path):

    detections = []

    # --------------------------------------------------------
    # RUN BOTH MODELS
    # --------------------------------------------------------

    base_results = base_model(
        image_path,
        conf=0.15
    )

    custom_results = custom_model(
        image_path,
        conf=0.15
    )

    # --------------------------------------------------------
    # READ IMAGE
    # --------------------------------------------------------

    image = cv2.imread(image_path)

    # --------------------------------------------------------
    # PROCESS BOTH RESULTS
    # --------------------------------------------------------

    all_results = [
        (base_results[0], base_model),
        (custom_results[0], custom_model)
    ]

    for result, model in all_results:

        for box in result.boxes:

            # ------------------------------------------------
            # BOUNDING BOX
            # ------------------------------------------------

            x1, y1, x2, y2 = map(
                int,
                box.xyxy[0]
            )

            # ------------------------------------------------
            # CONFIDENCE
            # ------------------------------------------------

            confidence = float(
                box.conf[0]
            )

            # ------------------------------------------------
            # CLASS ID
            # ------------------------------------------------

            class_id = int(
                box.cls[0]
            )

            # ------------------------------------------------
            # LABEL
            # ------------------------------------------------

            label = model.names[
                class_id
            ].replace("_", " ")

            # ------------------------------------------------
            # CREATE DETECTION OBJECT
            # ------------------------------------------------

            detection = DetectionResult(
                label=label,
                confidence=confidence,
                bbox=(x1, y1, x2, y2)
            )

            detections.append(detection)

            # ------------------------------------------------
            # DRAW BOX
            # ------------------------------------------------

            cv2.rectangle(
                image,
                (x1, y1),
                (x2, y2),
                (0, 255, 0),
                2
            )

            # ------------------------------------------------
            # LABEL TEXT
            # ------------------------------------------------

            text = (
                f"{label} "
                f"({confidence:.2f})"
            )

            cv2.putText(
                image,
                text,
                (x1, max(y1 - 10, 20)),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (0, 255, 0),
                2
            )

    # --------------------------------------------------------
    # CREATE OUTPUT ROOT
    # --------------------------------------------------------

    root_output = "../detect_out"

    os.makedirs(
        root_output,
        exist_ok=True
    )

    # --------------------------------------------------------
    # TASK-WISE OUTPUT FOLDER
    # --------------------------------------------------------

    task_name = os.path.basename(
        os.path.dirname(image_path)
    )

    task_output_dir = os.path.join(
        root_output,
        task_name
    )

    os.makedirs(
        task_output_dir,
        exist_ok=True
    )

    # --------------------------------------------------------
    # OUTPUT IMAGE PATH
    # --------------------------------------------------------

    image_name = os.path.basename(
        image_path
    )

    output_path = os.path.join(
        task_output_dir,
        f"{image_name.split('.')[0]}_result.jpg"
    )

    # --------------------------------------------------------
    # SAVE DETECTION TXT
    # --------------------------------------------------------

    txt_output_path = os.path.join(
        task_output_dir,
        f"{image_name.split('.')[0]}_result.txt"
    )

    with open(
        txt_output_path,
        "w",
        encoding="utf-8"
    ) as f:

        for det in detections:

            x1, y1, x2, y2 = det.bbox

            f.write(
                f"{det.label}, "
                f"{det.confidence:.4f}, "
                f"({x1}, {y1}, {x2}, {y2})\n"
            )

    # --------------------------------------------------------
    # SAVE IMAGE
    # --------------------------------------------------------

    cv2.imwrite(
        output_path,
        image
    )

    print(f"\nSaved output: {output_path}")
    print(f"Saved detections: {txt_output_path}")

    return detections