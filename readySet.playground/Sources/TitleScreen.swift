// This SwiftUI view renders the title screen of this playground experience

import SwiftUI
import AVFoundation

struct TitleScreen: View {
    @EnvironmentObject var playgroundData: DataModel
    
    @State var animationState: TitleAnimationState = .splash
    
    @State var mouseLocation = CGPoint(x: playgroundRect.midX, y: playgroundRect.midY)
    var perspectiveAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        let x = (mouseLocation.y-playgroundRect.midY)/2
        let y = (mouseLocation.x-playgroundRect.midX)/2
        
        return (x: -x, y: y, z: 0)
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var theme: AVAudioPlayer? = createPlayer(for: "Sounds/Title/Theme")
    var exit: AVAudioPlayer? = createPlayer(for: "Sounds/Title/Exit")
    
    var body: some View {
        ZStack {
            if animationState >= .background {
                background
                logo
                button
            } else {
                splash
            }
        }.onAppear {
            theme?.numberOfLoops = -1
            theme?.play()
            
            DispatchQueue.main.asyncAfter(deadline: .now()+2.25) {
                withAnimation {
                    animationState = .background
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now()+3.5) {
                withAnimation {
                    animationState = .logo
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now()+4.5) {
                withAnimation {
                    animationState = .grid
                }
            }
        }
    }
    
    var splash: some View {
        VStack {
            Spacer()
            Text("Swift Student Challenge '21")
                .font(Font(getFontWithAlignedNumbers(font: "Raleway", size: 25)).weight(.medium))
            Spacer()
            Text("created by @joogps")
                .font(.custom("Raleway", size: 19))
                .foregroundColor(Color(.systemGray))
        }.padding(40)
    }
    
    var background: some View {
        ZStack {
            IrregularGradient(colors: [Color.playgroundTheme.orange, Color.playgroundTheme.yellow, Color.playgroundTheme.green, Color.playgroundTheme.blue], speed: 8)
                .trackingMouse { location in
                    self.mouseLocation = location
                }
            
            if animationState >= .grid {
                SymbolGrid(animationState: $animationState)
                    .frame(width: playgroundRect.width, height: playgroundRect.height)
            }
            
            Color.playgroundTheme.white.opacity(colorScheme == .dark ? 0.3 : 0.4)
            
            RadialGradient(gradient: Gradient(colors: colorScheme == .dark ? [Color.playgroundTheme.gray, Color.playgroundTheme.gray.opacity(0)] : [Color.playgroundTheme.white, Color.playgroundTheme.white.opacity(0)]), center: .bottom, startRadius: animationState > .grid ? getDiagonal(from: playgroundRect) : 1, endRadius: animationState > .grid ? getDiagonal(from: playgroundRect)*2 : 1)
                .opacity(animationState > .grid ? 1.0 : 0.0)
                .animation(Animation.spring(response: 0.9, dampingFraction: 0.9).delay(2))
        }
    }
    
    var logo: some View {
        ZStack {
            if animationState >= .logo && animationState <= .grid {
                Image(nsImage: NSImage(named: "Logo.png")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 230)
                .transition(.offset(y: 230))
                .rotation3DEffect(
                    .init(degrees: 7),
                    axis: perspectiveAxis
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 5, y: 5)
                .animation(.spring(response: 0.7, dampingFraction: 0.9))
            }
        }.mask(Rectangle().frame(width: 500, height: 230, alignment: .center))
    }
    
    var button: some View {
        VStack {
            Button("", action: exitTitle).opacity(0)
            .disabled(!(animationState == .grid))
            .allowsHitTesting(false)
            .keyboardShortcut("r")
            
            Spacer()
            
            if animationState == .grid {
                Button(action: exitTitle, label: {
                    Text("press ⌘R to begin")
                        .font(Font.custom("Raleway", size: 22).weight(.semibold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 5, y: 5)
                }).buttonStyle(PlainButtonStyle())
            }
        }.padding(80)
    }
    
    func exitTitle() {
        theme?.pause()
        exit?.play()
        
        withAnimation(Animation.spring(response: 0.85, dampingFraction: 0.8).delay(0.85)) {
            animationState = .exit
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+4, execute: {
            withAnimation {
                playgroundData.currentScreen = .intro
            }
        })
    }
}

enum TitleAnimationState: Int, Comparable {
    static func < (lhs: TitleAnimationState, rhs: TitleAnimationState) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case splash = 0
    case background = 1
    case logo = 2
    case grid = 3
    case exit = 4
}

// This view renders the grid of symbols in the background

struct SymbolGrid: View {
    @State var symbols = [GridSymbol]()
    
    @Binding var animationState: TitleAnimationState
    
    let optionPool = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "Ø", "{", "}", "U"]
    let columns = Array(repeating: GridItem(.flexible()), count: 8)
    
    let indexes = Set(0...64-1)
        .subtracting(3*8+3-1...3*8+6-1)
        .subtracting(4*8+3-1...4*8+6-1)
        .subtracting(6*8+4-1...6*8+5-1)
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(symbols, id:\.id) { symbol in
                Text(symbol.text)
                    .transition(AnyTransition.offset([CGSize(width: 1, height: 0),
                                                        CGSize(width: 0, height: 1),
                                                        CGSize(width: -1, height: 0),
                                                        CGSize(width: 0, height: -1)].randomElement()!
                                                        .applying(.init(scaleX: 20, y: 20))).combined(with: .opacity))
                    .opacity(symbol.opacity)
                    .clipShape(Rectangle())
            }
        }.font(Font(getFontWithAlignedNumbers(font: "Raleway", size: 72)).weight(.black))
        .foregroundColor(.white)
        .onChange(of: animationState) { _ in
            if animationState > .grid {
                for n in 0...63 {
                    withAnimation(Animation.easeInOut(duration: 1).delay(Double.random(in: 0...1))) {
                        symbols[n] = GridSymbol(text: " ")
                    }
                }
            }
        }.onAppear {
            for _ in 1...64 {
                symbols.append(GridSymbol(text: " ", opacity: 1.0))
            }
            
            for n in indexes {
                withAnimation(Animation.easeInOut(duration: 1).delay(Double.random(in: 0...2))) {
                    setSymbol(for: n)
                }
            }
        }.onReceive(timer) { _ in
            if animationState < .exit {
                withAnimation(Animation.easeInOut(duration: 0.5)) {
                    setSymbol(for: indexes.randomElement()!)
                }
            }
        }
    }
    
    func setSymbol(for index: Int, delay: Double = 0) {
        let symbol = optionPool.randomElement()!
        let dontPanic = Double.random(in: 0...1) < 0.01 && !symbols.contains { $0.text == "42" }
        
        symbols[index] = GridSymbol(text: dontPanic ? "42" : symbol, opacity: Double.random(in: 0.1...0.5))
    }
}

struct GridSymbol {
    var id = UUID()
    var text: String
    var opacity: Double = 1.0
}
