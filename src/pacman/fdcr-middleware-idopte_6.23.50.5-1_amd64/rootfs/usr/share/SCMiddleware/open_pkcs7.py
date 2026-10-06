#!/usr/bin/python3
import subprocess 
import os
import sys
from pathlib import Path

if os.path.exists('/usr/lib/SCMiddleware') :
	sys.path.append('/usr/share/SCMiddleware')
else :
	sys.path.append('/usr/share/in_p11')

import crypto_common

jsonLang = crypto_common.Get_json()
error_msg = jsonLang["cryptoshellDLL"]["general_error_message"]

if len(sys.argv) < 2:
	sys.exit(1)

file = Path(sys.argv[1]).resolve()
paths = []
paths.append(str(file))
params = {
	"action": "OPEN",
	"files": paths,
}
try:
	pid = int(subprocess.check_output(["pidof", "SCManager"]).decode().strip())
	sid = str(os.getsid(pid))
except:
	crypto_common.show_error(error_msg)
	sys.exit(1)
try:
	crypto_common.send_request(params, sid)
except Exception as error:
	crypto_common.show_error(error) #should never happen
	sys.exit(1)

