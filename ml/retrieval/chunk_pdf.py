import fitz
import json
from langchain_text_splitters import RecursiveCharacterTextSplitter

def chunk_pdf(pdf_path, metadata, output_json):
    # Open the PDF file
    doc = fitz.open(pdf_path)
    
    # Extract text from all pages and join into one string
    text = ""
    for page in doc:
        text += page.get_text()
    
    # Split the text into chunks of 500 characters with 50 character overlap
    splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
    chunks = splitter.split_text(text)
    
    # Loop through each chunk and attach metadata
    result = []
    for i, chunk in enumerate(chunks):
        entry = {
            "chunk_index": i,
            "content": chunk,
            "subject": metadata["subject"],
            "grade": metadata["grade"],
            "unit": metadata["unit"],
            "topic": metadata["topic"],
            "lesson": metadata["lesson"]
        }
        result.append(entry)
    
    # Load existing chunks if file exists, otherwise start fresh
    try:
        with open(output_json, "r") as f:
            existing = json.load(f)
    except FileNotFoundError:
        existing = []
    
    # Append new chunks and save
    existing.extend(result)
    with open(output_json, "w") as f:
        json.dump(existing, f, indent=2)
    
    print(f"Done! Added {len(result)} chunks to {output_json}")


# --- Run it here ---
metadata = {
    "subject": "General Mathematics",
    "grade": "11",
    "unit": "your unit here",
    "topic": "your topic here",
    "lesson": "your lesson here"
}

try:
    chunk_pdf("general_math.pdf", metadata, "output_chunks.json")
except Exception as e:
    print(f"Error: {e}")