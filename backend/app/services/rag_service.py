# services/rag_service.py

from sentence_transformers import SentenceTransformer
from retrieval.test_retrieval import load_index_and_chunks

# The embedding model + FAISS index/chunks are loaded once, on first use, and
# cached. Loading is LAZY (not at import) so importing this module -- and the
# ask router that depends on it -- stays cheap: the app boots quickly, tests
# import it without paying the SBERT + index load, and a Gemini-only deployment
# that never calls RAG never loads them at all. They never change at runtime,
# so the one-time load is reused for every request. (Rebuild the index offline
# with build_faiss.py and restart to pick up new content.)
_model = None
_index = None
_chunks = None


def _ensure_loaded():
    global _model, _index, _chunks
    if _model is None:
        _model = SentenceTransformer("all-MiniLM-L6-v2")
        _index, _chunks = load_index_and_chunks()
    return _model, _index, _chunks


def retrieve_context(question: str, k: int = 5):
    model, index, chunks = _ensure_loaded()

    # Normalize the query embedding to unit length so the inner-product index
    # (IndexFlatIP, built from normalized vectors in build_faiss.py) returns
    # cosine similarity. Without this the query scale would distort the scores.
    query_embedding = model.encode(question, normalize_embeddings=True)\
        .astype("float32")\
        .reshape(1, -1)

    distances, indices = index.search(
        query_embedding,
        k=k
    )

    retrieved_chunks = [
        chunks[idx]["content"]
        for idx in indices[0]
    ]

    return {
        "chunks": retrieved_chunks,
        "indices": indices[0],
        "all_chunks": chunks
    }
