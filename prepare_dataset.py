import os
import shutil


#
# PATHS
#

VAL2014_PATH = "val2014"

IMAGE_LISTS_PATH = "src/dataset/image_lists"

OUTPUT_PATH = "test_images"


#
# TASK NAME MAPPING
#

TASK_NAMES = {

    1: "step_on_something",
    2: "sit_comfortably",
    3: "place_flowers",
    4: "get_potatoes_out_of_fire",
    5: "water_plant",
    6: "get_lemon_out_of_tea",
    7: "dig_hole",
    8: "open_bottle_of_beer",
    9: "open_parcel",
    10: "serve_wine",
    11: "pour_sugar",
    12: "smear_butter",
    13: "extinguish_fire",
    14: "pound_carpet"
}


#
# CREATE DATASET
#

for task_id, task_name in TASK_NAMES.items():

    txt_file = os.path.join(
        IMAGE_LISTS_PATH,
        f"imgIds_task_{task_id}_test.txt"
    )

    #
    # READ IMAGE IDS
    #

    with open(txt_file, "r") as f:

        image_ids = [
            line.strip()
            for line in f.readlines()
        ]

    #
    # CREATE TASK FOLDER
    #

    task_folder = os.path.join(
        OUTPUT_PATH,
        task_name
    )

    os.makedirs(task_folder, exist_ok=True)

    #
    # COPY FIRST 3 IMAGES
    #

    for image_id in image_ids[:3]:

        filename = (
            f"COCO_val2014_"
            f"{int(image_id):012d}.jpg"
        )

        src_path = os.path.join(
            VAL2014_PATH,
            filename
        )

        dst_path = os.path.join(
            task_folder,
            filename
        )

        #
        # COPY IMAGE
        #

        if os.path.exists(src_path):

            shutil.copy(
                src_path,
                dst_path
            )

            print(
                f"Copied: {filename} "
                f"-> {task_name}"
            )

        else:

            print(
                f"Missing: {filename}"
            )

print("\nDataset preparation complete.")