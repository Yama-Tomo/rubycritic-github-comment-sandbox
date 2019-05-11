# How to deployment

```bash
$ zip -r function.zip index.rb
$ aws lambda update-function-code --function-name <your lambda function name> --zip-file fileb://function.zip
```
