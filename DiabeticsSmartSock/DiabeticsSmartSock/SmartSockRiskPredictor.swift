import CoreML
import Foundation

struct SmartSockSensorSample {
    let leftHeelPressure: Double
    let leftBallPressure: Double
    let rightHeelPressure: Double
    let rightBallPressure: Double
    let leftHeelTemperature: Double
    let leftBallTemperature: Double
    let rightHeelTemperature: Double
    let rightBallTemperature: Double

    init?(values: [Double]) {
        guard values.count == 8 else {
            return nil
        }
        
        if values.suffix(4).contains(where: { $0 <= -100 }) {
            print("Warning: temperature value looks invalid: \(Array(values.suffix(4)))")
        }

        leftHeelPressure = values[0]
        leftBallPressure = values[1]
        rightHeelPressure = values[2]
        rightBallPressure = values[3]
        leftHeelTemperature = values[4]
        leftBallTemperature = values[5]
        rightHeelTemperature = values[6]
        rightBallTemperature = values[7]
    }
}

enum SmartSockFeatureExtractor {
    static let windowSize = 30
    static let stepSize = 5

    static func extract(from samples: [SmartSockSensorSample]) -> SmartSockWindowFeatures? {
        guard samples.count >= windowSize else {
            return nil
        }

        let window = Array(samples.suffix(windowSize))

        let leftHeelTemps = window.map(\.leftHeelTemperature)
        let leftBallTemps = window.map(\.leftBallTemperature)
        let rightHeelTemps = window.map(\.rightHeelTemperature)
        let rightBallTemps = window.map(\.rightBallTemperature)
        let leftHeelPressures = window.map(\.leftHeelPressure)
        let leftBallPressures = window.map(\.leftBallPressure)
        let rightHeelPressures = window.map(\.rightHeelPressure)
        let rightBallPressures = window.map(\.rightBallPressure)

        return SmartSockWindowFeatures(values: [
            "L_heel_temp_mean": mean(leftHeelTemps),
            "L_heel_temp_std": sampleStandardDeviation(leftHeelTemps),
            "L_heel_pressure_mean": mean(leftHeelPressures),
            "L_heel_pressure_std": sampleStandardDeviation(leftHeelPressures),
            "L_ball_temp_mean": mean(leftBallTemps),
            "L_ball_temp_std": sampleStandardDeviation(leftBallTemps),
            "L_ball_pressure_mean": mean(leftBallPressures),
            "L_ball_pressure_std": sampleStandardDeviation(leftBallPressures),
            "R_heel_temp_mean": mean(rightHeelTemps),
            "R_heel_temp_std": sampleStandardDeviation(rightHeelTemps),
            "R_heel_pressure_mean": mean(rightHeelPressures),
            "R_heel_pressure_std": sampleStandardDeviation(rightHeelPressures),
            "R_ball_temp_mean": mean(rightBallTemps),
            "R_ball_temp_std": sampleStandardDeviation(rightBallTemps),
            "R_ball_pressure_mean": mean(rightBallPressures),
            "R_ball_pressure_std": sampleStandardDeviation(rightBallPressures),
            "CrossFootDifference_temp_heel": mean(zip(leftHeelTemps, rightHeelTemps).map(-)),
            "CrossFootDifference_temp_ball": mean(zip(leftBallTemps, rightBallTemps).map(-)),
            "CrossFootDifference_pressure_heel": mean(zip(leftHeelPressures, rightHeelPressures).map(-)),
            "CrossFootDifference_pressure_ball": mean(zip(leftBallPressures, rightBallPressures).map(-))
        ])
    }

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else {
            return 0
        }

        return values.reduce(0, +) / Double(values.count)
    }

    private static func sampleStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else {
            return 0
        }

        let average = mean(values)
        let variance = values
            .map { pow($0 - average, 2) }
            .reduce(0, +) / Double(values.count - 1)

        return sqrt(variance)
    }
}

struct SmartSockWindowFeatures {
    let values: [String: Double]

    static let featureOrder = [
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
        "CrossFootDifference_pressure_ball"
    ]

    static let sample = SmartSockWindowFeatures(values: [
        "L_heel_temp_mean": 35.1,
        "L_heel_temp_std": 0.11,
        "L_heel_pressure_mean": 930,
        "L_heel_pressure_std": 22,
        "L_ball_temp_mean": 36.4,
        "L_ball_temp_std": 0.14,
        "L_ball_pressure_mean": 970,
        "L_ball_pressure_std": 31,
        "R_heel_temp_mean": 33.6,
        "R_heel_temp_std": 0.09,
        "R_heel_pressure_mean": 780,
        "R_heel_pressure_std": 18,
        "R_ball_temp_mean": 33.7,
        "R_ball_temp_std": 0.1,
        "R_ball_pressure_mean": 810,
        "R_ball_pressure_std": 20,
        "CrossFootDifference_temp_heel": 1.5,
        "CrossFootDifference_temp_ball": 2.7,
        "CrossFootDifference_pressure_heel": 150,
        "CrossFootDifference_pressure_ball": 160
    ])
}

final class SmartSockFeatureProvider: MLFeatureProvider {
    private let features: SmartSockWindowFeatures

    var featureNames: Set<String> {
        Set(SmartSockWindowFeatures.featureOrder)
    }

    init(features: SmartSockWindowFeatures) {
        self.features = features
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        guard SmartSockWindowFeatures.featureOrder.contains(featureName) else {
            return nil
        }

        return MLFeatureValue(double: features.values[featureName, default: 0])
    }
}

final class SmartSockRiskPredictor {
    private let models: [FootRiskLocation: MLModel]

    init(bundle: Bundle = .main) {
        var loadedModels: [FootRiskLocation: MLModel] = [:]

        for location in FootRiskLocation.allCases {
            guard let url = bundle.url(
                forResource: location.modelResourceName,
                withExtension: "mlmodelc"
            ),
            let model = try? MLModel(contentsOf: url) else {
                continue
            }

            loadedModels[location] = model
        }

        models = loadedModels
    }

    func predict(features: SmartSockWindowFeatures) -> FootRiskState? {
        guard models.count == FootRiskLocation.allCases.count else {
            return nil
        }

        let provider = SmartSockFeatureProvider(features: features)

        return FootRiskState(
            leftHeel: prediction(for: .leftHeel, provider: provider),
            leftBall: prediction(for: .leftBall, provider: provider),
            rightHeel: prediction(for: .rightHeel, provider: provider),
            rightBall: prediction(for: .rightBall, provider: provider)
        )
    }

    private func prediction(
        for location: FootRiskLocation,
        provider: MLFeatureProvider
    ) -> Int {
        guard let output = try? models[location]?.prediction(from: provider),
              let value = output.featureValue(for: location.rawValue) else {
            return 0
        }

        if value.type == .int64 {
            return Int(value.int64Value)
        }

        if value.type == .double {
            return Int(value.doubleValue)
        }

        return 0
    }
}
