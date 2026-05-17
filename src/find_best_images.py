import os
import shutil

from detector import detect_objects


#
# PATHS
#

VAL2014_PATH = "../val2014"

OUTPUT_PATH = "../filtered_images"


#
# TASK OBJECT MAPPING
#

TASK_OBJECTS = {

    "step_on_something": [
        "chair",
        "bench"
    ],

    "sit_comfortably": [
        "chair",
        "bed"
    ],

    "place_flowers": [
        "vase",
        "cup",
        "bowl"
    ],

    "get_potatoes_out_of_fire": [
        "bowl",
        "spoon"
    ],

    "water_plant": [
        "bottle",
        "cup"
    ],

    "get_lemon_out_of_tea": [
        "spoon"
    ],

    "dig_hole": [
        "knife",
        "spoon"
    ],

    "open_bottle_of_beer": [
        "bottle",
        "knife"
    ],

    "open_parcel": [
        "knife",
        "scissors"
    ],

    "serve_wine": [
        "wine glass",
        "cup",
        "bottle"
    ],

    "pour_sugar": [
        "cup",
        "bowl",
        "spoon"
    ],

    "smear_butter": [
        "knife"
    ],

    "extinguish_fire": [
        "bottle"
    ],

    "pound_carpet": [
        "baseball bat",
        "chair",
        "bench"
    ]
}


#
# CREATE OUTPUT
#

os.makedirs(
    OUTPUT_PATH,
    exist_ok=True
)


#
# SEARCH IMAGES
#

for task, target_objects in TASK_OBJECTS.items():

    print(f"\nTASK: {task}")

    task_output = os.path.join(
        OUTPUT_PATH,
        task
    )

    os.makedirs(
        task_output,
        exist_ok=True
    )

    selected = 0

    #
    # LOOP OVER VAL2014
    #

    for filename in os.listdir(VAL2014_PATH):

        image_path = os.path.join(
            VAL2014_PATH,
            filename
        )

        #
        # RUN DETECTOR
        #

        detections = detect_objects(
            image_path
        )

        #
        # EXTRACT LABELS
        #

        labels = [
            d.label
            for d in detections
        ]

        #
        # CHECK IF RELEVANT OBJECT EXISTS
        #

        found = any(
            obj in labels
            for obj in target_objects
        )

        #
        # COPY GOOD IMAGE
        #

        if found:

            shutil.copy(
                image_path,
                os.path.join(
                    task_output,
                    filename
                )
            )

            print(
                f"Selected: {filename}"
            )

            selected += 1

        #
        # STOP AFTER 3 GOOD IMAGES
        #

        if selected >= 20:

            print(
                f"Completed: {task}"
            )

            break


print("\nFiltered dataset creation complete.")