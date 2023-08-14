import SwiftUI
import AVFoundation

let playgroundRect = CGRect(x: 0, y: 0, width: 960, height: 700)

struct ContentView: View {
    @ObservedObject var playgroundData = DataModel()
    @Namespace private var animation
    
    @State var window: NSWindow?
    
    var body: some View {
        Group {
            switch playgroundData.currentScreen {
            case .title:
                TitleScreen()
            case .intro:
                IntroScreen(animation: animation)
                    .onAppear {
                        Sounds.background?.numberOfLoops = -1
                        Sounds.background?.play()
                    }
            case.canvas:
                CanvasScreen(animation: animation)
            }
        }
        .environmentObject(playgroundData)
        .frame(width: playgroundRect.width, height: playgroundRect.height)
        .clipShape(RoundedRectangle(cornerRadius: 7.0, style: .continuous))
        .onAppear {
            if let url = Bundle.main.url(forResource: "Raleway", withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, CTFontManagerScope.process, nil)
            }
        }
        .accessHostingWindow($window) { window in
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        }
    }
}
