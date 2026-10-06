#!/usr/bin/env python3
import requests
import subprocess 
import os
import zipfile
import locale
import json

#get system language
def Get_json():
	lang, _ = locale.getlocale()
	lang = lang[:2]
	try:
		#try to open downloaded language file
		f = open(os.path.expanduser('~/.local/share/SCMiddleware/languages/language.' + lang + '.json'))
		jsonLang = json.load(f)
	except:
		#unzip tokmgr.bin and try to read language file
		if os.path.exists('/usr/lib/SCMiddleware') :
			archive = zipfile.ZipFile("/usr/share/SCMiddleware/tokmgr.bin", 'r')
		else:
			archive = zipfile.ZipFile("/usr/share/in_p11/tokmgr.bin", 'r')
		try:
			langData = archive.read('languages/language.'+ lang +'.json')
		except:
			#default English language if we didn't find the system language
			langData = archive.read('languages/language.en.json')
		langData = langData.decode("utf-8")
		jsonLang = json.loads(langData)
	return jsonLang

def show_error(message):
	subprocess.run(["zenity", "--error", f"--text={message}"])

def send_request(params, sid):
	with open(os.path.expanduser('~/.idoss.conf')) as f:
		for line in f:
			if sid in line: # Search line with corresponding sid
				line = line.strip() # the line should look like ManagerPort-sid = port
				index = line.find('=') 
				port = int(line[index + 1:]) # get whats writen after =
				r = requests.get("http://127.0.0.1:" + str(port) + "/dyn/cryptoshell_InitFromExplorer", params = params, timeout = 2)
