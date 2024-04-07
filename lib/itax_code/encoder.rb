# frozen_string_literal: true

module ItaxCode
  # Handles the tax code generation logic.
  #
  # @example
  #   ItaxCode::Encoder.new(
  #     surname: "Rossi",
  #     name: "Mario",
  #     gender: "M",
  #     birthdate: "1980-01-01",
  #     birthplace: "Milano"
  #   ).encode
  #
  # @return [String] The encoded tax code
  class Encoder
    # @param [Hash]  data  The user attributes
    #
    # @option data [String]       :surname    The user first name
    # @option data [String]       :name       The user last name
    # @option data [String]       :gender     The user gender
    # @option data [String, Date] :birthdate  The user birthdate
    # @option data [String]       :birthplace The user birthplace
    def initialize(data = {})
      @surname    = data[:surname]
      @name       = data[:name]
      @gender     = data[:gender]&.upcase
      @birthdate  = data[:birthdate].to_s
      @birthplace = data[:birthplace]
      validate_data_presence!

      @birthdate = parse_birthdate!
    end

    # Computes the tax code from its components.
    #
    # @return [String] The calculated tax code
    def encode
      code  = encode_surname
      code += encode_name
      code += encode_birthdate
      code += encode_birthplace
      code += ItaxCode::Utils.encode_cin code
      code
    end

    private

      attr_accessor :surname, :name, :gender, :birthdate, :birthplace

      def encode_surname
        chars      = ItaxCode::Utils.slugged(surname).chars
        consonants = ItaxCode::Utils.extract_consonants chars
        vowels     = ItaxCode::Utils.extract_vowels chars
        "#{consonants[0..2]}#{vowels[0..2]}XXX"[0..2].upcase
      end

      def encode_name
        chars      = ItaxCode::Utils.slugged(name).chars
        consonants = ItaxCode::Utils.extract_consonants chars
        vowels     = ItaxCode::Utils.extract_vowels chars

        consonants = consonants.chars.values_at(0, 2..consonants.size).join if consonants.length > 3

        "#{consonants[0..2]}#{vowels[0..2]}XXX"[0..2].upcase
      end

      def encode_birthdate
        year  = birthdate.year.to_s[2..-1]
        month = ItaxCode::Utils.months[birthdate.month - 1]
        day   = format "%02d", (birthdate.day + (gender == "F" ? 40 : 0))
        "#{year}#{month}#{day}"
      end

      def encode_birthplace(src = ItaxCode::Utils.cities, stop: false)
        lookup_key = birthplace.match?(/^\w{1}\d{3}$/) ? "code" : "name"
        place_slug = ItaxCode::Utils.slugged(birthplace)
        place_item = src.find { |i| place_slug == ItaxCode::Utils.slugged(i[lookup_key]) }

        code = place_item&.[]("code")
        return code if ItaxCode::Utils.present?(code)
        raise MissingDataError, "no code found for #{birthplace}" if stop

        encode_birthplace(ItaxCode::Utils.countries, stop: true)
      end

      def validate_data_presence!
        instance_variables.each do |ivar|
          next if ItaxCode::Utils.present?(instance_variable_get(ivar))

          raise MissingDataError, "missing #{ivar} value"
        end
      end

      def parse_birthdate!
        Date.parse(birthdate)
      rescue StandardError
        raise InvalidBirthdateError, "#{birthdate} is not a valid date"
      end
  end
end
