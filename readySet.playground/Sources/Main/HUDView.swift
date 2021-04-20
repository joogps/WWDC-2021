import SwiftUI
import AVFoundation

struct HUDView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    var animation: Namespace.ID
    
    @State var messageCondition: (() -> (HUDPhases?))?
    @State var helpState: (() -> ())?
    
    @State var definingBy: Definitions = .enumeration
    
    @State var text: String = ""
    var textElements: Set<Double> {
        Set(text.components(separatedBy: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) })
    }
    
    let setStyles = [(name: "A", color: Color.playgroundTheme.blue),
                     (name: "B", color: Color.playgroundTheme.green),
                     (name: "C", color: Color.playgroundTheme.yellow),
                     (name: "D", color: Color.playgroundTheme.orange)]
    @State var currentSetStyleIndex = 0
    
    var availableSetStylesIndexes: [Int]  {
        let usedStyles = playgroundData.currentSets.map { (name: $0.name, color: $0.color) }
        let availableStyles = setStyles.filter { set in !usedStyles.contains { $0 == set } }
        return availableStyles.map { set in setStyles.firstIndex { $0 == set }! }
    }
    
    var currentSetStyle: (name: String, color: Color) {
        setStyles[currentSetStyleIndex]
    }
    
    @State var currentMenu: HUDMenus?
    
    @State var spotlight: HUDSpotlights?
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var openMenuSound: AVAudioPlayer? = createPlayer(for: "Sounds/Menu/Open")
    @State var closeMenuSound: AVAudioPlayer? = createPlayer(for: "Sounds/Menu/Close")
    @State var fileSelectMenuSound: AVAudioPlayer? = createPlayer(for: "Sounds/Menu/File select")
    @State var emptyMenuSound: AVAudioPlayer? = createPlayer(for: "Sounds/Menu/Empty")
    @State var helpMenuSound: AVAudioPlayer? = createPlayer(for: "Sounds/Menu/Help")
    @State var undoMenuSound: AVAudioPlayer? = createPlayer(for: "Sounds/Menu/Undo")
    @State var redoMenuSound: AVAudioPlayer? = createPlayer(for: "Sounds/Menu/Redo")
    
    @State var bubbleSounds = [createPlayer(for: "Sounds/Bubble/Bubble 1"), createPlayer(for: "Sounds/Bubble/Bubble 2"), createPlayer(for: "Sounds/Bubble/Bubble 3")]
    
    @State var simpleSetSound = createPlayer(for: "Sounds/Sets/Simple")
    @State var intersectionContainmentSetSound = createPlayer(for: "Sounds/Sets/Intersection : Containment")
    @State var complexIntersectionContainmentSetSound = createPlayer(for: "Sounds/Sets/Complex Intersection : Containment")
    @State var threewaySetSound = createPlayer(for: "Sounds/Sets/Three-way")
    @State var emptySetSound = createPlayer(for: "Sounds/Sets/Empty")
    
    var body: some View {
        ZStack {
            if spotlight != nil {
                Color.black.opacity(0.5)
            }
            
            ZStack(alignment: .topLeading) {
                VStack(alignment: .trailing) {
                    Spacer()
                    messages
                    toolbar
                }
                
                HStack(alignment: .top) {
                    if currentMenu != nil {
                        Group {
                            switch currentMenu! {
                            case .fileSelection:
                                fileSelectionMenu
                            case .emptyCanvas:
                                emptyCanvasMenu
                            case .help:
                                helpMenu
                            }
                        }.frame(width: 270)
                    } else {
                        menus
                    }
                    
                    Spacer()
                    
                    counter
                }
            }.padding(30)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 5, y: 5)
        }.frame(width: playgroundRect.width, height: playgroundRect.height)
        .onAppear(perform: playBubbleSound)
        .onChange(of: text) { _ in
            dismissMenu()
            evaluateCondition()
        }.onChange(of: playgroundData.activePopover) { _ in
            dismissMenu()
            evaluateCondition()
        }.onChange(of: playgroundData.userSetFiles) { _ in
            withAnimation {
                if !availableSetStylesIndexes.contains(currentSetStyleIndex) {
                    currentSetStyleIndex = availableSetStylesIndexes[0]
                }
            }
            
            dismissMenu()
            evaluateCondition()
        }.onChange(of: playgroundData.currentCanvasPhase) { _ in
            playBubbleSound()
            helpState = nil
            messageCondition = nil
        }
    }
    
    func evaluateCondition() {
        if messageCondition != nil {
            if let result = messageCondition!() {
                playgroundData.currentCanvasPhase = result
            }
        }
    }
    
    @ViewBuilder
    var messages: some View {
        if playgroundData.currentCanvasPhase != nil {
            switch playgroundData.currentCanvasPhase! {
            case .welcome: HUDMessageView(text: "/Welcome to the 􀮋 Canvas!/ Here is where you will play with sets. ", nextPhase: .panAndZoom, animation: animation)
            case .panAndZoom: HUDMessageView(text: "There's plenty of free space to explore, but you can 􀧐 pan and 􀊬 zoom with drags and mouse gestures if you feel like it!  ", nextPhase: .buttons)
            case .buttons: HUDMessageView(text: "There are a few important buttons and displays up at the top that will be very helpful soon! ", nextPhase: .toolbar, onAppear: {
                    withAnimation {
                        spotlight = .buttons
                    }
                })
            case .toolbar: HUDMessageView(text: "And you might've already noticed that there's a nice lil' toolbar right below me./ You'll use it to create your first set!/\n\nPro tip: you can click on the set letter to bring up the style selector. 💅 ", nextPhase: .type, onAppear: {
                    withAnimation {
                        spotlight = .toolbar
                    }
                })
            case .type: HUDMessageView(text: "Okay, let's get going!/ To add items to a set, just 􀇳 type the numbers you want in the input field, separated by commas. ", onAppear: {
                    withAnimation {
                        spotlight = nil
                    }
                    
                    helpState = {
                        text = "2, 3, 5"
                    }
                    
                    messageCondition = {
                        if playgroundData.currentSets.count > 0 {
                            dispatchToPhase(phase: .click)
                            return playgroundData.currentSets.last!.elements.count == 0 ? .empty : .great
                        } else {
                            return textElements.count >= 3 ? .send : nil
                        }
                    }
                })
            case .send: HUDMessageView(text: "Now hit 􀁧 or return to send your set to the.../ set.../ manager. ", onAppear: {
                    helpState = {
                        if textElements.count >= 3 {
                            addSet()
                        } else {
                            playgroundData.currentSets = [UserMathSet(style: currentSetStyle, elements: [2, 3, 5])]
                            playgroundData.parseSets()
                        }
                    }
                    
                    messageCondition = {
                        if playgroundData.currentSets.count > 0 {
                            dispatchToPhase(phase: .click)
                            return playgroundData.currentSets.last!.elements.count == 0 ? .empty : .great
                        }
                        
                        return nil
                    }
                })
            case .great: HUDMessageView(text: "Great! 🤖/\n\nSee your shiny new set being drawn there?/ That type of drawing is known as a Venn diagram. ", nextPhase: .click)
            case .empty: HUDMessageView(text: "Oopsie! 😅/\n\nThe set you have created is actually an empty set!/ But, don't worry, you'd get to that part eventually./ For now, keep in mind that empty sets can be also represented by the symbol Ø. ")
            case .click: HUDMessageView(text: "OK, now try to click on it to view more information!", onAppear: {
                    helpState = {
                        if playgroundData.currentSets.count == 0 {
                            playgroundData.currentSets = [UserMathSet(style: currentSetStyle, elements: [2, 3, 5])]
                            playgroundData.parseSets()
                        }
                        
                        playgroundData.activePopover = playgroundData.parsedObjects.first?.id
                    }
                    
                    messageCondition = { playgroundData.activePopover != nil ? .intersection : nil }
                })
            case .intersection: HUDMessageView(text: "Awesome! 🎉/\n\nNow go ahead and create an entirely new set, sharing at least one of the elements of this already existing set, to see what happens. ", onAppear: {
                    helpState = {
                        playgroundData.currentSets = [UserMathSet(style: setStyles[0], elements: [2, 3, 5]), UserMathSet(style: setStyles[1], elements: [5, 7, 11])]
                        playgroundData.parseSets()
                    }
                    
                    messageCondition = {
                        if playgroundData.currentSets.count > 0 {
                            if playgroundData.currentSets.last!.elements.count == 0 {
                                dispatchToPhase(phase: .intersection)
                                return .empty
                            }
                            if let intersection = playgroundData.parsedObjects.first(where: { $0 is MathIntersection }) as? MathIntersection {
                                return intersection.lhs is MathIntersection || intersection.rhs is MathIntersection ? .complexIntersectionExplanation : .intersectionExplanation
                            }
                        }
                        
                        return nil
                    }
                })
            case .intersectionExplanation: HUDMessageView(text: "Hooray!/\nYou're on fire! 🔥/\n\nThis new diagram that resulted from your creation is called an 􀫲 Intersection!/ The section in the middle of it can be represented by \((playgroundData.parsedObjects.first { $0 is MathIntersection } as? MathIntersection)?.description.prefix(5) ?? "A ∩ B").  ", nextPhase: .complexIntersection)
            case .complexIntersection: HUDMessageView(text: "Let's hurry up cause there's still a lot to go through!/\n\nNow you should try to create a third set, so that it shares elements with only one of those intersecting ones.", onAppear: {
                    helpState = {
                        playgroundData.currentSets = [UserMathSet(style: setStyles[0], elements: [2, 3, 5]), UserMathSet(style: setStyles[1], elements: [5, 7, 11]), UserMathSet(style: setStyles[2], elements: [11, 13, 17])]
                        playgroundData.parseSets()
                    }
                    
                    messageCondition = {
                        if playgroundData.currentSets.count > 0 {
                            if playgroundData.currentSets.last!.elements.count == 0 {
                                dispatchToPhase(phase: .complexIntersection)
                                return .empty
                            }
                            if let intersection = playgroundData.parsedObjects.first(where: { $0 is MathIntersection }) as? MathIntersection {
                                return intersection.lhs is MathIntersection || intersection.rhs is MathIntersection ? .complexIntersectionExplanation : nil
                            }
                        }
                        
                        return nil
                    }
                })
            case .complexIntersectionExplanation: HUDMessageView(text: "Yay, this one is my favorite! 🙃/\n\nYou see, you've now created a complex kind of intersection./ In fact, there are two intersections here, and they are only tied because of the set in the middle!/ Doesn't it look.../ a bit olympic to you? ", nextPhase: .containment)
            case .containment: HUDMessageView(text: "Alright!/ Ready for more?/\n\nHave you wondered what would happen if a set contained all of the elements of another set?/\n\nQuick tip: you can empty the canvas to make this task easier.", onAppear: {
                helpState = {
                    playgroundData.currentSets = [UserMathSet(style: setStyles[2], elements: [2, 3, 5]), UserMathSet(style: setStyles[3], elements: [2, 3, 5, 6, 7, 11])]
                    playgroundData.parseSets()
                }
                
                messageCondition = {
                    if playgroundData.currentSets.count > 0 {
                        if playgroundData.currentSets.last!.elements.count == 0 {
                            dispatchToPhase(phase: .containment)
                            return .empty
                        }
                        if playgroundData.parsedObjects.first(where: { $0 is MathContainment }) != nil {
                            return .containmentExplanation
                        }
                    }
                    
                    return nil
                }
            })
            case .containmentExplanation: HUDMessageView(text: "I love it! 💕/\n\nThis one is actually very straight-forward: since one of the sets contains the other, this is also represented in the diagram./ A set can also contain multiple sets, or even an intersection./ This relationship can be expressed by \((playgroundData.parsedObjects.first { $0 is MathContainment } as? MathContainment)?.description ?? "A ⊂ B")  ", nextPhase: .threeway)
            case .threeway: HUDMessageView(text: "Now we're wrapping up! 🎁/\n\nFor this final task, think of how you could make three sets share a same subset of elements. Impress me!/\n\nPro tip: to make it look really nice, try making all sets the exact same size.", onAppear: {
                helpState = {
                    playgroundData.currentSets = [UserMathSet(style: setStyles[2], elements: [2, 3, 5]), UserMathSet(style: setStyles[0], elements: [3, 5, 7]), UserMathSet(style: setStyles[1], elements: [5, 7, 11])]
                    playgroundData.parseSets()
                }
                
                messageCondition = {
                    if playgroundData.currentSets.count > 0 {
                        if playgroundData.currentSets.last!.elements.count == 0 {
                            dispatchToPhase(phase: .threeway)
                            return .empty
                        }
                        if playgroundData.parsedObjects.first(where: { $0 is MathThreeway }) != nil {
                            return .threewayExplanation
                        }
                    }
                    
                    return nil
                }
            })
            case .threewayExplanation: HUDMessageView(text: "Good job! ✨/\n\nIn this case, three sets overlap on the diagram, forming a circular-triangular sort of shape in the middle, which can be represented by \((playgroundData.parsedObjects.first { $0 is MathThreeway } as? MathThreeway)?.description.prefix(9) ?? "A ∩ B ∩ C").   ", nextPhase: .cover)
            case .cover: HUDMessageView(text: "Oh!/ This went fast!/\n\nWe're short on time here, so there are many topics, like operations and the set-builder, that we still didn't cover!/ But it's okay though, because at least we had a ton of fun./ Right?", nextPhase: .thankyou)
            case .thankyou: HUDMessageView(text: "Well, for now... that's it!/ Thank you so much!/ I'm leaving, but I hope we can meet again soon, okay?/\n\nKeep it up! 👋  ", onAppear: {
                DispatchQueue.main.asyncAfter(deadline: .now()+10) {
                    withAnimation {
                        playgroundData.currentCanvasPhase = nil
                    }
                }
            })
            }
        }
    }
    
    func dispatchToPhase(phase: HUDPhases) {
        DispatchQueue.main.asyncAfter(deadline: .now()+12.5, execute: { playgroundData.currentCanvasPhase = phase })
    }
    
    func playBubbleSound() {
        let player = bubbleSounds.randomElement()!
        player?.playFromBeginning()
    }
    
    var toolbar: some View {
        VStack(spacing: 0) {
            sets.frame(maxHeight: playgroundData.parsedObjects.count > 0 ? 10 : 0)
            
            HStack(spacing: 0) {
                notationSelector
                input
                send
            }.frame(height: 50)
        }.overlay((spotlight != nil ? (spotlight == .toolbar ? Color.clear :  Color.black.opacity(0.5)) : Color.clear).allowsHitTesting(false))
        .cornerRadius(15.0)
        .shadow(color: colorScheme == .dark ? currentSetStyle.color.opacity(0.1) : .clear, radius: 10)
    }
    
    var sets: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(playgroundData.parsedObjects, id: \.id) { object in
                HUDMathObjectView(object: object, isFinal: true)
            }
        }.overlay(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)]), startPoint: .top, endPoint: .center).allowsHitTesting(false))
    }
    
    var notationSelector: some View {
        ZStack {
            colorScheme == .dark ? Color.playgroundTheme.black : Color.white
            
            Menu {
                Text("Notation")
                
                Button(action: {
                    definingBy = .enumeration
                }) {
                    Text("Enumeration \(definingBy == .enumeration ? "􀆅" : "")")
                }
            } label: {
                EmptyView()
                    .frame(width: 50, height: 50)
            }.menuStyle(BorderlessButtonMenuStyle())
            .opacity(0.08)
            
            Image(systemName: definingBy == .enumeration ? "number" : "rectangle.portrait.arrowtriangle.2.inward")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.playgroundTheme.white : Color.playgroundTheme.gray)
                .allowsHitTesting(false)
        }.aspectRatio(1.0, contentMode: .fit)
        .help("Notation selector")
    }
    
    var styleSelector: some View {
        ZStack {
            Menu {
                Text("Style")
                
                ForEach(0..<setStyles.count) { index in
                    Button(action: {
                        withAnimation {
                            currentSetStyleIndex = index
                        }
                    }) {
                        Text("Set \(setStyles[index].name)").foregroundColor(availableSetStylesIndexes.contains(index) ? getColorTones(for: setStyles[index].color).foreground : Color(.systemGray)) + Text(currentSetStyleIndex == index ? " 􀆅" : "")
                    }.disabled(!availableSetStylesIndexes.contains(index))
                }
            } label: {
                EmptyView()
                    .frame(width: 50, height: 50)
            }.menuStyle(BorderlessButtonMenuStyle())
            .opacity(0.08)
            
            Text(currentSetStyle.name)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(getColorTones(for: currentSetStyle.color).foreground)
                .allowsHitTesting(false)
        }.aspectRatio(1.0, contentMode: .fit)
        .help("Style selector")
    }
    
    var input: some View {
        ZStack(alignment: .leading) {
            getColorTones(for: currentSetStyle.color).background
            
            styleSelector
            
            HStack {
                Text("= {")
                    .foregroundColor(getColorTones(for: currentSetStyle.color).foreground)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                
                ZStack(alignment: .leading) {
                    TextField("2, 3, 5...", text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    (Text(text != "" ? text : "2, 3, 5...").foregroundColor(.clear) +
                        Text(" }").font(.system(size: 20, weight: .regular, design: .serif))
                        .foregroundColor(getColorTones(for: currentSetStyle.color).foreground))
                        .lineLimit(1).allowsHitTesting(false)
                }.font(Font(getFontWithAlignedNumbers(font: "Raleway", size: 20)))
            }.padding(.horizontal, 15)
            .padding(.leading, 20)
        }
    }
    
    func getColorTones(for color: Color) -> (background: Color, foreground: Color) {
        (background: Color(hue: Double(NSColor(color).hueComponent), saturation: colorScheme == .dark ? 0.1 : 0.05, brightness: colorScheme == .dark ? 0.3 : 1.0), foreground: Color(hue: Double(NSColor(color).hueComponent), saturation: colorScheme == .dark ? 0.6 : 0.5, brightness: colorScheme == .dark ? 0.9 : 0.4))
    }
    
    var send: some View {
        ZStack {
            colorScheme == .dark ? Color.playgroundTheme.black : Color.white
            
            Button("", action: addSet).opacity(0)
                .allowsHitTesting(false)
                .keyboardShortcut(.return, modifiers: [])
            
            Button(action: addSet) {
                Image(systemName: "arrowtriangle.up.circle.fill")
                    .font(.system(size: 25))
                    .foregroundColor(currentSetStyle.color)
            }.buttonStyle(PlainButtonStyle())
        }.aspectRatio(1.0, contentMode: .fit)
        .disabled(playgroundData.currentSets.count >= 3)
        .help(playgroundData.currentSets.count < 3 ? "Send" : "Limit reached")
    }
    
    func addSet() {
        if playgroundData.currentSets.count < 3 {
            playgroundData.setPreviousState()
            
            withAnimation {
                playgroundData.currentSets.append(UserMathSet(style: currentSetStyle, elements: textElements))
                playgroundData.parseSets()
            }
            
            if let set = playgroundData.parsedObjects.last as? MathSet {
                if set.elements.count == 0 {
                    emptySetSound?.playFromBeginning()
                } else {
                    simpleSetSound?.playFromBeginning()
                }
            } else if let intersection = playgroundData.parsedObjects.last as? MathIntersection {
                if intersection.lhs is MathIntersection || intersection.rhs is MathIntersection
                    || intersection.lhs is MathContainment || intersection.rhs is MathContainment {
                    complexIntersectionContainmentSetSound?.playFromBeginning()
                } else {
                    intersectionContainmentSetSound?.playFromBeginning()
                }
            } else if playgroundData.parsedObjects.last is MathContainment {
                intersectionContainmentSetSound?.playFromBeginning()
            } else {
                threewaySetSound?.playFromBeginning()
            }
            
            
            text = ""
        }
    }
    
    var menus: some View {
        VStack {
            Button(action: {
                openMenu(menu: .fileSelection)
            }) {
                HUDButton(systemName: "folder.fill", animation: animation)
                    .overlay(Circle().fill(spotlight != nil ? (spotlight == .buttons ? Color.clear : Color.black.opacity(0.5)) : Color.clear).allowsHitTesting(false))
            }.buttonStyle(PlainButtonStyle())
            .help("File selection")
            
            Button(action: {
                openMenu(menu: .emptyCanvas)
            }) {
                HUDButton(systemName: "trash.fill", animation: animation)
                    .overlay(Circle().fill(spotlight != nil ? (spotlight == .buttons ? Color.clear : Color.black.opacity(0.5)) : Color.clear).allowsHitTesting(false))
            }.buttonStyle(PlainButtonStyle())
            .help("Empty canvas")
            
            Button(action: {
                openMenu(menu: .help)
            }) {
                HUDButton(systemName: "questionmark", animation: animation)
                    .overlay(Circle().fill(spotlight != nil ? (spotlight == .buttons ? Color.clear : Color.black.opacity(0.5)) : Color.clear).allowsHitTesting(false))
            }.buttonStyle(PlainButtonStyle())
            .help("Help")
            .disabled(helpState == nil)
            
            Button(action: {
                if playgroundData.currentPreviousState != nil {
                    if playgroundData.currentPreviousStateIsRedo {
                        redoMenuSound?.playFromBeginning()
                    } else {
                        undoMenuSound?.playFromBeginning()
                    }
                    
                    let newPreviousState = playgroundData.currentSets
                    
                    withAnimation {
                        playgroundData.currentSets = playgroundData.currentPreviousState!
                        playgroundData.currentPreviousState = newPreviousState
                        playgroundData.parseSets()
                    }
                    
                    withAnimation(.easeInOut(duration: 0.25)) {
                        playgroundData.currentPreviousStateIsRedo.toggle()
                    }
                }
            }) {
                HUDButton(systemName: "arrow.uturn.backward")
                    .rotation3DEffect(.degrees(playgroundData.currentPreviousStateIsRedo ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .overlay(Circle().fill(spotlight != nil ? (spotlight == .buttons ? Color.clear : Color.black.opacity(0.5)) : Color.clear).allowsHitTesting(false))
            }.buttonStyle(PlainButtonStyle())
            .help(playgroundData.currentPreviousStateIsRedo ? "Redo" : "Undo")
            .disabled(playgroundData.currentPreviousState == nil)
        }.font(Font.body.bold())
    }
    
    var fileSelectionMenu: some View {
        ZStack(alignment: .topLeading) {
            HUDMenuBackground(cornerRadius: 25.0)
                .matchedGeometryEffect(id: "Background-folder.fill", in: animation)
            
            VStack(alignment: .leading, spacing: 5) {
                HUDMenuHeader(title: "File selection", systemName: "folder.fill", animation: animation)
                    .font(Font.custom("Raleway", size: 20).weight(.bold))
                    .frame(height: 18)
                Spacer()
                
                VStack(spacing: 5) {
                    ForEach(playgroundData.userSetFiles) { file in
                        Button(action: {
                            fileSelectMenuSound?.playFromBeginning()
                            withAnimation(.easeInOut(duration: 0.1)) {
                                playgroundData.currentFileIndex = playgroundData.userSetFiles.firstIndex(of: file)!
                                playgroundData.parseSets()
                            }
                        }) {
                            HUDSelectionButton(file: file)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }.foregroundColor(colorScheme == .dark ? Color.playgroundTheme.white : Color.playgroundTheme.gray)
            .padding(20)
        }.frame(height: 285)
        .onTapGesture(perform: dismissMenu)
    }
    
    var emptyCanvasMenu: some View {
        ZStack(alignment: .topLeading) {
            HUDMenuBackground(cornerRadius: 25.0)
                .matchedGeometryEffect(id: "Background-trash.fill", in: animation)
            
            VStack(alignment: .leading) {
                HUDMenuHeader(title: "Empty Canvas", systemName: "trash.fill", animation: animation)
                    .font(Font.custom("Raleway", size: 20).weight(.bold))
                    .frame(height: 18)
                Spacer()
                
                Text("Are you sure you want to empty the 􀮋 Canvas? This action can be undone.").font(Font.custom("Raleway", size: 13).weight(.medium))
                
                Spacer()
                HStack {
                    Button(action: dismissMenu) {
                        HUDCapsuleButton(label: "Cancel")
                    }.buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        emptyMenuSound?.playFromBeginning()
                        
                        playgroundData.setPreviousState()
                        
                        withAnimation {
                            playgroundData.currentSets = []
                            playgroundData.parsedObjects = []
                        }
                        
                        dismissMenuWithoutSound()
                    }) {
                        HUDCapsuleButton(label: "Yes", style: .destructive)
                    }.buttonStyle(PlainButtonStyle())
                }.frame(height: 35)
                .font(Font.custom("Raleway", size: 16).weight(.semibold))
            }.foregroundColor(colorScheme == .dark ? Color.playgroundTheme.white : Color.playgroundTheme.gray)
            .padding(20)
        }.frame(height: 165)
        .onTapGesture(perform: dismissMenu)
    }
    
    var helpMenu: some View {
        ZStack(alignment: .topLeading) {
            HUDMenuBackground(cornerRadius: 25.0)
                .matchedGeometryEffect(id: "Background-questionmark", in: animation)
            
            VStack(alignment: .leading) {
                HUDMenuHeader(title: "Help", systemName: "questionmark", animation: animation)
                    .font(Font.custom("Raleway", size: 20).weight(.bold))
                    .frame(height: 18)
                Spacer()
                
                Text("If you are stuck or don't know what to do to proceed, Seth can give you a little hand. ")
                    .font(Font.custom("Raleway", size: 13).weight(.medium))
                
                Spacer()
                Button(action: {
                    helpMenuSound?.playFromBeginning()
                    
                    if helpState != nil {
                        helpState!()
                        helpState = nil
                    }
                    
                    dismissMenuWithoutSound()
                }) {
                    HUDCapsuleButton(label: "Get help", style: .help)
                }.buttonStyle(PlainButtonStyle())
                .frame(height: 35)
                .font(Font.custom("Raleway", size: 16).weight(.semibold))
            }.foregroundColor(colorScheme == .dark ? Color.playgroundTheme.white : Color.playgroundTheme.gray)
            .padding(20)
        }.frame(height: 165)
        .onTapGesture(perform: dismissMenu)
    }
    
    func openMenu(menu: HUDMenus) {
        openMenuSound?.playFromBeginning()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            currentMenu = menu
        }
    }
    
    func dismissMenu() {
        if currentMenu != nil {
            closeMenuSound?.playFromBeginning()
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                currentMenu = nil
            }
        }
    }
    
    func dismissMenuWithoutSound() {
        if currentMenu != nil {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                currentMenu = nil
            }
        }
    }
    
    var counter: some View {
        ZStack {
            colorScheme == .dark ? Color.playgroundTheme.black : Color.white
            
            HStack(spacing: 0) {
                Image(nsImage: NSImage(named: "Set Bits.png")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer()
                
                HStack(spacing: 0) {
                    Spacer()
                    Text(String(playgroundData.currentSets.count))
                        .foregroundColor(colorScheme == .dark ? Color.playgroundTheme.white : Color.playgroundTheme.gray)
                        .font(Font(getFontWithAlignedNumbers(font: "Raleway", size: 36)).weight(.bold))
                        .fixedSize()
                    Spacer()
                }.animation(nil)
            }.padding(10)
            .foregroundColor(Color.playgroundTheme.gray)
        }.frame(width: 110, height: 60)
        .overlay(spotlight != nil ? (spotlight == .buttons ? Color.clear : Color.black.opacity(0.5)) : Color.clear)
        .cornerRadius(25.0)
        .help(playgroundData.currentSets.count > 0 ? "\(playgroundData.currentSets.count) set"+(playgroundData.currentSets.count > 1 ? "s" : "") : "No sets")
    }
}

struct HUDMathObjectView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    var object: MathObject
    
    var isFinal: Bool = false
    
    var body: some View {
        Group {
            if object is MathSet {
                HUDMathSetView(set: object as! MathSet)
            } else if object is MathIntersection {
                HUDMathIntersectionView(intersection: object as! MathIntersection)
            } else if object is MathContainment {
                HUDMathContainmentView(containment: object as! MathContainment)
            } else if object is MathThreeway {
                HUDMathThreewayView(threeway: object as! MathThreeway)
            }
        }.allowsHitTesting(isFinal)
        .onTapGesture {
            if isFinal {
                playgroundData.activePopover = object.id
            }
        }
    }
}

