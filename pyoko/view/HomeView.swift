import SwiftUI

/// Selects navigation only; both platforms share models, services and session state.
struct HomeView: View {
    var body: some View {
        #if os(macOS)
        MacHomeView()
        #else
        PhoneHomeView()
        #endif
    }
}

extension View {
    @ViewBuilder
    func pyokoHideBackButton() -> some View {
        navigationBarBackButtonHidden(true)
    }
}
