// This SwiftUI view presents the main and final screen of the playground experience

import SwiftUI

struct CanvasScreen: View {
    @EnvironmentObject var playgroundData: DataModel
    
    var animation: Namespace.ID
    
    @GestureState var offset: CGSize = .zero
    @GestureState var scale: CGFloat = 1.0
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            colorScheme == .dark ? Color.playgroundTheme.gray : Color.playgroundTheme.white
            
            ZStack {
                background
                
                HStack {
                    Spacer()
                    ForEach(playgroundData.parsedObjects, id: \.id) { object in
                        MathObjectView(object: object, isFinal: true, animation: animation)
                        Spacer()
                    }
                }.frame(width: playgroundRect.width, height: playgroundRect.height)
            }.offset(offset)
            .scaleEffect(scale)
            .animation(.spring(response: 0.5, dampingFraction: 0.75))
            
            HUDView(animation: animation)
        }.gesture(DragGesture().updating($offset) { value, state, transaction in
            let width = value.translation.width
            let height = value.translation.height
            
            let nextValue = CGSize(width: width/pow(2, abs(width)/500+1), height: height/pow(2, abs(height)/500+1))
            
            let widthRange = abs(state.width) < abs(nextValue.width) ? abs(state.width)...abs(nextValue.width) : abs(nextValue.width)...abs(state.width)
            let heightRange = abs(state.height) < abs(nextValue.height) ? abs(state.height)...abs(nextValue.height) : abs(nextValue.height)...abs(state.height)
            
            if (widthRange.contains(100) || widthRange.contains(115) || widthRange.contains(125) || abs(nextValue.width) > 130) || (heightRange.contains(100) || heightRange.contains(115) || heightRange.contains(125) || abs(nextValue.height) > 130) {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            }
            
            state = nextValue
        }).gesture(MagnificationGesture().updating($scale) { value, state, transaction in
            let normalized = value+1
            state = max(min(normalized/pow(2, normalized/500+1), 2), 0.5)
            
            if state > 1.95 || state < 0.55 {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            }
        })
    }
    
    var background: some View {
        Image("Background Tile")
            .resizable(resizingMode: .tile)
            .opacity(0.1)
            .frame(width: playgroundRect.width*2, height: playgroundRect.height*2)
    }
}

// The views below render the sets themselves

struct MathObjectView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    var object: MathObject
    
    var isFinal: Bool = false
    
    var animation: Namespace.ID?
    
    var body: some View {
        Group {
            if object is MathSet {
                MathSetView(set: object as! MathSet, animation: animation)
            } else if object is MathIntersection {
                MathIntersectionView(intersection: object as! MathIntersection, animation: animation)
            } else if object is MathContainment {
                MathContainmentView(containment: object as! MathContainment, animation: animation)
            } else if object is MathThreeway {
                MathThreewayView(threeway: object as! MathThreeway, animation: animation)
            }
        }.overlay(
            Color.clear.contentShape(Rectangle())
                .allowsHitTesting(isFinal)
                .onTapGesture {
                    if isFinal {
                        playgroundData.activePopover = object.id
                    }
                }
        ).popover(isPresented: Binding(get: { playgroundData.activePopover != nil && playgroundData.activePopover! == object.id },
                                       set: { playgroundData.activePopover = $0 ? playgroundData.activePopover : nil }))
        {
            MathObjectPopoverView(object: object)
        }
    }
}

struct MathSetView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    let set: MathSet
    
    var animation: Namespace.ID?
    
    @State var showingPopover = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var userSet: UserMathSet {
        return set.userSet
    }
    
    var body: some View {
        Circle()
            .stroke(userSet.color, lineWidth: 4)
            .background(Circle().foregroundColor(userSet.color.opacity(0.4)))
            .frame(width: set.size, height: set.size)
            .blendMode(colorScheme == .dark ? .lighten : .multiply)
            .shadow(color: colorScheme == .dark ? userSet.color.opacity(0.3) : .clear, radius: 8)
            .matchedGeometryEffect(id: userSet.name, in: animation != nil ? animation! : Namespace().wrappedValue)
    }
}

struct MathIntersectionView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    let intersection: MathIntersection
    
    var animation: Namespace.ID?
    
    var body: some View {
        HStack(spacing: -intersection.gap) {
            MathObjectView(object: intersection.lhs, animation: animation)
            MathObjectView(object: intersection.rhs, animation: animation)
        }
    }
}

struct MathContainmentView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    let containment: MathContainment
    
    var animation: Namespace.ID?
    
    var body: some View {
        ZStack(alignment: containment.alignment) {
            MathObjectView(object: containment.outer, animation: animation)
            HStack(spacing: 0) {
                ForEach(containment.inner, id: \.id) { object in
                    MathObjectView(object: object, animation: animation)
                }
            }
        }
    }
}

