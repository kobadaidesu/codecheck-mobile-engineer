# セルフレポート

## 1. 基本情報

- 氏名（ニックネーム化）: kobadai
- 選択トラック: **iOS**
- 開発環境（OS / IDE / 言語バージョン）: macOS / Zed（コード編集）+
  Xcode 26.6（ビルド・シミュレータ実行）/ Swift 6.3.3（Swift 5言語モード）
- 対応 OS バージョン: iOS 17.0 以上（最新の iOS 26 で動作確認済み）
- 開発にかけたおおよその時間: 約30時間

## 2. 実装した機能

### 必須要件

- [x] キーワードでユーザー検索
- [x] 検索結果の一覧表示
- [x] ユーザー詳細表示（アイコン・名前・bio・フォロワー数など）
- [x] リポジトリ一覧表示
- [x] リポジトリ情報の表示（説明・言語・スター数など）
- [x] 端末ブラウザでページを開く（`SFSafariViewController`によるアプリ内ブラウザ）
- [x] ローディング / エラー状態の表現（`idle / loading / loaded / empty / error` の状態管理）
- [x] API 通信の自前実装（`URLSession`を使用。GitHub専用SDKは不使用）
- [x] ローカル保存（保存手段: **UserDefaults** / 保存対象: **検索履歴（キーワード）**）
- [x] （iOS）SwiftUIメイン + UIKit連携を1箇所以上（`SFSafariViewController`のラップ）

### ボーナス要件（対応したものだけ）

- [x] CI（GitHub ActionsによるSwiftLint / SwiftFormatの自動チェック）

## 3. 設計・技術選定について

- **画面、状態管理、通信、保存を分離**した。View（表示）/ ViewModel（状態管理）/
  Networking（通信）/ Storage（永続化）に役割を分け、処理を追いやすくした。
- **通信と保存の境界には`protocol`を定義**し、ViewModelはコンストラクタで依存を受け取る
  （Dependency Injection）。これにより、テスト時に本物のAPI / UserDefaultsではなく
  モックへ差し替えられる構成にした。
- **用途別にモデルを分けた**。GitHub APIでは検索結果、ユーザー詳細、リポジトリで返される情報が
  異なるため、用途ごとに必要な項目だけを持たせた。不要なOptionalが増えることを
  防ぎ、それぞれの画面で必要なデータを分かりやすくした。
- **画面状態を`enum`で表現**。特に「該当なし（empty）」と「通信失敗（error）」を別ケースに
  分けることで、UIで適切なメッセージを出し分けられるようにした。
- **ローカル保存はUserDefaultsを選択**。保存するデータが「検索キーワードの文字列配列」という
  少量・単純なリストであり、データベースを使うほどの構造・件数ではないため。課題の指針
  （少量・単純なデータはKey-Valueストア）に沿った判断。
- **API通信はURLSessionを使って自前で実装**した。共通処理（リクエスト生成・ステータス判定・
  デコード）をジェネリックな`fetch<T: Decodable>`に集約し、3エンドポイントの重複を排除した。

## 4. 工夫した点・こだわった点

- **API通信と画面の状態管理の分離**: APIクライアントを`protocol`で抽象化し、ViewModelへ
  外部から渡せる構成にすることで、実装の差し替えやテストをしやすくしました。また、GitHub APIごとに
  返される情報が異なるため、検索結果、ユーザー詳細、リポジトリのモデルを用途別に分けました。
- **API クライアントの共通化**: `searchUsers` / `fetchUser` / `fetchRepositories` に重複していた
  通信処理を `fetch<T: Decodable>(_ type: T.Type, from url: URL)` に集約。各メソッドは
  「URL の組み立て」と「変換する型の指定」だけに専念する形にした。
- **レート制限のハンドリング**: 403 / 429 を `GitHubAPIError.requestLimited` として捕捉し、
  ユーザーに分かりやすい日本語メッセージを表示。
- **検索連打への対応**: 新しい検索が始まったら前の検索を `Task` のキャンセルで中断し、
  キャンセル由来のエラーはユーザーに表示しないようにした。
- **画像読み込み状態の表示**: 当初は `AsyncImage` の image + placeholder 形式を使用していたが、
  読み込み中と失敗時を区別できなかった。phase 形式へ変更し、読み込み中・成功・失敗で表示を分け、
  失敗した場合は代替アイコンを表示するようにした。
- **UIKit連携を採用した理由**: 対応OSをiOS 17以上としており、iOS 17ではSwiftUI標準の
  アプリ内Web表示機能を利用できない。そのため、対応OS全体でGitHubのページをアプリ内表示できるよう、
  `SFSafariViewController`を`UIViewControllerRepresentable`でラップして組み込んだ。
- **検索履歴のロジック**: 「重複なし（大文字小文字を無視）・新しい順・最大 10 件」を Storage 層に
  閉じ込め、ViewModel 側は「いつ保存するか」だけを気にすればよい構造にした。

