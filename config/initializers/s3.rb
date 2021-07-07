# frozen_string_literal: true

# Aws.config.update({
#   credentials: Aws::Credentials.new(
#     Rails.application.credentials.s3Staging[:access_key_id],
#     Rails.application.credentials.s3Staging[:secret_access_key]
#   )
# })

# Sometimes the service URL expires too quickly.
Rails.application.config.active_storage.service_urls_expire_in = 1.hour
