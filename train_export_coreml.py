"""Train separate Random Forest risk models and export them to Core ML.

This replaces the notebook's MultiOutputClassifier training step with four
independent RandomForestClassifier models, one for each risk target.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report


WINDOW_SIZE = 30
RANDOM_STATE = 42
N_ESTIMATORS = 100

PARTS = ["L_heel_", "L_ball_", "R_heel_", "R_ball_"]

FEATURE_COLUMNS = [
    "L_heel_temp_mean",
    "L_heel_temp_std",
    "L_heel_pressure_mean",
    "L_heel_pressure_std",
    "L_ball_temp_mean",
    "L_ball_temp_std",
    "L_ball_pressure_mean",
    "L_ball_pressure_std",
    "R_heel_temp_mean",
    "R_heel_temp_std",
    "R_heel_pressure_mean",
    "R_heel_pressure_std",
    "R_ball_temp_mean",
    "R_ball_temp_std",
    "R_ball_pressure_mean",
    "R_ball_pressure_std",
    "CrossFootDifference_temp_heel",
    "CrossFootDifference_temp_ball",
    "CrossFootDifference_pressure_heel",
    "CrossFootDifference_pressure_ball",
]

TARGET_COLUMNS = [
    "L_heel_risk",
    "L_ball_risk",
    "R_heel_risk",
    "R_ball_risk",
]

RAW_COLUMNS = [
    "L_heel_pressure",
    "L_ball_pressure",
    "L_heel_temp",
    "L_ball_temp",
    "R_heel_pressure",
    "R_ball_pressure",
    "R_heel_temp",
    "R_ball_temp",
    "L_heel_risk",
    "L_ball_risk",
    "R_heel_risk",
    "R_ball_risk",
]


def extract_features(data: pd.DataFrame, window_size: int = WINDOW_SIZE) -> pd.DataFrame:
    """Extract the same windowed features used by the original notebook."""
    rows = []

    for i in range(0, len(data) - window_size):
        current = data.iloc[i : i + window_size, :]
        features = {}

        for part in PARTS:
            features[f"{part}temp_mean"] = current[f"{part}temp"].mean()
            features[f"{part}temp_std"] = current[f"{part}temp"].std()
            features[f"{part}pressure_mean"] = current[f"{part}pressure"].mean()
            features[f"{part}pressure_std"] = current[f"{part}pressure"].std()
            features[f"{part}risk"] = int(current[f"{part}risk"].mode()[0])

        features["CrossFootDifference_temp_heel"] = (
            current["L_heel_temp"] - current["R_heel_temp"]
        ).mean()
        features["CrossFootDifference_temp_ball"] = (
            current["L_ball_temp"] - current["R_ball_temp"]
        ).mean()
        features["CrossFootDifference_pressure_heel"] = (
            current["L_heel_pressure"] - current["R_heel_pressure"]
        ).mean()
        features["CrossFootDifference_pressure_ball"] = (
            current["L_ball_pressure"] - current["R_ball_pressure"]
        ).mean()

        rows.append(features)

    features_df = pd.DataFrame(rows)
    features_df[TARGET_COLUMNS] = features_df[TARGET_COLUMNS].astype(int)
    return features_df


def read_raw_csv(path: Path) -> pd.DataFrame:
    data = pd.read_csv(path)
    missing_columns = [column for column in RAW_COLUMNS if column not in data.columns]
    if missing_columns:
        raise ValueError(f"{path} is missing columns: {', '.join(missing_columns)}")
    return data


def generate_training_csv(path: Path) -> None:
    """Generate the same simulated training CSV as Simulate_Data.py."""
    import Simulate_Data

    rng_state = np.random.get_state()
    working_dir = Path.cwd()
    np.random.seed(RANDOM_STATE)

    try:
        os.chdir(path.parent)
        path.write_text(",".join(RAW_COLUMNS) + "\n", encoding="utf-8")

        activities = ["walking", "lying", "standing"]
        inflammation_patterns = [
            [0, 0, 0, 0],
            [2.2, 0, 0, 0],
            [0, 2.2, 0, 0],
            [0, 0, 2.2, 0],
            [0, 0, 0, 2.2],
            [0, 0, 2.2, 2.2],
            [0, 2.2, 0, 2.2],
            [2.2, 0, 0, 2.2],
            [0, 2.2, 2.2, 0],
            [2.2, 0, 2.2, 0],
            [2.2, 2.2, 0, 0],
            [0, 2.2, 2.2, 2.2],
            [2.2, 2.2, 0, 2.2],
            [2.2, 2.2, 2.2, 0],
            [2.2, 0, 2.2, 2.2],
            [2.2, 2.2, 2.2, 2.2],
        ]
        imbalance_patterns = [[0, 0], [1, 0], [0, 1]]

        for activity in activities:
            for inflammation in inflammation_patterns:
                for imbalance in imbalance_patterns:
                    Simulate_Data.simulate_activity(60, activity, inflammation, imbalance)
    finally:
        os.chdir(working_dir)
        np.random.set_state(rng_state)


def load_or_create_training_data(path: Path) -> pd.DataFrame:
    if not path.exists():
        generate_training_csv(path)
    return read_raw_csv(path)


def export_coreml_model(model: RandomForestClassifier, target: str, output_path: Path) -> None:
    try:
        import coremltools as ct
    except ImportError as exc:
        raise RuntimeError(
            "coremltools is required to export .mlmodel files. Install it with "
            "`python -m pip install coremltools` and rerun this script."
        ) from exc

    coreml_model = ct.converters.sklearn.convert(
        model,
        input_features=FEATURE_COLUMNS,
        output_feature_names=target,
    )
    coreml_model.short_description = f"Predicts {target} from smart sock window features."
    coreml_model.author = "DiabeticsSmartSock"
    coreml_model.license = "See repository license"

    for feature_name in FEATURE_COLUMNS:
        coreml_model.input_description[feature_name] = (
            f"{feature_name}, calculated over a {WINDOW_SIZE}-sample window"
        )
    coreml_model.output_description[target] = f"Predicted class for {target}"
    coreml_model.save(str(output_path))


def train_models(features: pd.DataFrame) -> dict[str, RandomForestClassifier]:
    x_train = features[FEATURE_COLUMNS]
    models = {}

    for target in TARGET_COLUMNS:
        model = RandomForestClassifier(n_estimators=N_ESTIMATORS, random_state=RANDOM_STATE)
        model.fit(x_train, features[target])
        models[target] = model

    return models


def print_training_reports(
    models: dict[str, RandomForestClassifier],
    features: pd.DataFrame,
    targets: Iterable[str] = TARGET_COLUMNS,
) -> None:
    x_train = features[FEATURE_COLUMNS]

    for target in targets:
        prediction = models[target].predict(x_train)
        print(f"--- {target} ---")
        print(classification_report(features[target], prediction, zero_division=0))


def main() -> None:
    repo_root = Path(__file__).resolve().parent
    training_csv = repo_root / "simulated_data_training.csv"

    raw_training_data = load_or_create_training_data(training_csv)
    training_features = extract_features(raw_training_data)
    models = train_models(training_features)

    print_training_reports(models, training_features)

    for target, model in models.items():
        joblib.dump(model, repo_root / f"{target}.pkl")
        export_coreml_model(model, target, repo_root / f"{target}.mlmodel")


if __name__ == "__main__":
    main()
