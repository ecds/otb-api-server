# frozen_string_literal: true

class ProcessMediumVariantsJob < ApplicationJob
  queue_as :default

  # Jobs don't inherit the request's Apartment tenant, so it must be passed in.
  def perform(tenant:, id:)
    Apartment::Tenant.switch(tenant) do
      medium = Medium.find_by(id:)
      next unless medium&.file&.attached?

      Medium::VARIANT_SIZES.each_key { |name| medium.variant_url(name) }
      medium.store_lqip_data!
    end
  end
end
