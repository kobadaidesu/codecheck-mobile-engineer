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
}

/*
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
        /*
         URLComponents自体はstruct　で中身にURLのパーツを持ってるので色々組み立てて.urlでURL?を返す計算property
         */
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

    func fetchUser(login: String) async throws -> UserDetail {
        guard let encodedLogin = login.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ),
        let url = URL(
            string: "https://api.github.com/users/\(encodedLogin)"
        ) else {
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
            return try JSONDecoder().decode(
                UserDetail.self,
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
