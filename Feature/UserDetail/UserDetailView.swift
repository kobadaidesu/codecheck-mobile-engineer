//
//  UserDetailView.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/14.
//

import SwiftUI

struct UserDetailView: View {
    @StateObject private var viewModel: UserDetailViewModel

    init(login: String) {
        _viewModel = StateObject(
            wrappedValue: UserDetailViewModel(login: login)
        )
    }

    /**
     Viewは隠してるけど中身は１つsome
     */
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("読み込み中です…")

            case .loaded:
                if let user = viewModel.user {
                    userContent(user)
                }

            case let .error(message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)

                    Text("ユーザー情報の取得に失敗しました")
                        .font(.headline)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("再試行") {
                        Task {
                            await viewModel.load()
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(viewModel.user?.login ?? "ユーザー詳細")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func userContent(_ user: UserDetail) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                AsyncImage(url: user.avatarURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())

                Text(user.name ?? user.login)
                    .font(.title2)
                    .bold()

                Text("@\(user.login)")
                    .foregroundStyle(.secondary)

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 32) {
                    statView(title: "Followers", value: user.followers)
                    statView(title: "Following", value: user.following)
                    statView(title: "Repositories", value: user.publicRepos)
                }

                Divider()

                Text("公開リポジトリ")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                repositoryContent
            }
            .padding()
        }
    }

    private func statView(title: String, value: Int) -> some View {
        VStack {
            Text("\(value)")
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var repositoryContent: some View {
        if viewModel.isLoadingRepositories {
            ProgressView("リポジトリを読み込み中です…")
        } else if let message = viewModel.repositoryErrorMessage {
            VStack(spacing: 8) {
                Text("リポジトリの取得に失敗しました")
                    .font(.headline)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("再試行") {
                    Task {
                        await viewModel.fetchRepositories()
                    }
                }
            }
        } else if viewModel.repositories.isEmpty {
            Text("公開リポジトリはありません")
                .foregroundStyle(.secondary)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.repositories) { repository in
                    repositoryRow(repository)
                }
            }
        }
    }

    private func repositoryRow(
        _ repository: Repository
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(repository.name)
                .font(.headline)

            if let description = repository.description,
               !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if let language = repository.language {
                    Label(
                        language,
                        systemImage: "chevron.left.forwardslash.chevron.right"
                    )
                }

                Label(
                    "\(repository.stargazersCount)",
                    systemImage: "star"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