struct HUDMathSetView: View {
    var set: MathSet
    
    var body: some View {
        self.set.userSet.color
    }
}

struct HUDMathIntersectionView: View {
    var intersection: MathIntersection
    
    var body: some View {
        HStack(spacing: 0) {
            HUDMathObjectView(object: intersection.lhs)
            HUDMathObjectView(object: intersection.rhs)
        }
    }
}

struct HUDMathContainmentView: View {
    var containment: MathContainment
    
    var body: some View {
        HStack(spacing: 0) {
            HUDMathObjectView(object: containment.outer)
            ForEach(containment.inner, id: \.id) { object in
                HUDMathObjectView(object: object)
            }
        }
    }
}

struct HUDMathThreewayView: View {
    var threeway: MathThreeway
    
    var body: some View {
        HStack(spacing: 0) {
            HUDMathObjectView(object: threeway.lhs)
            HUDMathObjectView(object: threeway.top)
            HUDMathObjectView(object: threeway.rhs)
        }
    }
}

struct HUDMessageView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    var text: String
    
    var nextPhase: HUDPhases? = nil
    var delay: Double = 3.0
    var onAppear: () -> () = {}
    
    var animation: Namespace.ID?
    
    @State var showingSpeech = false
    @State var paused = false
    
    @State var opacity = 1.0
    
    @State var offsetMovement: CGFloat = 1.0
    let timer = Timer.publish(every: 1.25, on: .main, in: .common).autoconnect()
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            
            if showingSpeech {
                speech
            }
            
            HStack {
                Spacer()
                SethView(paused: $paused)
                    .frame(width: 165)
                    .offset(y: offsetMovement*2.5)
                    .animation(.easeInOut(duration: 1.5))
                    .matchedGeometryEffect(id: "Seth", in: animation ?? Namespace().wrappedValue)
            }
        }.frame(width: 230)
        .onAppear {
            onAppear()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showingSpeech = true
            }
            
            withAnimation(.easeInOut(duration: 2.0)) {
                offsetMovement = -offsetMovement
            }
        }.onReceive(timer) { _ in
            withAnimation(Animation.easeInOut(duration: 2.0).delay(0.3)) {
                offsetMovement = -offsetMovement
            }
        }
    }
    
    var speech: some View {
        SpeechView(text: text, completion: {
            paused = true
            
            DispatchQueue.main.asyncAfter(deadline: .now()+delay, execute: {
                if nextPhase != nil {
                    playgroundData.currentCanvasPhase = nextPhase!
                }
            })
        }, arrowPosition: .bottomTrailing, lineWidth: 10.0, innerPadding: 16)
        .font(Font.custom("Raleway", size: 16).weight(.semibold))
        .transition(AnyTransition.scale(scale: 0.5, anchor: .bottomTrailing).combined(with: .opacity))
        .offset(y: offsetMovement*2.5)
        .opacity(opacity)
        .onHover { over in
            withAnimation {
                opacity = over ? 0.1 : 1.0
            }
        }
        .allowsHitTesting(false)
    }
}

