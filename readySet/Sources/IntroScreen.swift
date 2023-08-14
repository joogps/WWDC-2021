// This SwiftUI view presents the introduction screen of this playground experience

import SwiftUI

struct IntroScreen: View {
    @EnvironmentObject var playgroundData: DataModel
    
    var animation: Namespace.ID
    
    @State var showingExamples: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    let setA = MathSet(userSet: UserMathSet(style: (name: "A", color: Color.playgroundTheme.blue), elements: [1, 2, 3, 4, 5]))
    let setB = MathSet(userSet: UserMathSet(style: (name: "B", color: Color.playgroundTheme.green), elements: [2, 3, 5, 7, 11, 13]))
    let setC = MathSet(userSet: UserMathSet(style: (name: "C", color: Color.playgroundTheme.yellow), elements: [115, 70, 20, 67, 18, 96]))
    let setD = MathSet(userSet: UserMathSet(style: (name: "D", color: Color.playgroundTheme.orange), elements: [1.2, 1.4, 1.6, 1.8, 2.0]))
    
    @State var bubbleSounds = [createPlayer(for: "Bubble 1"), createPlayer(for: "Bubble 2"), createPlayer(for: "Bubble 3")]
    
    var body: some View {
        ZStack {
            colorScheme == .dark ? Color.playgroundTheme.gray : Color.playgroundTheme.white
            
            if showingExamples && playgroundData.currentIntroPhase == .defined {
                ExampleSetView(set: setA, size: 38).position(x: 300, y: 600)
                ExampleSetView(set: setB, size: 35).position(x: 640, y: 515)
                ExampleSetView(set: setC, size: 33).position(x: 310, y: 175)
                ExampleSetView(set: setD, size: 37).position(x: 630, y: 90)
                
                MathObjectView(object: MathIntersection(gap: CGFloat(setA.userSet.elements.intersection(setB.userSet.elements).count*30), lhs: setA, rhs: setB)).position(x: 630, y: 700).transition(AnyTransition.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
                MathObjectView(object: MathIntersection(gap: -35, lhs: setC, rhs: setD)).position(x: 200, y: 0).transition(AnyTransition.scale(scale: 0.5, anchor: .top).combined(with: .opacity))
            }
            
            switch playgroundData.currentIntroPhase {
            case .hi: IntroMessageView(text: "//Hi there!/ It's really nice to meet you in this, huh...// in this app, of course!", nextPhase: .seth, animation: animation)
            case .seth: IntroMessageView(text: "My name is Seth, by the way, and, according to my internal logs, I was designed to teach about set theory./\n\nOk then, set theory it is!", nextPhase: .know, animation: animation)
            case .know: IntroMessageView(text: "Now, don't get me wrong: I'm pretty sure YOU already know a LOT about set theory./ But I promise this will be fun nonetheless!", nextPhase: .remember, animation: animation)
            case .remember: IntroMessageView(text: "However, juuuust to remember, set theory is the branch of mathematics that studies.../ well, sets.", nextPhase: .sets, animation: animation)
            case .sets: IntroMessageView(text: "A set is a collection of non-repeatable objects./\n\nAnd, in fact, these objects can be anything you want them to be!/ In most cases though, these objects will be something relevant to the study of math (such as numbers or even sets themselves).", nextPhase: .defined, animation: animation)
            case .defined: IntroMessageView(text: "Sets can be defined with 􀫲 shapes and diagrams, or via special notations, always between 􀡅 curly braces./ You can see some examples displayed around my magic speech bubble.  ", nextPhase: .talking, completion: {
                    withAnimation(.spring()) {
                        showingExamples = true
                    }
                }, animation: animation)
            case .talking: IntroMessageView(text: "Enough of me talking though, what about going to the real deal?// Click on 􀁭 or press the right arrow key to access the 􀮋 Canvas.  ", nextPhase: .talking, action: {
                    withAnimation(.spring()) {
                        playgroundData.currentScreen = .canvas
                    }
                }, animation: animation)
            }
        }.onAppear(perform: playBubbleSound)
        .onChange(of: playgroundData.currentIntroPhase) { value in
            playBubbleSound()
            
            if value == .defined {
                DispatchQueue.main.asyncAfter(deadline: .now()+5.5) {
                    withAnimation(.spring()) {
                        showingExamples = true
                    }
                }
            } else {
                withAnimation(.spring()) {
                    showingExamples = false
                }
            }
        }
    }
    
    func playBubbleSound() {
        let player = bubbleSounds.randomElement()!
        player?.playFromBeginning()
    }
}

struct ExampleSetView: View {
    var set: MathSet
    var size: CGFloat
    
