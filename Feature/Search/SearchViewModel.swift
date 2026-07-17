//
//  SearchViewModel.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/14.
//

import Foundation

/**
 0件とerrorを分けるのがミソ
 enumってのは複数選択肢のうちちょうど１つを表現するのに便利
 */
enum SearchViewState {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""

    @Published private(set) var users: [UserSummary] = []
    @Published private(set) var state: SearchViewState = .idle

    private let apiClient: any GitHubAPIClientProtocol
    private var searchTask: Task<Void, Never>?

    init(
        apiClient: any GitHubAPIClientProtocol = GitHubAPIClient()
    ) {
        self.apiClient = apiClient
    }

    var isLoading: Bool {
        if case .loading = state {
            return true
        }

        return false
    }

    func search() {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else {
            users = []
            state = .idle
            return
        }

        searchTask?.cancel()

        state = .loading

        searchTask = Task {
            do {
                let result = try await apiClient.searchUsers(
                    query: trimmedQuery
                )

                try Task.checkCancellation()

                users = result
                state = result.isEmpty ? .empty : .loaded
            } catch is CancellationError {
                // 新しい検索によるキャンセルなのでエラー表示しない
            } catch {
                users = []
                state = .error(error.localizedDescription)
            }
        }
    }
}

/*
 [idle] ──検索開始──> [loading] ──┬─ 成功・結果あり ─> [loaded]
           ↑                              ├─ 成功・0件 ─────> [empty]
        空入力                            └─ 通信失敗 ───────> [error(理由)]
 */
