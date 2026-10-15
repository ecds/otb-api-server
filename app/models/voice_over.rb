# frozen_string_literal: true

# Audio narration attached to either a Tour or a Stop, in a given language.
class VoiceOver < ApplicationRecord
  include Searchable

  AUDIO_CONTENT_TYPES = [
    'audio/mpeg',
    'audio/mp4',
    'audio/x-m4a',
  ].freeze

  belongs_to :tour, optional: true
  belongs_to :stop, optional: true

  has_one_attached :file

  validates :language, presence: true
  validates :language, uniqueness: { scope: [:tour_id, :stop_id] }
  validates :file, content_type: {
    in: AUDIO_CONTENT_TYPES,
    message: 'must be an MP3 or M4A audio file',
  }
  validate :belongs_to_exactly_one_parent

  def search_data
    {
      id:,
      source_url: "#{Rails.application.routes.default_url_options[:host]}/#{Apartment::Tenant.current}/v4/public/media/#{CGI.escape(file.key || "")}",
      language:,
      filename: file.filename.to_s,
    }
  end

  private

  def belongs_to_exactly_one_parent
    return if tour.present? ^ stop.present?

    errors.add(:base, 'must belong to exactly one of tour or stop')
  end
end
