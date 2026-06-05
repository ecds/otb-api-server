# frozen_string_literal: true

# Base class for models.
class MediumBaseRecord < ApplicationRecord
  self.abstract_class = true
  validate :check_content_type

  before_create :attach_file
  before_destroy :purge

  validates :filename, presence: true

  # has_one_attached "#{Apartment::Tenant.current.underscore}_file"
  has_one_attached 'file'

  attr_accessor :content_type

  # def image_url
  #   return nil unless file.attached?

  #   file.url
  # end

  def tmp_file_path
    return Rails.root.join('public', 'storage', 'tmp', filename) if filename

    nil
  end

  def original_image_url
    file.url
  end

  #
  # Create and attach file from Base64 string.
  #
  # This should only be called once when a new medium obeject is created via the API
  # It assumes
  #
  # Some code taken from https://github.com/rootstrap/active-storage-base64/blob/v1.2.0/lib/active_storage_support/base64_attach.rb#L17-L32
  #
  #
  def attach_file
    return if base_sixty_four.nil?

    # file.blob.delete if file.attached?

    parse_base64
    File.open(tmp_file_path, 'wb') do |f|
      f.write(Base64.decode64(base_sixty_four))
      f.rewind
    end

    file.attach(
      io: File.open(tmp_file_path),
      filename: filename,
      content_type: content_type,
    )

    self.base_sixty_four = nil
  end

  def remove_tmp_file
    File.delete(tmp_file_path) if File.exist?(tmp_file_path)
  end

  def purge
    remove_tmp_file
    file.blob.delete if file.attached?
  end

  def check_content_type
    return if base_sixty_four.nil?

    parse_base64

    return if content_type.exclude?('jp2')

    errors.add(:base, 'JPEG 2000 fils are not supported. Please convert the image to a regular JPEG or WebP format.')
  end

  private

  def parse_base64
    if base_sixty_four.include?('data:')
      headers, self.base_sixty_four = base_sixty_four.split(',')
      headers =~ /^data:(.*?)$/
      self.content_type = Regexp.last_match(1).split(';base64').first
    else
      self.content_type = 'image/jpeg'
    end
  end
end
