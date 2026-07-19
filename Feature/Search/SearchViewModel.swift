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
    @Published private(set) var searchHistory: [String]

    private let apiClient: any GitHubAPIClientProtocol
    private let historyStore: any SearchHistoryStoreProtocol
    private var searchTask: Task<Void, Never>?

    init(
        apiClient: any GitHubAPIClientProtocol = GitHubAPIClient(),
        historyStore: any SearchHistoryStoreProtocol = SearchHistoryStore()
    ) {
        self.apiClient = apiClient
        self.historyStore = historyStore
        searchHistory = historyStore.load()
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

                if result.isEmpty {
                    state = .empty
                } else {
                    state = .loaded
                    historyStore.save(query: trimmedQuery)
                    searchHistory = historyStore.load()
                }
            } catch is CancellationError {
                // 新しい検索によるキャンセルなのでエラー表示しない
            } catch let error as URLError where error.code == .cancelled {
                // URLSession側のキャンセルなのでエラー表示しない
            } catch {
                users = []
                state = .error(error.localizedDescription)
            }
        }
    }

    func selectHistory(_ historyQuery: String) {
        query = historyQuery
        search()
    }

    func clearHistory() {
        historyStore.clear()
        searchHistory = []
    }
}

/*
 [idle] ──検索開始──> [loading] ──┬─ 成功・結果あり ─> [loaded]
           ↑                              ├─ 成功・0件 ─────> [empty]
        空入力                            └─ 通信失敗 ───────> [error(理由)]
 */
