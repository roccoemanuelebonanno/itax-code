module ItaxCode
  ##
  # This class handles the tax code generation logic.
  #
  # @param [String]       surname    The citizen first name
  # @param [String]       name       The citizen last name
  # @param [String]       gender     The citizen gender
  # @param [String, Date] birthdate  The citizen birthdate
  # @param [String]       birthplace The citizen birthplace
  #
  # @example
  #
  #   ItaxCode::Encoder.new(
  #     surname: "Rossi",
  #     name: "Matteo",
  #     gender: "M",
  #     birthdate: "1990-08-23",
  #     birthplace: "Milano"
  #   ).encode
  #
  # @return [String] The encoded tax code

  class Encoder
    def initialize(data = {}, utils = Utils.new)
      @surname    = data[:surname]
      @name       = data[:name]
      @gender     = data[:gender].try :upcase
      @birthdate  = parsed_date data[:birthdate]
      @birthplace = data[:birthplace]
      @utils      = utils
    end

    ##
    # This method calculates the tax code.
    #
    # @return [String] The calculated tax code

    def encode
      code = encode_surname
      code += encode_name
      code += encode_birthdate
      code += encode_birthplace
      code += utils.encode_cin code
      code
    end

    private

      attr_accessor :surname,
                    :name,
                    :gender,
                    :birthdate,
                    :birthplace,
                    :utils

      def encode_surname
        str        = utils.slugged(surname).chars
        consonants = utils.extract_consonants str
        vowels     = utils.extract_vowels str
        "#{consonants[0..2]}#{vowels[0..2]}XXX"[0..2].upcase
      end

      def encode_name
        str        = utils.slugged(name).chars
        consonants = utils.extract_consonants str
        vowels     = utils.extract_vowels str

        if consonants.length > 3
          arr = consonants.dup.chars
          arr.delete_at 1
          consonants = arr.join
        end

        "#{consonants[0..2]}#{vowels[0..2]}XXX"[0..2].upcase
      end

      def encode_birthdate
        year  = birthdate.year.to_s[2..-1]
        month = utils.months[birthdate.month - 1]
        day   = format "%02d", (birthdate.day + (gender == "F" ? 40 : 0))
        "#{year}#{month}#{day}"
      end

      def encode_birthplace
        utils.municipalities.find do |m|
          utils.slugged(m["name"]) == utils.slugged(birthplace)
        end.try(:[], "code")
      end

      def parsed_date(date)
        case date.class.name
        when "Date", "Time", "DateTime" then date
        else Date.parse(date)
        end
      end
  end
end