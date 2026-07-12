# GitHub REST API 事前調査

調査日: 2026-07-12  
調査方法: GitHub REST API へ認証情報を付けずに実リクエストを送信  
API バージョン: `2022-11-28`

## 1. 調査条件

すべてのリクエストに次のヘッダーを付け、`Authorization` ヘッダーは付けていない。

```http
Accept: application/vnd.github+json
X-GitHub-Api-Version: 2022-11-28
```

レスポンスは調査時点のものであり、件数、プロフィール内容、リポジトリ内容、
レート制限の残数は変化する。以下では実際に確認した内容を「実測」、
公式ドキュメントや実測から導いた実装上の判断を「実装方針」として分ける。

## 2. ユーザー検索 API

エンドポイント:

```http
GET https://api.github.com/search/users?q={keyword}&per_page={count}&page={page}
```

### 実測: 検索結果あり

`q=octocat&per_page=2&page=1` で `200 OK` を確認した。
レスポンス本文の必要部分は次のとおり。

```json
{
  "total_count": 1127,
  "incomplete_results": false,
  "items": [
    {
      "login": "octocat",
      "id": 583231,
      "avatar_url": "https://avatars.githubusercontent.com/u/583231?v=4",
      "html_url": "https://github.com/octocat",
      "type": "User",
      "site_admin": false,
      "score": 1.0
    }
  ]
}
```

`items` はユーザー配列で、検索一覧に必要な `id`、`login`、
`avatar_url`、`html_url` を含む。詳細画面で使う `name`、`bio`、
`followers` などは検索結果には含まれないため、選択後にユーザー詳細 API を呼ぶ。

### 実測: 検索結果 0 件

`q=codex-api-research-no-such-user-20260712` では `200 OK` となり、
本文は次の形だった。

```json
{
  "total_count": 0,
  "incomplete_results": false,
  "items": []
}
```

0 件は HTTP エラーではない。アプリではエラー表示ではなく「該当するユーザーなし」
という空状態として扱う。

### 実測: 不完全な検索結果

`q=repos:0 type:user&sort=joined&order=asc&per_page=1&page=1` では
`200 OK` だが `incomplete_results: true` だった。検索処理が時間制限などで
完了しなかった場合でも、取得できた `items` は返される。

実装では `incomplete_results` を必ずデコードし、`true` の場合は取得済みの
結果を破棄せず、結果が完全ではないことを状態として保持する。

## 3. ユーザー詳細 API

エンドポイント:

```http
GET https://api.github.com/users/{username}
```

### 実測

`GET /users/octocat` で `200 OK` を確認した。必要部分は次のとおり。

```json
{
  "login": "octocat",
  "id": 583231,
  "avatar_url": "https://avatars.githubusercontent.com/u/583231?v=4",
  "html_url": "https://github.com/octocat",
  "name": "The Octocat",
  "company": "@github",
  "blog": "https://github.blog",
  "location": "San Francisco",
  "email": null,
  "hireable": null,
  "bio": null,
  "twitter_username": null,
  "public_repos": 8,
  "followers": 23257,
  "following": 9
}
```

この実レスポンスでは `email`、`hireable`、`bio`、
`twitter_username` が `null` だった。プロフィールの任意入力項目は
ユーザーによって未設定になり得るため、表示時の代替値または非表示方針が必要になる。

## 4. 公開リポジトリ一覧 API

エンドポイント:

```http
GET https://api.github.com/users/{username}/repos?type=public&sort=updated&per_page={count}&page={page}
```

### 実測: リポジトリあり

`GET /users/octocat/repos?type=public&sort=updated&per_page=2&page=1` で
`200 OK` と JSON 配列を確認した。先頭の要素の必要部分は次のとおり。

```json
{
  "id": 1296269,
  "name": "Hello-World",
  "full_name": "octocat/Hello-World",
  "html_url": "https://github.com/octocat/Hello-World",
  "description": "My first repository on GitHub!",
  "homepage": "",
  "language": null,
  "forks_count": 6214,
  "stargazers_count": 3672,
  "license": null,
  "visibility": "public"
}
```

