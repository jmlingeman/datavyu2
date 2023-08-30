import SwiftUI

// Solution from:
// https://medium.com/@michaelrobertellis/how-to-programmatically-manage-focusstate-for-dynamically-created-textfields-and-texteditors-in-5516de893d1a

struct ArgumentTextField: View {
    
    @State var displayObject: Argument
    @FocusState var isFocused: Bool
    var focus: FocusState<Int?>.Binding
    var nextFocus: (Argument) -> Void
    
    var body: some View {
        TextField(displayObject.name, text: $displayObject.value, axis: .horizontal)
            .focused(self.$isFocused)
            .submitLabel(.next)
            .onSubmit {
                self.nextFocus(displayObject)
            }
    }
}
