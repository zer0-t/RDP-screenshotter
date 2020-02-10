#!/bin/bash
#
# RDP-screenshotter.sh - version 0.2 BETA(28-08-2016)
# Copyright (c) 2016 Zer0-T
# License: GPLv3
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

if [ -z $1 ]; then
    echo "Usage: $0 target.ip"
    exit 1
fi

# Configurable options
output="output"
timeout=60
timeoutStep=2
host=$1
blue="\e[34m[*]\e[0m"
red="\e[31m[*]\e[0m"
green="\e[32m[*]\e[0m"
temp="/tmp/${host}.png"

function screenshot {
    screenshot=$1
    window=$2
    echo -e "${blue} Saving screenshot to ${screenshot}"
    import -window ${window} "${screenshot}"
}

function isAlive {
    pid=$1
    kill -0 $pid 2>/dev/null
    if [ $? -eq 1 ]; then
        echo -e "${red} Process died, failed to connect to ${host}, NLA might be enabled on the server!"
        exit 1
    fi
}

function isTimedOut {
    t=$1
    if [ $t -ge $timeout ]; then
        echo -e "${red} Timed out connecting to ${host}"
        kill $!
        exit 1
    fi
}

export DISPLAY=:0

function ocr {
	echo -e "${blue} Converting image to B/W and running OCR for ${host}"
	convert "${temp}" -grayscale Rec709Luminance -resample 300x300 -unsharp 6.8x2.69 -quality 100 "${temp}" 
	tesseract "${temp}" "${output}/${host}" 1>/dev/null 2>&1
	echo -e "${green} OCR output saved in: ${output}/${host}.txt"
}


# Launch rdesktop in the background
echo -e "${blue} Initiating rdesktop connection to ${host}"
echo "yes" | rdesktop -u "" -a 16 $host &
pid=$!

# Get window id
window=
timer=0
    while true; do
    # Check to see if we timed out
    isTimedOut $(printf "%.0f" $timer)

   # Check to see if the process is still alive
    isAlive $pid
    window=$(xdotool search --name ${host})
    if [ ! "${window}" = "" ]; then
        echo -e "${blue} Got window id: ${window}"
        break
    fi
    timer=$(echo "$timer + 0.1" | bc)
    sleep 0.1
done

# If the screen is all black delay timeoutStep seconds
timer=0
while true; do

    # Make sure the process didn't die
    isAlive $pid

    isTimedOut $timer

    # Screenshot the window and if the only one color is returned (black), give it chance to finish loading
    screenshot "${temp}" "${window}"
    colors=$(convert "${temp}" -colors 5 -unique-colors txt:- | grep -v ImageMagick)
    if [ $(echo "${colors}" | wc -l) -eq 1 ]; then
        echo -e "${blue} Waiting on desktop to load"
        sleep $timeoutStep
    else
        # Many colors should mean we've got a console loaded
	echo -e "${green} Console Loaded for ${host}"
        break
    fi
    timer=$((timer + timeoutStep))
done


if [ ! -d "${output}" ]; then
    mkdir "${output}"
fi

afterScreenshot="${output}/${host}.png"
screenshot "${afterScreenshot}" "${window}"

# run ocr on saved image(s)
ocr

rm ${temp}

# Close the rdesktop window
kill $pid
