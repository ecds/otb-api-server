sites = TourSet.all.map(&:subdir)

sites.each do |ts|
  Apartment::Tenant.switch! ts
  reload!
  ids = Medium.all.map(&:id)
  ids.each do |id|
    # Apartment::Tenant.switch! ts
    m = Medium.find(id)
    next if m.video.nil?
    case m.provider
    when 'youtube'
      m.embed = "//www.youtube.com/embed/#{m.video}"
      puts m.embed
      m.video_provider = 'youtube'
      m.save
    when 'vimeo'
      m.embed = "//player.vimeo.com/video/#{m.video}"
      m.video_provider = 'vimeo'
      m.save
    end
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
  # if File.exist?(m.original_image.path) && !m.file.attached?
    # m.file.attach(io: File.open(m.original_image.path), filename: m.original_image.path.split('/').last)
#   else
#     m.delete
#   end
# end

sites = TourSet.all.map(&:subdir)

sites.each do |ts|
  Apartment::Tenant.switch! ts
  reload!
  ids = Medium.all.map(&:id)
  ids.each do |id|
    Apartment::Tenant.switch! ts
    m = Medium.find(id)
    next if m.file.attached?
    if m.original_image.path && File.exist?(m.original_image.path)
      m.file.attach(
        io: File.open(m.original_image.path),
        filename: m.original_image.path.split('/').last,
        content_type: m.original_image.content_type
      )
    end
  end
end

# sites = TourSet.all.map(&:subdir)
# sites.each do |ts|
#   Apartment::Tenant.switch! ts
#     reload!
#     ids = Medium.all.map(&:id)
#     ids.each do |id|
#       m = Medium.find(id)
#       next if m.file.attached?
#       if m.original_image.path && File.exist?(m.original_image.path)
#         m.file.attach(
#           io: File.open(m.original_image.path),
#           filename: m.original_image.path.split('/').last,
#           content_type: m.original_image.content_type
#         )
#       end
#     end
# end

require 'open-uri'
sites = TourSet.all.map(&:subdir)
sites.each do |ts|
  Apartment::Tenant.switch! ts
    reload!
ids = Medium.all.map(&:id)
ids.each do |id|
  m = Medium.find(id)
  next if m.file.attached?
  # if m.original_image.path && File.exist?(m.original_image.path)
    m.file.attach(
      io: URI.open("https://api.opentour.emory.edu#{m.original_image.url}"),
      filename: m.original_image.path.split('/').last,
      content_type: m.original_image.content_type
    )
  # end
end
end

media = [{"id":1,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16315528664.png"},{"id":2,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/315299464.jpg"},{"id":4,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16315585158.jpeg"},{"id":11,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365689809.jpeg"},{"id":8,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16353452580.png"},{"id":9,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16353452967.png"},{"id":15,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365704670.jpeg"},{"id":19,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365748166.jpeg"},{"id":16,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365706674.jpeg"},{"id":17,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365708608.jpeg"},{"id":3,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16315583885.jpeg"},{"id":5,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16315587373.png"},{"id":6,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16341496140.jpeg"},{"id":14,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365694188.png"},{"id":10,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16353454287.jpeg"},{"id":7,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16341498295.png"},{"id":18,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365709114.jpeg"},{"id":12,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365693051.jpeg"},{"id":13,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365693188.jpeg"},{"id":22,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/671271790.jpg"},{"id":21,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/671271790.jpg"},{"id":23,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16442803933.png"},{"id":20,"url":"https://api.opentour.emory.edu/uploads/middle-passage-markers/16365785848.jpeg"}]
ids = media.map {|m| m[:id]}
ids = Medium.all.map(&:id)
ids.each do |id|
  Apartment::Tenant.switch! 'middle-passage-markers'
  m = Medium.find(id)
  m.file.purge
  # next if m.file.attached?
  # if m.original_image.path && File.exist?(m.original_image.path)
  puts "https://api.opentour.emory.edu#{m.original_image.url}"
  m.file.attach(
    io: URI.open("https://api.opentour.emory.edu#{m.original_image.url}"),
    filename: m.original_image.url.split('/').last,
    content_type: m.original_image.content_type
  )
  puts m.original_image.url.split('/').last
  m.filename = m.original_image.url.split('/').last
    m.save!
    puts m.file.attached?
  # end
end


sites = TourSet.all.map(&:subdir)
sites.each do |ts|
  Apartment::Tenant.switch! ts
  reload!
  ids = Medium.all.map(&:id)
  ids.each do |id|
    Apartment::Tenant.switch! ts
    m = Medium.find(id)
    m.file.purge if m.file.attached?
    m.delete
  end
  TourMedium.all.each {|tm| tm.delete}
  StopMedium.all.each {|tm| tm.delete}
end

ActiveStorage::Blob.service.send(:path_for, m.file.key)
Apartment::Tenant.switch! 'july-22nd'
ids = Medium.all.map(&:id)
ids.each do |id|
  Apartment::Tenant.switch! 'july-22nd'
  m = Medium.find(id)

  next if m.file.attached?

  # next unless m.file.attached?

  next unless File.exists? ActiveStorage::Blob.service.send(:path_for, m.file.key)
Apartment::Tenant.switch! 'july-22nd'
  m.file.attach(
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

  m.file.attach(
    io: File.open(ActiveStorage::Blob.service.send(:path_for, m.file.key)),
    filename: m.file.filename.to_s,
    content_type: m.file.content_type
  )
end

User.all.each do |u|
  login = Login.find_by(user_id: u.id)
  u.email = login.identification
  u.save
end

sites = TourSet.all.map(&:subdir)

sites.each do |ts|
  puts ts
  Apartment::Tenant.switch! ts
  Tour.all.each do |t|
    puts t.title
    if t.bounds
      t.is_geo = true
      t.save
    end
  end
end

sites = TourSet.all.map(&:subdir)

sites.each do |ts|
  puts ts
  Apartment::Tenant.switch! ts
  Medium.all.each do |m|
    begin
      next unless m.public_send("#{ts.underscore}_file").present?
      next unless m.public_send("#{ts.underscore}_file").attached?

      m.public_send("#{ts.underscore}_file").purge
    rescue NoMethodError => error
    end
  end
end


sites = TourSet.all.map(&:subdir)
sites.each do |ts|
  Apartment::Tenant.switch! ts
    reload!
    ids = Medium.all.map(&:id)
    ids.each do |id|
      m = Medium.find(id)
      m.save
    end
  end
end

sites = TourSet.all.map(&:subdir)

sites.each do |ts|
  puts ts
  Apartment::Tenant.switch! ts
  Stop.all.each do |s|
    if s.lat
      s.update(lat: s.lat.round(5).to_f, lng: s.lng.round(5).to_f)
    end
    if s.parking_lat
      s.update(parking_lat: s.parking_lat.round(5).to_f, parking_lng: s.parking_lng.round(5).to_f)
    end
    s.save
  end
end

Medium.all.each do |m|
  next unless m.desktop_width.nil?
  m.save
end