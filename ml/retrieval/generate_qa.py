import json
import requests
import time

# Load chunks
with open("output_chunks.json", "r") as f:
    chunks = json.load(f)

# Ollama API endpoint
OLLAMA_URL = "http://localhost:11434/api/generate"

# Store Q&A pairs
qa_pairs = []

# Loop through chunks and generate Q&A
for i, chunk in enumerate(chunks):
    print(f"Processing chunk {i+1}/{len(chunks)}...")
    
    content = chunk["content"]
    
    # Create prompt for Ollama
    prompt = f"""Generate 2-3 question-answer pairs from this math content:

{content}

Return ONLY valid JSON with this structure:
[
  {{"question": "...", "answer": "..."}},
  {{"question": "...", "answer": "..."}}
]

Do not include any explanation, just the JSON."""
    
    try:
        # Call Ollama
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": "llama3",
                "prompt": prompt,
                "stream": False
            }
        )
        
        # Extract response
        if response.status_code == 200:
            result = response.json()
            generated_text = result["response"]
            
            # Try to parse JSON from response
            try:
                qa_list = json.loads(generated_text)
                for qa in qa_list:
                    qa["chunk_id"] = chunk["chunk_index"]
                    qa_pairs.append(qa)
            except json.JSONDecodeError:
                print(f"  Warning: Could not parse JSON for chunk {i}")
        
        # Small delay to avoid overwhelming Ollama
        time.sleep(0.5)
        
    except Exception as e:
        print(f"  Error processing chunk {i}: {e}")

# Save Q&A pairs
with open("genmath_qa_pairs.json", "w") as f:
    json.dump(qa_pairs, f, indent=2)

print(f"\nDone! Generated {len(qa_pairs)} Q&A pairs")