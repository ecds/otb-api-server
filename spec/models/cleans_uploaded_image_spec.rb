# frozen_string_literal: true

require 'rails_helper'
require 'vips'

RSpec.describe(CleansUploadedImage) do
  let(:dir) { Rails.root.join('tmp/cleans_uploaded_image') }
  let(:gps_tags) { { 'exif-ifd3-GPSLatitudeRef' => 'N', 'exif-ifd3-GPSLatitude' => '33/1 44/1 0/1' } }

  before { FileUtils.mkdir_p(dir) }
  after { FileUtils.rm_rf(dir) }

  # A small image with the given EXIF string tags, saved as `name`.
  def image_file(name, width: 40, height: 20, tags: {})
    image = Vips::Image.black(width, height, bands: 3).copy(interpretation: :srgb)
    image = image.mutate { |m| tags.each { |tag, value| m.set_type!(GObject::GSTR_TYPE, tag, value) } }
    path = dir.join(name).to_s
    image.write_to_file(path)
    path
  end

  def upload(path, content_type)
    Rack::Test::UploadedFile.new(path, content_type)
  end

  def create_medium(file)
    medium = build(:medium, base_sixty_four: nil, filename: File.basename(file.original_filename))
    medium.file.attach(file)
    medium.save!
    medium.reload
  end

  def stored(medium)
    Vips::Image.new_from_buffer(medium.file.download, '')
  end

  def gps?(image)
    image.get_fields.any? { |field| field.start_with?('exif-ifd3-') }
  end

  it 'converts an iPhone HEIC photo to JPEG' do
    # A committed file: CI's libheif can decode HEIC but has no encoder to
    # make one, and decoding is all production needs.
    heic = Rails.root.join('spec/fixtures/files/IMG_0001.heic').to_s
    medium = create_medium(upload(heic, 'image/heic'))
    expect(medium.file.content_type).to(eq('image/jpeg'))
    expect(medium.file.filename.to_s).to(eq('IMG_0001.jpg'))
    expect(medium.filename).to(eq('IMG_0001.jpg'))
    expect(stored(medium).get('vips-loader')).to(start_with('jpeg'))
  end

  it 'removes GPS coordinates from a JPEG' do
    path = image_file('photo.jpg', tags: gps_tags)
    expect(gps?(Vips::Image.new_from_file(path))).to(be(true))

    medium = create_medium(upload(path, 'image/jpeg'))
    expect(gps?(stored(medium))).to(be(false))
    expect(medium.file.content_type).to(eq('image/jpeg'))
  end

  it 'turns a sideways photo upright before removing its orientation tag' do
    # libvips writes the EXIF orientation from its own `orientation` field.
    path = dir.join('sideways.jpg').to_s
    Vips::Image.black(40, 20, bands: 3).copy(interpretation: :srgb)
      .mutate { |m| m.set_type!(GObject::GINT_TYPE, 'orientation', 6) }
      .write_to_file(path)
    expect(Vips::Image.new_from_file(path).get('orientation')).to(eq(6))

    image = stored(create_medium(upload(path, 'image/jpeg')))
    expect([image.width, image.height]).to(eq([20, 40]))
  end

  it 'stores an image without location or rotation as uploaded' do
    path = image_file('plain.png')
    medium = create_medium(upload(path, 'image/png'))
    expect(medium.file.download).to(eq(File.binread(path)))
  end

  it 'cleans a replacement image on an existing medium' do
    medium = create_medium(upload(image_file('plain.png'), 'image/png'))
    medium.update!(file: upload(image_file('replacement.jpg', tags: gps_tags), 'image/jpeg'))
    expect(gps?(stored(medium.reload))).to(be(false))
  end

  it 'leaves a file it cannot read for validation to reject' do
    path = dir.join('notes.heic').to_s
    File.write(path, 'not an image')
    medium = build(:medium, base_sixty_four: nil, filename: 'notes.heic')
    medium.file.attach(upload(path, 'image/heic'))
    expect(medium).not_to(be_valid)
  end
end
