import os
try:
    import psutil
    import shutil
    import winreg
    import uvicorn
    import fastapi
    import ctypes, sys
    from pydantic import BaseModel
    import win32com.client
    import pythoncom
    import sys, getpass
except:
    os.system("pip install -r requirements.txt")

import psutil
import shutil
import winreg
import uvicorn
import fastapi
import ctypes, sys
from pydantic import BaseModel
import win32com.client
import pythoncom
import sys, getpass
import pathlib
from datetime import datetime

api = fastapi.FastAPI()

#apps which cannot be blocked manually
appBlacklist = [
    "explorer.exe"
]

keysBuffer = []

class RegRequest(BaseModel):
    values: list[str]

class BreakRequest(BaseModel):
    goingOnBreak: bool
    keys: list[str]

def checkForAdmin():
    if ctypes.windll.shell32.IsUserAnAdmin():
        return True
    try:
        params = " ".join([f'"{arg}"' for arg in sys.argv])
        ctypes.windll.shell32.ShellExecuteW(
            None, "runas", sys.executable, params, None, 1
        )
        return False
    except:
        return False

def formatErrorLog(logtype: str, log: str):
    return f"\n{datetime.today().strftime(r"%Y/%m/%d")} [{logtype}]: {log}"

@api.post("/initLog")
def initLog():
    global errorLog
    path = f"{pathlib.Path.home()}/Documents/DesktopOpal/ErrorLog.txt"
    errorLog = open(path, "a")

@api.post("/initRegCheck")
def initialPolicyCheck():
    location = winreg.HKEY_CURRENT_USER
    try:
        try:
            keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER", 0, winreg.KEY_SET_VALUE)
            winreg.CloseKey(keyPath)
        except OSError as e:
            soft = winreg.OpenKey(location, r"SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES", 0, winreg.KEY_WRITE)
            explorerPolicyLocation = winreg.CreateKey(soft, "EXPLORER")
            winreg.SetValueEx(explorerPolicyLocation, "DisallowRun", 0, winreg.REG_DWORD, 1)
            winreg.CreateKey(explorerPolicyLocation, "DisallowRun")
            winreg.CloseKey(explorerPolicyLocation)
            winreg.CloseKey(soft)
    except Exception as e:
        errorLog.write(formatErrorLog(logtype="CRITICAL ERROR", log=f"WINDOWS REGISTRY FAILED TO OPEN: {e}.")) #uh oh
        killFixedProcess(toKill="desktop_opal.exe", restart=False) #yeah no the app can't run without that - TODO: maybe add an alert here for user?
        os.system("tskill 'desktop_opal'")
        exit()

@api.post("/terminateBlockedApps")
def terminateBlockedApps():
    location = winreg.HKEY_CURRENT_USER #TODO: implement some return values for management in the dart script i.e. if termination fails we're fine but if blocking/unblocking fails then we're screwed
    try:
        keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DISALLOWRUN", 0, winreg.KEY_READ)
        blockedApps = []
        for key in range(1, winreg.QueryInfoKey(keyPath)[1]+1):
            blockedApps.append(winreg.QueryValueEx(keyPath, str(key))[0])
        print(blockedApps)
        winreg.CloseKey(keyPath)
        for process in psutil.process_iter(["name"]):
            if process.info["name"] in blockedApps:
                process.terminate()
                #os.system(f"Stop-Process -Name '{app[:-4]}'")
    except Exception as e:
        errorLog.write(formatErrorLog(logtype="WARNING", log=f"Apps failed to terminate due to {e}."))

def killFixedProcess(toKill : str, restart : bool):
    for process in psutil.process_iter(["name"]):
        if process.info["name"] == toKill:
            process.terminate()
            if restart:
                os.system(toKill)

@api.post("/toggleBreak")
def toggleBreak(params: BreakRequest):
    global keysBuffer
    if params.goingOnBreak: #if we are going on break
        keysBuffer = params.keys #save existing keys
        deleteKeys(params=RegRequest(values=params.keys))
    else:
        createAppValues(params=RegRequest(values=keysBuffer))

@api.post("/createRegKeys")
def createAppValues(params: RegRequest):
    valuesToCreate = params.values
    location = winreg.HKEY_CURRENT_USER
    try:
        keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER", 0, winreg.KEY_ALL_ACCESS)
    except Exception as e:
        errorLog.write(formatErrorLog(logtype="ERROR", log=f"Winreg path failed to open due to {e}."))
        return -1
    try:
        winreg.SetValueEx(keyPath, "DisallowRun", 0, winreg.REG_DWORD, 1)
        keyPath = winreg.CreateKey(keyPath, "DisallowRun")
        numberOfValues = winreg.QueryInfoKey(keyPath)[1]
        valuesAdded = 0
        preExistingValues = [
            winreg.EnumValue(keyPath, i)[1]
            for i in range(0, numberOfValues)
        ]
        toRemove = []
        for app in valuesToCreate:
            if app in preExistingValues:
                toRemove.append(app)
        for app in toRemove:
            valuesToCreate.remove(app)
        for remainingApp in valuesToCreate:
            winreg.SetValueEx(keyPath, str(numberOfValues+valuesAdded+1), 0, winreg.REG_SZ, str(remainingApp))
            try:
                winreg.QueryValueEx(keyPath, str(numberOfValues+valuesAdded+1))
            except Exception as e:
                print(f"Addition of {remainingApp} failed with exception {e}")
            valuesAdded += 1
        terminateBlockedApps()
        #try:
        #    killFixedProcess(toKill="explorer", restart=True)
        #except:
        #    os.system("Stop-Process -Name 'explorer'")
        winreg.CloseKey(keyPath)
        return 0
    except Exception as e:
        winreg.CloseKey(keyPath)
        return -1

