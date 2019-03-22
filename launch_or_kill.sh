#!/bin/bash

if [ $(ps -u $USER u | grep popup_calc | wc -l) -ge 2 ]; then
    killall popup_calc
else
    ~/.local/share/popup_calc/popup_calc
fi
