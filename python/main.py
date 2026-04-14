from fastapi import FastAPI
from pydantic import BaseModel
from typing import Any, Dict, List
from pathlib import Path
from dataclasses import dataclass
import json
import joblib
import random
import pandas as pd



app = FastAPI()

BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "models"
DATA_DIR = BASE_DIR / "data"

MODEL_DIR.mkdir(parents=True, exist_ok=True)
DATA_DIR.mkdir(parents=True, exist_ok=True)

MODEL_PATH = MODEL_DIR / "boss_model.joblib"
DATASET_PATH = DATA_DIR / "boss_training_samples.jsonl"

print(f"ACTIVE DATASET PATH: {DATASET_PATH}", flush=True)


class DecisionRequest(BaseModel):
    timestamp: float | None = None
    player_behavior: Dict[str, Any] = {}
    player_state: Dict[str, Any] = {}
    boss_state: Dict[str, Any] = {}
    boss_recent_actions: List[str] = []


ACTION_LABELS = [
    "idle",
    "light_attack",
    "heavy_attack",
    "stomp",
    "punish",
    "backstep",
    "feint",
    "phase_transition",
]


@dataclass
class FightMemory:
    start_timestamp: float = -1.0
    last_timestamp: float = -1.0
    fight_age: float = 0.0

    greedy_memory: float = 0.0
    parry_memory: float = 0.0
    dash_memory: float = 0.0
    heal_memory: float = 0.0

    observed_attack_chain: float = 0.0
    player_low_hp_pressure: float = 0.0

    def reset(self) -> None:
        self.start_timestamp = -1.0
        self.last_timestamp = -1.0
        self.fight_age = 0.0

        self.greedy_memory = 0.0
        self.parry_memory = 0.0
        self.dash_memory = 0.0
        self.heal_memory = 0.0

        self.observed_attack_chain = 0.0
        self.player_low_hp_pressure = 0.0

    def update(self, payload: Dict[str, Any]) -> None:
        pb = payload.get("player_behavior", {})
        ps = payload.get("player_state", {})
        bs = payload.get("boss_state", {})

        timestamp = float(payload.get("timestamp", 0.0))
        boss_hp = float(bs.get("hp", 0.0))
        boss_max_hp = float(bs.get("max_hp", 1.0))
        player_hp = float(ps.get("hp", 0.0))
        player_max_hp = float(ps.get("max_hp", 1.0))

        # Likely new fight
        if self.last_timestamp >= 0.0:
            boss_hp_ratio = boss_hp / max(1.0, boss_max_hp)
            if timestamp < self.last_timestamp or (boss_hp_ratio >= 0.98 and self.fight_age > 5.0):
                self.reset()

        if self.start_timestamp < 0.0:
            self.start_timestamp = timestamp

        self.last_timestamp = timestamp
        self.fight_age = max(0.0, timestamp - self.start_timestamp)

        greedy_score = float(pb.get("greedy_score", 0.0))
        parry_score = float(pb.get("parry_score", 0.0))
        dash_score = float(pb.get("dash_score", 0.0))
        heal_score = float(pb.get("heal_score", 0.0))
        attack_chain = float(pb.get("attack_chain_count", 0.0))

        player_parrying = bool(ps.get("is_parrying", False))
        player_healing = bool(ps.get("is_healing", False))

        # Smooth fight memory
        self.greedy_memory = self.greedy_memory * 0.88 + greedy_score * 0.12
        self.parry_memory = self.parry_memory * 0.88 + (parry_score + (0.35 if player_parrying else 0.0)) * 0.12
        self.dash_memory = self.dash_memory * 0.88 + dash_score * 0.12
        self.heal_memory = self.heal_memory * 0.88 + (heal_score + (0.35 if player_healing else 0.0)) * 0.12
        self.observed_attack_chain = self.observed_attack_chain * 0.85 + attack_chain * 0.15

        player_hp_ratio = player_hp / max(1.0, player_max_hp)
        self.player_low_hp_pressure = 1.0 - player_hp_ratio

    def evolution_factor(self) -> float:
        # 0.0 early fight → 1.0 late fight
        return min(1.0, self.fight_age / 35.0)


