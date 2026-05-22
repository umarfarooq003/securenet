"""
Messa Simulation API — FastAPI wrapper for NetworkInfectionModel
Vercel-compatible: no WebSocket, no long-running threads.
Run locally with: uvicorn api.index:app --host 0.0.0.0 --port 8001 --reload
"""

import sys
import os
import json
import threading

# ── ensure messa.py and CSV files are importable ──────────────────────────────
# On Vercel, __file__ = /var/task/api/index.py
# ROOT_DIR          = /var/task  (where messa.py, nodes.csv, edges.csv live)
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT_DIR)

# Also change CWD so os.path.exists('nodes.csv') in messa.py works
os.chdir(ROOT_DIR)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List

import io
from contextlib import redirect_stdout

try:
    from messa import NetworkInfectionModel, DeviceType  # type: ignore
    _IMPORT_ERROR: Optional[str] = None
except Exception as _e:
    _IMPORT_ERROR = str(_e)
    NetworkInfectionModel = None  # type: ignore
    DeviceType = None  # type: ignore

# ── App ────────────────────────────────────────────────────────────────────────
app = FastAPI(title="Messa Network Infection Simulator API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Global simulation state ────────────────────────────────────────────────────
_model: Optional[NetworkInfectionModel] = None
_lock = threading.Lock()


# ── Pydantic schemas ───────────────────────────────────────────────────────────
class SimConfig(BaseModel):
    simulation_speed: float = 1.0
    infection_probability: float = 0.7
    recovery_chance: float = 0.1
    virus_spread_chance: float = 1.0
    initial_outbreak_size: int = 1
    virus_check_frequency: float = 0.05
    gain_resistance_chance: float = 0.5


class RunConfig(BaseModel):
    simulation_speed: float = 1.0
    infection_probability: float = 0.7
    recovery_chance: float = 0.1
    virus_spread_chance: float = 1.0
    initial_outbreak_size: int = 1
    virus_check_frequency: float = 0.05
    gain_resistance_chance: float = 0.5
    max_steps: int = 50  # Safety limit for Vercel timeout


# ── Helper: serialise current model state ─────────────────────────────────────
def _snapshot(model: NetworkInfectionModel) -> dict:
    infected   = model.count_infected_devices()
    recovered  = model.count_recovered_devices()
    resistant  = model.count_resistant_devices()
    total      = len(model.devices)
    healthy    = max(0, total - infected - recovered - resistant)

    devices = [
        {
            "id":             d.unique_id,
            "name":           d.name,
            "device_type":    d.device_type.value,
            "ip":             d.ip,
            "infected":       d.infected,
            "recovered":      (not d.infected and d.infection_time is not None),
            "resistant":      d.has_resistance,
            "security_level": round(d.security_level, 3),
            "connections":    [c.unique_id for c in d.connections],
        }
        for d in model.devices
    ]

    return {
        "step":                   model.schedule.time,
        "total_devices":          total,
        "infected_count":         infected,
        "recovered_count":        recovered,
        "resistant_count":        resistant,
        "healthy_count":          healthy,
        "infection_rate":         round((infected / total) * 100, 2) if total else 0.0,
        "new_infections":         model.new_infections_this_step,
        "recovered_devices":      model.recovered_devices_this_step,
        "new_resistance":         model.new_resistance_this_step,
        "successful_detections":  model.successful_detections_this_step,
        "devices":                devices,
    }


# ── Endpoints ──────────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"status": "ok", "service": "messa-api", "version": "1.0.0",
            "messa_loaded": _IMPORT_ERROR is None,
            "import_error": _IMPORT_ERROR}


@app.get("/health")
def health():
    return {"status": "ok", "service": "messa-api",
            "messa_loaded": _IMPORT_ERROR is None,
            "import_error": _IMPORT_ERROR}


@app.post("/simulation/setup")
def setup(config: SimConfig):
    global _model
    with _lock:
        _model = NetworkInfectionModel(
            simulation_speed       = config.simulation_speed,
            infection_probability  = config.infection_probability,
            recovery_chance        = config.recovery_chance,
            virus_spread_chance    = config.virus_spread_chance,
            initial_outbreak_size  = config.initial_outbreak_size,
            virus_check_frequency  = config.virus_check_frequency,
            gain_resistance_chance = config.gain_resistance_chance,
        )
        _model.infect_initial_device()
        _model.running = False
    return {"status": "ready", "device_count": len(_model.devices)}


@app.post("/simulation/step")
def step_once():
    if _model is None:
        return {"error": "No simulation loaded. POST /simulation/setup first."}
    with _lock:
        _model.running = True
        _model.paused  = False
        _model.step()
        _model.running = False
    return _snapshot(_model)


@app.get("/simulation/status")
def status():
    if _model is None:
        return {"error": "No simulation loaded."}
    return _snapshot(_model)


@app.post("/simulation/reset")
def reset():
    global _model
    with _lock:
        _model = None
    return {"status": "reset"}


@app.get("/simulation/topology")
def topology():
    if _model is None:
        return {"error": "No simulation loaded."}
    nodes = [
        {"id": d.unique_id, "name": d.name,
         "type": d.device_type.value, "ip": d.ip}
        for d in _model.devices
    ]
    edges, seen = [], set()
    for d in _model.devices:
        for c in d.connections:
            key = tuple(sorted([d.unique_id, c.unique_id]))
            if key not in seen:
                seen.add(key)
                edges.append({"source": d.unique_id, "target": c.unique_id})
    return {"nodes": nodes, "edges": edges}


# ── /simulation/run — Full simulation in ONE HTTP call ────────────────────────
# WebSocket is NOT supported on Vercel serverless functions.
# This endpoint runs the entire simulation synchronously and returns all steps.
@app.post("/simulation/run")
def run_simulation(config: RunConfig):
    """
    Sets up a fresh simulation, runs it to completion (or max_steps),
    and returns ALL step snapshots in a single JSON response.
    
    Use this instead of WebSocket on Vercel.
    Flutter app can call this once and get all simulation data.
    """
    global _model

    # Suppress verbose print() output from messa.py (126+ lines per call)
    # which significantly slows down Vercel serverless functions.
    _sink = io.StringIO()

    with redirect_stdout(_sink):
        # Build model
        model = NetworkInfectionModel(
            simulation_speed       = config.simulation_speed,
            infection_probability  = config.infection_probability,
            recovery_chance        = config.recovery_chance,
            virus_spread_chance    = config.virus_spread_chance,
            initial_outbreak_size  = config.initial_outbreak_size,
            virus_check_frequency  = config.virus_check_frequency,
            gain_resistance_chance = config.gain_resistance_chance,
        )
        model.infect_initial_device()
        model.running = True
        model.paused  = False

        # Store as global so /simulation/status can also read it
        with _lock:
            _model = model

        steps = []
        # Vercel free tier: 10-second function timeout.
        # Hard cap = 15 steps to ensure we finish in time.
        max_steps = min(config.max_steps, 15)

        for _ in range(max_steps):
            if not model.running:
                break

            model.step()
            snap = _snapshot(model)
            steps.append(snap)

            # Stop early if all devices are infected (simulation complete)
            if model.count_infected_devices() >= len(model.devices):
                break

            # Stop if infection died out (no more infected)
            if model.count_infected_devices() == 0 and model.schedule.time > 5:
                break

        model.running = False

    return {
        "status":       "completed",
        "total_steps":  len(steps),
        "device_count": len(model.devices),
        "final_state":  steps[-1] if steps else {},
        "steps":        steps,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("index:app", host="0.0.0.0", port=8001, reload=True)
