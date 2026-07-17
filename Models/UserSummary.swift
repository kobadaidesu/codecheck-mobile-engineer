//
//  UserSummary.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/13.
//

import Foundation

struct UserSearchResponse: Decodable {
    let items: [UserSummary]
}

// Decodable: JSON -> Swiftの方に変換できる
struct UserSummary: Decodable, Identifiable {
    let id: Int
    let login: String
    let avatarURL: URL
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

/*
 {
   "id": 1,
   "login": "octocat",
   "avatar_url": "https://...",
   "html_url": "https://github.com/octocat"
 }
 CodingKeyをやらないとavatar_urlをきれいに受け取れない
  これがあるとJSONの"html_url" -> SwiftのhtmlURLという対応になる
 */
