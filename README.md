# Backup Script

This Bash script automates creating and encrypting a backup archive. It tars (optionally compresses) the specified directory and encrypts the resulting archive with AES-256 via OpenSSL.

## Features
1. **Positional and Named Arguments**

- **Positional:** `./backup.sh <DIRECTORY> [<COMPRESSION>] [<OUTPUT_FILE>]`
- **Named:** `./backup.sh -i <DIRECTORY> [-c <COMPRESSION>] [-o <OUTPUT_FILE>]`

2. **Compression:** Available algorithms are `gzip`, `bzip2`, `xz`. Defaults to *none* if not specified. In case of *none*, archiving works without compression.

3. **Encryption:** Encrypts the archive using OpenSSL with `-aes-256-cbc -pbkdf2` and produces a final file ending in .enc unless an explicit filename is provided.

4. **Error Logging:** All error messages (stderr) are timestamped and logged in error.log. Warnings and errors—such as missing directories or invalid compression—go here.

5. **Help Option:** `-h` or `--help` available anywhere in the arguments to show usage instructions.

6. **Debug Mode:** By default, **DEBUG=1**, so script variables are printed to the terminal. If you set **DEBUG=0**, all normal script output is suppressed, and only errors are logged to *error.log*.

## Usage
You can run the script in two ways: positional or named arguments.

### Positional Mode
```sh
./backup.sh <DIRECTORY> [<COMPRESSION>] [<OUTPUT_FILE>]
```
- `<DIRECTORY>`: **Required**. Must be an existing directory.
- `<COMPRESSION>`: (Optional) One of none (default), `gzip`, `bzip2`, `xz`.
- `<OUTPUT_FILE>`: (Optional) The final name for the encrypted backup. Defaults to `<DIRECTORY>.backup.enc`.

#### Examples
**1. Minimal (no compression, default output):**
```sh
./backup.sh /var/www/html
```
Produces `html.backup.enc` in the current directory.

**2. Specify compression:**
```sh
./backup.sh /home/user gzip
```
Tar + gzip compresses `/home/user`, then encrypts into `user.backup.enc`.

**3. Fully specify:**
```sh
./backup.sh /srv/data xz data_archive.tar.xz
```
Creates `data_archive.tar.xz` (tar + xz), then encrypts into `data_archive.tar.xz`.

### Named Arguments Mode
```sh
./backup.sh -i <DIRECTORY> [-c <COMPRESSION>] [-o <OUTPUT_FILE>]
```
- **-i / --input `<DIRECTORY>`:** **Required** directory path to back up.
- **-c / --compression `<COMPRESSION>`:** Optional. Defaults to none.
- **-o / --output `<OUTPUT_FILE>`:** Optional. Defaults to `<DIRECTORY>.backup.enc` if omitted.

#### Examples
**1. Minimal:**
```sh
./backup.sh -i /var/log
```
Uses no compression; final file `log.backup.enc`.

**2. Specify compression & output:**
```sh
./backup.sh -i /var/log -c bzip2 -o logs_backup.tar.bz2
```
Compresses with `bzip2`, then encrypts into `logs_backup.tar.bz2`.

**3. Help:**
```sh
./backup.sh -h
./backup.sh --help
```
Shows usage instructions and exits.

### Debug/Verbose Mode
The script has a `DEBUG` variable near the top:
```sh
DEBUG=1
```
- **DEBUG=0** (default, quiet mode): Normal output is redirected to `/dev/null`; only errors and warnings show up in error.log.
- **DEBUG=1** (verbose mode): Prints internal variables (`BACKUP_DIR`, `COMPRESSION`, etc.) to stdout (for troubleshooting).

To enable **verbose mode** (i.e., keep normal output visible and print debugging info about the script’s variables) add `-v` or `--verbose` parameter while running the script.

## Outputs
After running successfully, you end up with an encrypted file (e.g., `mydata.backup.enc`). If you specified an output name (like `myarchive.tar.gz`), that’s the file you’ll see (still encrypted). The unencrypted tar is removed automatically.

## How to Restore / Unpack
**1. Decrypt:**
```sh
openssl enc -d -aes-256-cbc -pbkdf2 -in <encrypted_backup> -out <decrypted_backup>
```
You’ll be prompted for the passphrase used to create the backup.

**2. Extract:**

- If uncompressed (none), just:
```sh
tar -xf <decrypted_backup>
```
- If compressed with gzip:
```sh
tar -xzf <decrypted_backup>
```
- If compressed with bzip2:
```sh
tar -xjf <decrypted_backup>
```
- If compressed with xz:
```sh
tar -xJf <decrypted_backup>
```
(You can also do tar -xaf <decrypted_backup> and many modern tar versions will auto-detect the compression.)

## Logging & Error Handling
Errors and warnings (e.g., invalid compression type, missing directory) are timestamped in **error.log**. If you ever need to see normal script messages while debugging, use verbose mode.

## Requirements
- **Bash** (and basic Unix utilities like `tar`).
- **OpenSSL** installed and accessible in `PATH`.
