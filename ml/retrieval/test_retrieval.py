import faiss
import json
import numpy as np
from sentence_transformers import SentenceTransformer
import os

def load_index_and_chunks():
    """Load FAISS index and chunks"""
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    index_path = os.path.join(current_dir, "faiss_index.bin")
    chunks_path = os.path.join(current_dir, "output_chunks.json")
    
    index = faiss.read_index(index_path)
    with open(chunks_path, "r") as f:
        chunks = json.load(f)
    
    return index, chunks

# Only run this if file is executed directly, not imported
if __name__ == "__main__":
    # Load SBERT model
    model = SentenceTransformer("all-MiniLM-L6-v2")

    # Load FAISS index
    index = faiss.read_index("faiss_index.bin")

    # Load chunks
    with open("output_chunks.json", "r") as f:
        chunks = json.load(f)

    # Student query
    query = "how do I solve rational equations?"

    # Convert query into embedding
    query_embedding = model.encode([query])

    # Convert to float32
    query_embedding = np.array(query_embedding).astype("float32")

    # Search top 5 nearest chunks
    k = 5
    distances, indices = index.search(query_embedding, k)

    print("\nQUERY:")
    print(query)

    print("\nTOP RESULTS:\n")

    # Print retrieved chunks
    for i, idx in enumerate(indices[0]):
        print(f"Result {i+1}:")
        print(chunks[idx])
        print("-" * 50)