# Diabetic Smart Sock Core ML Feature Contract

The Core ML exports are four separate `RandomForestClassifier` models trained with the same feature extraction approach as the original notebook.

## Window Size

Features are calculated over a sliding window of **30 samples**.

## Feature Order

The iOS app must pass features to every Core ML model in this exact order:

1. `L_heel_temp_mean`
2. `L_heel_temp_std`
3. `L_heel_pressure_mean`
4. `L_heel_pressure_std`
5. `L_ball_temp_mean`
6. `L_ball_temp_std`
7. `L_ball_pressure_mean`
8. `L_ball_pressure_std`
9. `R_heel_temp_mean`
10. `R_heel_temp_std`
11. `R_heel_pressure_mean`
12. `R_heel_pressure_std`
13. `R_ball_temp_mean`
14. `R_ball_temp_std`
15. `R_ball_pressure_mean`
16. `R_ball_pressure_std`
17. `CrossFootDifference_temp_heel`
18. `CrossFootDifference_temp_ball`
19. `CrossFootDifference_pressure_heel`
20. `CrossFootDifference_pressure_ball`

## Models

- `L_heel_risk.mlmodel` predicts the risk class for the left heel.
- `L_ball_risk.mlmodel` predicts the risk class for the left ball of the foot.
- `R_heel_risk.mlmodel` predicts the risk class for the right heel.
- `R_ball_risk.mlmodel` predicts the risk class for the right ball of the foot.

Each model predicts one integer risk category from `0` to `4`.
