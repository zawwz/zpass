# zpass

Basic and simple password management for UNIX using shell. <br>
Does not require any setup, only uses a password to encrypt the archive.

Systems other than GNU/linux are untested at the moment

# Installing

## Dependencies

Requires:
- gpg
- tar

Optional:
- screen (key caching and clipboard time)
- lftp (for ftps remote files)
- curl (for WebDAV remote files)
- zenity (GUI prompt)
- kdialog (better GUI prompt in KDE)
- xclip (copy on X)
- wl-clipboard (copy on wayland)

## Prebuilt

From [zpkg](https://github.com/zawwz/zpkg) package repository

## From source

Requires [lxsh](https://github.com/zawwz/lxsh)

Clone this repository then run `sudo make install`

# Use

By design zpass uses encrypted archive files, wherein a file contains a value.
You can use predefined operations, or perform custom executions inside the archive.

See `zpass -h` for information on operations and configuration

When using `get` or `copy`, if the path entered is a folder,
zpass will look for a `default` file in this folder

## Example use

Create a file with `zpass c`.
A prompt will appear to use a password to encrypt the password archive file.
<b>If you lose this password, you lose access to all contents of the archive</b>.

You can create new values with either `zpass add <path...>`, `zpass new <path...>`, or `zpass set <path> <value>`

To copy a value into the clipboard, use `zpass <value>` or `zpass copy <value>`

## Configuration

zpass will load by default the file `.config/zpass/default.conf` in your home directory

### Configuring remote file

You can configure zpass to use a file on a remote server. <br>
Multiple methods of remote access can be used:
- SSH+SCP (requires SSH key configured)
- SFTP (requires SSH key configured)
- FTPS
- WebDAV (note: only HTTPS, not HTTP)

SFTP and WebDAV are the recommended options, as they are the easiest, most secure and most stable options. <br>
SFTP is the easiest to use as you only need a configured SSH access to a machine,
however if you want as little delay as possible, you should use WebDAV.

### SFTP example

```
ZPASS_REMOTE_METHOD=sftp
ZPASS_REMOTE_ADDR=example.com
ZPASS_REMOTE_USER=user
ZPASS_SSH_ID=~/.ssh/id_rsa
```

### WebDAV example

```
ZPASS_REMOTE_METHOD=webdav
ZPASS_REMOTE_ADDR=example.com
ZPASS_PATH=zpass
ZPASS_REMOTE_USER=user
ZPASS_REMOTE_PASSWORD=supersecretpassword
```

### Making the cache volatile

If you are caching keys, by default zpass uses `~/.cache` as a caching path.
This can be troublesome in case the machine stops before the cache timer runs out,
leaving a file containing the key in plaintext. <br>
This can be fixed by pointing the cache path to a volatile filesystem. <br>
For example:
```
ZPASS_CACHE_PATH=$XDG_RUNTIME_DIR/zpasscache
```

# Troubleshooting

### Prompt keeps appearing even with correct password

Make sure your gpg configuration is correct, you can run `gpg -c < /dev/null` to check

### I can't get a remote file to work

First verify that you can connect to the remote server with the appropriate protocol by using a client.
Then check that you have the correct rights to the target file (`$ZPASS_PATH/$ZPASS_FILE.tar.gpg`).

If you're attempting the create the file and the folder `$ZPASS_PATH` doesn't exist,
make sure you have correct rights to create said folder.

### I'm encountering another bug

Generate a debug build (`make debug`) and run with environment `DEBUG=true` set,
then send the full output as an issue.
