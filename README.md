# Desktop Opal

A flutter app based off the iOS app Opal which aims to help you get work done without distractions!

**NOTE: I am aware that there is no build for this. No matter what I did flutter would not build the windows version correctly so I've resorted to just uploading the source code.**

## Overview

Desktop Opal (DO) is my personal version of the iOS app Opal which I made as I couldn't find any screen time management apps for windows which I liked. DO uses a flutter UI to interact with a python API backend using the winreg module to manage the DisallowRun key in the windows registry. Since that was a mouthful, it boils down to Flutter UI frontend --> Python API --> Windows Registry Management. The python API runs on port 8000 of the callback IP 127.0.0.1 (URL: http://127.0.0.1:8000/[endpoint]) and listens for post and get requests from the flutter UI.

## Warnings

- While inside a block session, don't close the app OR the API, this will lock you out of any apps you blocked during that session.
- Don't be dumb (i.e. Don't block any system processes)

## Prerequisites
Desktop_Opal requires:
- Flutter >=3.8.1
- Python >3.11
- Desktop Development With C++ Package (Visual Studio 2022)
- Admin perms to access winreg

## Installation
- Clone repo
- Open repo in an IDE (don't ask why its the only way the program runs - see NOTE)
- Run IN DEBUG MODE (again - don't ask questions)
- Allow changes to device

# FAQ

**Help! All of my apps are still blocked even after my session has ended!**
This is fine and probably happened because the app or API closed during a block session. The uhoh button in settings *should* fix this however if it doesn't:
- Press windows+R and type in regedit
- Go to this path: SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER\\DISALLOWRUN
- Either:
- Delete ALL subkeys except (default)
- OR Delete the DisallowRun key entirely (the program should recreate this key on startup - if it doesn't, manually create it again at this path)

**Why do I have to run the app in debug?**
I thought I told you not to ask questions!
Honestly, I don't know, I spent a couple hours trying my best to fix it (making a build) but nothing I tried worked. Running the app outside of debug *works*, but no window is shown.

**How do I run flutter in debug mode?**
On any of the scripts in lib just press F5! It should default to debug mode. If it either gives an error while compiling or runs without debug mode: close the app, make sure the desktop development with C++ package is updated and run it in debug from the VS Code side menu.

**Why did this take you 53 hours?**
I don't know. It shouldn't have taken me this long, however I can think of a few reasons as to why:
- This is my first time using flutter for a full project.
- I hadn't used 75% of the packages I used prior to this project.
- This was my first time trying hybrid programming.
- I'm generally a slow worker (and went into this blind leading to me wasting like 10 hours on a weird layout).
