class RenameSite
  def rename_site(old_name, new_name)
    Apartment::Tenant.switch! "public"
    ActiveRecord::Base.transaction do
      # 1. Rename the schema
      ActiveRecord::Base.connection.execute(
        "ALTER SCHEMA \"#{old_name}\" RENAME TO \"#{new_name}\""
      )

      # 2. Update the tenant record
      TourSite.find_by!(subdir: old_name).update!(subdomain: new_name)
    end
  end
end
