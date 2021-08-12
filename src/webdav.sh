#!/bin/sh

webdav_folder_url() {
  echo "https://$remote_host${ZPASS_REMOTE_PORT+:$ZPASS_REMOTE_PORT}/"
}

# $1 = url complement , $@ = curl args
webdav_cmd() {
  complement=$1
  shift 1
  curl -s --user $remote_user:$ZPASS_REMOTE_PASSWORD "$@" "$(webdav_folder_url)$complement"
}

webdav_list() {
  webdav_cmd "$datapath/" -X PROPFIND --upload-file - -H "Depth: 1" << EOF | grep '<D:href>' | cut -d'>' -f2 | cut -d'<' -f1 | sed "s|^/$datapath/||g"
<?xml version="1.0"?>
<a:propfind xmlns:a="DAV:">
<a:prop><a:resourcetype/></a:prop>
</a:propfind>
EOF
}

webdav_create() {
  webdav_cmd "$datapath/" -X MKCOL >/dev/null
  webdav_cmd "$2" -T "$1" >/dev/null
}
