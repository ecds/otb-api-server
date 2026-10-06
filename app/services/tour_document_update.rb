# frozen_string_literal: true

# Applies a whole tour document (the shape the admin loads) in one
# transaction. Scalars are assigned when present; any list that is present is
# treated as complete: array order sets join positions, entries without a
# relation_id link an existing record, and joins missing from the list are
# removed (the shared stop/page/medium itself is never deleted). Creating new
# records and uploads stay on the existing endpoints.
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
  OVERLAY_FIELDS = [:north, :south, :east, :west].freeze

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
    @tour.mode_ids = Array(@doc[:modes]).filter_map { |m| m[:id] } if @doc.key?(:modes)
  end

  def sync_stops
    sync_joins('stops', @tour.tour_stops, @doc[:stops]) do |index, entry|
      TourStop.new(tour: @tour, stop_id: entry[:id], position: index + 1)
    end.each do |join, entry, path|
      join.icon_color = entry[:icon_color] if entry.key?(:icon_color) && join.has_attribute?(:icon_color)
      persist(join, path)
      stop = join.stop
      stop.assign_attributes(entry.slice(*STOP_FIELDS))
      persist(stop, path)
      next unless entry.key?(:media)

      sync_media("#{path}.media", stop.stop_media, entry[:media]) do |index, medium_entry|
        StopMedium.new(stop:, medium_id: medium_entry[:id], position: index + 1)
      end
    end
  end

  def sync_flat_pages
    sync_joins('flat_pages', @tour.tour_flat_pages, @doc[:flat_pages]) do |index, entry|
      TourFlatPage.new(tour: @tour, flat_page_id: entry[:id], position: index + 1)
    end.each do |join, entry, path|
      page = join.flat_page
      page.assign_attributes(entry.slice(*FLAT_PAGE_FIELDS))
      persist(page, path)
    end
  end

  def sync_tour_media
    sync_media('media', @tour.tour_media, @doc[:media]) do |index, entry|
      TourMedium.new(tour: @tour, medium_id: entry[:id], position: index + 1)
    end
  end

  def sync_media(path, joins, entries, &)
    sync_joins(path, joins, entries, &).each do |join, entry, entry_path|
      medium = join.medium
      medium.assign_attributes(entry.slice(*MEDIUM_FIELDS))
      persist(medium, entry_path)
    end
  end

  # Returns [join, entry, path] triples for the caller to update the joined
  # records; joins left out of `entries` are destroyed.
  def sync_joins(path, joins, entries)
    existing = joins.reload.index_by(&:id)
    kept = []
    results = []

    Array(entries).each_with_index do |entry, index|
      entry_path = "#{path}[#{index}]"
      join = if entry[:relation_id]
        existing[entry[:relation_id].to_i]
      else
        yield(index, entry)
      end

      if join.nil?
        @errors << { path: "#{entry_path}.relation_id", detail: 'does not belong to this tour' }
        next
      end

      join.position = index + 1
      created = join.new_record?
      persist(join, entry_path)
      # after_create callbacks on the join models reassign position.
      join.update!(position: index + 1) if created && join.persisted? && join.position != index + 1
      kept << join.id
      results << [join, entry, entry_path]
    end

    joins.reject { |join| kept.include?(join.id) }.each(&:destroy!) if @errors.empty?
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
