A#!/usr/bin/env python
import subprocess
import fileinput
import datetime
import urllib2
import signal
import glob
import time
import sys
import os
import re

MEM = "512M"

def signal_handler(signal, frame):
    log("**********************************************")
    log("SERVER TERMINATED BY CONTROL-C")
    log("**********************************************")
    sys.exit(0)

def get_latest_version_number():
    r = urllib2.urlopen(urllib2.Request("https://minecraft.net/download"))
    m = re.search(".*minecraft_server\.([^\s]*)\.jar.*", r.read())

    if not m:
        log("WARNING: Could not find latest version!")
        return -1

    return m.groups()[0]

def get_current_version_number():
    versions = sorted([".".join(jar.split(".")[1:-1]) for jar in glob.glob("minecraft_server.*.jar")])
    if versions:
        return versions[-1]
    else:
        return 0

def update_server():
    log("**********************************************")
    log("CHECKING FOR UPDATES")

    current_version = get_current_version_number()
    latest_version = get_latest_version_number()

    if current_version != latest_version:
        log("Update found: {0}".format(latest_version))
        subprocess.call(["curl", "-sO", "https://s3.amazonaws.com/Minecraft.Download/versions/{0}/minecraft_server.{0}.jar".format(latest_version)])
        current_version = latest_version
        log("Update complete!")

    log("**********************************************")
    return current_version

def update_eula():
    if os.path.isfile("eula.txt"):
        with open("eula.txt", "r") as file:
            filedata = file.read()

        with open("eula.txt", "w") as file:
            file.write(filedata.replace("eula=false", "eula=true"))

def run_server():
    version = update_server()
    update_eula()

    args = ["java", "-Xmx{0}".format(MEM), "-Xms{0}".format(MEM), "-jar", "minecraft_server.{0}.jar".format(version), "nogui"]

    proc = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    while True:
        line = proc.stdout.readline()
        if line != '':
            log(line.rstrip())
        else:
            break

def log(message):
    print("[{}] -- {}".format(datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S'), message))

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    while True:
        run_server()
