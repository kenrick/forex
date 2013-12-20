module Forex
  class TabularRates

    attr_accessor :table, :options, :translations

    COLUMN_LABELS = [:buy_cash, :buy_draft, :sell_cash, :sell_draft]

    DEFAULT_OPTIONS = {
      currency_code: 0,
      buy_cash: 1,
      buy_draft: 2,
      sell_cash: 3,
      sell_draft: 4,
    }

    def initialize(table, options = DEFAULT_OPTIONS, translations = Hash.new)
      @table = table
      @options = options.symbolize_keys
      @translations = translations
    end

    def parse_rates
      currency = options.delete(:currency_code) || 0

      table.css('tr').each_with_object({}) do |tr, currencies|
        cells = tr.css('td')
        return if cells.empty?

        raw_currency_code = Currency.new(cells[currency.to_i].content).to_s
        puts "raw_currency_code=#{raw_currency_code}"
        translated_currency_code  = translations.fetch(raw_currency_code, raw_currency_code)
        currency_code = Currency.new(translated_currency_code)

        next if currencies.has_key?(currency_code.to_s) || currency_code.invalid?

        currency_rates = {
          currency_code.to_s =>
            RowParser.new(cells, options).parse_currency_rates
        }

        currencies.merge!(currency_rates) #if currency_rates
      end
    end

  end

  class RowParser
    NoSuchColumn = Class.new(StandardError)

    attr_accessor :cells, :options

    def initialize(cells, options)
      @cells = cells
      @options = options
    end

    def parse_currency_rates
      TabularRates::COLUMN_LABELS.each_with_object({}) do |column_label, rates|
        next unless rate_column = options[column_label]

        rate_node = cells[rate_column.to_i]
        raise NoSuchColumn, "#{column_label} (#{rate_column}) does not exist in table" unless rate_node

        rates[column_label.to_sym] = Money.new(rate_node.content).value
      end
    end
  end

  class Money

    def initialize(string)
      @string = string
    end

    # converts the currency to it's storage representation
    def value
      value = @string.strip.to_f
      value == 0.0 ? nil : value
    end

  end

  class Currency
    def initialize(string)
      @string = string
    end

    # TODO validate the currency codes via http://www.xe.com/iso4217.php
    def valid?
      @string = to_s # hack
      !@string.blank? && @string.length == 3
    end

    def invalid?
      !valid?
    end

    def to_s
      @string.strip#.
        # Replace currency symbols with letter equivalent
        # TODO go crazy and add the rest http://www.xe.com/symbols.php

        # Remove all non word charactes ([^A-Za-z0-9_])
        # gsub(/\W/,'')

    end
  end
end

