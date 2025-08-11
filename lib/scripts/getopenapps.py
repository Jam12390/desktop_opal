import psutil

def blockApps(blockedApps : list):
    blockedAppsState = {app: False for app in blockedApps}
    openApps = psutil.process_iter()
    for process in openApps:
        if process.name() in blockedApps:
            blockedAppsState[process.name] = True
            process.terminate()
    return blockedAppsState