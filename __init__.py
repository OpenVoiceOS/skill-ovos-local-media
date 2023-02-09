#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright (c) 2016 - 2022 by Aditya Mehra <Aix.m@outlook.com>
# All rights reserved.

import os
import subprocess

from mycroft.skills.core import MycroftSkill, intent_file_handler
from mycroft_bus_client.message import Message
from ovos_plugin_common_play.ocp.status import *
from ovos_utils.process_utils import RuntimeRequirements
from ovos_utils import classproperty


class FileBrowserSkill(MycroftSkill):
    def __init__(self):
        """
        FileBrowserSkill Skill Class.
        """
        super(FileBrowserSkill, self).__init__(name="FileBrowserSkill")
        self.skill_location_path = None
        self.udev_thread = None
        self.audio_extensions = ["aac", "ac3", "aiff", "amr", "ape", "au", "flac", "alac", "m4a",
                                 "m4b", "m4p", "mid", "mp2", "mp3", "mpc", "oga", "ogg", "opus", "ra", "wav", "wma"]
        self.video_extensions = ["3g2", "3gp", "3gpp", "asf", "avi", "flv", "m2ts", "mkv", "mov",
                                 "mp4", "mpeg", "mpg", "mts", "ogm", "ogv", "qt", "rm", "vob", "webm", "wmv"]
        self.image_extensions = ["png", "jpg", "jpeg", "bmp", "gif", "svg"]

    @classproperty
    def runtime_requirements(self):
        # TODO - once OCP search is added remove gui requirement
        return RuntimeRequirements(internet_before_load=False,
                                   network_before_load=False,
                                   gui_before_load=True,
                                   requires_internet=False,
                                   requires_network=False,
                                   requires_gui=True,
                                   no_internet_fallback=True,
                                   no_network_fallback=True,
                                   no_gui_fallback=False)

    def initialize(self):
        self.add_event('skill.file-browser.openvoiceos.home', self.show_home)
        self.gui.register_handler('skill.file-browser.openvoiceos.handle.file',
                                  self.handle_file)
        self.gui.register_handler('skill.file-browser.openvoiceos.handle.folder.playlists',
                                  self.handle_folder_playlist)
        self.gui.register_handler('skill.file-browser.openvoiceos.send.file.kdeconnect',
                                  self.share_to_device_kdeconnect)
        self.skill_location_path = os.path.dirname(os.path.realpath(__file__))
        self.setup_udev_monitor()

    def setup_udev_monitor(self):
        try:
            import pyudev
            context = pyudev.Context()
            monitor = pyudev.Monitor.from_netlink(context)
            monitor.filter_by(subsystem='usb')
            self.udev_thread = pyudev.MonitorObserver(monitor, self.handle_udev_event)
            self.udev_thread.start()
        except Exception as e:
            pass

    def handle_udev_event(self, action, device):
        """
        Handle a udev event
        """
        if action == 'add':
            if device.device_node is not None:
                self.gui.show_notification("New USB device detected - Open file browser to explore it",
                                           action="skill.file-browser.openvoiceos.home", noticetype="transient",
                                           style="info")

        elif action == 'remove':
            if device.device_node is not None:
                self.gui.show_notification("A USB device was removed",
                                           noticetype="transient", style="info")

    @intent_file_handler("open.file.browser.intent")
    def show_home(self, message):
        """
        Show the file browser home page
        """
        self.gui.show_page("Browser.qml", override_idle=120)

    def _file2entry(self, file_url):
        base, file_extension = os.path.splitext(file_url)
        cover_images = [self.skill_location_path + "/ui/images/generic-audio-bg.jpg"]
        if os.path.isfile(file_url):
            name = base.split("/")[-1]
            cover_images = [f"{base}/{name}.{ext}" for ext in self.image_extensions
                            if os.path.isfile(f"{base}/{name}.{ext}")] or cover_images
        if file_extension in self.audio_extensions:
            media_type = MediaType.AUDIO
            playback_type = PlaybackType.AUDIO
        else:
            media_type = MediaType.VIDEO
            playback_type = PlaybackType.VIDEO

        return {
            "match_confidence": 100,
            "media_type": media_type,
            "length": 0,
            "uri": file_url,
            "playback": playback_type,
            "image": cover_images[0],
            "bg_image": cover_images[0],
            "skill_icon": "",
            "title": file_url.split("/")[-1],
            "skill_id": "skill-file-browser.openvoiceos"
        }

    def handle_file(self, message):
        """ 
        Handle a file from the file browser Video / Audio
        """
        file_url = message.data.get("fileURL", "")
        media = self._file2entry(file_url)
        playlist = [media]
        disambiguation = [media]
        self.bus.emit(Message("ovos.common_play.play",
                              {"media": media,
                               "playlist": playlist,
                               "disambiguation": disambiguation}))
        self.gui.release()

    def _folder2entry(self, folder_url):
        playlist = []
        for file in os.listdir(folder_url):
            file_url = "file://" + folder_url + "/" + file
            if os.path.isdir(file_url):
                media = self._folder2entry(file_url)
            else:
                media = self._file2entry(file_url)
            playlist.append(media)

        if len(playlist) > 0:
            media = playlist[0]
            folder_title = folder_url.split("/")[-1].replace("_", " ").replace("-", " ").title()
            return {
                "match_confidence": 100,
                "length": 0,
                "playlist": playlist,
                "playback": media["playback"],
                "image": media["image"],
                "bg_image": media["bg_image"],
                "skill_icon": "",
                "title": folder_title,
                "skill_id": "skill-file-browser.openvoiceos"
            }

    def handle_folder_playlist(self, message):
        """
        Handle a folder from the file browser as a playlist
        """
        folder_url = message.data.get("path", "")
        playlist = self._folder2entry(folder_url)
        if playlist:
            disambiguation = [playlist]
            media = playlist["playlist"][0]
            self.bus.emit(Message("ovos.common_play.play",
                                  {"media": media, "playlist": playlist,
                                   "disambiguation": disambiguation}))
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
        if self.udev_thread is not None:
            self.udev_thread.stop()
            self.udev_thread.join()


def create_skill():
    """
    Mycroft Create Skill Function
    """
    return FileBrowserSkill()
