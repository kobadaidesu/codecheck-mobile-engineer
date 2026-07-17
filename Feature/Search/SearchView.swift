import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchForm

                Divider()

                searchContent
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            }
            .navigationTitle("ユーザー検索")
        }
    }

    private var searchForm: some View {
        HStack {
            TextField(
                "GitHubユーザーを検索",
                text: $viewModel.query
            )
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit {
                viewModel.search()
            }

            Button("検索") {
                viewModel.search()
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                viewModel.query
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
            )
        }
        .padding()
    }

    @ViewBuilder
    private var searchContent: some View {
        switch viewModel.state {
        case .idle:
            messageView(
                systemImage: "magnifyingglass",
                title: "GitHubユーザーを検索",
                message: "ユーザー名やキーワードを入力してください。"
            )

        case .loading:
            ProgressView("検索中です…")

        case .loaded:
            userList

        case .empty:
            messageView(
                systemImage: "person.crop.circle.badge.questionmark",
                title: "該当するユーザーがいません",
                message: "別のキーワードで検索してください。"
            )

        case let .error(message):
            messageView(
                systemImage: "exclamationmark.triangle",
                title: "検索に失敗しました",
                message: message
            )
        }
    }

    private var userList: some View {
        List(viewModel.users) { user in
            NavigationLink {
                UserDetailView(login: user.login)
            } label: {
                HStack(spacing: 12) {
                    AsyncImage(url: user.avatarURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 48, height: 48)

                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())

                        case .failure:
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 48, height: 48)
                                .foregroundStyle(.secondary)

                        @unknown default:
                            EmptyView()
                        }
                    }

                    Text(user.login)
                        .font(.headline)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }

    private func messageView(
        systemImage: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    SearchView()
}
