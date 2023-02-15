#!/usr/bin/env python3

'''
pipe output from qltagvalues.sh into this script to tidy the output and pruduce a json dictionary of tag names with their values
'''

import fileinput
import json
import re

tidiedTags = {}
roles = {}

for line in fileinput.input():
    #
    # a line might look like 'artist=David Oistrakh, Mstislav Rostropovich, Sviatoslav Richter, Herbert von Karajan, Berlin Philarmonic Orchestra'
    #
    tag = line.rstrip().split('=')[0]
    values = line.split('=')[1].split(',')
    #
    #strip leading & trailing whitespace, and empty tag values
    values = list(map(lambda x: x.lstrip().rstrip(), values))
    values = [x for x in values if x != '']
    #
    # extract roles from performers eg performers=David Oistrakh (Violin), Mstislav Rostropovich (Cello), Sviatoslav Richter (Piano), Herbert von Karajan;Berlin Philharmonic Orchestra
    # apart from roles, performers aren't needed
    if tag == 'performers':
        roles = re.findall('\((.*?)\)', ','.join(values))
        values = roles
        tag = 'roles'
    #
    # add new set enrty for the tag containing the tidied values, or update existing set
    if values:
        if not tag in tidiedTags.keys() :
            tidiedTags[tag] = set(values)
        else:
            tidiedTags[tag].update(values)
#
# json doesn't like sets
tidiedTags = {k: list(v) for k, v in tidiedTags.items()}
#
print(json.JSONEncoder().encode(tidiedTags))

