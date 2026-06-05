# frozen_string_literal: true

module V4
  module Public
    class MediaController < V4Controller
      def show
        return 404 if @record.nil?

        if params[:variant]
          redirect_to(@record.files[params[:variant].to_sym], allow_other_host: true)
        else
          redirect_to(@record.file.blob.url, allow_other_host: true)
        end
      end

      private

      def set_record
        blob = ActiveStorage::Blob.find_by(key: params[:key])
        @record = ActiveStorage::Attachment.find_by(blob:)&.record
      end
    end
  end
end
