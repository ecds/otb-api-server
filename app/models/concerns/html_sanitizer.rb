
# frozen_string_literal: true

# app/models/concerns/html_saintizer.rb
module HtmlSanitizer
  extend ActiveSupport::Concern

  def self.accessible(text)
    Rails::Html::FullSanitizer.new.sanitize(text).to_s.gsub(/([A-z]\.)([A-z])/, '\1 \2')
  end

  def self.accessible_truncated(text)
    self.accessible(text).truncate(140)
  end
end
