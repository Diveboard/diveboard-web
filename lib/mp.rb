module Mp
  ## computes a string from an id - and ensure it's unique (bijective transformation)
  ## also retrieves the id back from a string
  ## using to_s(36) means it's case insensitive

  def Mp.shake id, opts={}
    return nil if id.nil?
    opts = {} unless opts.is_a? Hash
    opts[:base] ||= 62
    Mp.primes.each_with_index do |t,idx|
      if t>id
        return Mp.toBase((id* Mp.power)% t, opts[:base])
        break
      end
    end
    raise DBTechnicalError.new "No big enough prime to generate tinyurl for id", id: id
  end

  def Mp.deshake elem, opts={}
    return nil if elem.blank?
    opts = {} unless opts.is_a? Hash
    opts[:base] ||= 62
    elem_i = Mp.fromBase(elem, opts[:base])
    Mp.primes.each_with_index do |t,idx|
      if t>elem_i
        return (elem_i*Mp.reverse_factors[idx])%t
        break
      end
    end
    raise DBTechnicalError.new "could not be reversed - bigger than our biggest prime", elem: elem, elem_i: elem_i
  end

  protected

  def Mp.toBase(dec, base=62)
    nums ='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/'
     #allows up to base 64
     #add your own symbols to allow you to use higher bases
     result = ""
     #result string
     return nil if dec.instance_of? Float
     #if anyone has any idea how to make floating points acceptable, I'd love to hear it!
     return nil if base < 2
     #base 0 isn't possible, and neither is base 1
     return 0 if dec == 0
     #0 is 0 in every base
     while dec != 0
       result += nums[dec%base].chr
       dec = (dec/base).to_i
     end
     return result.reverse
   end

  def Mp.fromBase(str, base=62)
    rev = {"0"=>0, "1"=>1, "2"=>2, "3"=>3, "4"=>4, "5"=>5, "6"=>6, "7"=>7, "8"=>8, "9"=>9, "A"=>10, "B"=>11, "C"=>12, "D"=>13, "E"=>14, "F"=>15, "G"=>16, "H"=>17, "I"=>18, "J"=>19, "K"=>20, "L"=>21, "M"=>22, "N"=>23, "O"=>24, "P"=>25, "Q"=>26, "R"=>27, "S"=>28, "T"=>29, "U"=>30, "V"=>31, "W"=>32, "X"=>33, "Y"=>34, "Z"=>35, "a"=>36, "b"=>37, "c"=>38, "d"=>39, "e"=>40, "f"=>41, "g"=>42, "h"=>43, "i"=>44, "j"=>45, "k"=>46, "l"=>47, "m"=>48, "n"=>49, "o"=>50, "p"=>51, "q"=>52, "r"=>53, "s"=>54, "t"=>55, "u"=>56, "v"=>57, "w"=>58, "x"=>59, "y"=>60, "z"=>61, "+"=>62, "/"=>63} # from Mp.reverse_base
    result = 0
    id = 0
    str = str.reverse
    begin
      result += rev[str[id]]*(base**id)
      id +=1
    end while id < str.length
    return result
  end


  def Mp.primes
    return [ 6643838879, 119218851371, 5600748293801, 688846502588399, 32361122672259149]
  end
  def Mp.power
    return 54018521
  end

  def Mp.reverse_factors
    return [1603749406, 108381216778, 4052748765579, 516634880129310, 23535361888999874]
  end
  ## computed by primes.map {|t| modexp(power,(t-2),t)}

  ##idea: - 7 is power
  ##ruby-1.9.2-p180 :030 > (24556*7)%28657
  ## => 28607
  ##ruby-1.9.2-p180 :032 > (7**28655)%28657
  ## => 4094
  ##ruby-1.9.2-p180 :033 > (28607*4094)%28657
  ## => 24556


  ## modular exponentiation
  def Mp.modexp x, e, n
      return 1%n if e.zero?
      # k - most significant bit posistion
      ee, k = e, 0
      # linear search
      (ee>>=1;k+=1) while ee>0
      y = x
      (k-2).downto(0) do |j|
          y=y*y%n  # square
          (y=y*x%n) if e[j] == 1 # multiply
      end
      y
  end

  def Mp.reverse_base
    nums ='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/'
    rev={}
    i=0
    begin
      rev[nums[i]] = i
      i +=1
    end while i<nums.length
    return rev
  end


  def define_shake key
    self.class_variable_set('@@shake_key', key)
    send :define_method, :shaken_id do ||
      return "#{key}#{Mp.shake(self.id)}"
    end
    self.class.send :define_method, :fromshake do |code|
      return self.find(idfromshake code)
    end
    self.class.send :define_method, :idfromshake do |code|
      key = self.class_variable_get('@@shake_key')
      if code.is_a? Fixnum then
        return code
      elsif code[0..(key.length-1)] == key
         return Mp.deshake(code[key.length..-1])
      else
         return Integer(code.to_s, 10)
      end
    end
  end


end
