import json
import os

transcript_path = r"C:\Users\amosl\.gemini\antigravity-ide\brain\a336d7c9-107d-4cb8-b89b-2c5e7cd264e4\.system_generated\logs\transcript.jsonl"
output_path = r"c:\app\kata video editor\scratch_user_request.txt"

if os.path.exists(transcript_path):
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                if data.get("step_index") == 2440:
                    with open(output_path, 'w', encoding='utf-8') as out:
                        out.write(data["content"])
                    print("Successfully extracted step 2440 content!")
                    break
            except Exception as e:
                pass
else:
    print("Transcript not found at", transcript_path)
