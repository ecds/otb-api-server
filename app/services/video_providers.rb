# frozen_string_literal: true

# Embedded media providers. Each class knows how to recognize its items in a
# URL, build the iframe URL, and find a thumbnail; natively added media and
# Open Geographies media both use them.
module VideoProviders
  # An item known only by its id, for building URLs without a Medium record.
  Item = Struct.new(:embed_id)

  # Which provider a URL belongs to.
  PATTERNS = {
    'youtube' => /youtube\.com|youtu\.be/,
    'vimeo' => /vimeo\.com/,
    'soundcloud' => /soundcloud\.com/,
    'sketchfab' => /sketchfab\.com|skfb\.ly/,
    'matterport' => /matterport\.com/,
    'morphosource' => /morphosource\.org/,
  }.freeze

  class << self
    # Provider name for a URL, or nil.
    def detect(url)
      PATTERNS.find { |_name, pattern| pattern.match?(url.to_s) }&.first
    end

    # The class for a provider name; Base for anything else.
    def class_for(name)
      {
        'youtube' => Youtube,
        'vimeo' => Vimeo,
        'soundcloud' => Soundcloud,
        'sketchfab' => Sketchfab,
        'matterport' => Matterport,
        'morphosource' => Morphosource,
      }.fetch(name.to_s, Base)
    end
  end
end