## 5. 苦労した点・分からなかった点・未対応の点

### 苦労した点

- **GitHub APIのJSONとSwiftのモデルの対応**: GitHub APIのJSONでは、`name`や`bio`、
  リポジトリの`description`などに`null`が返る場合があるため、対応するプロパティをOptionalにする
  必要があった。また、`avatar_url`や`public_repos`などのスネークケースのキーを、Swift側では
  `avatarURL`や`publicRepos`として扱うため、`CodingKeys`を使って対応付ける方法を調べた。
- **OptionalのURLを使った`.sheet`の表示管理**: 選択したユーザーまたはリポジトリのURLを
  `URL?`として保持したが、`.sheet`の`isPresented`には`Binding<Bool>`が必要だった。そのため、
  URLが`nil`でない場合は表示し、閉じたときはURLを`nil`に戻す`Binding`を`get`と`set`で
  作成した。この状態の変換を理解するのに時間がかかった。
- **Xcodeのファイル管理**: ターミナルや外部エディタで作成したファイルが、Xcodeのビルド対象に
  反映されない問題の原因を調べるのに時間がかかった。実ファイルが存在するだけではなく、Xcodeの
  プロジェクトへの登録も必要だと分かり、Synchronized Groupsを使って実ディレクトリと同期した。
- **チュートリアルと実際の開発の違い**: Develop in Swift TutorialsでSwiftの基礎を学んだが、
  今回必要だったSwiftUIの状態管理や非同期通信などは、追加で調べながら実装する必要があった。

### 分からなかった点

Swiftを使ったアプリ開発は今回が初めてだったため、基本文法からSwiftUIの状態管理、非同期処理まで、
調べながら実装を進めました。特に、次の内容は理解に時間がかかりました。

- `async/await`によって通信処理の完了を待ちながら、画面の操作を止めずに処理する仕組みです。
  また、通信後に`@Published`の状態を更新するため、ViewModelへ`@MainActor`を付ける理由も
  調べました。
- `@Published`で状態の変化を通知し、`@StateObject`でViewModelを保持することで、SwiftUIの
  画面が状態に合わせて再描画される流れを理解するのに時間がかかりました。
- `URL?`を使ってSafari画面の表示状態を管理していたため、`.sheet`が必要とする`Bool`へ変換する
  `Binding`の`get`と`set`の仕組みを理解するのに苦労しました。

### 未対応の点

アプリ機能の必須要件はすべて実装しました。API通信を`protocol`で抽象化し、モックへ差し替えられる
構成にしましたが、モックの作成方法と非同期処理のテストを自分で説明できるところまで理解できなかった
ため、ボーナス要件のUnitテストは実装しませんでした。

## 6. 生成 AI の利用について

### 利用したAIツール

- Claude Code
- Codex
- ChatGPT

### AIを利用した部分と自分で考えた部分

GitHub APIの仕様調査では、生成AIに調査を行わせ、その結果をレポートとしてまとめました。その後、
調査内容を確認し、今回のアプリにはMVVMをベースとした設計が適していると判断しました。作成した
レポートをもとに生成AIと設計を検討し、今回の課題に合う構成へ調整しました。

生成AIは実務を想定した複雑な設計を提案することがあったため、提案をそのまま採用するのではなく、課題の規模や自分の理解度を考慮し、必要な部分だけを取り入れました。

開発開始時はSwiftのコードの書き方を十分に理解できていなかったため、最初の実装では生成AIにコードの
作成を補助してもらいました。その後、生成されたコードを一行ずつ確認し、処理内容を理解しながら
進めました。開発を進める中で、少しずつ自分でもコードを書けるようになりました。

また、コードを読んで冗長に感じる部分や改善できそうな部分があった場合は、生成AIに複数の修正案と
それぞれの違いを提示してもらい、内容を比較したうえで自分で採用する方法を選択しました。

最終的な設計や実装方法については、課題の規模と自分の理解度を踏まえて自分で判断しました。

### 内容を理解して説明できる状態にしたか

- [x] はい、提出したコードはすべて自分で説明できます

## 7. 参考にした情報源（任意）

- [GitHub REST APIドキュメント](https://docs.github.com/en/rest)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)（SwiftUI / URLSession / SFSafariViewController）
- [Develop in Swift Tutorials](https://developer.apple.com/tutorials/develop-in-swift/welcome-to-develop-in-swift-tutorials)
- [参考記事（Qiita）](https://qiita.com/kusumotoa/items/c924d5c67282fd11f664)
- [参考記事（Zenn）](https://zenn.dev/linnefromice/articles/gh-actions-ios-swift-code)
- [Swiftの基本文法に関する参考記事（Qiita）](https://qiita.com/Zack-yutapon/items/16f0019806b56ff091ad)
  - Swift の基本文法を学ぶために利用した。今回の実装では SwiftUI や非同期処理など、
    チュートリアルより発展した内容を追加で調べる必要があった。