同じページの別リポジトリでは `homepage: null` も確認した。
`language` と `license` も実際に `null` だった。
`description` は今回の2件では文字列だったが、未設定のリポジトリでは
`null` になり得る項目として扱う。

### 実測: リポジトリ 0 件

公開リポジトリ数が 0 のユーザーを検索して
`GET /users/mehdi/repos?type=public&per_page=20&page=1` を呼んだところ、
`200 OK` と空配列を確認した。

```json
[]
```

リポジトリ 0 件もエラーではなく、詳細画面内の空状態として扱う。

## 5. 404 エラー

### 実測

存在しないユーザー名を指定した
`GET /users/codex-api-research-no-such-user-20260712` では
`404 Not Found` と次の本文を確認した。

```json
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest",
  "status": "404"
}
```

成功モデルでのデコードを試みる前に HTTP ステータスを判定し、
エラー時は専用のエラーレスポンスとしてデコードする必要がある。

## 6. レート制限ヘッダー

### 実測

各レスポンスで次のヘッダーを確認した。

| リクエスト例 | Status | limit | remaining | used | resource |
| --- | ---: | ---: | ---: | ---: | --- |
| ユーザー検索 | 200 | 10 | 9 | 1 | `search` |
| 0件検索 | 200 | 10 | 8 | 2 | `search` |
| ユーザー詳細 | 200 | 60 | 53 | 7 | `core` |
| リポジトリ一覧 | 200 | 60 | 54 | 6 | `core` |
| 存在しないユーザー | 404 | 60 | 55 | 5 | `core` |

リクエストは一部並行して実行したため、表の `remaining` と `used` は
上から順に減少した値ではない。404 を含め、成功・失敗のどちらにも
レート制限ヘッダーが付いていた。

主に利用するヘッダー:

- `x-ratelimit-limit`: 制限枠の上限
- `x-ratelimit-remaining`: 現在の残数
- `x-ratelimit-used`: 使用済み件数
- `x-ratelimit-reset`: 制限解除時刻を表す Unix time（UTC）
- `x-ratelimit-resource`: 消費した制限枠。今回確認した値は `search` と `core`
- `retry-after`: セカンダリレート制限などで付く場合がある待機秒数

### 実装方針

未認証の通常 REST API は 1 時間あたり 60 回、Search API は別枠で
1 分あたり 10 回である。検索入力ごとに即時通信せず、debounce と
進行中リクエストのキャンセルを行うことで Search の枠を浪費しない。

`403` または `429` を受けた場合は、`retry-after`、
`x-ratelimit-remaining`、`x-ratelimit-reset` を確認する。
解除時刻までは自動で連続再試行しない。

## 7. ページネーション

### 実測

検索 API の `per_page=2&page=1` では次の `Link` ヘッダーを確認した。

```http
Link: <https://api.github.com/search/users?q=octocat&per_page=2&page=2>; rel="next",
      <https://api.github.com/search/users?q=octocat&per_page=2&page=500>; rel="last"
```

`total_count` は 1127 だったが、Search API から取得できるのは最大
1,000 件であるため、最終ページは 500 だった。

リポジトリ一覧でも次の `Link` ヘッダーを確認した。

```http
Link: <https://api.github.com/user/583231/repos?type=public&sort=updated&per_page=2&page=2>; rel="next",
      <https://api.github.com/user/583231/repos?type=public&sort=updated&per_page=2&page=4>; rel="last"
```

GitHub が返した次ページ URL は、元の username ベースの URL ではなく
ユーザー ID ベースの URL だった。クライアント側で URL を推測して再構築せず、
`Link` の `rel="next"` をそのまま次ページ情報として保持するのが安全である。
全件が1ページに収まる場合や空配列の場合、`Link` ヘッダーは付かない。

公式仕様では両 API とも `per_page` の既定値は 30、最大値は 100、
`page` の既定値は 1 である。

## 8. Swift モデル案

アプリが使用する項目だけを DTO として定義する。API の snake_case と
Swift の命名を明示的に対応させ、特に `URL` の大文字表記が
`.convertFromSnakeCase` で期待どおり変換されない問題を避ける。

