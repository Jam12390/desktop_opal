class Help{
  static const String blockedHelp = """
- Go to dashboard and press the block now button in the top right of your screen. 
- Then, select how long you want the block to last and if breaks are allowed.
- After pressing ok it'll take a second for the registry changes to take effect, once you see Time Remaining: xx:xx:xx update you should be good to go!

! - If you see "No apps registered to block", you need to go to settings and add some ticked entries under blocked apps. Whether that be using the auto-detect executables button or by manually adding entries, there must be at least 1 enabled entry for blocks to work.
! - Do not close the app while a session is in effect, this will cause your apps to remain blocked indefinitely. If you did quit the app during a session, pressing the uh oh button should fix this.
! - If for whatever reason your apps do not unblock after a session ends and the uh oh button doesn't fix the issue, open the windows registry and navigate to the path:
HKEY_CURRENT_USER\\SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\EXPLORER and delete the DisallowRun key in the registry tree.
""";
  
  static const String breakHelp = """
- Taking a break is simple. During a block session where breaks are allowed, press the take a break button, select a duration and press ok.

! - If you get the error "Blocking has been disabled for this session", you disabled blocking at the start of your session, now deal with it and get back to work.
! - If you REALLY need to access your apps and you disabled blocking, pressing the uh oh button in settings should end any session and unblock all apps.
""";

  static const String editHelp = """
- When first launching the app, I recommend pressing the auto-detect executables button in the bottom left of the blocked apps section. This (hopefully) should fill the blocked apps section with a bunch of your executable files.
- Checking and unchecking the boxes next to the entries will enable or disable them from being blocked.
- For manual editing, press the edit button in the top right. This will open a dialog with some options to edit each entry in the blocked apps list.

! - No auto-detected apps? Go to the manual editing section to add apps (sorry!)
""";

  static const String advEditHelp = """
[Entry name]      [Delete entry] [Toggle visibility in blocked apps]

[Entry name] - Name of the executable
[Delete entry] - Remove from appdata
[Toggle visibility] - Moves app between enabled apps and excluded apps (visibility in blockedApps)

Manual Addition:
To manually add an entry, simply enter the executable name for the program and press the arrow to the right of the text field to submit.
""";
}