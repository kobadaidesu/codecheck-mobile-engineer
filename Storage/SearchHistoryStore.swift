//
//  SearchHistoryStore.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/19.
//

import Foundation

final class SearchHistoryStore: SearchHistoryStoreProtocol {
    private enum Constants {
        static let key = "searchHistory"
        static let maximumCount = 10
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /**
     関数はこのKeyで保持されてる文字列の配列をだして
    stringArrayのかえりちは[String]?だから ?? で何もないとき空配列に変換してる
     */
    func load() -> [String] {
        userDefaults.stringArray(
            forKey: Constants.key
        ) ?? []
    }

    func save(query rawQuery: String) {
        let query = rawQuery.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return
        }

        var history = load()

        /*
         重複した検索履歴を削除し、新しい検索履歴を先頭に追加する
         $0は各要素
         */
        history.removeAll {
            $0.caseInsensitiveCompare(query) == .orderedSame
        }

        history.insert(query, at: 0)
        history = Array(
            history.prefix(Constants.maximumCount)
        )

        userDefaults.set(
            history,
            forKey: Constants.key
        )
    }

    func clear() {
        userDefaults.removeObject(
            forKey: Constants.key
        )
    }
}
