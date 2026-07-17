//
//  UserDetailViewModel.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/14.
//

import Foundation

enum UserDetailViewState {
    case loading
    case loaded
    case error(String)
}

@MainActor
final class UserDetailViewModel: ObservableObject {
    /*
     最初はUserDetailに情報がないのでoptional
     */
    @Published private(set) var user: UserDetail?
    @Published private(set) var state: UserDetailViewState = .loading
    /*
     repository property
     */
    @Published private(set) var repositories: [Repository] = []
    @Published private(set) var repositoryErrorMessage: String?
    @Published private(set) var isLoadingRepositories = false

    private let login: String
    private let apiClient: any GitHubAPIClientProtocol

    init(
        login: String,
        apiClient: any GitHubAPIClientProtocol = GitHubAPIClient()
    ) {
        self.login = login
        self.apiClient = apiClient
    }

    func fetchUser() async {
        state = .loading

        do {
            user = try await apiClient.fetchUser(login: login)
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func fetchRepositories() async {
        isLoadingRepositories = true
        repositoryErrorMessage = nil

        defer {
            isLoadingRepositories = false
        }

        do {
            repositories = try await apiClient.fetchRepositories(
                login: login
            )
        } catch {
            repositoryErrorMessage = error.localizedDescription
        }
    }

    func load() async {
        await fetchUser()

        guard case .loaded = state else {
            return
        }

        await fetchRepositories()
    }
}
