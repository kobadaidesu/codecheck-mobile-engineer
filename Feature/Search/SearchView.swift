import SwiftUI

struct SearchView: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    TextField("GitHubユーザーを検索", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)

                    Button("検索") {
                        print("検索キーワード: \(query)")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("ユーザー検索")
        }
    }
}

#Preview {
    SearchView()
}
