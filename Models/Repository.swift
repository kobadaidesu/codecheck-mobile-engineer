//
//  Repository.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/15.
//

import Foundation

struct Repository: Decodable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let language: String?
    let stargazersCount: Int
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case language
        case stargazersCount = "stargazers_count"
        case htmlURL = "html_url"
    }
}
