//
//  SearchHistoryStoreProtocol.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/19.
//

protocol SearchHistoryStoreProtocol {
    func load() -> [String]
    func save(query: String)
    func clear()
}
