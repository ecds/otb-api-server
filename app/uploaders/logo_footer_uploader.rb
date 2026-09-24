# frozen_string_literal: true

# app/uploarder/medium_uploader.rb

class LogoFooterUploader < LogoUploader
  # process :dimensions

  before :cache, :dimensions # callback, example here: http://goo.gl/9VGHI

  private

  def dimensions
    return unless file && model

    model.footer_width, model.footer_height = ::MiniMagick::Image.open(file.file)[:dimensions]
  end
end
