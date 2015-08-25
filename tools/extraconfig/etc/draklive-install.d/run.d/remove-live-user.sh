#!/bin/bash
#
# Removes live user
#

userdel -r live
# remove not needed stuff
rm -f /welcome.jpg
rm -f /splash.jpg
sync
