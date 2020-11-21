module ItaxCode
  ##
  # This class handles the parsing logic for TaxCode module.
  #
  # @param [String] tax_code
  #
  # @example
  #
  #   ItaxCode::Parser.new("RSSMRA70A01L726S").decode
  #
  # @return [Hash]

  class Parser
    def initialize(tax_code, utils = Utils.new)
      @tax_code = (tax_code || "").upcase
      @utils    = utils
    end

    ##
    # This method decodes the tax code.
    #
    # @return [Hash]

    def decode
      year        = decode_year
      month       = utils.months.find_index(raw[:birthdate_month]) + 1
      day, gender = decode_day_and_gender
      birthplace  = decode_birthplace

      {
        code: tax_code,
        gender: gender,
        birthdate: [year, month, day].join("-"),
        birthplace: birthplace,
        omocodes: omocodes,
        raw: raw
      }
    end

    private

      attr_accessor :tax_code, :utils

      def raw
        matches = tax_code.scan(utils.regex).flatten

        {
          surname: matches[0],
          name: matches[1],
          birthdate: matches[2],
          birthdate_year: matches[3],
          birthdate_month: matches[4],
          birthdate_day: matches[5],
          birthplace: matches[6],
          cin: matches[7]
        }
      end

      def decode_year
        year = utils.omocodia_decode raw[:birthdate_year]
        year = (Date.today.year.to_s[0..1] + year).to_i
        year -= 100 if year > Date.today.year
        year
      end

      def decode_day_and_gender
        day = utils.omocodia_decode(raw[:birthdate_day]).to_i

        if day > 40
          day -= 40
          [day, "F"]
        else
          [day, "M"]
        end
      end

      def decode_birthplace
        places = utils.municipalities
                      .select { |m| m["code"] == municipality_code }
        place = places.find { |m| !m["name"].include? "soppresso" }
        place = (place.presence || places.last).deep_symbolize_keys
        place[:name] = place[:name].gsub(" (soppresso)", "")
        place
      end

      def municipality_code
        raw[:birthplace][0] + utils.omocodia_decode(raw[:birthplace][1..-1])
      end

      def omocodes
        code_chars = tax_code[0..14].chars
        codes = []

        utils.omocodia_subs_indexes.reverse_each do |i|
          code_chars[i] = utils.omocodia_decode(code_chars[i])
        end

        code = code_chars.join
        code_cin = utils.encode_cin(code)
        code += code_cin
        codes.push(code)

        utils.omocodia_subs_indexes.reverse_each do |i|
          code_chars[i] = utils.omocodia_encode(code_chars[i])
          code = code_chars.join
          code_cin = utils.encode_cin(code)
          code += code_cin
          codes.push(code)
        end

        codes
      end
  end
end