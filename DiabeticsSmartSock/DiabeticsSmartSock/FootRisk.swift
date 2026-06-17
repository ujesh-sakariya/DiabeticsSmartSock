import SwiftUI

enum FootRiskLocation: String, CaseIterable, Identifiable {
    case leftHeel = "L_heel_risk"
    case leftBall = "L_ball_risk"
    case rightHeel = "R_heel_risk"
    case rightBall = "R_ball_risk"

    var id: String { rawValue }

    var modelResourceName: String { rawValue }
}

struct FootRiskState: Equatable {
    var leftHeel: Int
    var leftBall: Int
    var rightHeel: Int
    var rightBall: Int

    static let clear = FootRiskState(leftHeel: 0, leftBall: 0, rightHeel: 0, rightBall: 0)
    static let preview = FootRiskState(leftHeel: 1, leftBall: 3, rightHeel: 0, rightBall: 4)

    subscript(location: FootRiskLocation) -> Int {
        switch location {
        case .leftHeel:
            leftHeel
        case .leftBall:
            leftBall
        case .rightHeel:
            rightHeel
        case .rightBall:
            rightBall
        }
    }
}

extension Int {
    var riskColor: Color {
        switch self {
        case 0:
            .green
        case 1:
            .yellow
        case 2:
            .orange
        case 3:
            .red
        default:
            .purple
        }
    }
}
