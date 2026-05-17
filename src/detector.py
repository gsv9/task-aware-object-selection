from ultralytics import YOLO
from data_types import DetectionResult

import cv2
import os


# Load model ONLY ONCE
model = YOLO("yolo26n.pt")


def detect_objects(image_path):

    detections = []

    # Run inference
    results = model(image_path)

    result = results[0]

    # Read image for visualization
    image = cv2.imread(image_path)

    for box in result.boxes:

        # Bounding box coordinates
        x1, y1, x2, y2 = map(int, box.xyxy[0])

        # Confidence
        confidence = float(box.conf[0])

        # Class ID
        class_id = int(box.cls[0])

        # Label name
        label = model.names[class_id]

        # Create DetectionResult object
        detection = DetectionResult(
            label=label,
            confidence=confidence,
            bbox=(x1, y1, x2, y2)
        )

        detections.append(detection)

        # Draw rectangle
        cv2.rectangle(
            image,
            (x1, y1),
            (x2, y2),
            (0, 255, 0),
            2
        )

        # Label text
        text = f"{label} ({confidence:.2f})"

        cv2.putText(
            image,
            text,
            (x1, y1 - 10),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (0, 255, 0),
            2
        )

    # Create outputs folder if missing
    os.makedirs("outputs", exist_ok=True)

    # Output filename
    image_name = os.path.basename(image_path)

    output_path = f"outputs/{image_name.split('.')[0]}_result.jpg"

    # Save annotated image
    cv2.imwrite(output_path, image)

    print(f"\nSaved output: {output_path}")

    return detections