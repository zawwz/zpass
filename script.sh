
{
  curl -s --user zawz:8C9Hd-TMdkg-683cQ-HHfqB-okTj2 -X PROPFIND --upload-file - -H 'Depth: 1' https://nextcloud.zawz.net/remote.php/dav/files/zawz/zpass/ << EOF
<?xml version="1.0"?>
<a:propfind xmlns:a="DAV:">
<a:prop><a:resourcetype/></a:prop>
</a:propfind>
EOF

} | xmllint --xpath "$1" -
