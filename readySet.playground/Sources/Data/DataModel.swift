// This file contains the declaration of the playground's data structure

import SwiftUI

class DataModel: ObservableObject {
    @Published var currentScreen: Screens = .title
    
    @Published var currentIntroPhase: IntroPhases = .hi
    @Published var currentCanvasPhase: HUDPhases? = .welcome
    
    @Published var userSetFiles = [UserFile(name: "File A"), UserFile(name: "File B"), UserFile(name: "File C"), UserFile(name: "File D"), UserFile(name: "File E")]
    @Published var currentFileIndex = 0
    
    var currentFile: UserFile {
        get {
            userSetFiles[currentFileIndex]
        } set {
            userSetFiles[currentFileIndex] = newValue
        }
    }
    
    var currentSets: [UserMathSet] {
        get {
            currentFile.userSets
        } set {
            currentFile.userSets = newValue
        }
    }
    
    var currentPreviousState: [UserMathSet]? {
        get {
            currentFile.previousState
        } set {
            currentFile.previousState = newValue
        }
    }
    var currentPreviousStateIsRedo: Bool {
        get {
            currentFile.previousStateIsRedo
        } set {
            currentFile.previousStateIsRedo = newValue
        }
    }
    
    @Published var parsedObjects = [MathObject]()
    
    @Published var activePopover: UUID? = nil
    
    func setPreviousState() {
        currentPreviousState = currentSets
        currentPreviousStateIsRedo = false
    }
    
    // Not proud of this messy algorithm either.
    
    func parseSets() {
        parsedObjects = []
        
        for userSet in currentSets {
            parsedObjects.append(MathSet(userSet: userSet))
        }
        
        if parsedObjects.count == 2 {
            checkIntersection(index1: 0, index2: 1)
        }
        
        if parsedObjects.count == 3 {
            checkThreeway(index1: 0, index2: 1, index3: 2)
            
            if parsedObjects.count != 1 {
                let set1 = parsedObjects[0] as! MathSet
                let set2 = parsedObjects[1] as! MathSet
                let set3 = parsedObjects[2] as! MathSet
                
                let intersection1 = set1.elements.intersection(set2.elements)
                let intersection2 = set1.elements.intersection(set3.elements)
                let intersection3 = set2.elements.intersection(set3.elements)
                
                let intersections = (intersection1.count > 0 ? 1 : 0) + (intersection2.count > 0 ? 1 : 0) + (intersection3.count > 0 ? 1 : 0)
                
                if intersections > 1 {
                    if intersection1.count * intersection2.count > 0 {
                        checkComplexIntersection(index1: 1, index2: 0, index3: 2)
                    } else if intersection1.count * intersection3.count > 0 {
                        checkComplexIntersection(index1: 0, index2: 1, index3: 2)
                    } else if intersection2.count * intersection3.count > 0 {
                        checkComplexIntersection(index1: 0, index2: 2, index3: 1)
                    }
                } else {
                    if parsedObjects.count == 3 { checkIntersection(index1: 0, index2: 1) }
                    if parsedObjects.count == 3 { checkIntersection(index1: 0, index2: 2) }
                    if parsedObjects.count == 3 { checkIntersection(index1: 1, index2: 2) }
                }
            }
        }
    }
    
    func checkIntersection(index1: Int, index2: Int) {
        let set1 = parsedObjects[index1] as! MathSet
        let set2 = parsedObjects[index2] as! MathSet
        
        let intersection = set1.elements.intersection(set2.elements)
        if intersection.count > 0 {
            if intersection.count == set1.userSet.count || intersection.count == set2.userSet.count {
                parsedObjects = parsedObjects
                    .enumerated()
                    .filter { ![index1, index2].contains($0.offset) }
                    .map { $0.element }
                
                if set1.elements.count < set2.elements.count {
                    parsedObjects.append(MathContainment(description: generateDescription(inner: [set1], outer: set2), inner: [set1], outer: set2))
                } else {
                    parsedObjects.append(MathContainment(description: generateDescription(inner: [set2], outer: set1), inner: [set2], outer: set1))
                }
            } else {
                parsedObjects = parsedObjects
                    .enumerated()
                    .filter { ![index1, index2].contains($0.offset) }
                    .map { $0.element }
                
                let intersectionOffset = CGFloat(intersection.count)*30
                parsedObjects.append(MathIntersection(description: generateDescription(lhs: set1, rhs: set2, intersection: intersection), gap: intersectionOffset, lhs: set1, rhs: set2))
            }
        }
    }
    
