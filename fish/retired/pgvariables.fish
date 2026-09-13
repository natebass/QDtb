#!/usr/bin/env fish

# Check if common PostgreSQL environment variables are set
echo "Checking for common PostgreSQL environment variables:"

if test -z "$PGUSER"
  echo "PGUSER is not set."
else
  echo "PGUSER is set to: $PGUSER"
end

if test -z "$PGPASSWORD"
  echo "PGPASSWORD is not set."
else
  echo "PGPASSWORD is set to: $PGPASSWORD"
end

if test -z "$PGDATABASE"
  echo "PGDATABASE is not set."
else
  echo "PGDATABASE is set to: $PGDATABASE"
end

if test -z "$PGHOST"
  echo "PGHOST is not set."
else
  echo "PGHOST is set to: $PGHOST"
end

if test -z "$PGPORT"
  echo "PGPORT is not set."
else
  echo "PGPORT is set to: $PGPORT"
end

# Script to set the environment variables
echo
echo "Setting common PostgreSQL environment variables:"

set -l PGUSER (read -P "Enter PGUSER: ")
set -l PGPASSWORD (read -s -P "Enter PGPASSWORD: ")
echo
set -l PGDATABASE (read -P "Enter PGDATABASE: ")
set -l PGHOST (read -P "Enter PGHOST (optional, default is localhost): ")
if test -z "$PGHOST"
  set -l PGHOST localhost
end
set -l PGPORT (read -P "Enter PGPORT (optional, default is 5432): ")
if test -z "$PGPORT"
  set -l PGPORT 5432
end

# Set the variables to the environment
set -gx PGUSER $PGUSER
set -gx PGPASSWORD $PGPASSWORD
set -gx PGDATABASE $PGDATABASE
set -gx PGHOST $PGHOST
set -gx PGPORT $PGPORT

echo "PostgreSQL environment variables have been set."
