//
//  Helpers.swift
//  CGraphicsTutorial
//
//  Created by Peter Homberg on 3/12/26.
//

import Foundation

typealias AbsolutePoint = CGPoint
typealias RelativePoint = CGPoint

func * (lhs: CGSize, rhs: CGSize) -> CGSize {
    .init(width: lhs.width*rhs.width, height: lhs.height*rhs.height)
}

func * (lhs: CGPoint, rhs: CGSize) -> CGPoint {
    .init(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
}

func - (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    .init(x: lhs.x - rhs, y: lhs.y - rhs)
}

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

func / (lhs: CGSize, rhs: CGSize) -> CGSize {
    .init(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
}
func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
}

func - (lhs:CGPoint, rhs:CGPoint) -> CGSize {
    .init(width: lhs.x - rhs.x, height: lhs.y - rhs.y)
}

extension CGSize {
    var toPoint: CGPoint { .init(x: width, y: height) }
    var half: CGSize { .init(width: width/2, height: height/2) }
}
extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx*dx + dy*dy)  // Pythagorean theorem
    }
}
