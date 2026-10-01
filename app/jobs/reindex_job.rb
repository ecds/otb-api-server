# frozen_string_literal: true

class ReindexJob < ApplicationJob
  queue_as :searchkick

  def perform(tenant:, class_name:, id:)
    Apartment::Tenant.switch!(tenant)
    model = class_name.constantize
    ReindexService.call(model.find_by(id:))
  end
end
