//
//  Model.swift
//  DiabeticsSmartSock
//
//  Created by Ujesh Sakariya on 07/09/2025.
//

import CoreML

// Xcode automatically creates a class for the machine learning model
class PredictRisk {
    
    let LH : L_heel_risk_model
    let RH : R_heel_risk_model
    let LB : L_ball_risk_model
    let RB : R_ball_risk_model
    
    init() throws {
        
        // create a configuration object - needed as some models require custom configs like specifiying to use CPU or GPU etc
        // for now use default configs
        let config = MLModelConfiguration()
        
        do {
            // initialise all models with the class swift has created for us
            LH = try L_heel_risk_model(configuration:config)
            RH = try R_heel_risk_model(configuration:config)
            LB = try L_ball_risk_model(configuration:config)
            RB = try R_ball_risk_model(configuration:config)
        }
        catch {
            print("Error initialising models: \(error)")
            throw error
        }
        print("Models loaded")
    }
    
}
