# Spoofind
Pull a list of newly registered domains curated by SANS and check them against a list of regex searches.
- Read the SANS blog here: https://isc.sans.edu/diary/Experimental+New+Domain++Domain+Age+API/28770

Add regex searches to the list within the PowerShell script. Add in your API key and API URi for TheHive and uncomment the function call to post results to you Hive instance.

The format of the list should be:

- Line 1: %Google spoofs%
- Line 2: .*g[o0]{2}le\.com
- Line 3: %Another Search%
- Line 4: .*bing\.com

@agoodcloud_blog was a big help in getting this sorted - blog.agood.cloud
