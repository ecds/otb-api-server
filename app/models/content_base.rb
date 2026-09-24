# frozen_string_literal: true

class ContentBase < ApplicationRecord
  self.abstract_class = true
  class_attribute :html_fields, default: ['description']

  before_save :enforce_content_accessibility

  def enforce_content_accessibility
    html_fields.each do |field|
      self[field] = HtmlAccessibilityEnforcer.process(self[field])
    end
  end
end