```swift
struct UserSearchResponse: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [UserSummary]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}

struct UserSummary: Identifiable, Decodable {
    let id: Int
    let login: String
    let avatarURL: URL
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case id, login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

struct UserDetail: Identifiable, Decodable {
    let id: Int
    let login: String
    let avatarURL: URL
    let htmlURL: URL
    let name: String?
    let bio: String?
    let company: String?
    let blog: String?
    let location: String?
    let email: String?
    let hireable: Bool?
    let twitterUsername: String?
    let publicRepos: Int
    let followers: Int
    let following: Int

    enum CodingKeys: String, CodingKey {
        case id, login, name, bio, company, blog, location, email
        case hireable, followers, following
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case twitterUsername = "twitter_username"
        case publicRepos = "public_repos"
    }
}

struct Repository: Identifiable, Decodable {
    let id: Int
    let name: String
    let fullName: String
    let htmlURL: URL
    let description: String?
    let language: String?
    let stargazersCount: Int
    let forksCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName = "full_name"
        case htmlURL = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
    }
}

struct GitHubErrorResponse: Decodable {
    let message: String
    let documentationURL: URL?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case message, status
        case documentationURL = "documentation_url"
    }
}
```

### Optional にする項目

実測で `null` を確認した項目:

- `UserDetail.email`
- `UserDetail.hireable`
- `UserDetail.bio`
- `UserDetail.twitterUsername`
- `Repository.language`
- リポジトリモデルに含める場合の `homepage` と `license`

ユーザーごとの未設定を考慮して Optional にする項目:

- `UserDetail.name`
- `UserDetail.company`
- `UserDetail.blog`
- `UserDetail.location`
- `Repository.description`

`id`、`login`、API が提供する各 URL、件数値、リポジトリ名は、
今回の画面表示と識別に必要なため Optional にしない。将来 API の契約違反で
欠落した場合は、不完全なデータを表示するよりデコードエラーとして検出する。

## 9. エラー処理方針

想定するエラー型:

```swift
enum GitHubAPIError: Error {
    case invalidRequest
    case transport(URLError)
    case invalidResponse
    case notFound
    case rateLimited(resetAt: Date?, retryAfter: TimeInterval?)
    case validation(message: String)
    case server(statusCode: Int, message: String?)
    case http(statusCode: Int, message: String?)
    case decoding(DecodingError)
}
```

処理順序:

1. `URLSession` の通信エラーを `transport` として扱う。
2. `HTTPURLResponse` でなければ `invalidResponse` とする。
3. `200..<300` の場合だけ成功モデルをデコードする。
4. エラー時は可能なら `GitHubErrorResponse` をデコードし、次のように分類する。

| 状態 | 扱い |
| --- | --- |
| 検索0件、リポジトリ0件 | 成功。空状態を表示 |
| `incomplete_results: true` | 取得済み結果を表示し、部分結果として保持 |
| `404` | `notFound`。ユーザーが存在しない旨を表示 |
| `422` | `validation`。検索条件を見直せるメッセージを表示 |
| `403` / `429` | ヘッダーとエラー本文からレート制限を判定 |
| `500..<600` | `server`。時間を置いた再試行を案内 |
| その他の非2xx | ステータスと GitHub の `message` を保持した `http` |
| 成功本文の形式不一致 | `decoding`。一般的な取得失敗として表示し、ログには詳細を残す |

`403` は常にレート制限とは限らない。`x-ratelimit-remaining == 0`、
`retry-after` の有無、GitHub の `message` を組み合わせて判定する。
`URLError.cancelled` は検索語更新に伴う正常なキャンセルであれば
ユーザー向けエラーを表示しない。未認証では上限が低いため、
失敗時は無制限に自動再試行せず、基本は明示的な再試行操作を提供する。

## 10. 参考資料

- [Search users - GitHub Docs](https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-users)
- [Get a user - GitHub Docs](https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28#get-a-user)
- [List repositories for a user - GitHub Docs](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-a-user)
- [Using pagination in the REST API - GitHub Docs](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)
- [Rate limits for the REST API - GitHub Docs](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)
