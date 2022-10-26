require "active_support/inflector"

class String
  def parameterize_intl(separator: '-', preserve_case: false, locale: nil)
    # Replace accented chars with their ASCII equivalents.
    transliterated_string = ActiveSupport::Inflector.transliterate(self, replacement = '~', locale: locale)

    parameterized_string = if transliterated_string.include?('~')
      self.gsub(/[!@#$%^&*()-=_+|;':",.<>?\s']/, separator)
    else
      transliterated_string.gsub(/[^a-z0-9\-_]+/i, separator)
    end

    unless separator.nil? || separator.empty?
      if separator == '_'.freeze
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
      parameterized_string.gsub!(re_leading_trailing_separator, ''.freeze)
    end

    parameterized_string.downcase! unless preserve_case
    parameterized_string
  end
end
