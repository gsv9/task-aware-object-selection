import re


RESULTS_FILE = r"D:\task_aware_pipeline\results\evaluation_results_v8.txt"


#
# COUNTERS
#

total_images = 0

successful = 0

rejected = 0

latencies = []

task_stats = {}


#
# READ RESULTS FILE
#

with open(
    RESULTS_FILE,
    "r",
    encoding="utf-16"
) as f:

    lines = f.readlines()


current_task = None


#
# PARSE FILE
#

for raw_line in lines:

    line = raw_line.strip().lower()

    #
    # TASK NAME
    #

    if "task:" in line:

        current_task = (
            line.split("task:")[1]
            .strip()
        )

        if current_task not in task_stats:

            task_stats[current_task] = {
                "total": 0,
                "success": 0,
                "rejected": 0
            }

    #
    # PIPELINE START
    #

    if "pipeline start" in line:

        total_images += 1

        if current_task is not None:

            task_stats[current_task]["total"] += 1

    #
    # SUCCESS
    #

    if (
        "selected" in line
        and
        "no suitable object detected"
        not in line
    ):

        successful += 1

        if current_task is not None:

            task_stats[current_task]["success"] += 1

    #
    # REJECTION
    #

    if "no suitable object detected" in line:

        rejected += 1

        if current_task is not None:

            task_stats[current_task]["rejected"] += 1

    #
    # LATENCY
    #

    if "inference latency:" in line:

        match = re.search(
            r"([0-9.]+)",
            line
        )

        if match:

            latency = float(
                match.group(1)
            )

            latencies.append(latency)


#
# FINAL METRICS
#

avg_latency = 0.0

fps = 0.0

success_rate = 0.0


if len(latencies) > 0:

    avg_latency = (
        sum(latencies)
        / len(latencies)
    )

    fps = 1.0 / avg_latency


if total_images > 0:

    success_rate = (
        successful / total_images
    ) * 100


#
# PRINT SUMMARY
#

print("\n")
print("=" * 60)
print("EVALUATION SUMMARY")
print("=" * 60)

print(
    f"Total Images Evaluated : "
    f"{total_images}"
)

print(
    f"Successful Predictions : "
    f"{successful}"
)

print(
    f"Rejected Predictions   : "
    f"{rejected}"
)

print(
    f"Success Rate           : "
    f"{success_rate:.2f}%"
)

print(
    f"Average Latency        : "
    f"{avg_latency:.4f} sec"
)

print(
    f"FPS                    : "
    f"{fps:.2f}"
)


#
# TASK-WISE RESULTS
#

print("\n")
print("=" * 60)
print("TASK-WISE RESULTS")
print("=" * 60)

for task in task_stats:

    total = task_stats[task]["total"]

    success = task_stats[task]["success"]

    reject = task_stats[task]["rejected"]

    accuracy = 0.0

    if total > 0:

        accuracy = (
            success / total
        ) * 100

    print("\n")
    print(f"TASK: {task}")

    print(f"  Total     : {total}")

    print(f"  Success   : {success}")

    print(f"  Rejected  : {reject}")

    print(f"  Accuracy  : {accuracy:.2f}%")