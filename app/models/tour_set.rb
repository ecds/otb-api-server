# frozen_string_literal: true

# Model class for tour sets. This is the main model for "instances" of Open Tour Builder.
class TourSet < ApplicationRecord
  include Searchable

  before_save :set_subdir
  before_save :attach_file
  after_create :create_tenant
  after_create :create_defaults
  before_destroy :drop_tenant

  validates :name, presence: true, uniqueness: true

  has_one_attached 'logo'

  has_many :tour_set_admins, dependent: :destroy
  has_many :admins, through: :tour_set_admins, source: :user

  attr_accessor :published_tours

  def published_tours
    Apartment::Tenant.switch!(subdir)
    tours = []
    Tour.published.has_stops.each do |t|
      tour = {
        title: t.title,
        slug: t.slug,
        location: { lat: t.bounds[:centerLat], lng: t.bounds[:centerLng] },
      }
      tours.push(tour)
    end

    Apartment::Tenant.switch!('public')
    tours
  rescue Apartment::TenantNotFound => _e
    logger.warn('Tenant not found.')
  end

  def mapable_tours
    Apartment::Tenant.switch!(subdir)
    tours = []
    Tour.published.has_stops.mapable.each do |t|
      tour = {
        title: t.title,
        slug: t.slug,
        center: { lat: t.bounds[:centerLat], lng: t.bounds[:centerLng] },
      }
      tours.push(tour)
    end

    Apartment::Tenant.switch!('public')
    tours
  rescue Apartment::TenantNotFound => _e
    logger.warn('Tenant not found.')
  end

  def logo_url
    Apartment::Tenant.switch!('public')
    return logo.url if logo.attached?

    nil
  end

  def should_index?
    published_tours.count > 0
  end

  def preview_data
    {
      id:,
      description:,
      external_url:,
      footer_logo:,
      name:,
      logo_url:,
      notes:,
      subdir:,
    }
  end

  def search_data
    {
      **preview_data,
      mapable_tours:,
      published_tours:,
    }
  end

  def admin_data
    {
      **preview_data,
      admins: tour_set_admins.map { |ta| { id: ta.id, display_name: ta.user.display_name || ta.user.email } },
      tour_authors:,
    }
  end

  private

  def set_subdir
    self.subdir = name.parameterize_intl
  end

  def create_tenant
    Apartment::Tenant.create(subdir)
    versions = ActiveRecord::Base.connection.select_values('SELECT version FROM schema_migrations')
    Apartment::Tenant.switch!(subdir)
    versions.each do |version|
      ActiveRecord::Base.connection.execute(
        "INSERT INTO schema_migrations (version) VALUES ('#{version}') ON CONFLICT DO NOTHING"
      )
    end
    Apartment::Tenant.reset
  end

  def create_defaults
    # Apartment::Tenant.reset
    # themes = Theme.all.collect(&:title)
    Apartment::Tenant.switch!(subdir)
    Mode.create([
      { title: 'BICYCLING', icon: 'bicycle' },
      { title: 'DRIVING', icon: 'car' },
      { title: 'TRANSIT', icon: 'subway' },
      { title: 'WALKING', icon: 'walking' },
    ])
    Apartment::Tenant.switch!('public')
    # themes.each do |t|
    #   Theme.create(title: t)
    # end
  end

  def drop_tenant
    Apartment::Tenant.drop(subdir)
  end

  def tmp_file_path
    return if logo_title.nil?

    Rails.root.join('public', 'storage', 'tmp', logo_title)
  end

  #
  # Create and attach file from Base64 string.
  #
  # This should only be called once when a new medium object is created via the API
  # It assumes
  #
  # Some code taken from https://github.com/rootstrap/active-storage-base64/blob/v1.2.0/lib/active_storage_support/base64_attach.rb#L17-L32
  #
  #
  def attach_file
    return if base_sixty_four.nil? && !logo.attached?
    return if !will_save_change_to_base_sixty_four? && logo.attached?

    if base_sixty_four.nil? && logo.attached?
      logo.purge
    else
      _, self.base_sixty_four = base_sixty_four.split(',')

      return if base_sixty_four.nil?

      File.open(tmp_file_path, 'wb') do |f|
        f.write(Base64.decode64(base_sixty_four))
      end

      image = MiniMagick::Image.open(tmp_file_path)

      if image[:height] > 80
        image.resize('300x80')
        image.write(tmp_file_path)
      end

      logo.attach(
        io: File.open(tmp_file_path),
        filename: logo_title,
      )
    end
  end

  def tour_authors
    Apartment::Tenant.switch!(subdir)
    TourAuthor.all.map do |ta|
      user = ta.user.display_name || ta.user.email
      {
        id: ta.id,
        user:,
        tour: ta.tour.title,
      }
    end.sort_by { |ta| ta[:user] }
  end
end
