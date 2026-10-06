#!/usr/bin/env python3
from gi.repository import Nautilus, GObject
import subprocess 
import os, sys

if os.path.exists('/usr/lib/SCMiddleware') :
	sys.path.append('/usr/share/SCMiddleware')
else :
	sys.path.append('/usr/share/in_p11')

import crypto_common

jsonLang = crypto_common.Get_json()

error_msg = jsonLang["cryptoshellDLL"]["general_error_message"]
sign_label = jsonLang["cryptoshell"]["action"]["do_sign"]
encrypt_label =  jsonLang["cryptoshell"]["action"]["do_encrypt"]
signEncrypt_label = jsonLang["cryptoshell"]["action"]["do_sign_encrypt"]
open_label = jsonLang["cryptoshellDLL"]["open"]

#extention list where the open menu need to appear
extentionFileListToOpen = [
	"pdf",
	"p7",
	"p7s",
	"p7m",
	"asice",
	"asic",
	"asics",
]

class CryptoshellExtension(GObject.GObject, Nautilus.MenuProvider):
	def __init__(self):
		super().__init__()
		print("Initialized CryptoshellExtension")

	def menu_activate_cb(self, menu, files, action):
		listPath = ""
		for file in files:
			listPath += file.get_location().get_path()
			listPath += ","
		params = {
			"action": action,
			"files": listPath[:-1],
		} 
		#Check if manager is running otherwise send error message via zenity
		try:
			pid = int(subprocess.check_output(["pidof", "SCManager"]).decode().strip())
			sid = str(os.getsid(pid))
		except:
			crypto_common.show_error(error_msg)
			return
		try:
			crypto_common.send_request(params, sid)
		except Exception as error:
			crypto_common.show_error(error) #should never happen
			return

	def get_file_items(self, *args): #function that add new menu when right click is done on file/s
		files = args[-1]
		if not files:
			return []

		#Fabricate contextual menu
		sign = Nautilus.MenuItem(
			name = "CryptoShellExtension::Sign",
			label = sign_label,
		)
		encrypt = Nautilus.MenuItem(
			name = "CryptoShellExtension::Encrypt",
			label = encrypt_label,
		)
		signEncrypt = Nautilus.MenuItem(
			name = "CryptoShellExtension::SignEncrypt",
			label = signEncrypt_label,
		)
		open_signEncrypt = Nautilus.MenuItem(
			name = "CryptoShellExtension::Open",
			label = open_label,
		)
		#connect to the function when it will be clicked
		sign.connect("activate", self.menu_activate_cb, files, "SIGN")
		encrypt.connect("activate", self.menu_activate_cb, files, "ENCRYPT")
		signEncrypt.connect("activate", self.menu_activate_cb, files, "SIGNENCRYPT")
		open_signEncrypt.connect("activate", self.menu_activate_cb, files, "OPEN")

		#return the list of menu item depending on the extension of the file
		for file in files:
			filePath = file.get_location().get_path()
			fileExtension = ""
			for c in reversed(filePath):
				if c == ".":
					break
				fileExtension += c
			fileExtension = fileExtension[::-1]
			if fileExtension in extentionFileListToOpen:
				return [
					sign,
					encrypt,
					signEncrypt,
					open_signEncrypt
				]
				
		return [
			sign,
			encrypt,
			signEncrypt
		]

	# Even though we're not using background items, Nautilus will generate
	# a warning if the method isn't present
	def get_background_items(self, *args):
		return []