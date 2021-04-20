// This file houses the various objects that are part of the system

import SwiftUI

protocol MathObject {
    var id: UUID { get }
}

struct MathSet: MathObject {
    var id: UUID = UUID()
    
    var size: CGFloat {
        userSet.count == 0 ? 20 : CGFloat(userSet.count*30)
    }
    
    var userSet: UserMathSet
    var elements: Set<Double> {
        userSet.elements
    }
}

struct MathIntersection: MathObject {
    var id: UUID = UUID()
    
    var description: String = ""
    
    var gap: CGFloat = .zero
    
    var lhs: MathObject
    var rhs: MathObject
}

struct MathContainment: MathObject {
    var id: UUID = UUID()
    
    var description: String = ""
    
    var alignment: Alignment = .center
    
    var inner: [MathObject]
    var outer: MathObject
}

struct MathThreeway: MathObject {
    var id: UUID = UUID()
    
    var description: String = ""
    
    var offset: MathThreewayOffset = .zero
    
    var top: MathObject
    var lhs: MathObject
    var rhs: MathObject
}

struct MathThreewayOffset {
    var top: CGFloat
    var lhs: CGFloat
    var rhs: CGFloat
    
    static var zero: MathThreewayOffset {
        MathThreewayOffset(top: .zero, lhs: .zero, rhs: .zero)
    }
}
