# rubycritic-github-comment-sandbox

> PR作成時に rubycriticのスコアをコメントするサンプル

masterブランチとのスコアの差分をPRのコメントへPOSTします

<img width="728" src="https://user-images.githubusercontent.com/4970917/59962945-5858f980-9527-11e9-80bd-11960be2f257.png">

[demo](https://github.com/Yama-Tomo/rubycritic-github-comment-sandbox/pull/17)

## How to configuration

- リポジトリを circleci と連携させます

- AWS lambda をデプロイします
  - [README](https://github.com/Yama-Tomo/rubycritic-github-comment-sandbox/blob/master/.circleci/github-webhook/README.md) を参照してください

- リポジトリの webhookを設定します
  - **Payload URL**: デプロイした aws lambda のエンドポイントを設定
  - **Content typeL**: application/json
  - **Which events would you like to trigger this webhook?**: `Pull requests` にチェック


