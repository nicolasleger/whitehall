module ServiceListeners
  class AttachmentLinkHeaderUpdater
    include Rails.application.routes.url_helpers
    include PublicDocumentRoutesHelper

    attr_reader :attachment, :queue

    def initialize(attachment, queue: nil)
      @attachment = attachment
      @queue = queue
    end

    def update!
      return unless attachment.file?
      attachment_data = attachment.attachment_data
      return unless attachment_data.present?

      # TODO: Fix the problem with this helper method appending .en to the URL
      parent_document_url = public_document_url(attachment.attachable)
      # if (edition = attachment_visibility.visible_edition)
      #   response.headers['Link'] = "<#{public_document_url(edition)}>; rel=\"up\""
      # end

      enqueue_job(attachment_data.file, parent_document_url)
      if attachment_data.pdf?
        enqueue_job(attachment_data.file.thumbnail, parent_document_url)
      end
    end

  private

    def visibility_for(attachment_data)
      AttachmentVisibility.new(attachment_data, _anonymous_user = nil)
    end

    def enqueue_job(uploader, parent_document_url)
      legacy_url_path = uploader.asset_manager_path
      worker.perform_async(legacy_url_path, parent_document_url: parent_document_url)
    end

    def worker
      worker = AssetManagerUpdateAssetWorker
      queue.present? ? worker.set(queue: queue) : worker
    end
  end
end
