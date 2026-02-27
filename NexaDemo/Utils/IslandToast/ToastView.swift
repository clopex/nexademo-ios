//
//  ToastView.swift
//  NexaDemo
//
//  Created by Adis Mulabdic on 27. 2. 2026..
//

import SwiftUI

extension View {
    @ViewBuilder
    func dynamicIslandToasts(isPresented: Binding<Bool>, value: Toast) -> some View {
        self
            .modifier(DynamicIslandToastViewModifier(isPresented: isPresented, value: value))
    }
}

struct DynamicIslandToastViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    var value: Toast
    @State private var overlayWindow: PassThroughWindow?
    @State private var overlayController: CustomHostingView?
    
    
    func body(content: Content) -> some View {
        content
            .background(WindowExtractor { mainWindow in
                createOverlayWindow(mainWindow)
            })
            .onChange(of: isPresented) { oldValue, newValue in
                guard let overlayWindow else { return }
                if newValue {
                    overlayWindow.toast = value
                }
                
                overlayWindow.isPresented = newValue
                overlayController?.isStatusBarHidden = newValue
            }
        
            .onChange(of: overlayWindow?.isPresented) { oldValue, newValue in
                if let newValue, let overlayWindow, overlayWindow.toast?.id == value.id, newValue != isPresented {
                    isPresented = false
                }
            }
    }
    
    private func createOverlayWindow(_ mainWindow: UIWindow) {
        guard let windowScene = mainWindow.windowScene else { return }
        
        if let window = windowScene.windows.first(where: { $0.tag == 1009 }) as? PassThroughWindow {
            print("Using already Window!")
            self.overlayWindow = window
        } else {
            
            let overalyWindow = PassThroughWindow(windowScene: windowScene)
            overalyWindow.backgroundColor = .clear
            overalyWindow.isHidden = false
            overalyWindow.isUserInteractionEnabled = true
            overalyWindow.windowLevel = .statusBar + 1
            overalyWindow.tag = 1009
            createRootController(overalyWindow)
            
            self.overlayWindow = overalyWindow
        }
    }
    
    private func createRootController(_ window: PassThroughWindow) {
        let hostingConroller = CustomHostingView(rootView: ToastView(window: window))
        
        hostingConroller.view.backgroundColor = .clear
        window.rootViewController = hostingConroller
        
        self.overlayController = hostingConroller
    }
}

struct ToastView: View {
    
    var window: PassThroughWindow
    
    var body: some View {
        GeometryReader {
            let safeArea = $0.safeAreaInsets
            let size = $0.size
            
            let haveDynamicIsland: Bool = safeArea.top >= 59
            let dynamicIslanWidth: CGFloat = 120
            let dynamicIslandHeight: CGFloat = 36
            let topOffset: CGFloat = 11 + max((safeArea.top - 59), 0)
            
            let expandedWidth = size.width - 20
            let expandedHeight: CGFloat = haveDynamicIsland ? 90 : 70
            let scaleX: CGFloat = isExpended ? 1 : (dynamicIslanWidth / expandedWidth)
            let scaleY: CGFloat = isExpended ? 1 : (dynamicIslandHeight / expandedHeight)
            
            ZStack {
                ConcentricRectangle(corners: .concentric(minimum: .fixed(30)), isUniform: true)
                    .fill(.black)
                    .overlay {
                        ToastContent(haveIsland: haveDynamicIsland)
                            .frame(width: expandedWidth, height: expandedHeight)
                            .scaleEffect(x: scaleX, y: scaleY)
                    }
                    .frame(
                        width: isExpended ? expandedWidth : dynamicIslanWidth,
                        height: isExpended ? expandedHeight : dynamicIslandHeight
                    )
                    .offset(
                        y: haveDynamicIsland ? topOffset :(isExpended ? safeArea.top + 10 : -80)
                    )
                    .opacity(haveDynamicIsland ? 1 : (isExpended ? 1 : 0))
                    .animation(.linear(duration: 0.02).delay(isExpended ? 0 : 0.28)) { content in
                        content.opacity(haveDynamicIsland ? isExpended ? 1 : 0 : 1)
                    }
                    .geometryGroup()
                    .contentShape(.rect)
                    .gesture (
                        DragGesture().onEnded { value in
                            if value.translation.height < 0 {
                                window.isPresented = false
                            }
                        }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .animation(.bouncy(duration: 0.3, extraBounce: 0), value: isExpended)
        }
    }
    
    @ViewBuilder
    func ToastContent(haveIsland: Bool) -> some View {
        if let toast = window.toast {
            HStack(spacing: 10) {
                Image(systemName: toast.symbol)
                    .font(toast.symbolFont)
                    .foregroundStyle(toast.symbolForegrgoundStyle.0, toast.symbolForegrgoundStyle.1)
                    .symbolEffect(.wiggle, options: .default.speed(1.5), value: isExpended)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Spacer(minLength: 0)
                    Text(toast.title)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text(toast.message)
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
                .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .compositingGroup()
            .blur(radius: isExpended ? 0 : 5)
            .opacity(isExpended ? 1 : 0)
        }
    }
    
    var isExpended: Bool {
        window.isPresented
    }
}
