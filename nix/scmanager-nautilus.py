"""Host-side adapter for the vendor Nautilus extension.

Only uses the standard library: Nautilus supplies its own Python/GObject runtime.
HTTP requests run through the original helper inside SCManager's FHS environment.
"""

import json
import locale
from pathlib import Path
import subprocess
import zipfile


def Get_json():
    language = (locale.getlocale()[0] or "en")[:2]
    local_file = (
        Path.home() / ".local/share/SCMiddleware/languages" / f"language.{language}.json"
    )
    try:
        return json.loads(local_file.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        with zipfile.ZipFile("@middleware@/share/SCMiddleware/tokmgr.bin") as archive:
            try:
                data = archive.read(f"languages/language.{language}.json")
            except KeyError:
                data = archive.read("languages/language.en.json")
            return json.loads(data)


def show_error(message):
    subprocess.run(["@zenity@", "--error", f"--text={message}"], check=False)


def send_request(params, sid):
    subprocess.run(
        ["@scmanager@", "--nautilus-request", str(sid), json.dumps(params)],
        check=True,
    )
