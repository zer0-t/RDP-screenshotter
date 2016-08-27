# RDP-screenshotter

This bash script takes a screenshot of the RDP desktop.
The script will connect to an RDP server, and makes a screenshot. This information can be used to obtain usernames from logged in users.
The screenshot can be made because NLA(Network Level Authentication) is not configured properly.

More info about NLA: https://technet.microsoft.com/en-us/magazine/hh750380.aspx

## How does it work?

1. Connects to RDP using rdesktop
2. Verifies if screenshot can be made
3. Takes screenshot
4. Kills RDP connection

## Prerequisites

1. Linux host running an X server
2. The following packages: xdotool imagemagick rdesktop bc
3. Debian/Ubuntu/Kali install: `apt-get install xdotool imagemagick rdesktop bc tesseract-ocr`


## Usage
Scan a single host: `./RDP-screenshotter.sh 192.168.1.10`

Scan Multiple hosts: `for i in $(cat list.txt); do ./RDP-screenshotter.sh "${i}"; done`

## Credits
Used large chunks of code from the stickyKeysHunter.sh script from ztgrace

