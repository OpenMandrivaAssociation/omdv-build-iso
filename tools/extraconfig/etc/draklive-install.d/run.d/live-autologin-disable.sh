#!/bin/sh
sed -i -e 's/^\(AutoLoginEnable.*\)/#\1/g' -e 's/^\(AutoLoginUser.*\)/#\1/g' /usr/share/config/kdm/kdmrc
