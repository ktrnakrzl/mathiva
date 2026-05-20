import json
from sentence_transformers import SentenceTransformer
import numpy as np

# Load your chunks
with open("genmath_chunks.json", "r", encoding="utf-8") as f:
    chunks = json.load(f)

# Load SBERT model (downloads ~90MB on first run)
print("Loading SBERT model...")
model = SentenceTransformer("all-MiniLM-L6-v2")

# Extract just the text content from each chunk
texts = [chunk["content"] for chunk in chunks]

# Embed all chunks (this is the magic step)
print(f"Embedding {len(texts)} chunks...")
embeddings = model.encode(texts, show_progress_bar=True)

# Save embeddings as numpy array
np.save("genmath_embeddings.npy", embeddings)

# Save chunk metadata separately (without content, for fast loading)
metadata = [{k: v for k, v in c.items() if k != "content"} for c in chunks]
with open("genmath_metadata.json", "w") as f:
    json.dump(metadata, f, indent=2)

print(f"Done! Embeddings shape: {embeddings.shape}")
print(f"Each chunk → vector of {embeddings.shape[1]} numbers")