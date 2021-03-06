// This view renders Seth, our mascot

import SwiftUI

struct SethView: View {
    @Binding var paused: Bool
    
    var body: some View {
        Image(nsImage: NSImage(named: "Seth.png")!)
        .resizable().aspectRatio(contentMode: .fit)
            .background(paused ? nil : IrregularGradient(colors: [Color.playgroundTheme.orange, Color.playgroundTheme.yellow, Color.playgroundTheme.green, Color.playgroundTheme.blue], backgroundColor: Color.playgroundTheme.blue, speed: 1).scaleEffect(x: 0.32, y: 0.4, anchor: .bottom)
                        .mask(Image(nsImage: NSImage(named: "Seth Mask.png")!)
                                .resizable().aspectRatio(contentMode: .fit)))
    }
}
