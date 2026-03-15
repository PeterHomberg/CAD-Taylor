//
//  Bezier.swift
//  CAD Taylor
//
//  Created by Peter Homberg on 3/15/26.
//

import Foundation
import SwiftUI
enum HitResult {
    case curvePoint(index: Int)
    case controlPoint(index: Int)
    case controlPoint1(index: Int)

}


class DrawingModel: ObservableObject {
    @Published var bezierSegments: [BezierSegment] = []
    @Published var penMode: Bool = true
    @Published var bezierMode: Bool = false
    func clear() {
        print(" C L E A R")
        bezierSegments = []
    }
}

struct BezierSegment: Codable{
    var curvePoint: CGPoint = .zero
    var controlPoint: CGPoint = .zero
    var curvePoint1: CGPoint = .zero
    var controlPoint1: CGPoint = .zero

    
    func drawDashedLine(ctx: CGContext, from startPoint: CGPoint, to endPoint: CGPoint) {
        // Set stroke color and line width
        ctx.setStrokeColor(CGColor(red: 0.3, green: 0.5, blue: 0, alpha: 1))
        ctx.setLineWidth(1.0)
        
        // Define the dash pattern: 5 units painted, 5 units unpainted
        let dashLengths: [CGFloat] = [2, 2]
        // Set the line dash pattern with a phase of 0 (start from the beginning of the pattern)
        ctx.setLineDash(phase: 0, lengths: dashLengths)
        
        // Move to the starting point and add a line to the ending point
        ctx.move(to: startPoint)
        ctx.addLine(to: endPoint)
        
        // Stroke the path to render the line
        ctx.strokePath()
        
        // IMPORTANT: Reset the line dash to an empty array to ensure subsequent lines are solid
        ctx.setLineDash(phase: 0, lengths: [])
    }
    func draw(ctx: CGContext) -> () {
        ctx.saveGState()
        
        // first draw curve point
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        ctx.fillEllipse(in: CGRect(
            x: curvePoint.x - 10,
            y: curvePoint.y - 10,
            width: 20, height: 20
        ))
        
        if controlPoint != .zero  {
            // the draw control point
            ctx.setStrokeColor(CGColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1))
            ctx.addRect(CGRect(
                x: controlPoint.x - 5,
                y: controlPoint.y - 5,
                width: 10, height: 10
            ))
            drawDashedLine(ctx: ctx, from: curvePoint, to: controlPoint)
        }
        if controlPoint1 != .zero && curvePoint1 != .zero {
            // the draw control point
            ctx.setStrokeColor(CGColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1))
            ctx.addRect(CGRect(
                x: controlPoint1.x - 5,
                y: controlPoint1.y - 5,
                width: 10, height: 10
            ))
            drawDashedLine(ctx: ctx, from: curvePoint1, to: controlPoint1)
        }

        ctx.restoreGState()
    }
    
}