FIGHT_MEMORY = FightMemory()


def bool_to_int(value: bool) -> int:
    return 1 if value else 0


def extract_features(payload: Dict[str, Any]) -> Dict[str, float]:
    pb = payload.get("player_behavior", {})
    ps = payload.get("player_state", {})
    bs = payload.get("boss_state", {})
    history = payload.get("boss_recent_actions", [])

    player_hp = float(ps.get("hp", 0))
    player_max_hp = float(ps.get("max_hp", 0))
    boss_hp = float(bs.get("hp", 0))
    boss_max_hp = float(bs.get("max_hp", 0))

    return {
        "distance_to_player": float(bs.get("distance_to_player", 99999.0)),
        "player_hp": player_hp,
        "player_max_hp": player_max_hp,
        "player_hp_ratio": player_hp / max(1.0, player_max_hp),
        "boss_hp": boss_hp,
        "boss_max_hp": boss_max_hp,
        "boss_hp_ratio": boss_hp / max(1.0, boss_max_hp),
        "dash_score": float(pb.get("dash_score", 0.0)),
        "parry_score": float(pb.get("parry_score", 0.0)),
        "heal_score": float(pb.get("heal_score", 0.0)),
        "jump_score": float(pb.get("jump_score", 0.0)),
        "greedy_score": float(pb.get("greedy_score", 0.0)),
        "light_attack_score": float(pb.get("light_attack_score", 0.0)),
        "heavy_attack_score": float(pb.get("heavy_attack_score", 0.0)),
        "slam_attack_score": float(pb.get("slam_attack_score", 0.0)),
        "close_range_time": float(pb.get("close_range_time", 0.0)),
        "far_range_time": float(pb.get("far_range_time", 0.0)),
        "attack_chain_count": float(pb.get("attack_chain_count", 0)),
        "highest_attack_chain": float(pb.get("highest_attack_chain", 0)),
        "light_attack_count": float(pb.get("light_attack_count", 0)),
        "heavy_attack_count": float(pb.get("heavy_attack_count", 0)),
        "slam_attack_count": float(pb.get("slam_attack_count", 0)),
        "time_since_last_attack": float(pb.get("time_since_last_attack", 99999.0)),
        "time_since_last_dash": float(pb.get("time_since_last_dash", 99999.0)),
        "time_since_last_parry": float(pb.get("time_since_last_parry", 99999.0)),
        "time_since_last_heal": float(pb.get("time_since_last_heal", 99999.0)),
        "time_since_last_jump": float(pb.get("time_since_last_jump", 99999.0)),
        "is_parrying": bool_to_int(bool(ps.get("is_parrying", False))),
        "is_healing": bool_to_int(bool(ps.get("is_healing", False))),
        "is_attacking": bool_to_int(bool(ps.get("is_attacking", False))),
        "is_charging_attack": bool_to_int(bool(ps.get("is_charging_attack", False))),
        "parry_successful": bool_to_int(bool(ps.get("parry_successful", False))),
        "boss_phase": float(bs.get("phase", 1)),
        "in_phase_2": bool_to_int(bool(bs.get("in_phase_2", False))),
        "player_in_range": bool_to_int(bool(bs.get("player_in_range", False))),
        "can_normal": bool_to_int(bool(bs.get("can_normal", True))),
        "can_heavy": bool_to_int(bool(bs.get("can_heavy", True))),
        "can_stomp": bool_to_int(bool(bs.get("can_stomp", True))),
        "can_punish": bool_to_int(bool(bs.get("can_punish", True))),
        "can_backstep": bool_to_int(bool(bs.get("can_backstep", True))),
        "can_feint": bool_to_int(bool(bs.get("can_feint", True))),
        "can_phase_transition": bool_to_int(bool(bs.get("can_phase_transition", False))),
        "last_was_normal": bool_to_int(len(history) > 0 and history[-1] == "normal"),
        "last_was_heavy": bool_to_int(len(history) > 0 and history[-1] == "heavy"),
        "last_was_stomp": bool_to_int(len(history) > 0 and history[-1] == "stomp"),
        "last_was_backstep": bool_to_int(len(history) > 0 and history[-1] == "backstep"),
        "last_was_punish": bool_to_int(len(history) > 0 and history[-1] == "punish"),
        "last_was_feint": bool_to_int(len(history) > 0 and history[-1] == "feint"),
    }


