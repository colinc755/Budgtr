import SwiftUI

struct ContentView: View {
    @StateObject private var store = BudgetStore()

    var body: some View {
        RootTabView(store: store)
            .dismissKeyboardOnBackgroundTap()
    }
}
