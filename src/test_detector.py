from detector import detect_objects

detections = detect_objects("butter.jpg")

print("\n===== DETECTIONS =====")

for det in detections:

    print(
        det.label,
        round(det.confidence, 3),
        det.bbox
    )