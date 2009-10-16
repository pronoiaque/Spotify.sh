#!/bin/bash
# Automatically add new add and push the repo
#echo `cat spotify.pub`"|"`wmctrl -l | grep Spotify | cut -d" " -f 5-500` > 'spotify.pub'
git commit spotify.pub -m 'auto new ad'
git push origin
