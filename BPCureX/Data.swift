//
//  Data.swift
//  BPCureX
//
//  Created by yangjian on 2023/12/12.
//

import Foundation
import UIKit
import SwiftUI

struct DateDuration: Equatable, Codable {
    var min: Date = Date().exactlyDay.addingTimeInterval(-.weak + 1)
    var max: Date = Date().exactlyDay.addingTimeInterval(.day)
    
    static let `default` = DateDuration()
}

struct Measurement: Codable, Equatable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    
    var systolic: Int = 100 { // 收缩呀
        didSet {
            updateStatus()
        }
    }
    
    var diastolic: Int = 70 { // 舒张压
        didSet {
            updateStatus()
        }
    }
    var pulse: Int = 70 // 心率
    
    var status: Status = .normal
    
    var posture: Posture = .init()
    
    var date: Date = .init()
    
    var  note: String = ""
    
    public static func getStatus(systolic: Int, diastolic: Int) -> Status {
        var status = Status.normal
        if systolic < 90 || diastolic < 60 {
            status = .low
        }
        if 90..<120 ~= systolic, 60..<80 ~= diastolic {
            status = .normal
        }
        if 120..<130 ~= systolic,  60..<80 ~= diastolic {
            status = .elevated
        }
        
        if 130..<140 ~= systolic || 80..<90 ~= diastolic {
            status = .hy1
        }
        if 140...180 ~= systolic || 90...120 ~= diastolic {
            status = .hy2
        }
        if systolic > 180 || diastolic > 120 {
            status = .servereHy
        }
        return status
    }
    
    mutating func updateStatus() {
        status = Measurement.getStatus(systolic: systolic, diastolic: diastolic)
    }
    
    enum Status:String,  Codable, CaseIterable {
        case low, normal, elevated, hy1, hy2, servereHy
        var title: String {
            switch self {
            case .low:
                return "Low BP"
            case .normal:
                return "Normal BP"
            case .elevated:
                return "Elevated BP"
            case .hy1:
                return "Hypertension1 BP"
            case .hy2:
                return "Hypertension2 BP"
            case .servereHy:
                return "Severe hypertension"
            }
        }
        
        var uiColor: UIColor {
            UIColor(named: "color_" + self.rawValue)!
        }
        var color: Color {
            Color(uiColor: uiColor)
        }
        
        var endColor: UIColor {
            uiColor.withAlphaComponent(0.6)
        }
        
        static let uiColors: [UIColor] = Self.allCases.map {
            $0.uiColor
        }
    }
    
    struct Posture: Equatable, Codable, Hashable {
        enum Item: CaseIterable {
            case feel, arm, body
            var title: String {
                switch self {
                case .feel:
                    return "Feeling"
                case .arm:
                    return "Measured arm"
                case .body:
                    return "Body Position"
                }
            }
            var feelSource: [Feel] {
                Feel.allCases
            }
            
            var armSource: [Arm] {
                Arm.allCases
            }
            
            var bodySource: [Body] {
                Body.allCases
            }
            
        }
        var feel: Feel = .soso
        var arm: Arm = .left
        var body: Body = .lying
        enum Feel: String, Codable, Measure {
            var icon: String {
                return "edit_" + self.rawValue
            }
            case happy, said, soso
        }
        enum Arm: String, Codable, Measure {
            var icon: String {
                return "edit_" + self.rawValue
            }
            case left, right
        }
        enum Body: String, Codable, Measure {
            var icon: String {
                return "edit_" + self.rawValue
            }
            case stand, sit, lying
        }
    }
    
    var datasource: [[Int]] {
        Array(0...2).compactMap { _ in
            Array(30...250)
        }
    }
}

protocol Measure: CaseIterable, Hashable {
    var icon: String { get }
}