enum HUDPhases {
    case welcome
    case panAndZoom
    case buttons
    case toolbar
    case type
    case send
    case great
    case empty
    case click
    case intersection
    case intersectionExplanation
    case complexIntersection
    case complexIntersectionExplanation
    case containment
    case containmentExplanation
    case threeway
    case threewayExplanation
    case cover
    case thankyou
}


struct HUDButton: View {
    var systemName: String
    var animation: Namespace.ID?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25.0).fill(colorScheme == .dark ? Color.playgroundTheme.black : Color.white)
                .matchedGeometryEffect(id: "Background-\(systemName)", in: animation ?? Namespace().wrappedValue)
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(colorScheme == .dark ? Color.playgroundTheme.white : Color.playgroundTheme.gray)
                .matchedGeometryEffect(id: systemName, in: animation ?? Namespace().wrappedValue)
                .padding(14)
        }.frame(width: 50, height: 50)
    }
}

struct HUDMenuHeader: View {
    var title: String
    var systemName: String
    
    var animation: Namespace.ID?
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .matchedGeometryEffect(id: systemName, in: animation ?? Namespace().wrappedValue)
            Text(title)
        }
    }
}

struct HUDCapsuleButton: View {
    var label: String = ""
    var style: HUDCapsuleStyle = .normal
    
