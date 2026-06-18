import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: BudgetStore

    var body: some View {
        TabView {
            DashboardView(store: store)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }

            IncomeView(store: store)
                .tabItem {
                    Label("Income", systemImage: "banknote.fill")
                }

            BudgetView(store: store)
                .tabItem {
                    Label("Budget", systemImage: "list.bullet.rectangle.fill")
                }
        }
    }
}
