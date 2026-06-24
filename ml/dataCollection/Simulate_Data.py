import csv
import random
import numpy as np 
def simulate_activity(duration_sec=1800,activity='walking', inflamed=[0,0,0,0], pressure_imbalance=[0,0]):

    def random_noise(std):
        return np.random.normal(0,std)
    
    '''Function to simulate data for ML model'''

    timestamps = np.arange(duration_sec) # timestanps for activity 

    # Base values for activities 
    # can be tweaked depending on hardware readings
    activity_pressure = {'walking':(500,1000),'standing':(900,1000),'lying':(0,20)}
    activity_temperature = {'walking':35,'standing':34,'lying':33}


    # Initialising arrays for all 8 sensor values
    
    L_heel_pressure = np.zeros(duration_sec)
    R_heel_pressure = np.zeros(duration_sec)
    L_ball_pressure = np.zeros(duration_sec)
    R_ball_pressure = np.zeros(duration_sec)
    L_heel_temp = np.zeros(duration_sec)
    R_heel_temp = np.zeros(duration_sec)
    L_ball_temp = np.zeros(duration_sec)
    R_ball_temp = np.zeros(duration_sec)
    L_heel_risk = np.zeros(duration_sec)
    R_heel_risk = np.zeros(duration_sec)
    L_ball_risk = np.zeros(duration_sec)
    R_ball_risk = np.zeros(duration_sec)

    # temp noise
    temp_noise = 0.1

    for t in range(duration_sec):

        # setting base temperature of the feet
        left_temp = activity_temperature[activity] + random_noise(temp_noise)
        right_temp = activity_temperature[activity] + random_noise(temp_noise)

        # fluctutations between areas of the feel an setting values
        L_ball_temp[t] = left_temp + np.random.uniform(-0.05,0.05) + inflamed[0] # if we are simulating that part of the foot being inflamed
        L_heel_temp[t] = left_temp + np.random.uniform(-0.05,0.05) + inflamed[1]
        R_ball_temp[t] = right_temp + np.random.uniform(-0.05,0.05) + inflamed[2]
        R_heel_temp[t] = right_temp + np.random.uniform(-0.05,0.05) + inflamed[3]

        # simulating pressure values
        if activity == 'walking':
  
            step_phase = int(t % 2) # cadence accomodation

            # Base values
            low_p , high_p = activity_pressure[activity]

            if step_phase == 0: # simulate being on the left foot
                
                L_pressure = high_p + random_noise(30)
                R_pressure = low_p + random_noise(20)
            else: # being on the right foot 
                R_pressure = high_p + random_noise(30)
                L_pressure = low_p + random_noise(20)
            
            imb_val = 100 #imbalance if the user is leaning on one leg 

            L_heel_pressure[t] = np.clip(L_pressure + np.random.uniform(-5,5) + (imb_val if pressure_imbalance[0] == 1 else 0),0,1023)
            L_ball_pressure[t] = np.clip(L_pressure + np.random.uniform(-5,5) + (imb_val if pressure_imbalance[0] == 1 else 0),0,1023)
            R_heel_pressure[t] = np.clip(R_pressure + np.random.uniform(-5,5) + (imb_val if pressure_imbalance[1] == 1 else 0),0,1023)
            R_ball_pressure[t] = np.clip(R_pressure + np.random.uniform(-5,5) + (imb_val if pressure_imbalance[1] == 1 else 0),0,1023)
             
        elif activity == 'standing':

            imb_val = 100 #imbalance if the user is leaning on one leg 

            base_p = np.mean(activity_pressure['standing'])
            L_pressure = base_p + random_noise(15)
            R_pressure = base_p + random_noise(15)

            

            L_heel_pressure[t] = np.clip(L_pressure + np.random.uniform(-5,5) + (imb_val if pressure_imbalance[0] == 1 else 0),0,1023)
            L_ball_pressure[t] = np.clip(L_pressure + np.random.uniform(-5,5) + (imb_val if pressure_imbalance[0] == 1 else 0),0,1023)
            R_heel_pressure[t] = np.clip(R_pressure + np.random.uniform(-5,5) + (imb_val if pressure_imbalance[1] == 1 else 0),0,1023)
            R_ball_pressure[t] = np.clip(R_pressure + np.random.uniform(-5,5) + (imb_val if pressure_imbalance[1] == 1 else 0),0,1023)
             
        elif activity == 'lying':
            
            base_p = np.mean(activity_pressure['lying'])
            L_pressure = base_p + random_noise(15)
            R_pressure = base_p + random_noise(15)

            L_heel_pressure[t] = np.clip(L_pressure + np.random.uniform(-5,5),0,1023)
            L_ball_pressure[t] = np.clip(L_pressure + np.random.uniform(-5,5),0,1023)
            R_heel_pressure[t] = np.clip(R_pressure + np.random.uniform(-5,5),0,1023)
            R_ball_pressure[t] = np.clip(R_pressure + np.random.uniform(-5,5),0,1023)

        # labelling the data 
        L_heel_risk[t] = classify_risk(L_heel_temp[t],R_heel_temp[t],L_heel_pressure[t],R_heel_pressure[t])
        R_heel_risk[t] = classify_risk(R_heel_temp[t],L_heel_temp[t],R_heel_pressure[t],L_heel_pressure[t])
        L_ball_risk[t]= classify_risk(L_ball_temp[t],R_ball_temp[t],L_ball_pressure[t],R_ball_pressure[t])
        R_ball_risk[t] = classify_risk(R_ball_temp[t],L_ball_temp[t],R_ball_pressure[t],L_ball_pressure[t])

    with open('simulated_data_training.csv',mode='a', newline='') as file:
            
        writer = csv.writer(file)

        # Loop through your arrays to write each timestep as a row
        for t in range(duration_sec):
            writer.writerow([
                L_heel_pressure[t], L_ball_pressure[t], L_heel_temp[t], L_ball_temp[t],
                R_heel_pressure[t], R_ball_pressure[t], R_heel_temp[t], R_ball_temp[t],
                L_heel_risk[t], L_ball_risk[t], R_heel_risk[t], R_ball_risk[t]
            ])

                    
