# frozen_string_literal: true

module V4
  module Public
    class MediaController < V4Controller
      def show
        return head(:not_found) if @record.nil?

        url = params[:variant] ? @record.files[params[:variant].to_sym] : @record.file.blob.url
        # A size that isn't made yet (the variants job runs after upload) or
        # doesn't exist. The admin retries a 404 until it's ready.
        return head(:not_found) if url.blank?

        redirect_to(url, allow_other_host: true)
      end

      private

      def set_record
        blob = ActiveStorage::Blob.find_by(key: params[:key])
        @record = ActiveStorage::Attachment.find_by(blob:)&.record
      end
    end
  end
end
