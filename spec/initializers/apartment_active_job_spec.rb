# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(ApartmentActiveJob) do
  let(:tour_set) { create(:tour_set) }
  let(:ran_in) { [] }

  # Records which schema it ran in.
  let(:job_class) do
    log = ran_in
    Class.new(ApplicationJob) do
      define_method(:perform) { log << Apartment::Tenant.current }
    end
  end

  before { stub_const('TenantProbeJob', job_class) }
  after { Apartment::Tenant.reset }

  # Serialize in one tenant and run from another, like Sidekiq does.
  def run_from_public(job)
    data = job.serialize
    Apartment::Tenant.switch!('public')
    ActiveJob::Base.execute(data)
  end

  it 'records the tenant current when the job is created' do
    Apartment::Tenant.switch!(tour_set.subdir)
    expect(TenantProbeJob.new.serialize['apartment_tenant']).to(eq(tour_set.subdir))
  end

  it 'runs the job in the tenant it was enqueued from' do
    Apartment::Tenant.switch!(tour_set.subdir)
    run_from_public(TenantProbeJob.new)
    expect(ran_in).to(eq([tour_set.subdir]))
  end

  it 'leaves the worker in its previous tenant afterwards' do
    Apartment::Tenant.switch!(tour_set.subdir)
    run_from_public(TenantProbeJob.new)
    expect(Apartment::Tenant.current).to(eq('public'))
  end

  it 'runs jobs enqueued before the tenant was recorded as before' do
    Apartment::Tenant.switch!(tour_set.subdir)
    data = TenantProbeJob.new.serialize.except('apartment_tenant')
    Apartment::Tenant.switch!('public')
    ActiveJob::Base.execute(data)
    expect(ran_in).to(eq(['public']))
  end

  it "covers Rails' own ActiveStorage jobs" do
    Apartment::Tenant.switch!(tour_set.subdir)
    blob = create(:medium).file.blob
    expect(ActiveStorage::AnalyzeJob.new(blob).serialize['apartment_tenant']).to(eq(tour_set.subdir))
  end

  it 'analyzes the blob in its own tenant, not a public blob with the same id' do
    Apartment::Tenant.switch!(tour_set.subdir)
    blob = create(:medium).file.blob
    blob.update!(metadata: {})
    run_from_public(ActiveStorage::AnalyzeJob.new(blob))
    Apartment::Tenant.switch!(tour_set.subdir)
    expect(blob.reload).to(be_analyzed)
  end
end
