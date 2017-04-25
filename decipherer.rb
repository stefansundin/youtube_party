require "./interpreter"


class Decipherer
  include Interpreter

  def initialize(url = "", steps = "")
    @url = url
    @steps = steps
  end

  def decrypt(sig)
    @steps = decode_steps(@url) if @steps.empty?
    @steps.split(" ").each do |op|
      op, n = op[0], op[1..-1].to_i
      sig = case op
      when 'r' then sig.reverse
      when 's' then sig[n..-1]
      when 'w' then
        sig[0], sig[n] = sig[n], sig[0]
        sig
      end
    end
    sig
  end
end
