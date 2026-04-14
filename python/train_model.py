from pathlib import Path
import json
import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier

BASE_DIR = Path(__file__).resolve().parent
DATASET_PATH = BASE_DIR / "data" / "boss_training_samples.jsonl"
MODEL_PATH = BASE_DIR / "models" / "boss_model.joblib"

VALID_LABELS = {
    "light_attack",
    "heavy_attack",
    "stomp",
    "punish",
    "backstep",
    "feint",
    "phase_transition",
}


def is_valid_row(row: dict) -> bool:
    if not isinstance(row, dict):
        return False

    features = row.get("features")
    label = row.get("label")

    if not isinstance(features, dict) or not features:
        return False

    # Ignore idle completely
    if label not in VALID_LABELS:
        return False

    distance = float(features.get("distance_to_player", 99999.0))
    if distance >= 99999.0:
        return False

    return True


def load_rows():
    rows = []
    skipped = 0

    if not DATASET_PATH.exists():
        print("No training data found.")
        return rows, skipped

    with DATASET_PATH.open("r", encoding="utf-8") as f:
        for line_number, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                skipped += 1
                continue

            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                print(f"Skipping invalid JSON on line {line_number}")
                skipped += 1
                continue

            if not is_valid_row(row):
                skipped += 1
                continue

            rows.append(row)

    return rows, skipped


def main():
    rows, skipped = load_rows()

    if not rows:
        print("No usable training rows found.")
        print(f"Skipped rows: {skipped}")
        return

    features = []
    labels = []

    for row in rows:
        features.append(row["features"])
        labels.append(row["label"])

    df = pd.DataFrame(features).fillna(0)

    if df.empty:
        print("No usable feature rows found after DataFrame conversion.")
        return

    feature_columns = list(df.columns)

    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=8,
        random_state=42,
        class_weight="balanced"
    )
    model.fit(df, labels)

    bundle = {
        "model": model,
        "feature_columns": feature_columns,
    }

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(bundle, MODEL_PATH)

    print(f"Accepted rows: {len(df)}")
    print(f"Skipped rows: {skipped}")
    print("Label counts:")
    print(pd.Series(labels).value_counts())
    print(f"Model saved to: {MODEL_PATH}")


if __name__ == "__main__":
    main()