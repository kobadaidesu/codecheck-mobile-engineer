//
//  UserDatail.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/14.
//

import Foundation

struct UserDetail: Decodable, Identifiable {
    let id: Int
    let login: String
    let name: String?
    let bio: String?
    let avatarURL: URL
    let htmlURL: URL
    let followers: Int
    let following: Int
    let publicRepos: Int

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case name
        case bio
        case followers
        case following
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case publicRepos = "public_repos"
    }
}

/*
 {
   "login": "kobadai",
   "name": null,
   "bio": null
 }
 github api のJsonにあわせてるだけ
 */
