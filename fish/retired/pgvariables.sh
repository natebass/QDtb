#!/usr/bin/env bash

# Check if common PostgreSQL environment variables are set
echo "Checking for common PostgreSQL environment variables:"

if [[ -z "$PGUSER" ]]; then
  echo "PGUSER is not set."
else
  echo "PGUSER is set to: $PGUSER"
fi

if [[ -z "$PGPASSWORD" ]]; then
  echo "PGPASSWORD is not set."
else
  echo "PGPASSWORD is set to: $PGPASSWORD" 
fi

if [[ -z "$PGDATABASE" ]]; then
  echo "PGDATABASE is not set."
else
  echo "PGDATABASE is set to: $PGDATABASE"
fi

if [[ -z "$PGHOST" ]]; then
  echo "PGHOST is not set."
else
  echo "PGHOST is set to: $PGHOST"
fi

if [[ -z "$PGPORT" ]]; then
  echo "PGPORT is not set."
else
  echo "PGPORT is set to: $PGPORT"
fi

# Script to set the environment variables
echo
echo "Setting common PostgreSQL environment variables:"

read -p "Enter PGUSER: " PGUSER
read -s -p "Enter PGPASSWORD: " PGPASSWORD # Read password without echoing
echo
read -p "Enter PGDATABASE: " PGDATABASE
read -p "Enter PGHOST (optional, default is localhost): " PGHOST
if [[ -z "$PGHOST" ]]; then
  PGHOST="localhost"
fi
read -p "Enter PGPORT (optional, default is 5432): " PGPORT
if [[ -z "$PGPORT" ]]; then
  PGPORT="5432"
fi

# Export the variables to the environment
export PGUSER
export PGPASSWORD
export PGDATABASE
export PGHOST
export PGPORT

echo "PostgreSQL environment variables have been set."

