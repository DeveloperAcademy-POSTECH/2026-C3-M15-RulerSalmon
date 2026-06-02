from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import math
import wave
import struct


@dataclass
class SynthesisRequest:
    text: str
    voice_id: str


def synthesize_to_wav(request: SynthesisRequest, output_path: Path, sample_rate: int = 24000) -> Path:
    """
    Placeholder synthesis implementation.

    Replace this with the actual MeloTTS inference bridge once the trained/exported
    model path is verified. For now this generates a short sine tone so that the
    remote iOS playback flow can be validated end to end.
    """
    duration_seconds = min(max(len(request.text) * 0.03, 0.7), 4.0)
    frequency = 440.0 if request.voice_id.endswith("v1") else 523.25

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)

        total_frames = int(duration_seconds * sample_rate)
        for index in range(total_frames):
            sample = 0.18 * math.sin(2 * math.pi * frequency * (index / sample_rate))
            value = int(max(min(sample, 1.0), -1.0) * 32767)
            wav_file.writeframes(struct.pack("<h", value))

    return output_path
