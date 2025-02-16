#!/bin/bash
: '
Backup Script
Author: Tevfik Oguzhan Aksoy
'

# ------------------------------------------------------------------------------
# Log all errors to error.log with timestamps
# ------------------------------------------------------------------------------
exec 2> >( while IFS= read -r line; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line" >> error.log
done )

# Global variables to fill
BACKUP_DIR=""
COMPRESSION="none"
OUTPUT_FILE=""
TEMP_TAR=""

DEBUG=1

# ------------------------------------------------------------------------------
# Debug function to print the variables
# ------------------------------------------------------------------------------
debug(){
    echo "BACKUP_DIR: $BACKUP_DIR" 
    echo "COMPRESSION: $COMPRESSION"
    echo "OUTPUT_FILE: $OUTPUT_FILE"
    echo "TEMP_TAR: $TEMP_TAR"
}

# ------------------------------------------------------------------------------
# Help function to display usage instructions
# ------------------------------------------------------------------------------
help() {
    cat <<EOF
Usage:
  1) Positional mode:
    $0 <DIRECTORY> [<COMPRESSION>] [<OUTPUT_FILE>]
      - <DIRECTORY> is required.
      - <COMPRESSION> defaults to "none" if omitted.
      - <OUTPUT_FILE> defaults to "<DIRECTORY>.backup.enc" if omitted.

  2) Named arguments mode:
    $0 -i <DIRECTORY> [-c <COMPRESSION>] [-o <OUTPUT_FILE>]

Description:
  Creates a tar archive from <DIRECTORY> using an optional compression method
  (gzip, bzip2, xz, none) and encrypts it via openssl (AES-256-CBC).

Defaults:
  - If DIRECTORY is missing, script errors and exits.
  - If COMPRESSION is missing, it defaults to "none" (uncompressed tar).
  - If OUTPUT_FILE is missing, it defaults to "<DIRECTORY>.backup.enc".

-h, --help  Show this help message (recognized anywhere in arguments)

Examples:
  # Positional:
    $0 /var/log           # no compression => "none", output => "log.backup.enc"
    $0 /home/user gzip    # compressed with gzip, output => "user.backup.enc"
    $0 /var/www/html gzip html_backup.tar.gz

  # Named:
    $0 -i /srv/data -c xz -o data_backup.tar.xz
    $0 -i /var/www/html   # compression => none, output => "html.backup.enc"

Output:
  Creates an encrypted backup archive.
EOF
}

# ------------------------------------------------------------------------------
# Create a tar archive of a directory with optional compression
# ------------------------------------------------------------------------------
create_archive() {
    # If algo is "none", just create an uncompressed tar file.
    if [[ "$COMPRESSION" == "none" ]]; then
        tar -cf "$TEMP_TAR" "$BACKUP_DIR"
    else
        # Use the '--<algo>' form for tar compression flags (e.g. --gzip, --bzip2, --xz)
        tar -c --"$COMPRESSION" -f "$TEMP_TAR" "$BACKUP_DIR"
    fi

    # To unpack the archive, first decrypt, then:
    # tar -xaf <decrypted_backup>
}

# ------------------------------------------------------------------------------
# Encrypt the resulting archive with openssl using AES-256
# ------------------------------------------------------------------------------
encrypt_archive() {
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$TEMP_TAR" -out "$OUTPUT_FILE"
    # To decrypt, use: 
    # openssl enc -d -aes-256-cbc -pbkdf2 -in <encrypted_backup> -out <decrypted_backup>
}

# ------------------------------------------------------------------------------
# Main function to call the other functions
# ------------------------------------------------------------------------------
main() {
    # Create a temporary tar archive
    create_archive "$BACKUP_DIR" "$COMPRESSION" "$OUTPUT_FILE"
    
    # Encrypt the tar archive
    encrypt_archive "$OUTPUT_FILE"
    
    # Remove the unencrypted tar once encrypted
    rm -f "$TEMP_TAR"
}

# ------------------------------------------------------------------------------
# A small helper to set defaults for output if it's still empty after parsing
# ------------------------------------------------------------------------------
set_output_default() {
    if [[ -z "$OUTPUT_FILE" && -n "$BACKUP_DIR" ]]; then
        local base
        base="$(basename "$BACKUP_DIR")"
        TEMP_TAR="${base}.backup.temp"
        OUTPUT_FILE="${base}.backup.enc"
    else
        TEMP_TAR=${OUTPUT_FILE}.backup.temp
    fi
}

# ------------------------------------------------------------------------------
# Parse the arguments passed to the script
# ------------------------------------------------------------------------------
parse_arguments(){
    # Check if -h/--help is passed as an argument anywhere
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                help
                exit 0
                ;;
        esac
    done

    # Redirect stdout to /dev/null except the help message
    if [[ $DEBUG -eq 0 ]]; then
        exec 1>/dev/null
    fi

    if [[ "$1" =~ ^- ]]; then
        # Named arguments mode
        while [[ $# -gt 0 ]]; do
            case "$1" in
            -i|--input)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -c|--compression)
                COMPRESSION="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            *)
                # Unrecognized or extra parameter, just shift
                shift
                ;;
            esac
        done

        set_output_default

    else
        # We can have 1, 2, or 3 positional arguments
        # e.g. ./backup.sh <DIR> [<COMP>] [<OUT>]
        # If fewer than 1, then error

        if [[ $# -lt 1 ]]; then
            echo "Error: Missing directory argument." >&2
            exit 1
        fi

        BACKUP_DIR="$1"       # must exist

        if [[ $# -ge 2 ]]; then
            COMPRESSION="$2"   # optional
        fi
        if [[ $# -ge 3 ]]; then
            OUTPUT_FILE="$3"   # optional
        fi

        # If extra arguments are passed, warn the user in error.log and ignore them
        if [[ $# -gt 3 ]]; then
           echo "*** WARNING : extra positional arguments will be ignored." >&2
        fi

        # Apply default for output if not set
        set_output_default
    fi

    if [[ $DEBUG -eq 1 ]]; then
        debug
    fi

    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "Error: The directory '$BACKUP_DIR' does not exist or is not a directory." >&2
        exit 1
    fi

    case "$COMPRESSION" in
        none|gzip|bzip2|xz) ;; # valid
        *) echo "Warning: Invalid compression '$COMPRESSION'." >&2
        exit 2
    esac
}


parse_arguments "$@"
main

exit 0
