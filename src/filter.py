from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

from encoder import encode_text


# ---------------------------------------------------------------------------
# BONUS: Precomputed embeddings for common COCO labels
# Computed once at import time so repeated inference doesn't recompute them.
# ---------------------------------------------------------------------------

COCO_LABELS = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train",
    "truck", "boat", "traffic light", "fire hydrant", "stop sign",
    "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep",
    "cow", "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella",
    "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard",
    "sports ball", "kite", "baseball bat", "baseball glove", "skateboard",
    "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork",
    "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange",
    "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair",
    "couch", "potted plant", "bed", "dining table", "toilet", "tv",
    "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave",
    "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase",
    "scissors", "teddy bear", "hair drier", "toothbrush",
]

# Dict: label -> embedding vector
_coco_embedding_cache: dict = {}


def _build_coco_cache():
    """Precompute and cache embeddings for all COCO labels."""
    global _coco_embedding_cache
    embeddings = encode_text.__self__  # not needed — just call encode_text in batch

    # Use batch encode for speed (sentence-transformers supports list input)
    from encoder import model as _model
    vecs = _model.encode(COCO_LABELS)           # shape: (N, 384)
    _coco_embedding_cache = dict(zip(COCO_LABELS, vecs))


_build_coco_cache()


# ---------------------------------------------------------------------------
# Core function
# ---------------------------------------------------------------------------

def compute_similarity(task_query: str, labels: list[str]) -> list[float]:
    """
    Compute cosine similarity between a task query and a list of object labels.

    Args:
        task_query: Natural language task string.
                    e.g. "What should I use to cut fruit?"
        labels:     List of detected object label strings.
                    e.g. ["knife", "apple", "laptop"]

    Returns:
        List of float similarity scores, one per label, in the same order.
        e.g. [0.92, 0.78, 0.11]
    """
    task_embedding = encode_text(task_query)     # (384,)

    label_embeddings = []
    for label in labels:
        # Use precomputed embedding if available, otherwise encode on the fly
        if label in _coco_embedding_cache:
            emb = _coco_embedding_cache[label]
        else:
            emb = encode_text(label)
            _coco_embedding_cache[label] = emb   # cache for future calls
        label_embeddings.append(emb)

    similarities = []
    for emb in label_embeddings:
        score = cosine_similarity(
            [task_embedding],
            [emb]
        )[0][0]
        similarities.append(float(score))

    return similarities


# ---------------------------------------------------------------------------
# Quick sanity check when run directly
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    task = "What should I use to cut fruit?"
    labels = ["knife", "apple", "laptop"]

    scores = compute_similarity(task, labels)

    print(f"\nTask: '{task}'\n")
    for label, score in sorted(zip(labels, scores), key=lambda x: -x[1]):
        print(f"  {label:<12} → {score:.4f}")

    # Assertion: knife should rank highest
    top_label = labels[scores.index(max(scores))]
    assert top_label == "knife", f"Expected 'knife' at top, got '{top_label}'"
    print("\n✅ Sanity check passed — 'knife' ranked highest.")
