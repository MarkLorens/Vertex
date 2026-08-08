import SwiftUI

extension View {
    /// Drops the keyboard when a tap lands anywhere that isn't a control.
    /// A gesture inside beats one on its ancestor, so fields, buttons and rows
    /// still get their own taps — this only picks up what nothing else wanted.
    func dismissesKeyboardOnTap() -> some View {
        contentShape(.rect)
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                )
            }
    }
}
