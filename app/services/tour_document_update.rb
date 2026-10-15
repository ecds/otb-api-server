# frozen_string_literal: true

# Applies a tour document (the shape the admin loads) in one transaction.
# Only keys that are present are applied, so a partial document is fine.
#
# List entries (stops, flat_pages, media, a stop's media, modes):
#   { relation_id: 4, ...fields }          update that join's record
#   { relation_id: 4, _destroy: true }     unlink (the record itself is kept)
#   { id: 9 }                              link an existing record
# Entries left out of a list are untouched. `position` is only changed when an
# entry includes it. Linking an already-linked record and unlinking a missing
# join are no-ops, so retrying a request is safe. Creating new records and
# uploads stay on their own endpoints.
class TourDocumentUpdate
  class Invalid < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super('invalid tour document')
    end
  end

  TOUR_FIELDS = [
    :title,
    :published,
    :default_lng,
    :map_type,
    :description,
    :meta_description,
    :link_address,
    :link_text,
    :is_geo,
    :restrict_bounds,
    :restrict_bounds_to_overlay,
    :use_directions,
    :blank_map,
    :icon_color,
  ].freeze

  STOP_FIELDS = [
    :title,
    :description,
    :meta_description,
    :direction_intro,
    :direction_notes,
    :article_link,
    :address,
    :lat,
    :lng,
    :parking_address,
    :parking_lat,
    :parking_lng,
  ].freeze

  MEDIUM_FIELDS = [:title, :caption].freeze
  FLAT_PAGE_FIELDS = [:title, :body].freeze
  OVERLAY_FIELDS = [:north, :south, :east, :west, :rotation].freeze

  class << self
    def call(tour, document)
      new(tour, document).call
    end
  end

  def initialize(tour, document)
    @tour = tour
    @doc = document.to_h.deep_symbolize_keys
    @errors = []
  end

  def call
    Tour.transaction do
      sync_stops if @doc.key?(:stops)
      sync_flat_pages if @doc.key?(:flat_pages)
      sync_tour_media if @doc.key?(:media)
      sync_modes if @doc.key?(:modes)
      update_overlay if @doc[:map_overlay].is_a?(Hash)
      assign_tour_fields
      raise Invalid, @errors if @errors.any?

      # Saved last: update_saved_stop_order reads stop order from the DB.
      persist(@tour, 'tour', force: true)
      raise Invalid, @errors if @errors.any?
    end
    @tour
  end

  private

  def assign_tour_fields
    @tour.assign_attributes(@doc.slice(*TOUR_FIELDS))
    @tour.theme_id = @doc.dig(:theme, :id) if @doc.dig(:theme, :id)
    @tour.mode_id = @doc.dig(:mode, :id) if @doc.dig(:mode, :id)
  end

  def sync_modes
    Array(@doc[:modes]).each_with_index do |entry, index|
      mode_id = entry[:id]
      existing = @tour.tour_modes.find_by(mode_id:)
      if entry[:_destroy]
        existing&.destroy!
      elsif existing.nil?
        persist(TourMode.new(tour: @tour, mode_id:), "modes[#{index}]")
      end
    end
  end

  def sync_stops
    sync_joins('stops', @tour.tour_stops, @doc[:stops], :stop_id) do |entry, position|
      TourStop.new(tour: @tour, stop_id: entry[:id], position:)
    end.each do |join, entry, path|
      join.icon_color = entry[:icon_color] if entry.key?(:icon_color) && join.has_attribute?(:icon_color)
      persist(join, path)
      stop = join.stop
      stop.assign_attributes(entry.slice(*STOP_FIELDS))
      persist(stop, path)
      next unless entry.key?(:media)

      sync_media("#{path}.media", stop.stop_media, entry[:media]) do |medium_entry, position|
        StopMedium.new(stop:, medium_id: medium_entry[:id], position:)
      end
    end
  end

  def sync_flat_pages
    sync_joins('flat_pages', @tour.tour_flat_pages, @doc[:flat_pages], :flat_page_id) do |entry, position|
      TourFlatPage.new(tour: @tour, flat_page_id: entry[:id], position:)
    end.each do |join, entry, path|
      page = join.flat_page
      page.assign_attributes(entry.slice(*FLAT_PAGE_FIELDS))
      persist(page, path)
    end
  end

  def sync_tour_media
    sync_media('media', @tour.tour_media, @doc[:media]) do |entry, position|
      TourMedium.new(tour: @tour, medium_id: entry[:id], position:)
    end
  end

  def sync_media(path, joins, entries, &)
    sync_joins(path, joins, entries, :medium_id, &).each do |join, entry, entry_path|
      medium = join.medium
      medium.assign_attributes(entry.slice(*MEDIUM_FIELDS))
      persist(medium, entry_path)
    end
  end

  # Returns [join, entry, path] triples for the caller to update the joined
  # records. `record_key` is the join's foreign key to the linked record
  # (stop_id, medium_id, ...), used to make linking idempotent.
  def sync_joins(path, joins, entries, record_key)
    existing = joins.reload.to_a
    by_id = existing.index_by(&:id)
    next_position = (existing.filter_map(&:position).max || 0) + 1
    results = []

    Array(entries).each_with_index do |entry, index|
      entry_path = "#{path}[#{index}]"

      if entry[:relation_id]
        join = by_id[entry[:relation_id].to_i]
        if entry[:_destroy]
          join&.destroy!
          next
        end
        if join.nil?
          @errors << { path: "#{entry_path}.relation_id", detail: 'does not belong to this tour' }
          next
        end
      else
        join = existing.find { |j| j.public_send(record_key) == entry[:id].to_i }
        join ||= yield(entry, entry[:position] || next_position).tap do
          next_position += 1
        end
      end
      join.position = entry[:position] if entry.key?(:position)

      position = join.position
      created = join.new_record?
      persist(join, entry_path)
      # after_create callbacks on the join models reassign position.
      join.update!(position:) if created && join.persisted? && join.position != position
      results << [join, entry, entry_path]
    end

    results
  end

  def update_overlay
    overlay = @tour.map_overlay
    return unless overlay && overlay.id == @doc[:map_overlay][:id]

    overlay.assign_attributes(@doc[:map_overlay].slice(*OVERLAY_FIELDS))
    persist(overlay, 'map_overlay')
  end

  def persist(record, path, force: false)
    return unless force || record.new_record? || record.changed?
    return if record.save

    record.errors.each do |error|
      @errors << { path: "#{path}.#{error.attribute}", detail: error.message }
    end
  end
end
