# frozen_string_literal: true

class ReindexJob < ApplicationJob
  queue_as :searchkick

  def perform(tenant:, class_name:, id:)
    Apartment::Tenant.switch!(tenant)
    model = class_name.constantize
    record = model.find(id)
    record.presence&.reindex
  end
end
