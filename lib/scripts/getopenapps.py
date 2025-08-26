import psutil
import winreg
import subprocess

def getBlockedAppState(blockedApps : list):
    blockedAppsState = {app: False for app in blockedApps}
    openApps = psutil.process_iter()
    for process in openApps:
        if process.name() in blockedApps:
            blockedAppsState[process.name] = True
            process.terminate()
    return blockedAppsState

def createKeys(valuesToCreate : list): #
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

def createAppValues(valuesToCreate : list, debug : bool):
    #try:
    location = winreg.HKEY_CURRENT_USER
    keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DISALLOWRUN", 0, winreg.KEY_ALL_ACCESS)
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
    for process in psutil.process_iter():
        if process.name() == "explorer.exe" and not debug:
            process.kill()
    #except Exception as e:
    #    input(f"Process failed with exception {e}, press enter to exit.")
    winreg.CloseKey(keyPath)

def deleteKeys(valuesToDelete : list):
    location = winreg.HKEY_CURRENT_USER
    keyPath = winreg.OpenKeyEx(location, "SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DISALLOWRUN", 0, winreg.KEY_ALL_ACCESS)
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

def main():
    createAppValues(valuesToCreate=["calc.exe", "chrome.exe"], debug=True)
    deleteKeys(valuesToDelete=["calc.exe", "chrome.exe"])

if __name__ == "__main__":
    main()

#TODO: add app detection on first open + in blocksettings add a floatingactionbutton for refreshing apps or to manually add an app's executable (could look if dart has its own version of regex for detecting .exe at the end)