    @Environment(\.colorScheme) var colorScheme
    
    var styleColor: Color {
        switch style {
        case .normal:
            return colorScheme == .dark ? Color.playgroundTheme.gray : Color.playgroundTheme.white
        case .selected:
            return Color.playgroundTheme.blue
        case .destructive:
            return Color.playgroundTheme.orange
        case .help:
            return Color.playgroundTheme.green
        }
    }
    
    var body: some View {
        ZStack {
            Capsule().fill(styleColor)
            Text(label).foregroundColor(style != .normal ? Color.white : Color.primary)
        }.shadow(color: colorScheme == .dark ? styleColor.opacity(0.3) : .clear, radius: 8)
    }
}

enum HUDCapsuleStyle {
    case normal
    case selected
    case destructive
    case help
}

struct HUDSelectionButton: View {
    @EnvironmentObject var playgroundData: DataModel
    
    var file: UserFile
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            HUDCapsuleButton(style: file == playgroundData.currentFile ? .selected : .normal)
            
            HStack(spacing: 4) {
                Text(file.name)
                    .font(Font(getFontWithAlignedNumbers(font: "Raleway", size: 16)).weight(.medium))
                    .padding(.leading, 5)
                Spacer()
                
                if file.userSets.count > 0 {
                    Image(nsImage: NSImage(named: "Set Bits.png")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Text(String(file.userSets.count))
                        .font(Font(getFontWithAlignedNumbers(font: "Raleway", size: 14)).weight(.bold))
                } else {
                    Text("-")
                        .font(Font.custom("Raleway", size: 14).weight(.bold))
                }
                
                Spacer()
                Image(systemName: file == playgroundData.currentFile ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }.padding(10)
        }.foregroundColor(file == playgroundData.currentFile || colorScheme == .dark ? Color.playgroundTheme.white : Color.playgroundTheme.black)
    }
}

struct HUDMenuBackground: View {
    var cornerRadius: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(colorScheme == .dark ? Color.playgroundTheme.black : Color.white)
    }
}

enum HUDMenus {
    case fileSelection
    case emptyCanvas
    case help
}

enum HUDSpotlights {
    case buttons
    case toolbar
}
