"""
PC Troubleshooting Expert System - FastAPI backend
---------------------------------------------------
Architecture:  HTML/CSS/JS  ->  FastAPI (this file)  ->  SWI-Prolog  ->  Knowledge base

FastAPI does no reasoning of its own. For every request it starts
SWI-Prolog with prolog/bridge.pl, sends the request as JSON on standard
input and returns Prolog's JSON reply to the browser.

Run from the project folder:
    uvicorn backend.main:app --reload
Then open http://127.0.0.1:8000
"""

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Dict, Literal

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

ROOT = Path(__file__).resolve().parent.parent
PROLOG_DIR = ROOT / "prolog"
FRONTEND_DIR = ROOT / "frontend"

Answer = Literal["yes", "no", "unknown"]


def find_swipl() -> str:
    """Locate the swipl executable (PATH, SWIPL env variable, or default Windows install)."""
    candidates = [
        os.environ.get("SWIPL"),
        shutil.which("swipl"),
        r"C:\Program Files\swipl\bin\swipl.exe",
        r"C:\Program Files (x86)\swipl\bin\swipl.exe",
        "/Applications/SWI-Prolog.app/Contents/MacOS/swipl",
    ]
    for c in candidates:
        if c and Path(c).exists():
            return c
    raise RuntimeError(
        "SWI-Prolog (swipl) was not found. Install it from https://www.swi-prolog.org "
        "or set the SWIPL environment variable to the full path of swipl."
    )


SWIPL = find_swipl()


def ask_prolog(request: dict) -> dict:
    """Send one JSON request to the Prolog bridge and return its JSON reply."""
    proc = subprocess.run(
        [SWIPL, "-q", str(PROLOG_DIR / "bridge.pl")],
        input=json.dumps(request),
        capture_output=True,
        text=True,
        encoding="utf-8",
        cwd=PROLOG_DIR,
        timeout=20,
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        raise HTTPException(500, f"Prolog error: {proc.stderr.strip() or 'no output'}")
    reply = json.loads(proc.stdout)
    if "error" in reply:
        raise HTTPException(500, f"Prolog error: {reply['error']}")
    return reply


# ------------------------------------------------------------------ models
class ForwardRequest(BaseModel):
    known: Dict[str, Answer] = {}


class BackwardRequest(BaseModel):
    goal: str = "any"          # "any" or a fault id such as "psu_failure"
    known: Dict[str, Answer] = {}


# ------------------------------------------------------------------ app
app = FastAPI(title="PC Troubleshooting Expert System")


@app.get("/api/knowledge")
def knowledge():
    """All facts, rules and references (used by the Knowledge base page)."""
    return ask_prolog({"action": "meta"})


@app.post("/api/forward")
def forward(req: ForwardRequest):
    """Data-driven reasoning from the symptoms the user selected."""
    return ask_prolog({"action": "forward", "known": req.known})


@app.post("/api/backward")
def backward(req: BackwardRequest):
    """Goal-driven reasoning; returns the next question or a diagnosis."""
    return ask_prolog({"action": "backward", "goal": req.goal, "known": req.known})


@app.get("/")
def index():
    return FileResponse(FRONTEND_DIR / "index.html")


app.mount("/static", StaticFiles(directory=FRONTEND_DIR), name="static")
