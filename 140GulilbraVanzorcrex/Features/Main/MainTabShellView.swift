import SwiftUI

struct MainTabShellView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onSelectTab: { index in
                selection = index
            })
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            CarnivalHubView()
                .tabItem {
                    Label("Carnival", systemImage: "party.popper.fill")
                }
                .tag(1)

            TrophiesHubView()
                .tabItem {
                    Label("Trophies", systemImage: "trophy.fill")
                }
                .tag(2)

            ProgressHubView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)

            SettingsHubView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.appAccent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}
