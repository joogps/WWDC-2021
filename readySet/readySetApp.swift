//
//  readySetApp.swift
//  readySet
//
//  Created by João Gabriel Pozzobon dos Santos on 13/08/23.
//

import SwiftUI

@main
struct readySetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizabilityContentSize()
    }
}

extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}
