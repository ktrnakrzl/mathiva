import json
import os

import faiss
import numpy as np
from sentence_transformers import SentenceTransformer

# Build the FAISS retrieval index from the chunked PDF text.
#
# Retrieval uses COSINE similarity, not raw L2 distance: all-MiniLM-L6-v2 is
# trained so that semantic closeness is measured by the angle between vectors,
# not their straight-line distance. We get cosine out of FAISS by (1) L2-
# normalizing every embedding to unit length and (2) using an inner-product
# index (IndexFlatIP) -- the inner product of two unit vectors *is* their
# cosine similarity. The query side (rag_service / test_retrieval) must
# normalize the query embedding the same way, or the scores won't line up.

_HERE = os.path.dirname(os.path.abspath(__file__))
_CHUNKS_PATH = os.path.join(_HERE, "output_chunks.json")
_INDEX_PATH = os.path.join(_HERE, "faiss_index.bin")
MODEL_NAME = "all-MiniLM-L6-v2"

# Load chunks
with open(_CHUNKS_PATH, "r", encoding="utf-8") as f:
    chunks = json.load(f)

# Extract content
chunk_texts = [c["content"] for c in chunks]

# Load SBERT model and encode as unit-length vectors (for cosine via IP).
model = SentenceTransformer(MODEL_NAME)
embeddings = model.encode(
    chunk_texts,
    convert_to_numpy=True,
    normalize_embeddings=True,
)

# Convert to float32 (FAISS requirement)
embeddings = embeddings.astype("float32")

# Get vector dimension
dimension = embeddings.shape[1]

# Create FAISS index. Inner product on normalized vectors == cosine similarity.
index = faiss.IndexFlatIP(dimension)

# Add embeddings
index.add(embeddings)

# Check total vectors
print("Total vectors:", index.ntotal)

# Save index
faiss.write_index(index, _INDEX_PATH)

print("FAISS index saved successfully.")