    var color: Color {
        self.set.userSet.color
    }
    
    var colorTones: (background: Color, foreground: Color) {
        (background: Color(hue: Double(NSColor(color).hueComponent), saturation: colorScheme == .dark ? 0.1 : 0.05, brightness: colorScheme == .dark ? 0.3 : 1.0), foreground: Color(hue: Double(NSColor(color).hueComponent), saturation: colorScheme == .dark ? 0.6 : 0.5, brightness: colorScheme == .dark ? 0.9 : 0.4))
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        (Text(set.userSet.name + " = { ").font(.system(size: size, weight: .bold, design: .serif)) +
            Text(set.userSet.parsedElements).font(Font(getFontWithAlignedNumbers(font: "Raleway", size: size)).weight(.medium)) +
            Text(" }").font(.system(size: size, weight: .bold, design: .serif))).foregroundColor(colorTones.foreground).padding().padding(.horizontal).background(Capsule().fill(colorTones.background))
            .shadow(color: color.opacity(0.05), radius: 10, x: 5, y: 5)
            .transition(AnyTransition.scale(scale: 0.5).combined(with: .opacity))
    }
}

struct IntroMessageView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    var text: String
    var nextPhase: IntroPhases
    var action: () -> () = {}
    
    var completion: () -> () = {}
    
    var animation: Namespace.ID?
    
    @State var skip = false
    
    @State var showingSpeech = false
    @State var showingNext = false
    
    @State var offsetMovement: CGFloat = 1.0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .top, spacing: 5) {
                SethView(paused: $showingNext).frame(width: 255)
                    .rotationEffect(.degrees(-5))
                    .offset(y: -20+offsetMovement*6)
                    .animation(.easeInOut(duration: 1.25))
                    .matchedGeometryEffect(id: "Seth", in: animation ?? Namespace().wrappedValue)
                
                Spacer()
                
                if showingSpeech {
                    speech
                }
            }.padding(60)
            
            VStack {
                Spacer()
                
                Button("", action: {
                    if showingNext {
                        goToNextPhase()
                    } else {
                        skip = true
                    }
                }).opacity(0)
                .allowsHitTesting(false)
                .keyboardShortcut(.rightArrow, modifiers: [])
                
                ZStack(alignment: .topLeading) {
                    if showingNext {
                        RoundedRectangle(cornerRadius: 25.0, style: .continuous).fill(Color(white: colorScheme == .dark ? 0.3 : 0.98))
                    }
                    if showingNext {
                        next.padding(20)
                    }
                }.frame(width: 200, height: 200)
                .offset(x: 100, y: 100)
            }
        }.shadow(color: Color.black.opacity(0.05), radius: 10, x: 5, y: 5)
        .transition(.scale(scale: 0.95))
        .contentShape(Rectangle().size(playgroundRect.size))
        .onTapGesture {
            skip = true
        }.onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showingSpeech = true
            }
            
            withAnimation(Animation.easeInOut(duration: 1.75)) {
                offsetMovement = -offsetMovement
            }
        }.onReceive(timer) { _ in
            withAnimation(Animation.easeInOut(duration: 1.75).delay(0.3)) {
                offsetMovement = -offsetMovement
            }
        }
    }
    
    var speech: some View {
        SpeechView(text: text, skip: $skip, completion: {
            completion()
            
            withAnimation(.spring()) {
                showingNext = true
            }
        }).font(Font.custom("Raleway", size: 20).weight(.semibold))
        .transition(AnyTransition.scale(scale: 0.5, anchor: .topLeading).combined(with: .opacity))
        .offset(y: offsetMovement*3.5)
    }
    
    var next: some View {
        Button(action: goToNextPhase) {
            Image(systemName: "arrowtriangle.right.circle.fill")
                .resizable().frame(width: 68, height: 68)
                .foregroundColor(Color.playgroundTheme.blue)
                .overlay(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing).mask(Image(systemName: "arrowtriangle.right.circle.fill").resizable().frame(width: 68, height: 68)))
        }.buttonStyle(PlainButtonStyle())
        .shadow(color: colorScheme == .dark ? Color.playgroundTheme.blue.opacity(0.2) : .clear, radius: 8)
        .transition(AnyTransition.scale(scale: 0.6).combined(with: .opacity))
        .help("Next")
    }
    
    func goToNextPhase() {
        withAnimation {
            playgroundData.currentIntroPhase = nextPhase
        }
        action()
    }
}

enum IntroPhases {
    case hi
    case seth
    case know
    case remember
    case sets
    case defined
    case talking
}
