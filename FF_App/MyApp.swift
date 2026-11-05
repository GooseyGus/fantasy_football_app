import SwiftUI
import UIKit

@main struct MyApp: App {
    init() {
        // Navigation titles aren't styled by SwiftUI's font and foreground style, so set them here.
        let ink = UIColor(Color.ink)
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: ink, .font: UIFont.din(.largeTitle)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: ink, .font: UIFont.din(.headline)]
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.soft)
                .foregroundStyle(Color.ink)
                .font(.din(.body))
                .preferredColorScheme(.dark)
        }
    }
}
