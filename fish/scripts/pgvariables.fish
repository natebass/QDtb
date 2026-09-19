#!/usr/bin/env fish

# 1. Inspect existing environment variables
echo "Checking for common PostgreSQL environment variables:"

if test -z "$PGUSER"
    echo "  PGUSER:     [Not Set]"
else
    echo "  PGUSER:     $PGUSER"
end

if test -z "$PGPASSWORD"
    echo "  PGPASSWORD: [Not Set]"
else
    echo "  PGPASSWORD: [Set - Hidden]"
end

if test -z "$PGDATABASE"
    echo "  PGDATABASE: [Not Set]"
else
    echo "  PGDATABASE: $PGDATABASE"
end

if test -z "$PGHOST"
    echo "  PGHOST:     [Not Set]"
else
    echo "  PGHOST:     $PGHOST"
end

if test -z "$PGPORT"
    echo "  PGPORT:     [Not Set]"
else
    echo "  PGPORT:     $PGPORT"
end

echo

# 2. Interactive prompt for new values
echo "Setting common PostgreSQL environment variables:"

read -P "Enter PGUSER: " input_user
read -s -P "Enter PGPASSWORD: " input_password
echo
read -P "Enter PGDATABASE: " input_db
read -P "Enter PGHOST [localhost]: " input_host
read -P "Enter PGPORT [5432]: " input_port

# 3. Apply defaults if optional fields were left blank
if test -z "$input_host"
    set input_host localhost
end

if test -z "$input_port"
    set input_port 5432
end

# 4. Export globally to the current shell environment
set -gx PGUSER $input_user
set -gx PGPASSWORD $input_password
set -gx PGDATABASE $input_db
set -gx PGHOST $input_host
set -gx PGPORT $input_port

echo "PostgreSQL environment variables updated for current session."
