# frozen_string_literal: true

# Single place responsible for keeping Elasticsearch in sync with a record
# after a write. Cascades to whichever Tour(s) the record belongs to when the
# record itself isn't Searchkick-indexed (e.g. join models like StopMedium).
class ReindexService
  class << self
    # For requests: queue the reindexing instead of doing it inline, since
    # rebuilding a tour loads every stop and medium in it. Searchable records
    # already queue their own job after commit (see Searchable); join records
    # need their tours queued here.
    def enqueue(record)
      return unless record

      tenant = Apartment::Tenant.current
      if record.destroyed?
        # Cheap for a deleted record: it's only removed from the index. Its
        # tours are found now, while the join still knows them.
        record.reindex if record.respond_to?(:reindex)
        tours_for(record).each { |tour| ReindexJob.perform_later(tenant:, class_name: 'Tour', id: tour.id) }
      elsif !record.class.include?(Searchable)
        ReindexJob.perform_later(tenant:, class_name: record.class.name, id: record.id)
      end
    rescue StandardError => e
      Rails.logger.error("ReindexService could not queue #{record.class}##{record.id}: #{e.message}")
    end

    def call(record)
      return unless record

      preloaded(record).reindex if record.respond_to?(:reindex)
      tours_for(record).each { |tour| preloaded(tour).reindex }
    rescue StandardError => e
      Rails.logger.error("ReindexService failed for #{record.class}##{record.id}: #{e.message}")
    end

    # Searchkick indexes the object it's given (it only applies search_import
    # for bulk/async reindexes), so reload through search_import here to avoid
    # building search_data with N+1 queries.
    def preloaded(record)
      return record unless record.class.respond_to?(:search_import)

      record.class.search_import.find_by(id: record.id) || record
    end

    def tours_for(record)
      return record.tours if record.respond_to?(:tours)
      return [record.tour] if record.respond_to?(:tour) && record.tour
      return record.stop.tours if record.respond_to?(:stop) && record.stop

      []
    end
  end
end
