import os
import subprocess
from os.path import join, dirname

from json_database import JsonStorageXDG
from ovos_bus_client.apis.ocp import OCPInterface
from ovos_bus_client.message import Message

from ovos_utils import classproperty
from ovos_utils.log import LOG
from ovos_utils.process_utils import RuntimeRequirements
from ovos_workshop.decorators import intent_handler
from ovos_workshop.decorators.ocp import ocp_search
from ovos_workshop.skills.common_play import MediaType, PlaybackType
from ovos_workshop.skills.common_play import OVOSCommonPlaybackSkill


class LocalMediaSkill(OVOSCommonPlaybackSkill):
    audio_extensions = ["aac", "ac3", "aiff", "amr", "ape", "au", "flac", "alac", "m4a",
                        "m4b", "m4p", "mid", "mp2", "mp3", "mpc", "oga", "ogg", "opus", "ra", "wav", "wma"]
    video_extensions = ["3g2", "3gp", "3gpp", "asf", "avi", "flv", "m2ts", "mkv", "mov",
                        "mp4", "mpeg", "mpg", "mts", "ogm", "ogv", "qt", "rm", "vob", "webm", "wmv"]
    image_extensions = ["png", "jpg", "jpeg", "bmp", "gif", "svg"]

    def __init__(self, *args, **kwargs):
        self.supported_media = [MediaType.SHORT_FILM]
        self.skill_icon = join(dirname(__file__), "res", "icon", "ovos-file-browser.svg")
        self.archive = JsonStorageXDG("LocalMedia", subfolder="OCP")
        super().__init__(*args, **kwargs)
        self.scan_local_media()

    @classproperty
    def runtime_requirements(self):
        return RuntimeRequirements(internet_before_load=False,
                                   network_before_load=False,
                                   gui_before_load=False,
                                   requires_internet=False,
                                   requires_network=False,
                                   requires_gui=False,
                                   no_internet_fallback=True,
                                   no_network_fallback=True,
                                   no_gui_fallback=False)

    def initialize(self):
        self.ocp = OCPInterface(self.bus)
        self.udev_thread = None
        self.add_event(f'{self.skill_id}.home', self.show_home)
        self.add_event(f'{self.skill_id}.scan', self.scan_local_media)
        self.gui.register_handler('file.play', self.handle_file)
        self.gui.register_handler('folder.play', self.handle_folder_playlist)
        self.gui.register_handler('file.kdeconnect.send', self.share_to_device_kdeconnect)
        self.setup_udev_monitor()

    def scan_local_media(self, message: Message = None):
        """ build a local index of scanned user media
         folders are mapped to MediaType, eg

         ~/OCPMedia/Music
         ~/OCPMedia/Movies
         ~/OCPMedia/Podcasts
         ~/OCPMedia/...

         subfolders are loaded as playlists
         """
        base_path = self.settings.get("media_path", "~/OCPMedia")
        media_path = os.path.expanduser(base_path)
        LOG.info(f"Scanning for OCP media under {base_path}")

        tmap = {
            "Music": MediaType.MUSIC,
            "Movies": MediaType.MOVIE,
            "Audiobooks": MediaType.AUDIOBOOK,
            "Podcasts": MediaType.PODCAST.PODCAST,
            "RadioTheatre": MediaType.RADIO_THEATRE,
            "AudioDescriptions": MediaType.AUDIO_DESCRIPTION,
            "Anime": MediaType.ANIME,
            "Cartoon": MediaType.CARTOON,
            "Documentaries": MediaType.DOCUMENTARY,
            "Series": MediaType.VIDEO_EPISODES,
            "SilentMovies": MediaType.SILENT_MOVIE,
            "Shorts": MediaType.SHORT_FILM,
            "BWMovies": MediaType.BLACK_WHITE_MOVIE
        }
        LOG.info(f"Please use the MediaType subfolders to organize your collection: {list(tmap.keys())}")

        audio = [MediaType.AUDIO, MediaType.MUSIC, MediaType.PODCAST, MediaType.RADIO, MediaType.RADIO_THEATRE,
                 MediaType.AUDIO_DESCRIPTION, MediaType.ASMR, MediaType.ADULT_AUDIO]

        def norm_name(n):
            return n.split("|")[0].split("(")[0].split("[")[0].split("{")[0].split("-")[0].strip()

        # scan files
        for t, media_type in tmap.items():
            if os.path.isdir(f"{media_path}/{t}"):
                entries = []
                for f in os.listdir(f"{media_path}/{t}"):
                    ext = self.audio_extensions if media_type in audio else self.video_extensions
                    if not any(f.endswith(e) for e in ext):
                        continue
                    LOG.debug(f"found {t}: {f}")
                    entry = self._file2entry(f"{base_path}/{f}", media_type)
                    self.archive[f"{base_path}/{f}"] = entry
                    entries.append(entry)

                if t == "Movies":
                    self.register_ocp_keyword(MediaType.MOVIE, "movie_name",
                                              [norm_name(n["title"]) for n in entries])
                elif t == "Music":
                    self.register_ocp_keyword(MediaType.MUSIC, "song_name",
                                              [norm_name(n["title"]) for n in entries])
                elif t == "Podcasts":
                    self.register_ocp_keyword(MediaType.PODCAST, "podcast_name",
                                              [norm_name(n["title"]) for n in entries])
                elif t == "Anime":
                    self.register_ocp_keyword(MediaType.ANIME, "anime_name",
                                              [norm_name(n["title"]) for n in entries])
                elif t == "Documentaries":
                    self.register_ocp_keyword(MediaType.DOCUMENTARY, "documentary_name",
                                              [norm_name(n["title"]) for n in entries])
                # TODO all media types

        # scan folders
        for t, media_type in tmap.items():
            if os.path.isdir(f"{media_path}/{t}"):
                entries = []
                # TODO - register folder as album / series / ...  name
                for f in os.listdir(f"{media_path}/{t}"):
                    if os.path.isdir(f):
                        LOG.debug(f"found {t} playlist: {f}")
                        entry = self._folder2entry(f"{base_path}/{f}", media_type)
                        self.archive[f"{base_path}/{f}"] = entry
                        entries.append(entry)

        self.archive.store()

    @ocp_search()
    def search_db(self, phrase, media_type):
        base_score = 0
        entities = self.ocp_voc_match(phrase)
        base_score += 30 * len(entities)

        candidates = [video for video in self.archive.values()
                      if video["media_type"] == media_type]

        if entities:
            title = list(entities.values())[0]
            return [video for video in candidates
                    if title.lower() in video["title"].lower()]
        return []

    ## File Browser
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
                                           action=f'{self.skill_id}.home', noticetype="transient",
                                           style="info")

        elif action == 'remove':
            if device.device_node is not None:
                self.gui.show_notification("A USB device was removed", noticetype="transient", style="info")

    @intent_handler("open.file.browser.intent")
    def show_home(self, message):
        """
        Show the file browser home page
        """
        self.gui.show_page("Browser", override_idle=120)

    def _file2entry(self, file_url, media_type=None):
        file_url = os.path.expanduser(file_url)
        base, file_extension = file_url.split(".", 1)
        cover_images = [f"{os.path.dirname(__file__)}/ui/images/generic-audio-bg.jpg"]
        if os.path.isfile(file_url):
            name = base.split("/")[-1]
            cover_images = [f"{base}/{name}.{ext}" for ext in self.image_extensions
                            if os.path.isfile(f"{base}/{name}.{ext}")] or cover_images
        if file_extension in self.audio_extensions:
            media_type = media_type or MediaType.AUDIO
            playback_type = PlaybackType.AUDIO
        else:
            media_type = media_type or MediaType.VIDEO
            playback_type = PlaybackType.VIDEO

        if not file_url.startswith("file://"):
            file_url = "file://" + file_url

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
            "skill_id": self.skill_id
        }

    def handle_file(self, message):
        """
        Handle a file from the file browser Video / Audio
        """
        file_url = message.data.get("fileURL", "")
        media = self._file2entry(file_url)
        playlist = [media]
        self.ocp.play(playlist)
        self.gui.release()

    def _folder2entry(self, folder_url, media_type=None):
        playlist = []
        for file in os.listdir(folder_url):
            file_url = f"{folder_url}/{file}"
            if os.path.isdir(file_url):
                media = self._folder2entry(file_url, media_type)
            else:
                media = self._file2entry(file_url, media_type)
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
                "skill_id": self.skill_id
            }

    def handle_folder_playlist(self, message):
        """
        Handle a folder from the file browser as a playlist
        """
        folder_url = message.data.get("path", "")
        playlist = self._folder2entry(folder_url)
        if playlist:
            self.ocp.play(playlist)
            self.gui.release()

    def share_to_device_kdeconnect(self, message):
        """
        Share a file to a device using KDE Connect
        """
        file_url = message.data.get("file", "")
        device_id = message.data.get("deviceID", "")
        subprocess.Popen(["kdeconnect-cli", "--share", file_url, "--device", device_id])

    def shutdown(self):
        if self.udev_thread is not None:
            self.udev_thread.stop()
            self.udev_thread.join()


