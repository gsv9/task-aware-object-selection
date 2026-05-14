import math


def bbox_center(bbox):

    x1, y1, x2, y2 = bbox

    cx = (x1 + x2) / 2
    cy = (y1 + y2) / 2

    return cx, cy


def spatial_score(target, detections):

    tx, ty = bbox_center(target.bbox)

    total = 0.0

    for obj in detections:

        if obj == target:
            continue

        ox, oy = bbox_center(obj.bbox)

        distance = math.sqrt(
            (tx - ox) ** 2 +
            (ty - oy) ** 2
        )

        proximity = 1 / (distance + 1)

        total += proximity

    return total