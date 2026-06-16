# services/rag_service.py

from sentence_transformers import SentenceTransformer
from retrieval.test_retrieval import load_index_and_chunks

model = SentenceTransformer("all-MiniLM-L6-v2")


def retrieve_context(question: str, k: int = 5):

    index, chunks = load_index_and_chunks()

    query_embedding = model.encode(question)\
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