#!/bin/bash
#installs simplecv on a raspberry pi

apt-get update
apt-get install -y python2.7 python-pip python-setuptools cmake gcc gcc++ python-numpy ipython python-scipy git python-opencv
git clone https://github.com/sightmachine/SimpleCV.git /usr/share/SimpleCV
python /usr/share/SimpleCV/setup.py
