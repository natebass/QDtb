#!/usr/local/bin/python3
from __future__ import print_function
import httplib2
import os
from apiclient import discovery
import oauth2client
from oauth2client import client
from oauth2client import tools
import datetime
import subprocess
import csv
import io
from os.path import expanduser
import json

### Sync Todos With Calendar ###
# Todo: Check if event already exists before adding a duplicate
# Reminder: Todos -> Reminders

# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/calendar-python-quickstart.json
SCOPES = 'https://www.googleapis.com/auth/calendar'
CLIENT_SECRET_FILE = 'client_secret.json'
APPLICATION_NAME = 'Google Calendar API Python Quickstart'

# This is for the oauth flow
try:
    import argparse

    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None


def get_credentials():
    """Gets valid user credentials from storage.

    If nothing has been stored, or if the stored credentials are invalid,
    the OAuth2 flow is completed to obtain the new credentials.

    Returns:
        Credentials, the obtained credential.
    """
    home_dir = os.path.expanduser('~')
    credential_dir = os.path.join(home_dir, '.credentials')
    if not os.path.exists(credential_dir):
        os.makedirs(credential_dir)
    credential_path = os.path.join(credential_dir,
                                   'calendar-python-quickstart.json')

    store = oauth2client.file.Storage(credential_path)
    credentials = store.get()
    if not credentials or credentials.invalid:
        flow = client.flow_from_clientsecrets(CLIENT_SECRET_FILE, SCOPES)
        flow.user_agent = APPLICATION_NAME
        if flags:
            credentials = tools.run_flow(flow, store, flags)
        else:  # Needed only for compatibility with Python 2.6
            credentials = tools.run(flow, store)
        print('Storing credentials to ' + credential_path)
    return credentials


def parse_as_csv(todos):
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['Subject', 'Start Date', 'All Day Event', 'Description'])
    for todo in todos:
        description = todo.file + ': ' + todo.line
        writer.writerow([
            todo.message, datetime.datetime.now().strftime('%m/%d/%y'), 'True', description])
    return output.getvalue()


def getCalendarService():
    credentials = get_credentials()
    http = credentials.authorize(httplib2.Http())
    return discovery.build('calendar', 'v3', http=http)


def grep_tracked_files_for_todos():
    class Todo:
        def __init__(self, file, message, line):
            self.file = file
            self.message = message
            self.line = line

    shell_output = subprocess.check_output('git ls-files | xargs grep -Hin "^\s*# todo"', shell=True).decode(
        "utf-8").split('\n')
    # Last line is blank
    del shell_output[-1]

    todos = []
    for line in shell_output:
        segs = line.split(':')
        file = segs[0]
        line = segs[1]
        # Todo: Get all values after segs[3] in case there are more colons in the string, possibly splat?
        message = segs[3].strip()
        todos.append(Todo(file, message, line))
    return todos


def checkIfUnique(todos, service):
    now = datetime.datetime.utcnow().isoformat() + 'Z'  # 'Z' indicates UTC time
    print('Getting the upcoming 100 events')
    eventsResult = service.events().list(
        calendarId='primary', timeMin=now, maxResults=100, singleEvents=True,
        orderBy='startTime').execute()
    events = eventsResult.get('items', [])
    # Delete from todos if it has already been uploaded.
    for e in events:
        summary = e['summary']
        for todo in todos:
            if summary in todo.message:
                todos.remove(todo)


def main():
    service = getCalendarService()
    todos = grep_tracked_files_for_todos()
    checkIfUnique(todos, service)
    event = parse_as_csv(todos)
    # open(expanduser('~/Desktop/example.csv'), 'a').write(event)
    service.events().import_(calendarId='primary', body=event).execute()


if __name__ == '__main__':
    main()
