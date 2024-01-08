# <img src='https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/svgs/solid/folder-open.svg' card_color='#55dffe' width='50' height='50' style='vertical-align:bottom'/> File Browser

![ocp_file_browser](https://github.com/OpenVoiceOS/skill-ovos-local-media/assets/33701864/d88630f2-3291-410a-a499-1d33ab93415c)

## About
File Browser For Open Voice OS

for voice search this skill builds a local index of scanned user media

your collection needs to be organized in the following fashion to be detected by this skill

     ~/OCPMedia/Music
     ~/OCPMedia/Movies
     ~/OCPMedia/Podcasts
     ~/OCPMedia/...

folders are mapped to MediaType, subfolders are loaded as playlists

you can set the base folder (`~/OCPMedia` by default) in the skill `settings.json` 

```json
{
  "media_path": "~/OCPMedia"
}
```

## Examples
* "Open File Browser"
* "Show File Browser"

## Credits
Aditya Mehra (@AIIX)

## Category
**Daily**

## Tags
#filebrowser
#browser
#file
#manager
#local
#usb

## Notes
- File Browser requires latest OVOS Shell: https://github.com/OpenVoiceOS/ovos-shell
- Not backwards compatible with Mycroft-Core GUI API, Requires OVOS QML Plugin from ovos-shell
