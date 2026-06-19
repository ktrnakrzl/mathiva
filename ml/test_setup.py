import torch
from sentence_transformers import SentenceTransformer
import faiss
import sympy

print("PyTorch:", torch.__version__)
print("FAISS: OK")
print("SymPy:", sympy.__version__)

model = SentenceTransformer("all-MiniLM-L6-v2")
print("SBERT loaded:", model)