def is_valid_payload(payload: Dict[str, Any]) -> bool:
    bs = payload.get("boss_state", {})

    if not bs:
        return False

    distance = float(bs.get("distance_to_player", 99999.0))
    if distance >= 99999.0:
        return False

    return True


def log_sample(payload: Dict[str, Any], chosen_action: str, source: str) -> None:
    if not is_valid_payload(payload):
        print("SKIP SAMPLE: invalid payload", flush=True)
        return

    # Skip idle completely so the dataset focuses on real attacks
    if chosen_action == "idle":
        print("SKIP SAMPLE: idle", flush=True)
        return

    distance = float(payload["boss_state"].get("distance_to_player", 99999.0))
    player_hp = float(payload.get("player_state", {}).get("hp", 0))
    boss_hp = float(payload.get("boss_state", {}).get("hp", 0))
    boss_state = str(payload.get("boss_state", {}).get("state", "none"))

    record = {
        "features": extract_features(payload),
        "label": chosen_action,
        "source": source,
        "payload": payload,
    }

    print(
        f"SAVING SAMPLE: {chosen_action} | "
        f"state={boss_state} | dist={distance:.2f} | "
        f"player_hp={player_hp:.0f} | boss_hp={boss_hp:.0f}",
        flush=True,
    )

    with DATASET_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")


def load_model_bundle():
    if not MODEL_PATH.exists():
        return None

    try:
        bundle = joblib.load(MODEL_PATH)

        if isinstance(bundle, dict) and "model" in bundle:
            return bundle

        if hasattr(bundle, "predict"):
            return {"model": bundle, "feature_columns": None}

        return None
    except Exception as e:
        print(f"LOAD MODEL ERROR: {e}", flush=True)
        return None


def predict_with_model(bundle, features: Dict[str, float]) -> str:
    model = bundle["model"]
    feature_columns = bundle.get("feature_columns")

    row_df = pd.DataFrame([features]).fillna(0)

    if feature_columns:
        for col in feature_columns:
            if col not in row_df.columns:
                row_df[col] = 0.0
        row_df = row_df[feature_columns]

    prediction = model.predict(row_df)[0]
    return str(prediction)


