# frozen_string_literal: true

require 'active_support/inflector'

class String
  def parameterize_intl(separator: '-', preserve_case: false, locale: nil)
    # Replace accented chars with their ASCII equivalents.
    transliterated_string = ActiveSupport::Inflector.transliterate(self, '~', locale: locale)

    parameterized_string = if transliterated_string.include?('~')
      gsub(/[!@#$%^&*()-=_+|;':",.<>?\s']/, separator)
    else
      transliterated_string.gsub(/[^a-z0-9\-_]+/i, separator)
    end

    if separator.present?
      if separator == '_'
        re_duplicate_separator        = /-{2,}/
        re_leading_trailing_separator = /^-|-$/
      else
        re_sep = Regexp.escape(separator)
        re_duplicate_separator        = /#{re_sep}{2,}/
        re_leading_trailing_separator = /^#{re_sep}|#{re_sep}$/
      end
      # No more than one of the separator in a row.
      parameterized_string.gsub!(re_duplicate_separator, separator)
      # Remove leading/trailing separator.
      parameterized_string.gsub!(re_leading_trailing_separator, '')
    end

    parameterized_string.downcase! unless preserve_case
    parameterized_string
  end
end