@api.post("/deleteRegKeys")
def deleteKeys(params: RegRequest):
    initialPolicyCheck()
    valuesToDelete = params.values
    location = winreg.HKEY_CURRENT_USER
    try:
        keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DisallowRun", 0, winreg.KEY_ALL_ACCESS)
    except Exception as e:
        errorLog.write(formatErrorLog(logtype="CRITICAL ERROR", log=f"FAILED TO UNBLOCK APPS DUE TO {e}. CONSULT THE UH OH BUTTON."))
        wipeEntries()
        killFixedProcess(toKill="desktop_opal.exe", restart=False)
        exit()
    numberOfValues = winreg.QueryInfoKey(keyPath)[1]
    preExistingValues = [
        winreg.EnumValue(keyPath, i)[1]
        for i in range(0, numberOfValues)
    ]
    for value in valuesToDelete:
        if value in preExistingValues:
            removedPosition = preExistingValues.index(value) + 1
            #preExistingValues.remove(value)
            winreg.DeleteValue(keyPath, str(removedPosition))
            decreaseFurtherValues(startingValue=removedPosition, numberOfValues=numberOfValues, keyPath=keyPath)
            numberOfValues -= 1
            preExistingValues.remove(value)
    winreg.CloseKey(keyPath)

def decreaseFurtherValues(startingValue : int, numberOfValues : int, keyPath : winreg.HKEYType):
    for upperValue in range(startingValue+1, numberOfValues+1):
        upperValueName = winreg.QueryValueEx(keyPath, str(upperValue))[0]
        winreg.DeleteValue(keyPath, str(upperValue))
        winreg.SetValueEx(keyPath, str(upperValue-1), 0, winreg.REG_SZ, str(upperValueName))

@api.post("/wipeEntries")
def wipeEntries():
    location = winreg.HKEY_CURRENT_USER
    try:
        keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DisallowRun", 0, winreg.KEY_ALL_ACCESS)
        try:
            numberOfValues = winreg.QueryInfoKey(keyPath)[1]
            for key in range(1, numberOfValues):
                winreg.DeleteKey(keyPath, str(key))
            #killFixedProcess(toKill="explorer.exe", restart=True)
            winreg.CloseKey(keyPath)
            return 0
        except:
            winreg.CloseKey(keyPath)
            return -1
    except Exception as e:
        errorLog.write(formatErrorLog(logtype="OH NO", log=f"THE UH OH BUTTON HAS FAILED, PLEASE CONSULT THE MANUAL FIX FOR WIPING ENTRIES AND REPORT TO THE GITHUB REPO. {e}"))


@api.get("/checkForDesktopExecutables")
def getAutoExecutables():
    potentialPaths = [
        os.path.join(os.path.join(os.environ["USERPROFILE"]), "OneDrive\\Desktop"),
        os.path.join(os.path.join(os.environ["USERPROFILE"]), "Desktop"),
        "C:\\Users\\Public\\Desktop"
    ]
    combinedExecutables = []

    for path in potentialPaths:
        combinedExecutables += getExecutables(files=createList(path=path), path=path) #TODO: continue here

    if len(combinedExecutables) == 0:
        errorLog.write(formatErrorLog(logtype="WARNING", log="No executables located at common desktop paths."))
    return combinedExecutables

def getExecutables(files: list, path: str):
    pythoncom.CoInitialize()
    shell = win32com.client.Dispatch("WScript.Shell")
    executables = []
    for file in files:
        fileName = os.fsdecode(file)
        if fileName.endswith(".lnk"):
            shortcut = shell.createShortcut(os.path.join(path, fileName))
            if ".exe" in shortcut.targetPath:
                splitPath = shortcut.targetPath.split("\\")
                executables.append(splitPath[len(splitPath)-1])
    return executables

def createList(path: str):
    try:
        result = []
        for file in os.listdir(os.fsencode(path)):
            result.append(file)
        return result
    except:
        return []

#potentially use in future
@api.get("/isInstalled")
def checkForInstall(app: str):
    install = shutil.which(app)
    if install != None:
        return True
    else:
        return False

@api.get("/test")
def test(string : str):
    print(string)

def main():
    pass

if __name__ == "__main__":
    if not checkForAdmin():
        sys.exit(0)
    main()

if not checkForAdmin():
    sys.exit(0)
uvicorn.run(api, host="127.0.0.1", port=8000)