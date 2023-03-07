# Resynchronization of timstamps with time-translation table
# Values between two time points are interpolated linerary
# 
# Format time-translation table:
#   00:01:34,000 --> 00:01:35,000       Converts 1:34 to 1:35
#   00:02:34,000 --> 00:02:35,000       Converts 2:34 to 2:35
#
# Format of the file to resynchronize:
#   00:01:31,020 --> 00:01:32,080
#   00:01:33,700 --> 00:01:35,730

import datetime
import argparse
import re
from datetime import timedelta
import codecs


def get_date_from(string_value):
    if (match := re.match(r'^(.*?)-->', string_value)):
        date_str = match.group(1).strip()
        return datetime.datetime.strptime(date_str, '%H:%M:%S,%f')


def get_date_to(string_value):
    if (match := re.search(r'-->(.*),?.*$', string_value)):
        date_str = match.group(1).strip()
        return datetime.datetime.strptime(date_str, '%H:%M:%S,%f')

def convert_time(time_to_convert: datetime, time_table, checkIndexInTimetable: bool):
    global _index_time_table
    global _verbose

    # If applicable move to the next index in the translation-table
    if checkIndexInTimetable:
        while time_to_convert > time_table[_index_time_table + 1]['From']:
            if _index_time_table + 1 >= len(time_table) - 1:
                print("ERROR: Translation table incomplete, time " + str(time_to_convert) + " out of bound (please add a row)")
                exit()    
            else:
                _index_time_table += 1
            if _verbose:
                print("--> increased index in time translation table to position [" + str(_index_time_table) + "] for time: " + str(time_to_convert))

    # Interpolation: A'B' = AB / AC * A'C'
    ab = time_to_convert - time_table[_index_time_table]['From']
    ac = time_table[_index_time_table + 1]['From'] - time_table[_index_time_table]['From']
    a2c2 = time_table[_index_time_table + 1]['To'] - time_table[_index_time_table]['To']
    a2b2 = ab.total_seconds() / ac.total_seconds() * a2c2.total_seconds()

    convertedTime = time_table[_index_time_table]['To'] + timedelta(seconds = a2b2)
    return convertedTime

# Main program

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process and resynchronize time stamps according to a time-translation table')
    parser.add_argument('timetable_file', help='Time translation table')
    parser.add_argument('input_file', help='File containing the timestamps to resynchronize')
    parser.add_argument('output_file', help='Output file')
    parser.add_argument('-v', '--verbose', action="store_true", help='Prinout verbose')

    args = parser.parse_args()

    _verbose = args.verbose
    if _verbose:
        print("-- Option: Prinout verbose")

    # Read time translation file
    time_table = []
    with open(args.timetable_file, 'r') as f:
        for line in f:
            if '-->' in line:
                from_date = get_date_from(line)
                to_date = get_date_to(line)
                if from_date and to_date:
                    time_table.append({'From': from_date, 'To': to_date})


    # Update timestamps and re-write it to the console
    _index_time_table = 0
    inputFile = codecs.open(args.input_file, 'r', 'cp1251')
    outputFile = codecs.open(args.output_file, 'w', 'cp1251')

    while (read_line := inputFile.readline()):
        
        if '-->' in read_line:
            date1 = get_date_from(read_line)
            newBeginTimeSpan = convert_time(date1, time_table, True)

            date2 = get_date_to(read_line)
            newEndTimespan = convert_time(date2, time_table, False)

            outputFile.write(newBeginTimeSpan.strftime('%H:%M:%S,%f')[:-3] + " --> " + newEndTimespan.strftime('%H:%M:%S,%f')[:-3])
            outputFile.write('\r\n')
        else:
            outputFile.write(read_line)
            pass  # do nothing with the line
        
    inputFile.close()
    outputFile.close()


    
