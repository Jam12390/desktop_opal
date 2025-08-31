import os
import win32com.client

shell = win32com.client.Dispatch("WScript.Shell")
desktopPath = os.path.join(os.path.join(os.environ["USERPROFILE"]), "OneDrive\\Desktop")
publicDesktopPath = "C:\\Users\\Public\\Desktop"

foundShortcuts = []

def getExecutables(files: list, path: str):
    executables = []
    for file in files:
        fileName = os.fsdecode(file)
        if fileName.endswith(".lnk"):
            shortcut = shell.createShortcut(path+f"/{fileName}")
            if ".exe" in shortcut.targetPath:
                splitPath = shortcut.targetPath.split("\\")
                executables.append(splitPath[len(splitPath)-1])
    return executables

def createList(path: str):
    result = []
    for file in os.listdir(os.fsencode(path)):
        result.append(file)
    return result

publicExecutables = getExecutables(files=createList(path=publicDesktopPath), path=publicDesktopPath)
otherExecutables = getExecutables(files=createList(path=desktopPath), path=desktopPath)
combinedExecutables = []

for i in publicExecutables:
    combinedExecutables.append(i)
for i in otherExecutables:
    if i not in combinedExecutables:
        combinedExecutables.append(i)

print(combinedExecutables)

"""
Found methods of detecting executables:
Scan desktop folder for shortcuts -> get the target of those shortcuts
    Shortcut formats:
        .split("\\")[len(list)]
        some launchers use path/launcher.exe" -from-desktop (could use .split on .exe and readd it?)
        e.g. .split("/")[len(list)].split(".exe")[0] + ".exe"
    Block common apps e.g. steam.exe & UbisoftConnect.exe
    Scan HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall for executables
"""