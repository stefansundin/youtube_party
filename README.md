- https://www.jwz.org/hacks/youtubedown
- https://github.com/rg3/youtube-dl
- https://rg3.github.io/youtube-dl/

```
sudo apt-get install libio-socket-ssl-perl 	libhtml-parser-perl
wget -U "Firefox" https://www.jwz.org/hacks/youtubedown
perl youtubedown --title test https://www.youtube.com/watch?v=_JQH3G0cCtY
```


```ruby
ruby -r './youtube_party' -e 'puts YoutubeParty.get_video_info("a48o2S1cPoo")'
ruby -r './youtube_party' -e 'ap YoutubeParty.get_video_info("a48o2S1cPoo")'
ruby -r './youtube_party' -e 'ap YoutubeParty.get_video_info("vU8dCYocuyI")'
ruby -r './youtube_party' -e 'ap YoutubeParty.get_video_info("aRrDsbUdY_k")'
ruby -r './youtube_party' -e 'puts YoutubeParty.get_ffmpeg_cmd("aRrDsbUdY_k")'
ruby -r './youtube_party' -e 'ap YoutubeParty.get_oembed_info("aRrDsbUdY_k")'

./cons
YoutubeParty.get_video_info("a48o2S1cPoo")
```

Test video with cipher:
```
ruby -r './youtube_party' -e 'ap YoutubeParty.get_video_info("_JQH3G0cCtY", 16881)'
ruby -r './youtube_party' -e 'ap YoutubeParty.get_video_info("_JQH3G0cCtY", 135957536242)'
ruby -r './youtube_party' -e 'puts YoutubeParty.get_ffmpeg_cmd("_JQH3G0cCtY", 135957536242)'
```

Apply cipher:
```
ruby -r './youtube_party' -e 'puts YoutubeParty.apply_cipher("334334FC6DBAA0BF390DACE760426A436A473D20294C.1B5CF882A6A48FC7AC17773E5DB8FBA4A0EB07C7C7", 135957536242)'
9C70BE0A4ABF8BD5E37771CA7CF84A6A288FC5B1.C49202D374A634A624067ECAD073FB0AABD6CF43
```
