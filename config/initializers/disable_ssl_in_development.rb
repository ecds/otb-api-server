# frozen_string_literal: true

Rails.application.configure { config.force_ssl = false } if Rails.env.development?
