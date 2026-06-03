import json
import faiss
import numpy as np
from sentence_transformers import SentenceTransformer

# Load chunks
with open("output_chunks.json", "r") as f:
    chunks = json.load(f)

# Extract content
chunk_texts = [c["content"] for c in chunks]

# Load SBERT model and encode
model = SentenceTransformer("all-MiniLM-L6-v2")
embeddings = model.encode(chunk_texts, convert_to_numpy=True)

# Convert to float32
embeddings = embeddings.astype("float32")

# Get vector dimension
dimension = embeddings.shape[1]

# Create FAISS index
index = faiss.IndexFlatL2(dimension)

# Add embeddings
index.add(embeddings)

# Check total vectors
print("Total vectors:", index.ntotal)

# Save index
faiss.write_index(index, "faiss_index.bin")

print("FAISS index saved successfully.")