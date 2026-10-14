# frozen_string_literal: true

# Prepares a newly attached image before it's validated and stored:
#
# - HEIC/HEIF (iPhone photos) is converted to JPEG, since only Safari can
#   display it.
# - Metadata is removed, notably EXIF GPS coordinates, which would publish
#   where a photo was taken. The image is turned upright first, because the
#   orientation tag goes with the rest of the metadata.
#
# Other images are stored untouched, so ordinary uploads aren't re-encoded.
# GIFs are skipped: re-saving would lose their animation.
module CleansUploadedImage
  extend ActiveSupport::Concern

  HEIF_LOADERS = ['heifload', 'heifload_buffer', 'heifload_source'].freeze
  # XMP and IPTC can also carry location (place names, coordinates).
  LOCATION_FIELDS = ['xmp-data', 'iptc-data'].freeze
  JPEG_QUALITY = 90

  included do
    # Before validation, so a converted HEIC passes the content type check.
    before_validation :clean_uploaded_image, if: -> { attachment_changes['file'].present? }
  end

  private

  def clean_uploaded_image
    path = uploaded_image_path
    return unless path

    require 'vips'
    image = Vips::Image.new_from_file(path.to_s)
    return if image.get('vips-loader').start_with?('gif')

    heif = HEIF_LOADERS.include?(image.get('vips-loader'))
    return unless heif || needs_cleaning?(image)

    attach_cleaned_image(image, heif)
  rescue Vips::Error, LoadError => e
    # Leave the upload as it is; content type validation still applies.
    Rails.logger.warn("Could not clean uploaded image: #{e.message}")
  end

  def needs_cleaning?(image)
    fields = image.get_fields
    fields.any? { |field| field.start_with?('exif-ifd3-') } || # GPS
      LOCATION_FIELDS.intersect?(fields) ||
      (fields.include?('orientation') && image.get('orientation') > 1)
  end

  def uploaded_image_path
    attachable = attachment_changes['file'].attachable
    attachable.is_a?(Hash) ? attachable[:io].try(:path) : attachable.try(:path)
  end

  def attach_cleaned_image(image, heif)
    image = image.autorot
    format = heif ? '.jpg' : File.extname(uploaded_image_filename).downcase.presence || '.jpg'
    # Kept on the record so it isn't deleted before the upload after commit.
    @cleaned_upload = Tempfile.new(['upload', format], binmode: true)
    write_without_metadata(image, @cleaned_upload.path)

    name = heif ? "#{File.basename(uploaded_image_filename, ".*")}.jpg" : uploaded_image_filename
    # Assigned rather than attached: attach saves a persisted record at once.
    self.file = { io: File.open(@cleaned_upload.path), filename: name, content_type: heif ? 'image/jpeg' : nil }.compact
    self.filename = name if has_attribute?(:filename)
  end

  def uploaded_image_filename
    attachable = attachment_changes['file'].attachable
    name = attachable.is_a?(Hash) ? attachable[:filename] : attachable.try(:original_filename)
    name.presence || filename.presence || 'image'
  end

  # libvips 8.15+ can keep just the color profile. Older versions (Debian
  # bookworm ships 8.14) can only strip everything, so convert to sRGB first
  # to keep wide-gamut iPhone colors from looking dull.
  def write_without_metadata(image, path)
    options = path.end_with?('.jpg', '.jpeg') ? { Q: JPEG_QUALITY } : {}
    if Vips.at_least_libvips?(8, 15)
      image.write_to_file(path, **options, keep: :icc)
    else
      image = image.icc_transform('srgb') if image.get_fields.include?('icc-profile-data')
      image.write_to_file(path, **options, strip: true)
    end
  end
end
