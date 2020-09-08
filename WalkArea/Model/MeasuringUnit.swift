//
//  MeasuringUnit.swift
//  WalkArea
//
//  Created by Sergio Rodríguez Rama on 08/05/2020.
//  Copyright © 2020 Sergio Rodríguez Rama. All rights reserved.
//

import Foundation

enum MeasuringUnit {
    
    // MARK: - Static
    
    // Update this if you add/remove a new case
    static var allCases: [MeasuringUnit] = [.kilometers, .meters, .miles, .yards]
    
    // MARK: - Cases
    
    // Update allCases if you add/remove a new case
    case meters
    case yards
    case kilometers
    case miles
    
    // MARK: Internal var let
    
    var name: String {
        switch self {
        case .meters:
            return NSLocalizedString("meters", comment: "")
        case .yards:
            return NSLocalizedString("yards", comment: "")
        case .kilometers:
            return NSLocalizedString("kilometers", comment: "")
        case .miles:
            return NSLocalizedString("miles", comment: "")
        }
    }
    
    var symbol: String {
        switch self {
        case .meters:
            return NSLocalizedString("m", comment: "")
        case .yards:
            return NSLocalizedString("yd", comment: "")
        case .kilometers:
            return NSLocalizedString("km", comment: "")
        case .miles:
            return NSLocalizedString("mi", comment: "")
        }
    }
    
    // MARK: Internal methods
    
    func inMeters(_ distance: Double) -> Double {
        switch self {
        case .meters:
            return distance * 1
        case .yards:
            return distance * 0.914
        case .kilometers:
            return distance * 1000
        case .miles:
            return distance * 1760 * 0.914
        }
    }
    
    func fromMeters(_ distance: Double) -> Double {
        switch self {
        case .meters:
            return distance * 1
        case .yards:
            return distance / 0.914
        case .kilometers:
            return distance / 1000
        case .miles:
            return (distance / 0.914) / 1760
        }
    }
}

