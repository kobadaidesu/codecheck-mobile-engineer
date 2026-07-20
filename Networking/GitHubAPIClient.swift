//
//  GitHubAPIClient.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/14.
//

import Foundation

protocol GitHubAPIClientProtocol {
    func searchUsers(query: String) async throws -> [UserSummary]
    func fetchUser(login: String) async throws -> UserDetail
    func fetchRepositories(login: String) async throws -> [Repository]
}

/**
 LocalizedErrorはユーザーに見せる日本語メッセージのために書いてる
 */
enum GitHubAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestLimited
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "検索URLを作成できませんでした。"

        case .invalidResponse:
            "サーバーから正しい応答を受け取れませんでした。"

        case .requestLimited:
            "GitHub APIの利用制限に達した可能性があります。しばらくしてから再度お試しください。"

        case let .httpStatus(statusCode):
            "通信に失敗しました。ステータスコード: \(statusCode)"
        }
    }
}

struct GitHubAPIClient: GitHubAPIClientProtocol {
    func searchUsers(query: String) async throws -> [UserSummary] {
        /*
         URLComponents自体はstruct　で中身にURLのパーツを持ってるので色々組み立てて.urlでURL?を返す計算property
         */
        var components = URLComponents(
            string: "https://api.github.com/search/users"
        )

        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
        ]

        guard let url = components?.url else {
            throw GitHubAPIError.invalidURL
        }

        let searchResponse = try await fetch(
            UserSearchResponse.self,
            from: url
        )

        return searchResponse.items
    }

    func fetchUser(login: String) async throws -> UserDetail {
        guard let encodedLogin = login.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ),
            let url = URL(
                string: "https://api.github.com/users/\(encodedLogin)"
            )
        else {
            throw GitHubAPIError.invalidURL
        }

        return try await fetch(UserDetail.self, from: url)
    }

    func fetchRepositories(login: String) async throws -> [Repository] {
        guard let encodedLogin = login.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            throw GitHubAPIError.invalidURL
        }

        var components = URLComponents(
            string: "https://api.github.com/users/\(encodedLogin)/repos"
        )

        components?.queryItems = [
            URLQueryItem(name: "sort", value: "updated"),
            URLQueryItem(name: "per_page", value: "100"),
        ]

        guard let url = components?.url else {
            throw GitHubAPIError.invalidURL
        }

        return try await fetch([Repository].self, from: url)
    }

    private func fetch<T: Decodable>(
        _ type: T.Type,
        from url: URL
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        /*
         • https://docs.github.com/en/rest/using-the-rest-api/getting-started-with-the-rest-api
            にUser-Agent必須って書いてある
            今回だとUser-Agent: GitHubUserSearchAppッテ送られる
            Acceptは返信の形式の希望 JSONで返して JSONDecoder().decode()で壊れるリスクがあるから形式を固定してる
         */
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "GitHubUserSearchApp",
            forHTTPHeaderField: "User-Agent"
        )

        /*
         URLSessionの仕様で２つの返り値がくる
         dataに中身の本文(body)が入る, responseはstatus codeやheader などがいろいろはいってる
         URLResponseという汎用的な型
         */
        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200 ..< 300:
            return try JSONDecoder().decode(
                type,
                from: data
            )

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