def adapt_action(action: str, payload: Dict[str, Any]) -> str:
    pb = payload.get("player_behavior", {})
    ps = payload.get("player_state", {})
    bs = payload.get("boss_state", {})

    FIGHT_MEMORY.update(payload)

    distance = float(bs.get("distance_to_player", 99999.0))

    greedy_score = float(pb.get("greedy_score", 0.0))
    parry_score = float(pb.get("parry_score", 0.0))
    dash_score = float(pb.get("dash_score", 0.0))
    attack_chain = int(pb.get("attack_chain_count", 0))

    player_attacking = bool(ps.get("is_attacking", False))
    player_parrying = bool(ps.get("is_parrying", False))
    player_healing = bool(ps.get("is_healing", False))
    player_charging = bool(ps.get("is_charging_attack", False))

    can_normal = bool(bs.get("can_normal", True))
    can_heavy = bool(bs.get("can_heavy", True))
    can_stomp = bool(bs.get("can_stomp", True))
    can_punish = bool(bs.get("can_punish", True))
    can_backstep = bool(bs.get("can_backstep", True))
    can_feint = bool(bs.get("can_feint", True))

    evo = FIGHT_MEMORY.evolution_factor()

    effective_greedy = greedy_score + FIGHT_MEMORY.greedy_memory * (0.6 + 0.8 * evo)
    effective_parry = parry_score + FIGHT_MEMORY.parry_memory * (0.6 + 0.8 * evo)
    effective_dash = dash_score + FIGHT_MEMORY.dash_memory * (0.6 + 0.8 * evo)
    effective_heal = FIGHT_MEMORY.heal_memory * (0.7 + 0.9 * evo)
    effective_chain = attack_chain + FIGHT_MEMORY.observed_attack_chain * (0.5 + 0.7 * evo)

    aggression_bias = 0.15 + 0.45 * evo + 0.25 * FIGHT_MEMORY.player_low_hp_pressure

    # hard counters
    if player_healing and distance <= 105 and can_heavy:
        return "heavy_attack"

    if effective_heal >= 0.18 and distance <= 110 and can_punish:
        return "punish"

    # evolves into anti-parry play
    if can_feint and (player_parrying or effective_parry >= 0.18):
        feint_chance = 0.20 + 0.45 * evo
        if random.random() < feint_chance:
            return "feint"

    # evolves into anti-pressure play
    if can_backstep and distance <= 65:
        backstep_pressure = (
            (0.20 if player_attacking else 0.0)
            + min(0.35, effective_greedy * 0.8)
            + min(0.30, effective_chain * 0.08)
        )
        if random.random() < min(0.75, backstep_pressure + 0.15 * evo):
            return "backstep"

    # evolves into punish-heavy play
    if can_punish and distance <= 75:
        punish_pressure = (
            (0.25 if player_attacking else 0.0)
            + (0.25 if player_charging else 0.0)
            + min(0.30, effective_chain * 0.07)
        )
        if random.random() < min(0.80, punish_pressure + 0.18 * evo):
            return "punish"

    # anti-dash at range grows stronger late fight
    if can_stomp and distance >= 140:
        stomp_pressure = min(0.65, effective_dash * 0.9) + 0.10 * evo
        if random.random() < stomp_pressure:
            return "stomp"

    # less passive as fight continues
    if action == "idle":
        if distance <= 45 and can_normal and random.random() < 0.55 + aggression_bias * 0.2:
            return "light_attack"
        if distance <= 100 and can_heavy and random.random() < 0.45 + aggression_bias * 0.25:
            return "heavy_attack"
        if distance > 100 and can_stomp and random.random() < 0.35 + aggression_bias * 0.2:
            return "stomp"

    # small late-fight nudges
    if action == "light_attack" and can_heavy and distance <= 85 and random.random() < 0.10 + 0.20 * evo:
        return "heavy_attack"

    if action == "heavy_attack" and can_punish and distance <= 55 and player_attacking and random.random() < 0.12 + 0.20 * evo:
        return "punish"

    if action == "stomp" and can_backstep and distance <= 55 and effective_greedy >= 0.15 and random.random() < 0.10 + 0.18 * evo:
        return "backstep"

    return action


