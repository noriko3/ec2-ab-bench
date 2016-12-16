# ec2-ab-bench

https://github.com/manabusakai/ec2-bench を元に改造したものです。

ab の結果を容易に取得したかったので、cloud-config での実行をやめて、ssh でコマンドを投げる方式にしました。


## ec2-ab-bench とは

ec2 にインスタンスを作成して、そこに ssh をして、対象に ab をするためのツールです。

## 使い方

`aws configure` で APIKEY や SECKEY の設定をしてください。

### config ファイル

    image_id="ami-983ce8f6"
    instance_type="t2.micro"
    instance_count="2"
    request_number="200"
    client_number="100"
    key_name="noriko"
    subnet_id="subnet-964784ff"
    security_group_ids="sg-71756618"

ami はリージョン毎に違うので、確認してください。

inctance_type もリージョン毎に違うので、確認してください。

instance_count は同時に立ち上げるインスタンスの数です。ユーザによって？上限が異なるようです。

request_number リクエスト数です。 ab -r [ココ]

client_number クライアント数です。 ab -c [ココ]

key_name SSH用のキーの名前を入れます。先に用意しておく必要があります。

subnet_id ネットワークのサブネットのIDが必要ですので、先にネットワークを作成しておく必要があります。

security_group_ids 外部からSSHが出来るセキュリティグループを作成しておく必要があります。

## 使い方

引数に ab したい URL を指定します

       $ sh ec2-ab-bench.sh http://www.example.com/
       work_dir: /Users/noriko/tmp/ab/1216-1758
       Instances: i-xxxxxxxx i-xxxxxxxx
       Cleanup command: aws ec2 terminate-instances --instance-ids i-xxxxxxxx i-xxxxxxxx

work_dir の中に実行結果が インスタンスID.log のファイルに入っています

ターミネイトするためのコマンドが表示されるので、終わったらこのコマンドを実行してターミネイトできます。

## その他

- AWSLinuxのファイルディスクリプタの制限がデフォルトで 1024 だったため、-c に 10000 とか指定できなかったので、起動時に設定を変更しています。これでも足りない場合はその辺いじってください。
- ssh の実行を & をつけてバックグラウンドで行うようにしてしまったため、いつ終わったかわかりませんが、投げているコマンドの 2>/dev/null を削除すれば何となくわかります。この辺はあとでちょっと調整したいところ
- t2.micro と m4.xlarge では10倍ほど結果に差が出ました(ただし個人の感想です)。

## License

MIT License
