#!/bin/bash
#
/home/david/quodlibet/quodlibet.py --print-query='' --with-pattern='artist=<artist>
genre=<genre>
composer=<composer>
mood=<mood>
style=<style>
performers=<~performers>'  | sort | uniq | ./tags2tidyJson.py
exit

#!/bin/bash
#
/home/david/quodlibet/quodlibet.py --print-query='' --with-pattern='artist=<artist>
genre=<genre>
composer=<composer>
mood=<mood>
style=<style>'  | sort | uniq | ./tags2tidyJson.py
exit
