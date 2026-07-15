#!/bin/bash
audio_path=/home/audio/mrcp-asr/audio
before_day="+30"

find $audio_path -mtime $before_day -type f -exec rm {} \;

