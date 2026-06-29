# services/rag_service.py

from sentence_transformers import SentenceTransformer
from retrieval.test_retrieval import load_index_and_chunks

# Load the embedding model AND the FAISS index + chunks once, at import time.
# Previously the index (~1.7 MB) and chunks (~0.8 MB) were re-read from disk on
# *every* /ask request; they never change at runtime, so we load them once and
# reuse them. (Rebuild the index offline with build_faiss.py and restart to
# pick up new content.)
model = SentenceTransformer("all-MiniLM-L6-v2")
_index, _chunks = load_index_and_chunks()


def retrieve_context(question: str, k: int = 5):

    # Normalize the query embedding to unit length so the inner-product index
    # (IndexFlatIP, built from normalized vectors in build_faiss.py) returns
    # cosine similarity. Without this the query scale would distort the scores.
    query_embedding = model.encode(question, normalize_embeddings=True)\
        .astype("float32")\
        .reshape(1, -1)

    distances, indices = _index.search(
        query_embedding,
        k=k
    )

    retrieved_chunks = [
        _chunks[idx]["content"]
        for idx in indices[0]
    ]

    return {
        "chunks": retrieved_chunks,
        "indices": indices[0],
        "all_chunks": _chunks
    }
