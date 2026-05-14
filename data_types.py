from dataclasses import dataclass
from typing import Tuple


@dataclass
class DetectionResult:

    label: str

    confidence: float

    bbox: Tuple[int, int, int, int]

    task_score: float = 0.0

    spatial_score: float = 0.0

    final_score: float = 0.0