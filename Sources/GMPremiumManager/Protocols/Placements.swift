//
//  Placements.swift
//  GMPremiumManager
//
//  Created by Mert Serin on 2024-10-13.
//

import Foundation

public protocol Placements: Hashable {
    static var allCases: [Self] { get }

    var id: String { get }
}

extension Placements {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