def classify_risk(risk_temp,compare_temp,risk_pressure,compare_pressure):
            '''risk is the part we assessing
            Returns:
                0 = no risk
                1 = mild (temp diff present, low pressure)
                2 = moderate (temp diff present, high pressure or could be due to imbalanced)
                3 = high (temp diff present, high pressure & balanced)
                4 = very high (large temp diff, high pressure & balanced) '''
            
            temp_diff = risk_temp - compare_temp
            if temp_diff > 2.2:
                if risk_pressure > 900:
                    if risk_pressure - compare_pressure > 100:
                        return 3 # imbalance could be causing temp diff but temp diff is still quite high
                    else:
                        return 4 # high pressure and significan temp difference
                else:
                        return 3 # pressure is low therefore not much mechanical damage
            if temp_diff > 1.1:
                if risk_pressure > 900:
                    if risk_pressure - compare_pressure > 100:
                        return 1 # imbalance could be causing temp diff but temp diff is moderate
                    else:
                        return 2 # high pressure and moderate temp difference
                else:
                        return 1 # temp difference is present but pressure is low
            else:
                return 0 # temp diff is not substantial 
                    
            
if __name__ == "__main__":
    with open('simulated_data_training.csv',mode='a', newline='') as file:
            
        writer = csv.writer(file)

        writer.writerow([
                    'L_heel_pressure', 'L_ball_pressure', 'L_heel_temp', 'L_ball_temp',
                    'R_heel_pressure', 'R_ball_pressure', 'R_heel_temp', 'R_ball_temp',
                    'L_heel_risk', 'L_ball_risk', 'R_heel_risk', 'R_ball_risk'
                ])
    
    activity = ['walking','lying','standing']
    inflamation = [[0,0,0,0],
    [2.2,0,0,0],
    [0,2.2,0,0],
    [0,0,2.2,0],
    [0,0,0,2.2],
    [0,0,2.2,2.2],
    [0,2.2,0,2.2],
    [2.2,0,0,2.2],
    [0,2.2,2.2,0],
    [2.2,0,2.2,0],
    [2.2,2.2,0,0],
    [0,2.2,2.2,2.2],
    [2.2,2.2,0,2.2],
    [2.2,2.2,2.2,0],
    [2.2,0,2.2,2.2],
    [2.2,2.2,2.2,2.2]
    ]
    imbalance = [[0,0],[1,0],[0,1]]

    for a in activity:
         for i in inflamation:
              for j in imbalance:
                    simulate_activity(60, a, i,j)



             

