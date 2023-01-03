#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright (c) 2016 - 2022 by Aditya Mehra <Aix.m@outlook.com>
# All rights reserved.

import os
import subprocess
from mycroft.skills.core import MycroftSkill, intent_file_handler
from ovos_plugin_common_play.ocp.status import *
from mycroft_bus_client.message import Message

__author__ = 'aix'


class FileBrowserSkill(MycroftSkill):
    def __init__(self):
        """
        FileBrowserSkill Skill Class.
        """
        super(FileBrowserSkill, self).__init__(name="FileBrowserSkill")
        self.skill_location_path = None

    def initialize(self):
        self.add_event('skill.file-browser.openvoiceos.home', self.show_home)
        self.gui.register_handler('skill.file-browser.openvoiceos.handle.file', self.handle_file)
        self.gui.register_handler('skill.file-browser.openvoiceos.send.file.kdeconnect', self.share_to_device_kdeconnect)
        self.audioExtensions = ["aac", "ac3", "aiff", "amr", "ape", "au", "flac", "alac" , "m4a", "m4b", "m4p", "mid", "mp2", "mp3", "mpc", "oga", "ogg", "opus", "ra", "wav", "wma"]
        self.videoExtensions = ["3g2", "3gp", "3gpp", "asf", "avi", "flv", "m2ts", "mkv", "mov", "mp4", "mpeg", "mpg", "mts", "ogm", "ogv", "qt", "rm", "vob", "webm", "wmv"]
        self.skill_location_path = os.path.dirname(os.path.realpath(__file__))

    @intent_file_handler("open.file.browser.intent")
    def show_home(self, message):
        """
        Show the file browser home page
        """

        self.gui.show_page("Browser.qml", override_idle=120)

    def handle_file(self, message):
        """ 
        Handle a file from the file browser Video / Audio
        """
        fileUrl = message.data.get("fileURL", "")
        # Determine if file is audio or video
        fileExtension = fileUrl.split(".")[-1]
        if fileExtension in self.audioExtensions:            
            media = {
                "match_confidence": 100,
                "media_type": MediaType.AUDIO,
                "length": 0,
                "uri": fileUrl,
                "playback": PlaybackType.AUDIO,
                "image": self.skill_location_path + "/ui/images/generic-audio-bg.jpg",
                "bg_image": self.skill_location_path + "/ui/images/generic-audio-bg.jpg",
                "skill_icon": "",
                "title": fileUrl.split("/")[-1],
                "skill_id": "skill-file-browser.openvoiceos"
            }
            playlist = [media]
            disambiguation = [media]
            self.bus.emit(Message("ovos.common_play.play", {"media": media, "playlist": playlist, "disambiguation": disambiguation}))
            self.gui.release()
            
        if fileExtension in self.videoExtensions:
            media = {
                "match_confidence": 100,
                "media_type": MediaType.VIDEO,
                "length": 0,
                "uri": fileUrl,
                "playback": PlaybackType.VIDEO,
                "image": self.skill_location_path + "/ui/images/generic-audio-bg.jpg",
                "bg_image": self.skill_location_path + "/ui/images/generic-audio-bg.jpg",
                "skill_icon": "",
                "title": fileUrl.split("/")[-1],
                "skill_id": "skill-file-browser.openvoiceos"
            }
            playlist = [media]
            disambiguation = [media]
            self.bus.emit(Message("ovos.common_play.play", {"media": media, "playlist": playlist, "disambiguation": disambiguation}))
            self.gui.release()
            
    def share_to_device_kdeconnect(self, message):
        """
        Share a file to a device using KDE Connect
        """
        file_url = message.data.get("file", "")
        device_id = message.data.get("deviceID", "")
        subprocess.Popen(["kdeconnect-cli", "--share", file_url, "--device", device_id])
    
    def stop(self):
        """
        Mycroft Stop Function
        """
        pass

def create_skill():
    """
    Mycroft Create Skill Function
    """
    return FileBrowserSkill()

