#!/bin/sh

function urlencode() {
    echo "$1" | perl -MURI::Escape -lne 'print uri_escape($_)'
}

# Consumer key
consumer_key='acbdefghijklmnopqrstuEQ4gV'
# Consumer secret
consumer_secret='acbdefghijklmnopqrstuacbdefghijklmnopqrstuvJREaEb0mv'
# Access token
access_token='acbdefghijklmnopqrstuacbdefghijklmnopqrstueqs4QeuxLc'
# Access token secret
access_token_secret='acbdefghijklmnopqrstuacbdefghijklmnopqrstuqeOg0'
# REST API address
api_url='https://api.twitter.com/1.1/statuses/update.json'

oauth_consumer_key=$consumer_key					# twitterで取得したConsumer key
oauth_nonce=`openssl rand 64 | md5sum | base64`		# ランダムな英数字のみからなる文字列32文字を設定
oauth_signature_method='HMAC-SHA1'					# HMAC-SHA1固定
oauth_timestamp=`date '+%s'`						# いわゆるUNIXタイムスタンプ
oauth_token=$access_token							# アクセストークン
oauth_version='1.0'									# 1.0固定
status=`php -r "print( rawurlencode( \"$1\" ));"`	# つぶやきの内容。

param='oauth_consumer_key='$oauth_consumer_key\
'&oauth_nonce='$oauth_nonce\
'&oauth_signature_method='$oauth_signature_method\
'&oauth_timestamp='$oauth_timestamp\
'&oauth_token='$oauth_token\
'&oauth_version='$oauth_version\
'&status='$status
signature_param='POST&'`urlencode $api_url`'&'`urlencode $param`
key=`urlencode $consumer_secret`'&'`urlencode $access_token_secret`
signature=`echo -n $signature_param | openssl dgst -hmac $key -sha1 -binary | base64`
oauth_signature=`urlencode $signature`			# シグネチャを設定

param='oauth_consumer_key='$oauth_consumer_key\
'&oauth_nonce='$oauth_nonce\
'&oauth_signature='$oauth_signature\
'&oauth_signature_method='$oauth_signature_method\
'&oauth_timestamp='$oauth_timestamp\
'&oauth_token='$oauth_token\
'&oauth_version='$oauth_version\
'&status='$status

# echo 'Bash :'
# echo "curl --request 'POST' '"$api_url"' --data '"$param"'"
# echo
# echo

curl -v --request 'POST' $api_url --data $param
