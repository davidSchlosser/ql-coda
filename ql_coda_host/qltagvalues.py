#!/usr/bin/env python3

import json
import os
import sys
sys.path.append('/home/david/quodlibet')
from quodlibet.main import main
import quodlibet
#quodlibet.init()
from quodlibet.library import SongLibrarian

library_path = os.path.join(quodlibet.get_user_dir(), "songs")
library = quodlibet.library.init(library_path)

tag = sys.argv[1]
ret = sorted({value for value in library.tag_values(tag)})
#for value in ret:
#    print(value)
payload = json.JSONEncoder().encode({"tag": tag, "values": ret})
print(payload)
#print('{"tag":"%s", "values":%s}' % ( tag, ret))



#!/usr/bin/env python2

import os
import re
import quodlibet
from quodlibet import library

quodlibet.init()
lib = library.init(os.path.join(quodlibet.get_user_dir(), "songs"))