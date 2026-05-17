from detector import detect_objects

import os


dataset_path = "../dataset"


classes = [

    "bed",
    "bench",
    "bottle",
    "bowl",
    "chair",
    "couch",
    "cup",
    "fork",
    "knife",
    "potted_plant",
    "scissors",
    "spoon",
    "vase",
    "wine_glass"
]


for class_name in classes:

    class_folder = os.path.join(
        dataset_path,
        class_name
    )

    print("\n======================")
    print(f"CLASS : {class_name}")
    print("======================")

    images = os.listdir(class_folder)

    for image_name in images[:3]:

        image_path = os.path.join(
            class_folder,
            image_name
        )

        print(f"\nTesting : {image_name}")

        detections = detect_objects(image_path)

        print("Detections:")

        for det in detections:

            print(
                det.label,
                round(det.confidence, 3)
            )