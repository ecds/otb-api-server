# frozen_string_literal: true

# Public-schema cache for Open Geographies media records. Keyed by the OG
# UUID so the same record isn't resolved more than once across all tenants.
class OpenGeographiesMedium < ApplicationRecord
  CACHE_TTL = 30.days

  validates :uuid, presence: true, uniqueness: true

  def stale?
    updated_at < CACHE_TTL.ago
  end
end
