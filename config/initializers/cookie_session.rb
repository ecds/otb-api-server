# frozen_string_literal: true
Rails.application.config.session_store(:cookie_store, key: '_otb_session')
Rails.application.config.action_dispatch.cookies_serializer = :json
