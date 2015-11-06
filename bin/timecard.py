#!/usr/bin/python
#
# Extract printable records from Timesheet android app backups
#

import sqlite3
import dateutil.parser
import datetime
import sys

# CREATE TABLE TIMES ( clientName text, projectName text, project text,
# amountPerhour FLOAT, date1 text, date2 text, breaks integer, notes text, amount
# FLOAT, methodId integer, status integer);

totals = {}

def get_dollar(val):
    return "%.2f" % ((val.total_seconds() / 60 / 60) * 150.1)


with sqlite3.connect(sys.argv[1]) as db:
    cur = db.cursor()
    cur.execute("SELECT clientName, projectName, date1, date2 FROM TIMES order by date1 asc")

    rows = cur.fetchall()

    for row in rows:
        row = list(row)
        row[1] = row[1].upper()
        diff = dateutil.parser.parse(row[3]) - dateutil.parser.parse(row[2])
        print ', '.join(map(str, (row[3].split()[0], diff, row[0], row[1], get_dollar(diff))))

        if row[0] not in totals:
            totals[row[0]] = {}
        if row[1] not in totals[row[0]]:
            totals[row[0]][row[1]] = datetime.timedelta()
        totals[row[0]][row[1]] += diff

for c in totals:
    for p in totals[c]:
        print ', '.join((c, p, str(totals[c][p])))
print repr(totals)
