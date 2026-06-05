# frozen_string_literal: true

module ActiveStorageApartmentFix
  extend ActiveSupport::Concern

  def key
    self[:key] ||= "#{Apartment::Tenant.current}/#{self.class.generate_unique_secure_token(length: 28)}"
  end

  class_methods do
    def create_before_direct_upload!(**args)
      Apartment::Tenant.switch(Apartment::Tenant.current) do
        super
      end
    end
  end
end

Rails.application.config.to_prepare do
  ActiveStorage::Blob.prepend(ActiveStorageApartmentFix)

  ActiveRecord::Base.class_eval do
    def self.find_signed!(signed_id, purpose: nil)
      Apartment::Tenant.switch(Apartment::Tenant.current) do
        super
      end
    end
  end
end
