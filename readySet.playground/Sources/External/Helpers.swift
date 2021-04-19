// This file contains all helper elements that don't fit anywhere else

import Foundation
import SwiftUI
import AppKit
import AVFoundation

extension Color {
    struct playgroundTheme {
        static var blue: Color { Color(#colorLiteral(red: 0.3450980392, green: 0.3882352941, blue: 0.9725490196, alpha: 1)) }
        static var green: Color { Color(#colorLiteral(red: 0.2274509804, green: 0.8509803922, blue: 0.5764705882, alpha: 1)) }
        static var yellow: Color { Color(#colorLiteral(red: 1, green: 0.8901960784, blue: 0.5058823529, alpha: 1)) }
        static var orange: Color { Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)) }
        static var white: Color { Color(#colorLiteral(red: 0.99, green: 0.9864911983, blue: 0.9801, alpha: 1)) }
        static var gray: Color { Color(#colorLiteral(red: 0.2173916101, green: 0.2078431373, blue: 0.2, alpha: 1)) }
        static var black: Color { Color(#colorLiteral(red: 0.137254902, green: 0.1311863363, blue: 0.1215686275, alpha: 1)) }
    }
}

func createPlayer(for resource: String) -> AVAudioPlayer? {
    let player: AVAudioPlayer
    
    if let path = Bundle.main.path(forResource: resource, ofType: "mp3") {
        let url = URL(fileURLWithPath: path)

        do {
            player = try AVAudioPlayer(contentsOf: url)
            return player
        } catch {
            print("Couldn't create player")
            return nil
        }
    }
    
    print("Couldn't find sound file")
    return nil
}

extension AVAudioPlayer {
    func playFromBeginning() {
        if isPlaying {
            pause()
        }
        currentTime = 0
        play()
    }
}

func getFontWithAlignedNumbers(font: String, size: CGFloat) -> CTFont {
    let font = CTFontCreateWithName(font as CFString, size, nil)

    let fontFeatureSettings: [CFDictionary] = [
        [
            kCTFontFeatureTypeIdentifierKey: kNumberCaseType,
            kCTFontFeatureSelectorIdentifierKey: 1,
        ] as CFDictionary
    ]

    let fontDescriptor = CTFontDescriptorCreateWithAttributes([
        kCTFontFeatureSettingsAttribute: fontFeatureSettings
    ] as CFDictionary)

    let fontWithFeatures = CTFontCreateCopyWithAttributes(font, size, nil, fontDescriptor)
    return fontWithFeatures
}

func getDiagonal(from rect: CGRect) -> CGFloat {
    sqrt(pow(rect.width, 2)+pow(rect.height, 2))
}

extension NSTextField {
    open override var focusRingType: NSFocusRingType {
            get { .none }
            set { }
    }
}