struct MathThreewayView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    let threeway: MathThreeway
    
    var animation: Namespace.ID?
    
    var body: some View {
        ZStack {
            MathObjectView(object: threeway.top, animation: animation)
                .offset(x: 0, y: -threeway.offset.top)
            MathObjectView(object: threeway.lhs, animation: animation)
                .offset(x: cos(135.0 * CGFloat.pi / 180.0)*threeway.offset.lhs, y: sin(135.0 * CGFloat.pi / 180.0)*threeway.offset.lhs)
            MathObjectView(object: threeway.rhs, animation: animation)
                .offset(x: cos(45.0 * CGFloat.pi / 180.0)*threeway.offset.rhs, y: sin(45.0 * CGFloat.pi / 180.0)*threeway.offset.rhs)
        }
    }
}

// The view below render the popovers for our sets

struct MathObjectPopoverView: View {
    let object: MathObject
    
    @ViewBuilder
    var body: some View {
        if object is MathSet {
            MathSetPopoverView(set: object as! MathSet)
        } else if object is MathIntersection {
            MathIntersectionPopoverView(intersection: object as! MathIntersection)
        } else if object is MathContainment {
            MathContainmentPopoverView(containment: object as! MathContainment)
        } else if object is MathThreeway {
            MathThreewayPopoverView(threeway: object as! MathThreeway)
        }
    }
}

struct MathSetPopoverView: View {
    @EnvironmentObject var playgroundData: DataModel
    
    let set: MathSet
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Set ").font(.system(size: 15)) + Text(set.userSet.name).font(.system(size: 15, weight: .regular, design: .serif))
                    Text(set.elements.count > 0 ? "\(set.elements.count) item"+(set.elements.count > 1 ? "s" : "") : "Empty set")
                        .font(.system(size: 13))
                        .foregroundColor(Color(.systemGray))
                }
                Spacer()
                Button(action: {
                    playgroundData.setPreviousState()
                    
                    withAnimation {
                        playgroundData.currentSets = playgroundData.currentSets.filter {$0 != set.userSet}
                        playgroundData.parseSets()
                    }
                }, label: {
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                }).buttonStyle(PlainButtonStyle())
            }
            Divider()
            Text(set.userSet.count > 0 ? "{ \(set.userSet.parsedElements) }" : set.userSet.parsedElements)
                .font(.system(size: 12, weight: .regular, design: .serif))
                .frame(width: set.elements.count < 15 ? 100 : 200, alignment: .leading)
                .lineLimit(nil)
            Spacer()
        }.padding(20)
        .background(set.userSet.color.opacity(0.05))
    }
}

struct MathIntersectionPopoverView: View {
    let intersection: MathIntersection
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 5) {
                Text("Intersection \(Image(systemName: "circlebadge.2"))")
                    .font(.system(size: 19, weight: .semibold))
                    .lineLimit(1)
                Text(intersection.description)
                    .font(.system(size: 14, design: .serif))
            }.frame(minWidth: 200).padding()
            
            HStack(spacing: 0) {
                MathObjectPopoverView(object: intersection.lhs)
                MathObjectPopoverView(object: intersection.rhs)
            }.cornerRadius(12.5)
            .overlay(RoundedRectangle(cornerRadius: 12.5).stroke(Color(white: 0.85)))
        }
    }
}

struct MathContainmentPopoverView: View {
    let containment: MathContainment
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 5) {
                Text("Containment \(Image(systemName: "smallcircle.filled.circle"))")
                    .font(.system(size: 19, weight: .semibold))
                    .lineLimit(1)
                Text(containment.description)
                    .font(.system(size: 14, design: .serif))
            }.frame(minWidth: 200).padding()
            
            VStack(spacing: 0) {
                MathObjectPopoverView(object: containment.outer)
                    .cornerRadius(12.5)
                
                HStack(spacing: 0) {
                    ForEach(containment.inner, id: \.id) { object in
                        MathObjectPopoverView(object: object)
                    }
                }.cornerRadius(12.5)
                .padding(7.5)
            }.overlay(RoundedRectangle(cornerRadius: 12.5).stroke(Color(white: 0.85)))
        }
    }
}

struct MathThreewayPopoverView: View {
    let threeway: MathThreeway
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 5) {
                Text("Three-way diagram \(Image(systemName: "camera.filters"))")
                    .font(.system(size: 19, weight: .semibold))
                    .lineLimit(nil)
                Text(threeway.description)
                    .font(.system(size: 14, design: .serif))
            }.frame(minWidth: 200).padding()
            
            HStack(spacing: 0) {
                MathObjectPopoverView(object: threeway.lhs)
                MathObjectPopoverView(object: threeway.top)
                MathObjectPopoverView(object: threeway.rhs)
            }.cornerRadius(12.5)
            .overlay(RoundedRectangle(cornerRadius: 12.5).stroke(Color(white: 0.85)))
        }
    }
}
