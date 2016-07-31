# Pass &eurl= to prevent "It is restricted from playback on certain sites." error. (e.g. _JQH3G0cCtY)
# For some reason the order of keys is randomized. Don't ask me why.

# TODO:
# Get sig function: https://github.com/rg3/youtube-dl/blob/466a6145372aa70f44a9b39c7fdeb05301a5485a/youtube_dl/extractor/youtube.py#L876

require "uri"
require "httparty"
require "awesome_print"

module URI
  def to_h
    {
      "scheme" => self.scheme,
      "host" => self.host,
      "port" => self.port,
      "path" => self.path,
      "query" => Hash[URI.decode_www_form(self.query)],
    }
  end
end

class YoutubeParty
  include HTTParty
  base_uri "https://www.youtube.com"

  def self.get_video_info(video_id, sts=nil)
    url = "/get_video_info?video_id=#{video_id}"
    url += "&eurl=https://www.youtube.com/watch?v=#{video_id}"
    url += "&sts=#{sts}" if sts
    puts url
    r = get(url)
    data = Hash[URI.decode_www_form(r.body)]
    return data if r["status"] == "fail"

    data.keys.each do |k|
      if %w[keywords fmt_list watermark].include?(k)
        data[k] = data[k].split(",")
      end
      if %w[use_cipher_signature has_cc].include?(k)
        data[k] = data[k].downcase == "true"
      end
      if %w[allow_embed allow_ratings cc3_module cc_asr enablecsi is_listed iv3_module iv_allow_in_place_switch iv_load_policy muted no_get_video_log tmi].include?(k)
        data[k] = data[k] == "1"
      end
      if %w[cl default_audio_track_index idpj ldpj length_seconds timestamp view_count].include?(k)
        data[k] = data[k].to_i
      end
      if %w[avg_rating loudness].include?(k)
        data[k] = data[k].to_f
      end
      if %w[url_encoded_fmt_stream_map adaptive_fmts].include?(k)
        data[k] = parse_urlmap(data[k])
      end
    end
    data.sort.to_h
  end

  def self.get_ffmpeg_cmd(video_id, sts=nil)
    info = get_video_info(video_id, sts)
    video_url = select_best(info["adaptive_fmts"], "video/mp4")["url"]
    audio_url = select_best(info["adaptive_fmts"], "audio/mp4")["url"]
    metadata = {
      title: info["title"],
      comment: "https://www.youtube.com/watch?v=#{video_id}\nUploaded by #{info["author"]}\\nhttps://www.youtube.com/channel/#{info["ucid"]}\nDownloaded on #{Time.now.strftime("%F")}"
    }.map { |k,v| "-metadata #{k}=$'#{v.gsub("'","").gsub("\n","\\n")}'" }.join(" ")
    fn = info["title"].gsub(/[:*?"<>|]/,"") + ".mp4"
    "ffmpeg -i \"#{video_url}\" -i \"#{audio_url}\" -codec copy #{metadata} \"#{fn}\""
  end

  def self.get_oembed_info(video_id)
    url = "https://www.youtube.com/oembed?url=http://www.youtube.com/watch?v=#{video_id}&format=json"
    r = get(url, format: :json)
    r.parsed_response.sort.to_h
  end

  # private

  def self.select_best(streams, type)
    streams.select do |fmt|
      fmt["type"].start_with?(type)
    end.sort_by do |fmt|
      -fmt["bitrate"]
    end[0]
  end

  def self.parse_urlmap(str)
    str.split(",").map do |s|
      h = Hash[URI.decode_www_form(s)].sort.to_h
      h.keys.each do |k|
        # fps to_f ?
        if %w[bitrate clen itag lmt projection_type].include?(k)
          h[k] = h[k].to_i
        end
      end
      # h["url_parts"] = URI.parse(h["url"]).to_h
      if h["s"]
        sig = apply_cipher(h["s"])
        # h["decoded_signature"] = sig
        h["url"] += "&signature=#{sig}"
      end
      h
    end
  end

  def self.apply_cipher(s, sts=nil)
    # 16881 r w70 s2 w53 s1
    # cipher = "r w70 s2 w53 s1"
    # 'vflNzKG7n' => '135957536242 s3 r s2 r s1 r w67',  # 30 Jan 2013
    cipher = "s3 r s2 r s1 r w67"
    cipher.split(" ").each do |op|
      if op == "r"
        s = s.reverse
      elsif op[0] == "s"
        n = op[1..-1].to_i
        s = s[n..-1]
      elsif op[0] == "w"
        n = op[1..-1].to_i
        temp = s[0]
        s[0] = s[n]
        s[n] = temp
      end
    end
    return s
  end
end
