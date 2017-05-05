#!/bin/bash

set -euo pipefail

cd ~/g/avar-hn-backup

mkdir {comments-txt,comments-json,user-json} || :

if ! test -s user-json/avar.json
then
    curl -s https://hacker-news.firebaseio.com/v0/user/avar.json?print=pretty > user-json/avar.json
fi

jq '.submitted[]' user-json/avar.json >/tmp/avar-comments-list.txt

for comment in $(cat /tmp/avar-comments-list.txt | sort -n)
do
    echo $comment:

    if ! test -s comments-json/$comment.json
    then
        sleep 1
        curl -s "https://hacker-news.firebaseio.com/v0/item/$comment.json?print=pretty" >comments-json/$comment.json
    fi

    # Whatever's there already clobber it, it's in source control and
    # we're likely re-running a newer version of the script.
    >comments-txt/$comment.txt
    printf "%s:\t%s\n" Comment-Id $comment >>comments-txt/$comment.txt
    printf "%s:\t%s\n" Comment-Author $(jq -r '.["by"]' < comments-json/$comment.json) >>comments-txt/$comment.txt
    printf "%s\t" Comment-Date: >>comments-txt/$comment.txt
    cat comments-json/$comment.json | date --date="@$(jq -r '.["time"]')" >>comments-txt/$comment.txt
    printf "%s:\t%s\n" Comment-Type $(jq -r '.["type"]' < comments-json/$comment.json) >>comments-txt/$comment.txt
    printf "%s:\t%s\n" Parent-Id $(jq -r '.["parent"]' < comments-json/$comment.json) >>comments-txt/$comment.txt

    echo >>comments-txt/$comment.txt
    jq -r '.["text"]' < comments-json/$comment.json | w3m -dump -cols 80 -T text/html  >>comments-txt/$comment.txt

    cat comments-txt/$comment.txt
done
