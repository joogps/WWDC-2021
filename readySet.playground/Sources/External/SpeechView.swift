// This renders the speech view used for user interaction

import SwiftUI

struct SpeechView: View {
    let text: String
    let skip: Binding<Bool>
    let completion: (() -> ())?
    
    let arrowPosition: SpeechBubbleArrowPosition
    let lineWidth: CGFloat
    let innerPadding: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    
    init(text: String, skip: Binding<Bool> = .constant(false), completion: (() -> ())? = nil, arrowPosition: SpeechBubbleArrowPosition = .topLeading, lineWidth: CGFloat = 15.0, innerPadding: CGFloat = 25.0) {
        self.text = text
        self.skip = skip
        self.completion = completion
        
        self.arrowPosition = arrowPosition
        self.lineWidth = lineWidth
        self.innerPadding = innerPadding
    }
    
    var body: some View {
        HStack {
            Spacer()
            typewriter
            Spacer()
        }.background(background)
    }
    
    var typewriter: some View {
        TypewriterText(text, skip: skip, completion: completion)
            .foregroundColor(colorScheme == .dark ? Color.playgroundTheme.white : Color.playgroundTheme.gray)
            .padding(innerPadding)
            .padding(arrowPosition == .topLeading ? .leading : .bottom, 35)
    }
    
    var background: some View {
        ZStack {
            IrregularGradient(colors: [Color.playgroundTheme.orange, Color.playgroundTheme.yellow, Color.playgroundTheme.green, Color.playgroundTheme.blue], backgroundColor: Color.playgroundTheme.blue, speed: 5)
                .scaleEffect(1.2)
                .mask(SpeechBubble(arrowPosition: arrowPosition).stroke(Color.black, lineWidth: lineWidth))
            SpeechBubble(arrowPosition: arrowPosition).fill(colorScheme == .dark ? Color.playgroundTheme.black : Color.white)
        }
    }
}

struct TypewriterText: View {
    let fullText: String
    let skip: Binding<Bool>
    let completion: (() -> ())?
    
    init(_ fullText: String, skip: Binding<Bool> = .constant(false), completion: (() -> ())? = nil) {
        self.fullText = fullText
        self.skip = skip
        self.completion = completion
    }
    
    @State var index = 0
    
    var formattedString: String {
        (skip.wrappedValue ? fullText[...] : fullText[..<String.Index(utf16Offset: index, in: fullText)]).replacingOccurrences(of: "/", with: "")
    }
    
    var body: some View {
        Text(fullText)
            .hidden()
            .background(Text(formattedString))
            .onAppear(perform: update)
    }
    
    func update() {
        if index < fullText.count && !skip.wrappedValue {
            let pause = fullText[String.Index(utf16Offset: index, in: fullText)] == "/" ? 0.5 : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04+pause) {
                index += 1
                update()
            }
        } else {
            completion?()
        }
    }
}

// I'm not proud of this.

struct SpeechBubble: Shape {
    let arrowPosition: SpeechBubbleArrowPosition
    
    func path(in rect: CGRect) -> Path {
        var balloon = Path()
        
        let radius = CGFloat(25)
        
        let arrowSize = CGSize(width: 35, height: 35)
        let arrowRadius = CGFloat(3)
        
        // Top left
        balloon.move(to: CGPoint(x: rect.minX+(arrowPosition == .topLeading ? arrowSize.width : 0), y: rect.minY+radius))
        balloon.addArc(center: CGPoint(x: rect.minX+radius+(arrowPosition == .topLeading ? arrowSize.width : 0), y: rect.minY+radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        
        // Top right
        balloon.addArc(center: CGPoint(x: rect.maxX-radius, y: rect.minY+radius), radius: radius, startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
        
        // Bottom right
        balloon.addArc(center: CGPoint(x: rect.maxX-radius, y: rect.maxY-radius-(arrowPosition == .bottomTrailing ? arrowSize.height : 0)), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        if arrowPosition == .bottomTrailing {
            balloon.addArc(center: CGPoint(x: rect.maxX-radius-arrowRadius, y: rect.maxY-arrowRadius), radius: arrowRadius, startAngle: .degrees(0), endAngle: .degrees(135), clockwise: false)
            balloon.addLine(to: CGPoint(x: rect.maxX-radius-arrowSize.width, y: rect.maxY-arrowSize.height))
        }
        
        // Bottom left
        balloon.addArc(center: CGPoint(x: rect.minX+radius+(arrowPosition == .topLeading ? arrowSize.width : 0), y: rect.maxY-radius-(arrowPosition == .bottomTrailing ? arrowSize.height : 0)), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        
        if arrowPosition == .topLeading {
            balloon.addLine(to: CGPoint(x: rect.minX+arrowSize.width, y: rect.minY+radius+arrowSize.height))
            balloon.addArc(center: CGPoint(x: rect.minX+arrowRadius, y: rect.minY+radius+arrowRadius), radius: arrowRadius, startAngle: .degrees(135), endAngle: .degrees(270), clockwise: false)
        }
        
        balloon.closeSubpath()
        
        return balloon
    }
}

enum SpeechBubbleArrowPosition {
    case topLeading
    case bottomTrailing
}

struct SpeechView_Previews: PreviewProvider {
    static var previews: some View {
        SpeechView(text: "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor.")
    }
}
