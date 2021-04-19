import PlaygroundSupport
import SwiftUI
import AVFoundation

let playgroundRect = CGRect(x: 0, y: 0, width: 960, height: 700)

struct ContentView: View {
    @ObservedObject var playgroundData = DataModel()
    @Namespace private var animation
    
    @State var background: AVAudioPlayer? = createPlayer(for: "Sounds/Background")
    
    var body: some View {
        Group {
            switch playgroundData.currentScreen {
            case .title:
                TitleScreen()
            case .intro:
                IntroScreen(animation: animation)
                    .onAppear {
                        background?.numberOfLoops = -1
                        background?.play()
                    }
            case.canvas:
                CanvasScreen(animation: animation)
            }
        }.environmentObject(playgroundData)
        .frame(width: playgroundRect.width, height: playgroundRect.height)
        .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous))
    }
}

public func readySet() {
    let cfURL = Bundle.main.url(forResource: "Raleway", withExtension: "ttf")! as CFURL
    CTFontManagerRegisterFontsForURL(cfURL, CTFontManagerScope.process, nil)
    
    let view = ContentView()
    PlaygroundPage.current.setLiveView(view)
}

