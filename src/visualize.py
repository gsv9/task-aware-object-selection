import cv2


def draw_results(
    image_path,
    detections,
    output_path,
    threshold=0.20
):

    image = cv2.imread(image_path)

    if image is None:
        return

    #
    # NO DETECTIONS
    #

    if len(detections) == 0:

        cv2.putText(
            image,
            "NO OBJECTS DETECTED",
            (30, 50),
            cv2.FONT_HERSHEY_SIMPLEX,
            1,
            (0, 0, 255),
            2
        )

        cv2.imwrite(
            output_path,
            image
        )

        return

    #
    # TOP OBJECT
    #

    top = detections[0]

    #
    # REJECTION CASE
    #

    if top.final_score < threshold:

        cv2.putText(
            image,
            "NO SUITABLE OBJECT FOUND",
            (30, 50),
            cv2.FONT_HERSHEY_SIMPLEX,
            1,
            (0, 0, 255),
            2
        )

    else:

        #
        # DRAW TOP OBJECT
        #

        x1, y1, x2, y2 = map(
            int,
            top.bbox
        )

        cv2.rectangle(
            image,
            (x1, y1),
            (x2, y2),
            (0, 255, 0),
            3
        )

        #
        # LABEL TEXT
        #

        text = (
            f"{top.label} | "
            f"{top.final_score:.2f}"
        )

        cv2.putText(
            image,
            text,
            (x1, max(y1 - 10, 20)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (0, 255, 0),
            2
        )

    #
    # SAVE
    #

    cv2.imwrite(
        output_path,
        image
    )