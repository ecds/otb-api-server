# frozen_string_literal: true

# Base class for models.
class MediumBaseRecord < ApplicationRecord
  self.abstract_class = true
  before_create :attach_file

  has_one_attached "#{Apartment::Tenant.current.underscore}_file"

  def tmp_file_path
    return Rails.root.join('public', 'storage', 'tmp', title) if self.title
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

    headers, self.base_sixty_four = base_sixty_four.split(',')
    headers =~ /^data:(.*?)$/
    content_type = Regexp.last_match(1).split(';base64').first
    File.open(tmp_file_path, 'wb') do |f|
      f.write(Base64.decode64(base_sixty_four))
    end

    self.public_send("#{Apartment::Tenant.current.underscore}_file").attach(
      io: File.open(tmp_file_path),
      filename: title,
      content_type: content_type
    )
  end

  def remove_tmp_file
    nil
  end
end