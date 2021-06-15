Medium.all.each do |m|
  next if m.video.nil?
  case m.provider
  when 'youtube'
    m.embed = "//www.youtube.com/embed/#{m.video}";
    puts m.embed
    m.video_provider = 'youtube'
    m.save
  when 'vimeo'
    m.embed = "//player.vimeo.com/video/#{m.video}"
    m.video_provider = 'vimeo'
    m.save
  end
end

media = Medium.all.map(&:id)

media.each do |m|
  puts m
  Apartment::Tenant.switch! 'july-22nd'
  medium = Medium.find(m)
  if !medium.file.attached?
    medium.delete
  end
end

# Medium.all.each do |m|
#   if File.exist?(m.original_image.path) && !m.file.attached?
#     m.file.attach(io: File.open(m.original_image.path), filename: m.original_image.path.split('/').last)
#   else
#     m.delete
#   end
# end

ActiveStorage::Blob.service.send(:path_for, m.public_send("#{Apartment::Tenant.current.underscore}_file").key)
Apartment::Tenant.switch! 'july-22nd'
ids = Medium.all.map(&:id)
ids.each do |id|
  Apartment::Tenant.switch! 'july-22nd'
  m = Medium.find(id)

  next if m.public_send("#{Apartment::Tenant.current.underscore}_file").attached?

  next unless m.file.attached?

  next unless File.exists? ActiveStorage::Blob.service.send(:path_for, m.file.key)
Apartment::Tenant.switch! 'july-22nd'
  m.public_send("#{Apartment::Tenant.current.underscore}_file").attach(
    io: File.open(ActiveStorage::Blob.service.send(:path_for, m.file.key)),
    filename: m.file.filename.to_s,
    content_type: m.file.content_type
  )
  Apartment::Tenant.switch! 'july-22nd'
end

Apartment::Tenant.switch! 'july-22nd'
ids = MapIcon.all.map(&:id)
ids.each do |id|
  Apartment::Tenant.switch! 'july-22nd'
  m = MapIcon.find(id)
  next unless m.file.attached?

  next unless File.exists? ActiveStorage::Blob.service.send(:path_for, m.file.key)

  m.public_send("#{Apartment::Tenant.current.underscore}_file").attach(
    io: File.open(ActiveStorage::Blob.service.send(:path_for, m.file.key)),
    filename: m.file.filename.to_s,
    content_type: m.file.content_type
  )
end