# frozen_string_literal: true

# Model class for tour sets. This is the main model for "instances" of Open Tour Builder.
class TourSet < ApplicationRecord
  before_save :set_subdir
  before_save :attach_file
  after_create :create_tenant
  after_create :create_defaults
  before_destroy :drop_tenant

  validates :name, presence: true, uniqueness: true

  has_one_attached 'logo'

  has_many :tour_set_admins
  has_many :admins, through: :tour_set_admins, source: :user

  attr_accessor :published_tours

  def published_tours
    begin
      Apartment::Tenant.switch! self.subdir
      tours = []
      Tour.published.has_stops.each do |t|
        tour = {
          title: t.title,
          slug: t.slug
        }
        tours.push(tour)
      end
      tours
    rescue Apartment::TenantNotFound => error
      # self.delete
    end
  end

  def mapable_tours
    begin
      Apartment::Tenant.switch! self.subdir
      tours = []
      Tour.published.has_stops.mapable.each do |t|
        tour = {
          title: t.title,
          slug: t.slug,
          center: { lat: t.bounds[:centerLat], lng: t.bounds[:centerLng] }
        }
        tours.push(tour)
      end
      tours
    rescue Apartment::TenantNotFound => error
      # self.delete
    end
  end

  def logo_url
    Apartment::Tenant.switch! 'public'
    begin
      return logo.url if logo.attached?
    rescue URI::InvalidURIError
      # FIXME: This seems to be a problem when testing?
    end

    nil
  end

  private

    def set_subdir
      self.subdir = name.parameterize
    end

    def create_tenant
      Apartment::Tenant.create(subdir)
      # This is a bit of hack to fake the migrations from the
      # auth engine. Hopfully this will be replaced when we
      # redo the auth engine.
      Apartment::Tenant.reset
      schemas = ActiveRecord::SchemaMigration.all

      schemas.each do |schema|
        Apartment::Tenant.switch!(subdir)
        migration = ActiveRecord::SchemaMigration.find_by_version(schema.version)
        if migration.nil?
          ActiveRecord::SchemaMigration.create(version: schema.version)
        end
      end
    end

    def create_defaults
      # Apartment::Tenant.reset
      # themes = Theme.all.collect(&:title)
      Apartment::Tenant.switch! subdir
      Mode.create([
        { title: 'BICYCLING', icon: 'bicycle' },
        { title: 'DRIVING', icon: 'car' },
        { title: 'TRANSIT', icon: 'subway' },
        { title: 'WALKING', icon: 'walking' }
      ])
      # themes.each do |t|
      #   Theme.create(title: t)
      # end
    end

    def drop_tenant
      Apartment::Tenant.drop(subdir)
    end

    def tmp_file_path
      return nil if logo_title.nil?

      Rails.root.join('public', 'storage', 'tmp', logo_title)
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
      return if base_sixty_four.nil? && !logo.attached?


      return if !self.will_save_change_to_base_sixty_four? && logo.attached?

      if base_sixty_four.nil? && logo.attached?
        logo.purge
      else
        headers, self.base_sixty_four = base_sixty_four.split(',')

        return if base_sixty_four.nil?

        File.open(tmp_file_path, 'wb') do |f|
          f.write(Base64.decode64(base_sixty_four))
        end

        image = MiniMagick::Image.open(tmp_file_path)

        if image[:height] > 80
          image.resize('300x80')
          image.write(tmp_file_path)
        end

        self.logo.attach(
          io: File.open(tmp_file_path),
          filename: logo_title
        )
      end
    end
end
