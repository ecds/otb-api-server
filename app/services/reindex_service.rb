# frozen_string_literal: true

# Single place responsible for keeping Elasticsearch in sync with a record
# after a write. Cascades to whichever Tour(s) the record belongs to when the
# record itself isn't Searchkick-indexed (e.g. join models like StopMedium).
class ReindexService
  class << self
    def call(record)
      return unless record

      record.reindex if record.respond_to?(:reindex)
      tours_for(record).each(&:reindex)
    rescue StandardError => e
      Rails.logger.error("ReindexService failed for #{record.class}##{record.id}: #{e.message}")
    end

    def tours_for(record)
      return record.tours if record.respond_to?(:tours)
      return [record.tour] if record.respond_to?(:tour) && record.tour
      return record.stop.tours if record.respond_to?(:stop) && record.stop

      []
    end
  end
end
