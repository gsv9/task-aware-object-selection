import os

from pipeline import run_pipeline

from visualize import draw_results


#
# TASK -> QUERY MAP
#

TASK_QUERIES = {

    "step_on_something":
        "What should I use to step on something?",

    "sit_comfortably":
        "What should I use to sit comfortably?",

    "place_flowers":
        "What should I use to place flowers?",

    "get_potatoes_out_of_fire":
        "What should I use to get potatoes out of fire?",

    "water_plant":
        "What should I use to water a plant?",

    "get_lemon_out_of_tea":
        "What should I use to get lemon out of tea?",

    "dig_hole":
        "What should I use to dig a hole?",

    "open_bottle_of_beer":
        "What should I use to open a bottle of beer?",

    "open_parcel":
        "What should I use to open a parcel?",

    "serve_wine":
        "What should I use to serve wine?",

    "pour_sugar":
        "What should I use to pour sugar?",

    "smear_butter":
        "What should I use to smear butter?",

    "extinguish_fire":
        "What should I use to extinguish a fire?",

    "pound_carpet":
        "What should I use to pound a carpet?"
}


#
# ROOT IMAGE DIRECTORY
#

TEST_ROOT = "../test_images"


#
# OUTPUT ROOT
#

OUTPUT_ROOT = "outputs"

os.makedirs(
    OUTPUT_ROOT,
    exist_ok=True
)


#
# PROCESS ALL TASKS
#

for task_folder in TASK_QUERIES:

    task_path = os.path.join(
        TEST_ROOT,
        task_folder
    )

    task_query = TASK_QUERIES[task_folder]

    #
    # TASK OUTPUT FOLDER
    #

    task_output_dir = os.path.join(
        OUTPUT_ROOT,
        task_folder
    )

    os.makedirs(
        task_output_dir,
        exist_ok=True
    )

    print("\n")
    print("=" * 60)
    print(f"TASK: {task_folder}")
    print("=" * 60)

    #
    # LOOP THROUGH IMAGES
    #

    for image_name in os.listdir(task_path):

        #
        # SKIP NON-IMAGE FILES
        #

        if not image_name.lower().endswith(
            (".jpg", ".jpeg", ".png")
        ):
            continue

        image_path = os.path.join(
            task_path,
            image_name
        )

        #
        # RUN PIPELINE
        #

        detections = run_pipeline(
            image_path=image_path,
            task_query=task_query
        )

        #
        # OUTPUT IMAGE PATH
        #

        output_path = os.path.join(
            task_output_dir,
            image_name.replace(
                ".jpg",
                "_result.jpg"
            )
        )

        #
        # DRAW RESULTS
        #

        draw_results(
            image_path=image_path,
            detections=detections,
            output_path=output_path,
            threshold=0.20
        )

        print(
            f"\nSaved output: "
            f"{output_path}"
        )