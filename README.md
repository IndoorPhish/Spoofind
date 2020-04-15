# Spoofind
Pull a list of newly registered domains and check them against a list of regex searches.

Add regex searches to a file named Search.txt in the same directory as the PowerShell script.
The format of the file should be:

- Line 1: ---Google spoofs---
- Line 2: .*g[0o]gle.*
- Line 3: ---Another Search---
- Line 4: .*bing\.com
