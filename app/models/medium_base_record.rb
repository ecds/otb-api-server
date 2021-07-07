# frozen_string_literal: true

# Base class for models.
class MediumBaseRecord < ApplicationRecord
  self.abstract_class = true
  before_create :attach_file
  before_destroy :purge

  # has_one_attached "#{Apartment::Tenant.current.underscore}_file"
  has_one_attached 'file'

  def image_url
    return nil unless file.attached?

    file.service_url
  end

  def tmp_file_path
    return Rails.root.join('public', 'storage', 'tmp', filename) if self.filename
    nil
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

    file.blob.delete if file.attached?

    headers, self.base_sixty_four = base_sixty_four.split(',')
    headers =~ /^data:(.*?)$/
    content_type = Regexp.last_match(1).split(';base64').first
    File.open(tmp_file_path, 'wb') do |f|
      f.write(Base64.decode64(base_sixty_four))
    end

    self.file.attach(
      io: File.open(tmp_file_path),
      filename: filename,
      content_type: content_type
    )
  end

  def remove_tmp_file
    File.delete(tmp_file_path) if File.exists?(tmp_file_path)
  end

  def purge
    remove_tmp_file
    file.blob.delete if file.attached?
  end
end
