# frozen_string_literal: true

namespace :tenants do
  desc 'Check for duplicate titles across all tenant schemas'
  task check_duplicate_titles: :environment do
    duplicates = {}

    Apartment::Tenant.each do |tenant|
      Apartment::Tenant.switch!(tenant)

      dupes = Tour
        .group('LOWER(title)')
        .having('COUNT(*) > 1')
        .count

      duplicates[tenant] = dupes if dupes.any?
    ensure
      Apartment::Tenant.reset
    end

    if duplicates.empty?
      puts '✓ No duplicates found'
    else
      puts "Duplicates found in #{duplicates.keys.length} tenant(s):"
      duplicates.each do |tenant, dupes|
        puts "\n  #{tenant}:"
        dupes.each { |title, count| puts "    '#{title}' × #{count}" }
      end
      exit 1
    end
  end
end
