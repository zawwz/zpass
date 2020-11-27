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
- openssh (for remote files)
- zenity (GUI prompt)
- kdialog (better GUI prompt in KDE)
- xclip (copy on X)
- wl-clipboard (copy on wayland)

## Prebuilt

From [zpkg](https://github.com/zawwz/zpkg) package repository

## From source

Requires [lxsh](https://github.com/zawwz/lxsh)

Clone this repository then run `make install`

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

You can configure zpass to use a file on a remote server.
You need SSH access to the target machine.<br>
Here is an example configuration:
```
ZPASS_REMOTE_ADDR=user@example.com
ZPASS_SSH_ID=~/.ssh/id_rsa
```

### Making the cache volatile

If you are caching keys, by default zpass uses `~/.cache` as a caching path.
This can be troublesome in case the machine stops before the cache timer runs out,
leaving a file containing the key in plaintext. <br>
This can be fixed by pointing the cache path to a volatile filesystem. <br>
For example:
```
ZPASS_CACHE_PATH=/tmp/zpasscache
```

# Troubleshooting

### Prompt keeps appearing even with correct password

Make sure your gpg configuration is correct, you can run `gpg -c < /dev/null` to check
