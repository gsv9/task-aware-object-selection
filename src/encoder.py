from sentence_transformers import SentenceTransformer

model = SentenceTransformer('all-MiniLM-L6-v2')


def encode_text(text: str):
    """
    Encode a string into a 384-dimensional embedding vector.

    Args:
        text: Input string to encode.

    Returns:
        numpy array of shape (384,)
    """
    embedding = model.encode(text)
    return embedding


# Quick sanity check when run directly
if __name__ == "__main__":
    vec = encode_text("What should I use to cut fruit?")
    print(f"Embedding dimension: {len(vec)}")   # Expected: 384
