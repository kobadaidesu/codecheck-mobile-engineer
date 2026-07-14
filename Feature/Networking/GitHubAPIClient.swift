//
//  GitHubAPIClient.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/14.
//

import Foundation

protocol GitHubAPIClientProtocol {
    func searchUsers(query: String) async throws -> [UserSummary]
}

enum GitHubAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestLimited
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "検索URLを作成できませんでした。"

        case .invalidResponse:
            return "サーバーから正しい応答を受け取れませんでした。"

        case .requestLimited:
            return "GitHub APIの利用制限に達した可能性があります。しばらくしてから再度お試しください。"

        case .httpStatus(let statusCode):
            return "通信に失敗しました。ステータスコード: \(statusCode)"
        }
    }
}

struct GitHubAPIClient: GitHubAPIClientProtocol {
    func searchUsers(query: String) async throws -> [UserSummary] {
        var components = URLComponents(
            string: "https://api.github.com/search/users"
        )

        components?.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]

        guard let url = components?.url else {
            throw GitHubAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "GitHubUserSearchApp",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            let searchResponse = try JSONDecoder().decode(
                UserSearchResponse.self,
                from: data
            )

            return searchResponse.items

        case 403, 429:
            throw GitHubAPIError.requestLimited

        default:
            throw GitHubAPIError.httpStatus(
                httpResponse.statusCode
            )
        }
    }
}

/*
検索文字を受け取る
↓
URLを作る
↓
GitHubへリクエストする
↓
JSONをSwiftのモデルへ変換する
*/
