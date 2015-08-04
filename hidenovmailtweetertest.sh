#!/bin/sh

# Refresh token を元に Access token を取得する。
function get_gmail_access_token() {
    access_token=`curl --silent -d "client_id=$consumer_key&client_secret=$consumer_secret&refresh_token=$refresh_token&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token | jq -r '.access_token'`
    echo -n $access_token > ./.gmailaccesstoken
}

# Consumer key
consumer_key='1234567890123456789012345678901234567890fsda.apps.googleusercontent.com'
# Consumer secret
consumer_secret='abcdefhijklmnopqrstuYKeq'
# Refresh token
refresh_token='abcdefhijklmnopqrstuabcdefhijklmnopqrstuabcdefhijklmnopqrstuzcRFq6'
# REST API address
api_url='https://www.googleapis.com/gmail/v1/users/me/messages/'
# Allow Mail Address
allow_addr='keitai_denwano_meado%40t.vodafone.ne.jp'

if ! [ -e ./.gmailaccesstoken ]; then
    get_gmail_access_token
fi

access_token=`cat ./.gmailaccesstoken`

# 未読メール一覧の件数取得
_ids_cnt=`curl --silent -H "Authorization: Bearer $access_token" $api_url'?labelIds=UNREAD&q=from:('"$_allow_addr"')' | jq -r '.resultSizeEstimate'`
# 未読メール一覧の件数が取得できなかったら Access token を再取得
if [ $_ids_cnt == 'null'  ]; then
    get_gmail_access_token
    access_token=`cat ./.gmailaccesstoken`
    _ids_cnt=`curl --silent -H "Authorization: Bearer $access_token" $api_url'?labelIds=UNREAD' | jq -r '.resultSizeEstimate'`
    if [ $_ids_cnt == 'null' ]; then
        echo 'Mail List can not Collect'
        exit 1
    fi
fi

# 未読メールが１件以上存在する。
if [ $_ids_cnt != '0' ]; then
    _ids=`curl --silent -H "Authorization: Bearer $access_token" $api_url'?labelIds=UNREAD' | jq -r '.messages[].id'`
    for((_i=1;;_i++))
    do
       _id=`echo -n $_ids | cut -d ' ' -f $_i`
        if [ ${#_id} -eq 0 ]; then
            break
        fi
echo -n 'Retrieving a message : '$_id
        _msg=`curl --silent -H "Authorization: Bearer $access_token" $api_url$_id`
        if [ ${#_msg} -ne 0 ]; then
#            _from_addr=`echo -n $_msg | jq -r '.payload.headers[] | select(.name=="From") | .value'`
#            _allow=`echo -n $_from_addr | grep "$allow_addr"`
#            if [ ${#_allow} -ne 0 ]; then
#echo ' : From Addr Allowed'
# 該当メッセージを既読にする。
                curl --silent --request 'POST' -H "Authorization: Bearer $access_token"\
                  -H 'Content-Type:application/json'\
                  -H 'Content-length:29'\
                  -d '{"removeLabelIds":["UNREAD"]}'\
                  $api_url$_id'/modify' > /dev/null
                  _body=`echo "$_msg" | jq -r '.payload.body.data' | awk '{gsub(/_/,"/");gsub(/-/,"+");print $0}' | base64 -d`
echo 'BODY : --->'
# 必ず変数を "～" で括らないと文字化けするよ！
echo "$_body"
echo '<---'
echo
                ./tweet.sh "$_body"
#            else
#echo ' : From Addr Denied'
#            fi
        else
echo ' ? Message ?'
        fi
    done
else
echo 'Message Not Found'
fi

