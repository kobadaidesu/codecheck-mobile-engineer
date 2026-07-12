# GitHub REST API 事前調査（未認証）

GitHub ユーザー検索アプリ（iOS / SwiftUI + UIKit 連携）実装に向けた、GitHub REST API の事前調査メモ。

- **調査日**: 2026-07-12
- **前提**: 認証なし（トークン不要）。`Accept: application/vnd.github+json`、`User-Agent` 付与。
- **確認方法**: `curl` で実際にレスポンス／ヘッダーを取得して確認。
- **表記ルール**: 🟢=実測で確認 / 🟡=仕様・一般論からの推測（今回のサンプルでは未確認）。
- **巨大な JSON 全文は貼らず、アプリで使う項目に絞って整理**している。

---

## 1. 対象エンドポイント（未認証）

| 用途 | メソッド / パス |
| --- | --- |
| ユーザー検索 | `GET https://api.github.com/search/users?q={keyword}` |
| ユーザー詳細 | `GET https://api.github.com/users/{username}` |
| 公開リポジトリ一覧 | `GET https://api.github.com/users/{username}/repos` |

いずれも `per_page`（最大 100）と `page` でページ制御可能。

---

## 2. ユーザー検索 API 🟢

`GET /search/users?q=torvalds&per_page=2` → **200**

- トップレベルは配列ではなく **ラッパーオブジェクト**:
  - `total_count`（Int, 例: 454）
  - `incomplete_results`（Bool）
  - `items`（配列）
- `items[]` の要素はユーザーの**簡易版**。アプリで使う主な項目:
  - `login`（String）, `id`（Int）, `avatar_url`（String）, `html_url`（String）
  - `type`（String, 例 `"User"` / `"Organization"`）, `score`（Number）
- **注意**: 検索結果の `items[]` には `name` / `bio` / `followers` などの**詳細項目は含まれない**。
  一覧表示はここまでで足り、詳細画面では別途「ユーザー詳細 API」を叩く必要がある。

### 0 件時のレスポンス 🟢

ヒットしないキーワードで検索 → **200（エラーではない）**

- `total_count: 0`、`items: []`（空配列）、`incomplete_results: false`
- `Link` ヘッダーは付かない。
- → **空状態（該当なし）は HTTP エラーでなく `items` の空判定で表現する**。

---

## 3. ユーザー詳細 API 🟢

`GET /users/torvalds` → **200**

アプリで使う主な項目:

| フィールド | 型 | 備考 |
| --- | --- | --- |
| `login` | String | 必ず存在 |
| `id` | Int | 必ず存在 |
| `avatar_url` | String | アイコン画像 |
| `html_url` | String | ブラウザで開く URL |
| `name` | String? | 🟢 `null` になり得る |
| `bio` | String? | 🟢 実測で `null` を確認 |
| `company` | String? | 🟢 `null` になり得る |
| `location` | String? | 🟢 `null` になり得る |
| `blog` | String? | 🟢 未設定時は **空文字 `""`**（null ではなく）を確認 |
| `email` | String? | 🟢 未認証では基本 `null` |
| `twitter_username` | String? | 🟢 実測で `null` を確認 |
| `hireable` | Bool? | 🟢 実測で `null` を確認 |
| `public_repos` | Int | 公開リポジトリ数 |
| `public_gists` | Int | |
| `followers` | Int | |
| `following` | Int | |

---

## 4. 公開リポジトリ一覧 API 🟢

`GET /users/torvalds/repos?per_page=100` → **200**、トップレベルは**配列**。

アプリで使う主な項目:

| フィールド | 型 | 備考 |
| --- | --- | --- |
| `id` | Int | |
| `name` | String | リポジトリ名 |
| `full_name` | String | `owner/name` |
| `html_url` | String | ブラウザで開く URL |
| `description` | String? | 🟡 未設定時 `null`（今回サンプルでは全件あり） |
| `language` | String? | 🟡 主要言語なしなら `null`（今回サンプルでは全件あり） |
| `stargazers_count` | Int | スター数 |
| `forks_count` | Int | |
| `open_issues_count` | Int | |
| `fork` | Bool | フォークかどうか |
| `homepage` | String? | 🟢 未設定時 `null` または空文字（12件中10件で null/空） |
| `license` | Object? | 🟢 実測で `null` を確認（12件中2件）。中身は `{ key, name, spdx_id, url }` |
| `default_branch` | String | |
| `visibility` | String | 未認証なので基本 `"public"` |

- **リポジトリが 0 件のユーザー**: 空配列 `[]` を返す 🟡（0件検索と同様、エラーではなく空判定で扱う想定）。

---

## 5. 404 エラー 🟢

`GET /users/{存在しないユーザー}` → **404**

- `Content-Type: application/json`
- ボディ: `{ "message": "Not Found", "documentation_url": "https://docs.github.com/rest", "status": "404" }`
- → **存在しないユーザーは 404。空状態とは区別してエラー扱い**する（詳細画面直叩き時など）。

---

## 6. レート制限ヘッダー 🟢

未認証時の実測値。**Core（ユーザー/リポジトリ系）と Search（検索系）で別枠**。

| ヘッダー | Core（`/users`, `/repos`） | Search（`/search/users`） |
| --- | --- | --- |
| `x-ratelimit-limit` | **60** / 時 | **10** / 分 |
| `x-ratelimit-remaining` | 残り回数 | 残り回数 |
| `x-ratelimit-used` | 使用済み回数 | 使用済み回数 |
| `x-ratelimit-reset` | リセット時刻（UNIX epoch 秒） | 同左 |
| `x-ratelimit-resource` | `core` | `search` |

