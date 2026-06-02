# Remote TTS Server

This server exists to validate the iOS UI and playback flow before local ONNX inference is fully available.

## Run
```bash
cd melotts-ios-poc
source .venv/bin/activate
uvicorn server.app:app --reload --port 8000
```

## Endpoint
`POST /synthesize`

Request body:
```json
{
  "text": "안녕하세요.",
  "voiceId": "custom_ko_melotts_v1"
}
```

Response:
- `audio/wav`

## Notes
- This server is intentionally simple.
- By default it can run in a placeholder mode that returns a generated tone if no real model backend is wired in yet.
- Replace `server/synthesize.py` internals with the actual MeloTTS inference adapter once the training/export path is verified.
