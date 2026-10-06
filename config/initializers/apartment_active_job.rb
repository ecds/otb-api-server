# frozen_string_literal: true

# Jobs run in Sidekiq, outside any request, so they start in the default
# (public) schema. Record the Apartment tenant when a job is created and switch
# back to it when the job runs. This covers every ActiveJob, including Rails'
# own ActiveStorage jobs (AnalyzeJob, PurgeJob, ...), whose arguments are only
# a global ID with no tenant in it.
module ApartmentActiveJob
  TENANT_KEY = 'apartment_tenant'

  attr_accessor :apartment_tenant

  def initialize(...)
    super
    @apartment_tenant = Apartment::Tenant.current
  end

  def serialize
    super.merge(TENANT_KEY => apartment_tenant)
  end

  def deserialize(job_data)
    super
    # Jobs enqueued before this existed have no tenant; they run as before.
    self.apartment_tenant = job_data[TENANT_KEY]
  end

  # Wraps perform_now, not around_perform: arguments (and their GlobalID
  # lookups, e.g. AnalyzeJob's blob) are deserialized before perform callbacks.
  def perform_now
    return super if apartment_tenant.blank?

    Apartment::Tenant.switch(apartment_tenant) { super }
  end
end

ActiveSupport.on_load(:active_job) do
  prepend(ApartmentActiveJob)
end
