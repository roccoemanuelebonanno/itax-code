# frozen_string_literal: true

require "./lib/itax_code/version"
require "./lib/itax_code/utils"
require "./lib/itax_code/encoder"
require "./lib/itax_code/parser"
require "./lib/itax_code/error"

module ItaxCode
  class << self
    # Encodes the user tax code.
    #
    # @param [Hash] data The user attributes
    #
    # @option data [String]       :surname
    # @option data [String]       :name
    # @option data [String]       :gender
    # @option data [String, Date] :birthdate
    # @option data [String]       :birthplace
    #
    # @return [String]
    def encode(data)
      Encoder.new(data).encode
    end

    # Decodes the tax code in its components.
    #
    # @param [String] tax_code The user tax code
    #
    # @return [Hash]
    def decode(tax_code)
      Parser.new(tax_code).decode
    end

    # Checks the given tax code validity.
    #
    # @param [String] tax_code The user tax code
    #
    # @return [Boolean]
    def valid?(tax_code)
      decode(tax_code)
      true
    rescue Parser::Error
      false
    end
  end
end
