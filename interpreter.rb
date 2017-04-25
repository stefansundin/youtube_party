require "uri"
require "httparty"

module Interpreter
  extend self

  # decode_steps("https://www.youtube.com/yts/jsbin/player-en_US-vfl5-0t5t/base.js")
  # => "s1 w44 r s1"
  def decode_steps(url)
    js_code = HTTParty.get(url)

    decoder = extract_signature(js_code, url)
    actions = extract_actions(js_code, decoder.first[:obj_name])

    steps = decoder.map do |s|
      step  = actions[s[:member]]
      index = s[:index]
      case step
        when "r"      then step
        when "s", "w" then step + index
      end
    end

    steps.join(" ")
  end

  # find signature function and interpreter each line statement
  def extract_signature(js_code, url)
    sig_function_name = js_code.match(/(["\'])signature\1\s*,\s*([a-zA-Z0-9$]+)\(/m)[2]
    code = js_code.match(/
      (?:
        function\s+#{sig_function_name}|
     		[{;,]\s*#{sig_function_name}\s*=\s*function|
     		var\s+#{sig_function_name}\s*=\s*function
      )
     	\s*\((?<args>[^)]*)\)
      \s*\{(?<code>[^}]+)\}
    /xm)["code"].split(";")

    raise "Could not find JS function #{@@url} with function name #{sig_function_name}" if code.empty?

    code.map { |s| interpret_statement(s) }.select { |s| s[:obj_name] != "a" }
  end

  # interpret_statement("yc.Kx(a,44)")
  # => {
  #   obj_name: "yc",
  #   member:   "Kx",
  #   args:     "a,44",
  #   index:    "44"
  # }
  def interpret_statement(stmt)
    stmt_m = stmt.lstrip().match(/
      (?<obj_name>[a-zA-Z_$][a-zA-Z_$0-9]*)\.
      (?<member>[^(]+)
      (?:\(
        (?<args>
          [^()\d]*
          (?<index>\d*)
        )
      \))?$
    /xm)

    {
      obj_name: stmt_m["obj_name"],
      member:   stmt_m["member"],
      args:     stmt_m["args"],
      index:    stmt_m["index"]
    }
  end

  # if statement is "yc.Kx(a,44)", the obj_name `yc` will become input
  #   obj_name: "yc"
  #
  # extract_actions("yc")
  # => {
  #   "hG" => "s",    # splice
  #   "Dt" => "v",    # reverse
  #   "Kx" => "w",    # swap
  # }
  def extract_actions(js_code, obj_name)
    fields = js_code.match(/(?<!this\.)#{obj_name}\s*=\s*{\s*(?<fields>([a-zA-Z$0-9]+\s*:\s*function\(.*?\)\s*{.*?}(?:,\s*)?)*)}\s*/m)["fields"]
    fields_m = fields.scan(/([a-zA-Z$0-9]+)\s*:\s*function\(([a-z,]+)\){([^}]+)}/m)

    actions = {}
    fields_m.each do |f|
      key, code = f[0], f[2]
      actions[key] = case code
        when /splice/       then "s"
        when /reverse/      then "r"
        when /var.+length/  then "w"
      end
    end
    actions
  end
end
