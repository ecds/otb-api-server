# frozen_string_literal: true

# Public-schema cache for Open Geographies media records. Keyed by the OG
# UUID so the same record isn't resolved more than once across all tenants.
class OpenGeographiesMedium < ApplicationRecord
  CACHE_TTL = 30.days
  # A lookup that found no thumbnail (a timeout, a provider refusing the
  # request) is tried again sooner.
  MISSING_THUMBNAIL_TTL = 1.hour

  validates :uuid, presence: true, uniqueness: true

  def stale?
    updated_at < (thumbnail_url.blank? ? MISSING_THUMBNAIL_TTL : CACHE_TTL).ago
  end
end
