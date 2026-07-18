//
//  SafariView.swift
//  kadai
//
//  Created by Kobayashi Daigo on 2026/07/18.
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(
        context _: Context
    ) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    /**
     protocolに準拠してupdateUIViewControllerを実装してるけど処理は何もしてない
     更新する必要がないから
     */
    func updateUIViewController(
        _: SFSafariViewController,
        context _: Context
    ) {}
}