def rule_decision(payload: Dict[str, Any]) -> Dict[str, str]:
    pb = payload.get("player_behavior", {})
    ps = payload.get("player_state", {})
    bs = payload.get("boss_state", {})
    history = payload.get("boss_recent_actions", [])

    distance = float(bs.get("distance_to_player", 99999.0))

    can_normal = bool(bs.get("can_normal", True))
    can_heavy = bool(bs.get("can_heavy", True))
    can_stomp = bool(bs.get("can_stomp", True))
    can_punish = bool(bs.get("can_punish", True))
    can_backstep = bool(bs.get("can_backstep", True))
    can_feint = bool(bs.get("can_feint", True))
    can_phase = bool(bs.get("can_phase_transition", False))

    greedy_score = float(pb.get("greedy_score", 0.0))
    parry_score = float(pb.get("parry_score", 0.0))
    dash_score = float(pb.get("dash_score", 0.0))
    attack_chain = int(pb.get("attack_chain_count", 0))

    player_healing = bool(ps.get("is_healing", False))
    player_parrying = bool(ps.get("is_parrying", False))
    player_attacking = bool(ps.get("is_attacking", False))
    player_charging = bool(ps.get("is_charging_attack", False))
    parry_successful = bool(ps.get("parry_successful", False))

    def repeated(action_name: str) -> bool:
        return len(history) > 0 and history[-1] == action_name

    def add_weighted(choices: List[str], action: str, weight: int) -> None:
        for _ in range(max(0, weight)):
            choices.append(action)

    if can_phase:
        return {"action": "phase_transition", "reason": "boss_hp_threshold"}

    if player_healing and distance <= 100 and can_heavy:
        return {"action": "heavy_attack", "reason": "punish_heal"}

    if distance <= 70 and can_punish and (player_attacking or player_charging):
        return {"action": "punish", "reason": "punish_commitment"}

    choices: List[str] = []

    if can_feint:
        if player_parrying or parry_successful:
            add_weighted(choices, "feint", 6)
        elif parry_score >= 0.1:
            add_weighted(choices, "feint", 4)

    if can_backstep and distance <= 60:
        if player_attacking:
            add_weighted(choices, "backstep", 5)
        if attack_chain >= 2:
            add_weighted(choices, "backstep", 4)
        if greedy_score >= 0.1:
            add_weighted(choices, "backstep", 3)
        if dash_score >= 0.2:
            add_weighted(choices, "backstep", 2)

    if can_punish and distance <= 80:
        if player_attacking:
            add_weighted(choices, "punish", 3)
        if player_charging:
            add_weighted(choices, "punish", 4)
        if attack_chain >= 2:
            add_weighted(choices, "punish", 3)

    if distance <= 40:
        if can_normal and not repeated("normal"):
            add_weighted(choices, "light_attack", 5)
        if can_heavy and not repeated("heavy"):
            add_weighted(choices, "heavy_attack", 3)

    elif distance <= 100:
        if can_heavy and not repeated("heavy"):
            add_weighted(choices, "heavy_attack", 4)
        if can_normal:
            add_weighted(choices, "light_attack", 2)
        if can_stomp:
            add_weighted(choices, "stomp", 1)

    elif distance <= 180:
        if can_stomp and not repeated("stomp"):
            add_weighted(choices, "stomp", 3)
        if can_heavy:
            add_weighted(choices, "heavy_attack", 2)
        if can_backstep:
            add_weighted(choices, "backstep", 1)

    else:
        if can_stomp:
            add_weighted(choices, "stomp", 3)
        if can_heavy:
            add_weighted(choices, "heavy_attack", 2)
        add_weighted(choices, "idle", 1)

    if not choices:
        return {"action": "idle", "reason": "no_valid_action"}

    action = random.choice(choices)

    reasons = {
        "light_attack": "close_pressure",
        "heavy_attack": "mid_pressure",
        "stomp": "long_range_control",
        "punish": "punish_commitment",
        "backstep": "escape_pressure",
        "feint": "bait_parry",
        "phase_transition": "boss_hp_threshold",
        "idle": "fallback_idle",
    }

    return {"action": action, "reason": reasons.get(action, "weighted_choice")}


@app.get("/")
def root():
    return {"message": "Boss AI API is running"}


@app.get("/model_status")
def model_status():
    return {
        "model_exists": MODEL_PATH.exists(),
        "dataset_exists": DATASET_PATH.exists(),
    }


@app.post("/decide_action")
def decide_action(data: DecisionRequest):
    payload = data.model_dump()

    distance = float(payload.get("boss_state", {}).get("distance_to_player", 99999.0))
    state_name = str(payload.get("boss_state", {}).get("state", "none"))
    print(f"REQUEST RECEIVED | state={state_name} | dist={distance:.2f}", flush=True)

    features = extract_features(payload)
    bundle = load_model_bundle()

    if bundle is not None:
        try:
            ml_action = predict_with_model(bundle, features)
            action = adapt_action(ml_action, payload)

            if action not in ACTION_LABELS:
                action = "idle"

            print(
                f"ML EVOLVE | base={ml_action} | final={action} | "
                f"fight_age={FIGHT_MEMORY.fight_age:.2f} | evo={FIGHT_MEMORY.evolution_factor():.2f} | "
                f"greedy_mem={FIGHT_MEMORY.greedy_memory:.2f} | "
                f"parry_mem={FIGHT_MEMORY.parry_memory:.2f} | "
                f"dash_mem={FIGHT_MEMORY.dash_memory:.2f}",
                flush=True,
            )

            log_sample(payload, action, "ml")
            return {"action": action, "reason": "ml_prediction_adapted"}
        except Exception as e:
            print(f"ML ERROR: {e}", flush=True)

    result = rule_decision(payload)
    log_sample(payload, result["action"], "rules")
    return result