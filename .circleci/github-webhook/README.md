# AWS lambda code

github の webhook を受け取り circleci のジョブをキックします

## How to deployment

- circleci のダッシュボードから API トークンを作成します

- KMS に circleci のトークンを設定します
  - キー名: CIRCLE_CI_TOKEN

- lambda をデプロイします

```bash
$ zip -r function.zip index.rb
$ aws lambda update-function-code --function-name <your lambda function name> --zip-file fileb://function.zip
```
