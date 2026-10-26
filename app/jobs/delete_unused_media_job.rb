# frozen_string_literal: true

# Deletes media that aren't used anywhere, along with their files. Each one
# is checked again before it's deleted, so anything added to a tour or stop
# since the request is kept.
class DeleteUnusedMediaJob < ApplicationJob
  queue_as :default

  def perform(tenant:, ids:)
    Apartment::Tenant.switch(tenant) do
      Medium.unused.where(id: ids).find_each(&:destroy)
    end
  end
end
