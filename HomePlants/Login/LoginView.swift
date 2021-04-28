import SwiftUI
import Combine

struct LoginView: View {
    @State var username = ""
    @State var password = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var store: LoginStore

    init(store: LoginStore) {
        self.store = store
    }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .accentColor(.primary)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
            SecureField("Password", text: $password, onCommit: {
                login()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .accentColor(.primary)
            .font(.system(size: 15))
            .foregroundColor(.primary)
            .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
            Button("Login") { login() }
                .font(.title)
                .padding()
        }.onReceive(store.$isLoggedIn, perform: { state in
            if state == .authorized {
                presentationMode.wrappedValue.dismiss()
            }
        }).padding()
    }

    func login() {
        store.login(username, password)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(store: LoginStore(parent: .mock))
    }
}
