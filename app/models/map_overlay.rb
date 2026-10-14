# frozen_string_literal: true

#
# Model class for map overlays.
#
class MapOverlay < MediumBaseRecord
  before_save :set_initial_bounds

  belongs_to :tour, optional: true
  belongs_to :stop, optional: true

  delegate :published, to: :tour

  # Places a new overlay inside the tour's bounds so it can be adjusted in the
  # admin. When the image's size is known the box keeps its aspect ratio
  # (in map projection, so it isn't stretched on the map); otherwise it fills
  # the tour's bounds.
  def set_initial_bounds
    return if tour.nil? || tour.stops_bounds.nil? || (tour.stop_count&.< 2)
    return unless [south, north, east, west].all? { |bound| bound.to_f.zero? }

    # Stops only: Tour#bounds would use this overlay, which has no bounds yet.
    box = tour.stops_bounds.slice(:south, :north, :east, :west)
    box = fit_to_aspect(box, image_aspect_ratio) if image_aspect_ratio
    self.south, self.north, self.east, self.west = box.values_at(:south, :north, :east, :west)
  end

  def search_data
    {
      id:,
      east: east.to_f,
      image_url: http_path,
      north: north.to_f,
      south: south.to_f,
      west: west.to_f,
      rotation:,
      width: file.metadata['width'],
      height: file.metadata['height'],
    }
  end

  # private

  # Web Mercator y, in the same units as degrees of longitude. Latitudes are
  # clamped to the projection's limit.
  def mercator_y(lat)
    lat = lat.clamp(-85.05, 85.05)
    Math.log(Math.tan((Math::PI / 4) + (lat * Math::PI / 360))) * 180 / Math::PI
  end

  def mercator_lat(y)
    ((2 * Math.atan(Math.exp(y * Math::PI / 180))) - (Math::PI / 2)) * 180 / Math::PI
  end

  # The largest box with the given width/height ratio that fits inside `box`,
  # centered on it.
  def fit_to_aspect(box, aspect)
    top = mercator_y(box[:north])
    bottom = mercator_y(box[:south])
    width = box[:east] - box[:west]
    height = top - bottom
    return box unless width.positive? && height.positive?

    center_x = (box[:east] + box[:west]) / 2
    center_y = (top + bottom) / 2
    if width / height > aspect
      width = height * aspect
    else
      height = width / aspect
    end

    {
      south: mercator_lat(center_y - (height / 2)),
      north: mercator_lat(center_y + (height / 2)),
      east: center_x + (width / 2),
      west: center_x - (width / 2),
    }
  end

  # Width / height of the image, or nil when it can't be read. Rotation turns
  # the whole box, so it doesn't change the box's shape.
  def image_aspect_ratio
    return @image_aspect_ratio if defined?(@image_aspect_ratio)

    width, height = image_dimensions
    @image_aspect_ratio =
      if width.to_i.positive? && height.to_i.positive?
        width.to_f / height
      end
  end

  # Reads only the image header. Before the first save the file hasn't been
  # uploaded yet, so it's read from the incoming upload.
  def image_dimensions
    attachable = attachment_changes['file']&.attachable
    path = attachable.is_a?(Hash) ? attachable[:io].try(:path) : attachable.try(:path)

    if path
      require 'vips'
      image = Vips::Image.new_from_file(path.to_s)
      return [image.width, image.height]
    end

    return unless file.attached?

    # The admin creates the overlay first and links it to the tour in a
    # second request, before the background analysis has run. Analyze now
    # so the first placement has the image's size.
    file.blob.analyze unless file.blob.analyzed?
    file.blob.metadata.values_at('width', 'height')
  rescue Vips::Error, LoadError, ActiveStorage::Error
    nil
  end
end
