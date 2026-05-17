import os
import shutil

#
# SOURCE OUTPUT FOLDER
#

SOURCE_ROOT = "outputs"

#
# DESTINATION
#

DEST_ROOT = "final_demo_images"

#
# TASKS TO KEEP
#

VALID_TASKS = [
    "sit_comfortably",
    "place_flowers",
    "serve_wine",
    "pour_sugar",
    "smear_butter",
    "extinguish_fire"
]

#
# CREATE DEST ROOT
#

os.makedirs(
    DEST_ROOT,
    exist_ok=True
)

#
# COPY BEST IMAGES
#

for task in VALID_TASKS:

    source_task = os.path.join(
        SOURCE_ROOT,
        task
    )

    dest_task = os.path.join(
        DEST_ROOT,
        task
    )

    #
    # SKIP IF TASK FOLDER DOESN'T EXIST
    #

    if not os.path.exists(source_task):
        continue

    #
    # CREATE TASK FOLDER
    #

    os.makedirs(
        dest_task,
        exist_ok=True
    )

    #
    # GET IMAGE FILES
    #

    images = [
        f for f in os.listdir(source_task)
        if f.lower().endswith(
            (".jpg", ".jpeg", ".png")
        )
    ]

    #
    # COPY FIRST 2 IMAGES
    #

    for image_name in images[:2]:

        src_path = os.path.join(
            source_task,
            image_name
        )

        dst_path = os.path.join(
            dest_task,
            image_name
        )

        shutil.copy(
            src_path,
            dst_path
        )

        print(
            f"Copied: {task}/{image_name}"
        )

print("\nDone organizing demo images.")