if __name__ == "__main__":
    from ovos_utils.messagebus import FakeBus

    LOG.set_level("DEBUG")

    s = LocalMediaSkill(bus=FakeBus(), skill_id="t.fake")
    # 2024-01-07 23:14:37.871 - OVOS - __main__:scan_local_media:58 - INFO - Scanning for OCP media under ~/OCPMedia
    # 2024-01-07 23:14:37.871 - OVOS - __main__:scan_local_media:75 - INFO - Please use the MediaType subfolders to organize your collection: ['Music', 'Movies', 'Audiobooks', 'Podcasts', 'RadioTheatre', 'AudioDescriptions', 'Anime', 'Cartoon', 'Documentaries', 'Series', 'SilentMovies', 'Shorts', 'BWMovies']
    # 2024-01-07 23:14:37.871 - OVOS - __main__:scan_local_media:90 - DEBUG - found Movies: Robocop - The Baliscon Cut.mp4
    # 2024-01-07 23:14:37.872 - OVOS - __main__:scan_local_media:90 - DEBUG - found Movies: Robocop 2 - The Baliscon Cut.mp4
    # 2024-01-07 23:14:37.872 - OVOS - __main__:scan_local_media:90 - DEBUG - found Movies: Robocop Prime Directives - The Baliscon Cut.mp4
    # 2024-01-07 23:14:37.872 - OVOS - __main__:scan_local_media:90 - DEBUG - found Movies: Robocop 3 - The Baliscon Cut.mp4

    for r in s.search_db("play Robocop", MediaType.MOVIE):
        print(r)
        # {'match_confidence': 100, 'media_type': <MediaType.MOVIE: 10>, 'length': 0, 'uri': 'file:///home/miro/OCPMedia/Robocop - The Baliscon Cut.mp4', 'playback': <PlaybackType.VIDEO: 1>, 'image': '/home/miro/PycharmProjects/OCP_sprint/skills/skill-ovos-local-media/ui/images/generic-audio-bg.jpg', 'bg_image': '/home/miro/PycharmProjects/OCP_sprint/skills/skill-ovos-local-media/ui/images/generic-audio-bg.jpg', 'skill_icon': '', 'title': 'Robocop - The Baliscon Cut.mp4', 'skill_id': 't.fake'}
        # {'match_confidence': 100, 'media_type': <MediaType.MOVIE: 10>, 'length': 0, 'uri': 'file:///home/miro/OCPMedia/Robocop 2 - The Baliscon Cut.mp4', 'playback': <PlaybackType.VIDEO: 1>, 'image': '/home/miro/PycharmProjects/OCP_sprint/skills/skill-ovos-local-media/ui/images/generic-audio-bg.jpg', 'bg_image': '/home/miro/PycharmProjects/OCP_sprint/skills/skill-ovos-local-media/ui/images/generic-audio-bg.jpg', 'skill_icon': '', 'title': 'Robocop 2 - The Baliscon Cut.mp4', 'skill_id': 't.fake'}
        # {'match_confidence': 100, 'media_type': <MediaType.MOVIE: 10>, 'length': 0, 'uri': 'file:///home/miro/OCPMedia/Robocop Prime Directives - The Baliscon Cut.mp4', 'playback': <PlaybackType.VIDEO: 1>, 'image': '/home/miro/PycharmProjects/OCP_sprint/skills/skill-ovos-local-media/ui/images/generic-audio-bg.jpg', 'bg_image': '/home/miro/PycharmProjects/OCP_sprint/skills/skill-ovos-local-media/ui/images/generic-audio-bg.jpg', 'skill_icon': '', 'title': 'Robocop Prime Directives - The Baliscon Cut.mp4', 'skill_id': 't.fake'}
        # {'match_confidence': 100, 'media_type': <MediaType.MOVIE: 10>, 'length': 0, 'uri': 'file:///home/miro/OCPMedia/Robocop 3 - The Baliscon Cut.mp4', 'playback': <PlaybackType.VIDEO: 1>, 'image': '/home/miro/PycharmProjects/OCP_sprint/skills/skill-ovos-local-media/ui/images/generic-audio-bg.jpg', 'bg_image': '/home/miro/PycharmProjects/OCP_sprint/skills/skill-ovos-local-media/ui/images/generic-audio-bg.jpg', 'skill_icon': '', 'title': 'Robocop 3 - The Baliscon Cut.mp4', 'skill_id': 't.fake'}
