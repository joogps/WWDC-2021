//
//  Sounds.swift
//  readySet
//
//  Created by João Gabriel Pozzobon dos Santos on 14/08/23.
//

import Foundation
import AVFoundation

struct Sounds {
    static var theme: AVAudioPlayer? = createPlayer(for: "Theme")
    static var exit: AVAudioPlayer? = createPlayer(for: "Exit")
    
    static var background: AVAudioPlayer? = createPlayer(for: "Background")
    
    static var bubbleSounds = [createPlayer(for: "Bubble 1"), createPlayer(for: "Bubble 2"), createPlayer(for: "Bubble 3")]
    
    static var openMenuSound: AVAudioPlayer? = createPlayer(for: "Open")
    static var closeMenuSound: AVAudioPlayer? = createPlayer(for: "Close")
    static var fileSelectMenuSound: AVAudioPlayer? = createPlayer(for: "File select")
    static var emptyMenuSound: AVAudioPlayer? = createPlayer(for: "Empty")
    static var helpMenuSound: AVAudioPlayer? = createPlayer(for: "Help")
    static var undoMenuSound: AVAudioPlayer? = createPlayer(for: "Undo")
    static var redoMenuSound: AVAudioPlayer? = createPlayer(for: "Redo")
    
    static var simpleSetSound = createPlayer(for: "Simple")
    static var intersectionContainmentSetSound = createPlayer(for: "Intersection : Containment")
    static var complexIntersectionContainmentSetSound = createPlayer(for: "Complex Intersection : Containment")
    static var threewaySetSound = createPlayer(for: "Three-way")
    static var emptySetSound = createPlayer(for: "Empty set")
}
