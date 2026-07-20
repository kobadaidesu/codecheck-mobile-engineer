# GitHub ユーザー検索アプリ（kadai）

GitHub のユーザーを検索し、その詳細・公開リポジトリを閲覧できる iOS アプリです。
アットマーク・ソリューション モバイルエンジニア インターン 事前提出課題。

## 選択トラック

- **iOS（Swift / SwiftUI + 一部 UIKit 連携）**

## 主な機能

- キーワードによる GitHub ユーザー検索
- 検索結果の一覧表示（アイコン画像・ユーザー名）
- ユーザー詳細表示（アイコン・名前・bio・フォロワー数・フォロー数・公開リポジトリ数）
- 公開リポジトリ一覧の表示（リポジトリ名・説明・主要言語・スター数）
- ユーザー / リポジトリのページを **アプリ内ブラウザ（SFSafariViewController）** で表示
- 検索履歴のローカル保存（再起動後も復元。過去のキーワードから再検索可能）
- ローディング / エラー / 該当なし の状態表示

## 対応環境

| 項目 | バージョン |
| --- | --- |
| 対応 OS | iOS 17.0 以上（最新の iOS 26 で動作確認済み） |
| ビルド・実行 | Xcode 26.6（ビルド / シミュレータ実行） |
| 言語 | Swift 6.3.3（Swift 5 言語モード） |
| UI | SwiftUI（+ UIKit 連携を一部） |

## セットアップ・実行手順

1. リポジトリをクローンする
   ```bash
   git clone https://github.com/kobadaidesu/codecheck-mobile-engineer.git
   cd codecheck-mobile-engineer
   ```
2. `kadai.xcodeproj` を Xcode で開く
   ```bash
   open kadai.xcodeproj
   ```
3. 実行先のシミュレータ（例: iPhone 17 Pro）を選び、`⌘R` で実行する

> GitHub REST API を **未認証** で利用しているため、APIキーやトークンの設定は不要です。
> ただし未認証リクエストにはレート制限（通常 60 req/h、Search API は 10 req/min）があります。

## アーキテクチャ

画面、状態管理、API 通信、ローカル保存を別のファイルに分けています。

```
App/         アプリの起動処理
Feature/     SwiftUI の画面と ViewModel
Models/      GitHub API のレスポンスモデル
Networking/  URLSession を使った GitHub API 通信
Storage/     UserDefaults を使った検索履歴の保存
```

View は画面表示、ViewModel はローディング・成功・エラーなどの状態管理、Networking は通信、
Storage は保存を担当します。

検索履歴は最大 10 件の文字列だけを保存するため、データベースではなく、
少量のデータを簡単に保存できる UserDefaults を選びました。

## 工夫した点

- API 通信と画面の状態管理を別の役割に分けました。
- 検索結果とユーザー詳細で、それぞれ必要な情報に合わせたモデルを使用しました。
- `AsyncImage` の読み込み中・成功・失敗を分けて表示しました。

## 苦労した点

- GitHub API の JSON に含まれる `null`と`CodingKeys`の扱い。
- Optional の URL を使った sheet の表示管理。
- Xcode のプロジェクトと実際のファイルの同期。

詳しい内容は [REPORT.md](REPORT.md) に記載しています。

## 未対応の点

アプリ機能の必須要件はすべて実装しました。

ボーナス要件の Unit テストについては、API 通信をモックへ差し替えられる構成にしましたが、
モックを使った ViewModel のテストまでは実装できませんでした。

## 使用しているツール

アプリ本体ではサードパーティライブラリを使用していません。
コードの書式と品質を確認するため、CI で SwiftFormat と SwiftLint を使用しています。

## セルフレポート

実装時に考えたこと、苦労した点、生成 AI の利用については
[REPORT.md](REPORT.md) に記載しています。

## 補足

- 学習・選考目的の課題実装です。