- 上限到達時は **HTTP 403（または 429）** を返す 🟡（今回は未到達のため実測せず。ボディ `message` に "rate limit" 系の文言、`x-ratelimit-remaining: 0`）。
- `GET /rate_limit` で現在の残量を確認可能（このエンドポイント自体はレート制限を消費しない）🟢。
- → **`x-ratelimit-remaining` と `reset` を見て、0 到達時は「時間をおいて再試行」を促す UI にする**。

---

## 7. ページネーション 🟢

- 件数が多い場合、**`Link` レスポンスヘッダー**に次/最終ページの URL が入る:
  - 例: `<...&page=2>; rel="next", <...&page=227>; rel="last"`
- `search/users` / `repos` いずれも `Link` を確認。次ページが無い場合は `rel="next"` が付かない。
- `per_page`（最大 100, 既定 30）, `page`（1 始まり）で制御。
- **Search API は未認証だと最大 1000 件（page 上限あり）** 🟡。
- ボーナス要件のページネーションは、`Link` の `rel="next"` 有無、または `total_count` と取得済み件数の比較で「追加読み込み可能か」を判定する方針。

---

## 8. Swift モデル案

必要な項目のみ `Codable` でマッピング（`snake_case` は `CodingKeys` か `keyDecodingStrategy = .convertFromSnakeCase` で吸収）。

```swift
// 検索レスポンスのラッパー
struct UserSearchResponse: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [UserSummary]
}

// 検索結果の一覧要素（詳細項目は含まれない）
struct UserSummary: Decodable, Identifiable {
    let id: Int
    let login: String
    let avatarUrl: String
    let htmlUrl: String
    let type: String
}

// ユーザー詳細
struct UserDetail: Decodable {
    let id: Int
    let login: String
    let avatarUrl: String
    let htmlUrl: String
    let name: String?
    let bio: String?
    let company: String?
    let location: String?
    let blog: String?            // 未設定は "" になり得る
    let email: String?
    let twitterUsername: String?
    let hireable: Bool?
    let publicRepos: Int
    let followers: Int
    let following: Int
}

// リポジトリ
struct Repository: Decodable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let htmlUrl: String
    let description: String?
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let fork: Bool
    let homepage: String?
    let license: License?

    struct License: Decodable {
        let key: String
        let name: String
        let spdxId: String
    }
}

// エラーレスポンス（404 / レート制限など）
struct GitHubErrorResponse: Decodable {
    let message: String
    let documentationUrl: String?
}
```

### Optional にすべき項目（重要）

- **ユーザー詳細**: `name`, `bio`, `company`, `location`, `blog`, `email`, `twitterUsername`, `hireable`
  （🟢 実測で `null` を確認済みのものを含む。`blog` は `null` ではなく空文字のこともある点に注意）
- **リポジトリ**: `description`, `language`, `homepage`, `license`
  （`homepage`/`license` は 🟢 実測で null 確認、`description`/`language` は 🟡 仕様上 null になり得る）
- 逆に **`id` / `login` / `avatar_url` / `html_url` / 各種 count は非 Optional** で扱ってよい（常に存在）。
- 表示側では、Optional を「未設定」文言や非表示にフォールバックさせ、`blog == ""` も未設定扱いに正規化する。

---

## 9. エラー処理方針

想定するエラーと扱い:

| 区分 | 検知方法 | UI / 挙動 |
| --- | --- | --- |
| ネットワーク失敗 | `URLError`（オフライン等） | 「通信に失敗しました」＋リトライ |
| 該当なし（0件） | 200 かつ `items` / 配列が空 | **エラーではなく「空状態」**として専用表示 |
| 存在しないユーザー | 404 + `message: "Not Found"` | 「ユーザーが見つかりません」 |
| レート制限超過 | 403/429 かつ `x-ratelimit-remaining: 0` | 「時間をおいて再試行してください」＋ `reset` 時刻の案内 |
| デコード失敗 | `DecodingError` | 予期しない形式としてログ＋汎用エラー表示 |
| その他 4xx/5xx | ステータスコード判定 | 汎用エラー表示 |

方針:

- **HTTP ステータスと業務的な「空」を明確に区別**する（0件は成功扱い、404 はエラー扱い）。
- レスポンス取得後に `URLResponse` を `HTTPURLResponse` にキャストし、`statusCode` で分岐 → `Result` / `throws` でドメインエラー型（例: `enum GitHubAPIError`）に変換して ViewModel へ渡す。
- レート制限は `x-ratelimit-remaining` を事前に見て過剰リクエストを抑制、超過時は待機時間を提示。
- `async/await`（必須要件）で実装し、ローディング / 成功 / 空 / エラーの状態を明示的に持つ。

---

## 10. 補足・未確認事項

- 🟡 レート制限超過時の実ステータス（403 か 429 か）とボディ文言は、今回は上限未到達のため未実測。実装時に意図的に到達させて確認予定。
- 🟡 `description` / `language` の `null` は今回のサンプル（torvalds の12件）では出現せず。仕様上は `null` になり得るため Optional 前提で扱う。
- Search API の未認証上限は「1分あたり10リクエスト」。連続検索時のデバウンス／スロットリングを検討する。
