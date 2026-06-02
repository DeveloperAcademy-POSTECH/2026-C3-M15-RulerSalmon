from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from pathlib import Path
import tempfile

from server.synthesize import SynthesisRequest, synthesize_to_wav

app = FastAPI(title="MeloTTS POC Server")


class HTTPSynthesisRequest(BaseModel):
    text: str = Field(..., min_length=1)
    voiceId: str = Field(default="custom_ko_melotts_v1")


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/synthesize")
def synthesize(payload: HTTPSynthesisRequest):
    try:
        with tempfile.TemporaryDirectory() as tmp_dir:
            output_path = Path(tmp_dir) / "synth.wav"
            synthesize_to_wav(
                SynthesisRequest(text=payload.text, voice_id=payload.voiceId),
                output_path,
            )
            return FileResponse(output_path, media_type="audio/wav", filename="synth.wav")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
