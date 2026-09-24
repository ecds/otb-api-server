# frozen_string_literal: true

class ProcessMediumVariantsJob < ApplicationJob
  queue_as :default

  def perform(medium_id)
    medium = Medium.find_by(id: medium_id)
    return unless medium&.file&.attached?
    return if medium.file.content_type.include?('gif')

    medium.file.variant(resize_to_limit: [5, 5]).processed
    medium.file.variant(resize_to_limit: [300, 300]).processed
    medium.file.variant(resize_to_limit: [400, 400]).processed
    medium.file.variant(resize_to_limit: [750, 750]).processed
  end
end