    func checkComplexIntersection(index1: Int, index2: Int, index3: Int) {
        let set1 = parsedObjects[index1] as! MathSet
        let set2 = parsedObjects[index2] as! MathSet
        let set3 = parsedObjects[index3] as! MathSet
        
        let intersection1 = set1.elements.intersection(set2.elements)
        let intersection2 = set2.elements.intersection(set3.elements)
        
        parsedObjects = []
        
        if intersection1.count == set1.userSet.count {
            if intersection2.count == set3.userSet.count {
                parsedObjects.append(MathContainment(description: generateDescription(inner: [set1, set3], outer: set2), inner: [set1, set3], outer: set2))
            } else {
                parsedObjects.append(MathIntersection(description: generateDescription(lhs: set2, rhs: set3, intersection: intersection2), gap: CGFloat(intersection2.count)*30, lhs: MathContainment(description: generateDescription(inner: [set1], outer: set2), alignment: .leading, inner: [set1], outer: set2), rhs: set3))
            }
        } else if intersection2.count == set3.userSet.count {
            if intersection1.count == set1.userSet.count {
                parsedObjects.append(MathContainment(description: generateDescription(inner: [set3, set1], outer: set2), inner: [set3, set1], outer: set2))
            } else {
                parsedObjects.append(MathIntersection(description: generateDescription(lhs: set1, rhs: set2, intersection: intersection1), gap: CGFloat(intersection1.count)*30, lhs: set1, rhs: MathContainment(description: generateDescription(inner: [set3], outer: set2), alignment: .trailing, inner: [set3], outer: set2)))
            }
        } else {
            parsedObjects.append(MathIntersection(description: generateDescription(lhs: set1, rhs: set2, intersection: intersection1), gap: CGFloat(intersection1.count)*30, lhs: set1, rhs: MathIntersection(description: generateDescription(lhs: set2, rhs: set3, intersection: intersection2), gap: CGFloat(intersection2.count)*30, lhs: set2, rhs: set3)))
        }
    }
    
    func checkThreeway(index1: Int, index2: Int, index3: Int) {
        let set1 = parsedObjects[index1] as! MathSet
        let set2 = parsedObjects[index2] as! MathSet
        let set3 = parsedObjects[index3] as! MathSet
        
        let intersection = set1.elements.intersection(set2.elements).intersection(set3.elements)
        
        if intersection.count > 0 {
            parsedObjects = []
            
            let offset = MathThreewayOffset(top: CGFloat((set1.elements.count-intersection.count)*15),
                                            lhs: CGFloat((set2.elements.count-intersection.count)*15),
                                            rhs: CGFloat((set3.elements.count-intersection.count)*15))
            
            parsedObjects.append(MathThreeway(description: generateDescription(top: set1, lhs: set2, rhs: set3, intersection: intersection), offset: offset, top: set1, lhs: set2, rhs: set3))
        }
    }
    
    func generateDescription(lhs: MathSet, rhs: MathSet, intersection: Set<Double>) -> String {
        return "\(lhs.userSet.name) ∩ \(rhs.userSet.name) = { \(intersection.sorted().map { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0) : String($0) }.joined(separator: ", ")) }"
    }
    
    func generateDescription(inner: [MathSet], outer: MathSet) -> String {
        return inner.map { "\(outer.userSet.name) ⊂ \($0.userSet.name)" }.joined(separator: " and ")
    }
    
    func generateDescription(top: MathSet, lhs: MathSet, rhs: MathSet, intersection: Set<Double>) -> String {
        return "\(lhs.userSet.name) ∩ \(top.userSet.name) ∩ \(rhs.userSet.name) = { \(intersection.sorted().map { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0) : String($0) }.joined(separator: ", ")) }"
    }
}

struct UserMathSet: Equatable {
    static func == (lhs: UserMathSet, rhs: UserMathSet) -> Bool {
        lhs.elements == rhs.elements
    }
    
    var style: (name: String, color: Color)
    
    var name: String {
        style.name
    }
    var color: Color {
        style.color
    }
    
    var elements = Set<Double>()
    var definedBy: Definitions = .enumeration
    
    var count: Int {
        elements.count
    }
    
    var parsedElements: String {
        elements.count > 0 ? elements.sorted().map { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0) : String($0) }.joined(separator: ", ") : "Ø"
    }
}

struct UserFile: Equatable, Identifiable {
    var id = UUID()
    
    var name: String
    var userSets = [UserMathSet]()
    
    var previousState: [UserMathSet]?
    var previousStateIsRedo = false
}

enum Definitions {
    case enumeration
    case builder
}

enum Screens {
    case title
    case intro
    case canvas
}
