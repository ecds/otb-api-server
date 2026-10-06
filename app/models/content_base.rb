# frozen_string_literal: true

class ContentBase < ApplicationRecord
  self.abstract_class = true
  class_attribute :html_fields, default: ['description']

  before_save :enforce_content_accessibility

  # Search data for a sorted media join list (tour_media / stop_media). Only
  # the first item, the one a gallery shows on load, carries the inline lqip.
  def media_search_data(joins)
    sorted = joins.sort_by(&:position)
    sorted.each_with_index.map do |join, index|
      data = join.search_data
      index.zero? && join.medium&.lqip_data ? data.merge(lqip_data: join.medium.lqip_data) : data
    end
  end

  def enforce_content_accessibility
    html_fields.each do |field|
      self[field] = HtmlAccessibilityEnforcer.process(self[field])
    end
  end
end
