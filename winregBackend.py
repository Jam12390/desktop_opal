import psutil
import winreg
import os
import uvicorn
import fastapi
import ctypes, sys
from pydantic import BaseModel
import win32com.client

import pythoncom
import sys, getpass

api = fastapi.FastAPI()

#apps which cannot be blocked manually
appBlacklist = [
    "explorer.exe"
]

class RegRequest(BaseModel):
    values: list[str]

class BreakRequest(BaseModel):
    value: int

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

@api.post("/initRegCheck")
def initialPolicyCheck():
    location = winreg.HKEY_CURRENT_USER
    try:
        keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER", 0, winreg.KEY_SET_VALUE)
        winreg.CloseKey(keyPath)
    except OSError as e:
        print(e)
        soft = winreg.OpenKey(location, r"SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES", 0, winreg.KEY_WRITE)
        explorerPolicyLocation = winreg.CreateKey(soft, "EXPLORER")
        winreg.SetValueEx(explorerPolicyLocation, "DisallowRun", 0, winreg.REG_DWORD, 1)
        winreg.CreateKey(explorerPolicyLocation, "DisallowRun")
        winreg.CloseKey(explorerPolicyLocation)
        winreg.CloseKey(soft)

@api.post("/terminateBlockedApps")
def terminateBlockedApps(blockedApps : list):
    openApps = psutil.process_iter()
    for process in openApps:
        if process.name() in blockedApps:
            process.terminate()

@api.post("/toggleBreak")
def toggleBreak(params: BreakRequest):
    location = winreg.HKEY_CURRENT_USER
    keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER", 0, winreg.KEY_WRITE)
    winreg.SetValueEx(keyPath, "DisallowRun", 0, winreg.REG_DWORD, params.value)
    os.system("gpupdate /target:user")

def createKeys(valuesToCreate : list): #this is redundant - please remove after program finish
    try:
        location = winreg.HKEY_CURRENT_USER
        keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DISALLOWRUN", 0, winreg.KEY_ALL_ACCESS)
        numberOfValues = winreg.QueryInfoKey(keyPath)[1] #this usually should be - 1 since there is always a default blank value, however since we are using this for a for loop its just easier to leave it like this
        valuesAdded = 0
        for app in valuesToCreate: #cycle through each app to be blocked
            appValueExists = False
            for value in range(1, numberOfValues): #and check each one against preexisting values (no need to make duplicates)
                if winreg.QueryValueEx(keyPath, str(value))[0] == app: #if the entry already exists
                    print(f"Found entry {app} at entry no.{value}")
                    appValueExists = True #no need to make another value
            if not appValueExists: #if an entry doesnt exist for this app
                print(f"Attempting to create entry for {app} at index {numberOfValues+valuesAdded}")
                winreg.SetValueEx(keyPath, str(numberOfValues+valuesAdded), 0, winreg.REG_SZ, str(app)) #make one with the next available pointer
                valuesAdded += 1 #increment the pointer to be used for the next value
                try:
                    print(winreg.QueryValueEx(keyPath, str(numberOfValues+valuesAdded)))
                    print(f"Successfully created entry for {app}")
                except Exception as e:
                    print(f"WARNING: Entry for {app} failed with exception {e}")
    except Exception as e:
        print(e)
        input("Press enter to exit.")

@api.post("/createRegKeys")
def createAppValues(params: RegRequest):
    valuesToCreate = params.values
    try:
        location = winreg.HKEY_CURRENT_USER
        keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER", 0, winreg.KEY_ALL_ACCESS)
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
        #for process in psutil.process_iter():
        #    if process.name() == "explorer.exe" and not debug:
        #        process.kill()
        os.system("gpupdate /target:user")
        winreg.CloseKey(keyPath)
        return 0
    except Exception as e:
        print(e)
        return -1

@api.post("/deleteRegKeys")
def deleteKeys(params: RegRequest):
    valuesToDelete = params.values
    location = winreg.HKEY_CURRENT_USER
    keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DisallowRun", 0, winreg.KEY_ALL_ACCESS)
    numberOfValues = winreg.QueryInfoKey(keyPath)[1]
    preExistingValues = [
        winreg.EnumValue(keyPath, i)[1]
        for i in range(0, numberOfValues)
    ]
    toRemove = []
    for value in valuesToDelete:
        if value in preExistingValues:
            removedPosition = preExistingValues.index(value) + 1
            #preExistingValues.remove(value)
            winreg.DeleteValue(keyPath, str(removedPosition))
            decreaseFurtherValues(startingValue=removedPosition, numberOfValues=numberOfValues, keyPath=keyPath)
            numberOfValues -= 1
            preExistingValues.remove(value)
    #for value in range(1, numberOfValues):
    #    try:
    #        if winreg.QueryValueEx(keyPath, str(value))[1] in valuesToDelete:
    #            winreg.DeleteValue(keyPath, str(value))
    #            decreaseFurtherValues(startingValue=value, numberOfValues=numberOfValues, keyPath=keyPath)
    #            numberOfValues -= 1
    #    except Exception as e:
    #        print(e)

def decreaseFurtherValues(startingValue : int, numberOfValues : int, keyPath : winreg.HKEYType):
    for upperValue in range(startingValue+1, numberOfValues+1):
        upperValueName = winreg.QueryValueEx(keyPath, str(upperValue))[0]
        winreg.DeleteValue(keyPath, str(upperValue))
        winreg.SetValueEx(keyPath, str(upperValue-1), 0, winreg.REG_SZ, str(upperValueName))

@api.post("/wipeEntries")
def wipeEntries():
    try:
        location = winreg.HKEY_CURRENT_USER
        keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DisallowRun", 0, winreg.KEY_ALL_ACCESS)
        numberOfValues = winreg.QueryInfoKey(keyPath)[1]
        for key in range(1, numberOfValues):
            winreg.DeleteKey(keyPath, str(key))
        return 0
    except:
        return -1


@api.get("/checkForDesktopExecutables")
def getAutoExecutables():
    desktopPath = os.path.join(os.path.join(os.environ["USERPROFILE"]), "OneDrive\\Desktop")
    publicDesktopPath = "C:\\Users\\Public\\Desktop"

    print("User:", getpass.getuser())
    print("CWD:", os.getcwd())
    print("Desktop path:", desktopPath)

    publicExecutables = getExecutables(files=createList(path=publicDesktopPath), path=publicDesktopPath)
    otherExecutables = getExecutables(files=createList(path=desktopPath), path=desktopPath)
    combinedExecutables = []

    for i in publicExecutables:
        combinedExecutables.append(i)
    for i in otherExecutables:
        if i not in combinedExecutables:
            combinedExecutables.append(i)
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
    result = []
    for file in os.listdir(os.fsencode(path)):
        result.append(file)
    return result

@api.get("/test")
def test(a : int, b : int):
    return {"result": a+b}

#def main():
    #deleteKeys(valuesToDelete=["chrome.exe"])
#    uvicorn.run(api, host="127.0.0.1", port=8000)
    #initialPolicyCheck()

if __name__ == "__main__":
    if not checkForAdmin():
        sys.exit(0)

if not checkForAdmin():
        sys.exit(0)
uvicorn.run(api, host="127.0.0.1", port=8000)

#TODO: add app detection on first open + in blocksettings add a floatingactionbutton for refreshing apps or to manually add an app's executable (could look if dart has its own version of regex for detecting .exe at the end)