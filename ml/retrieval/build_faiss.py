import faiss
import numpy as np

# Load embeddings
embeddings = np.load("../embeddings/genmath_embeddings.npy")

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
faiss.write_index(index, "../embeddings/faiss_index.bin")

print("FAISS index saved successfully.")