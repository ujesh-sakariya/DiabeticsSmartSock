from collections import deque
import joblib # import the machine learning model
import pandas as pd
import csv
import numpy as np
import os

model = joblib.load("risk_model.pkl")

WINDOW_SIZE = 5 # 30 samples
STEP_SIZE = 5 # slide every 5 samples

buffer = deque()


def extractFeatures(data):
    '''extract the features from the data values'''

    features = {}
    parts = ['L_heel_','L_ball_','R_heel_','R_ball_']

    current = pd.DataFrame(data,columns=[
                    'L_heel_pressure', 'L_ball_pressure', 'R_heel_pressure', 'R_ball_pressure',
                    'L_heel_temp', 'L_ball_temp','R_heel_temp', 'R_ball_temp'])
    for p in parts:
        
        features[p+'temp_mean'] = current[p+'temp'].mean()
        features[p+'temp_std'] = current[p+'temp'].std()
        features[p+'pressure_mean'] = current[p+'pressure'].mean()
        features[p+'pressure_std'] = current[p+'pressure'].std()
       
        
    features['CrossFootDifference_temp_heel'] = ((current['L_heel_temp'] - current['R_heel_temp']).mean())
    features['CrossFootDifference_temp_ball'] = ((current['L_ball_temp'] - current['R_ball_temp']).mean())
    features['CrossFootDifference_pressure_heel'] = ((current['L_heel_pressure'] - current['R_heel_pressure']).mean())
    features['CrossFootDifference_pressure_ball'] = ((current['L_ball_pressure'] - current['R_ball_pressure']).mean())

    return pd.DataFrame([features])
    
    

def runPrediction(line):
    ''' add the data to the buffer '''
    buffer.append(line)
    print('got here')
    if len(buffer) == WINDOW_SIZE:
        window = list(buffer)
        print(buffer)
        print(list(buffer))
        features = extractFeatures(window) 
        risk_analysis = model.predict(features)
        logWindow(features,risk_analysis)

        for _ in range(5): # remove the oldest 5 values
            buffer.popleft()
    
    

def logWindow(features, risk_analysis):
    file_path = 'CollectedData.csv'

    # Convert risk_analysis to DataFrame
    values = np.array(risk_analysis)
    new_columns = ['L_heel_risk', 'L_ball_risk', 'R_heel_risk', 'R_ball_risk']
    df = pd.DataFrame(values, columns=new_columns)

    # Concatenate along columns to ensure all original + new columns are present
    combined = pd.concat([features.reset_index(drop=True), df.reset_index(drop=True)], axis=1)

    with open(file_path, mode='a', newline='') as f:
        writer = csv.writer(f)

        # Write header if file is empty
        if os.stat(file_path).st_size == 0:
            writer.writerow(combined.columns.tolist())

        # Write all rows
        writer.writerows(combined.values.tolist())
    updateOutput(risk_analysis)


def updateOutput(risk_anlysis):
   print(risk_anlysis)
    
