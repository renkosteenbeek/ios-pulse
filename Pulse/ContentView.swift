import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "heart.fill") {
                HomeView()
            }
            Tab("History", systemImage: "clock.fill") {
                HistoryListView()
            }
            Tab("Profile", systemImage: "person.fill") {
                ProfileView()
            }
        }
        .tint(.red)
    }
}
