class FileAttachment < Attachment
  include HasContentId

  delegate :url, :content_type, :pdf?, :csv?, :opendocument?,
    :file_extension, :file_size,
    :number_of_pages, :file, :filename, :filename_without_extension, :virus_status,
    to: :attachment_data

  after_destroy :destroy_unused_attachment_data

  accepts_nested_attributes_for :attachment_data, reject_if: ->(attributes) { attributes[:file].blank? && attributes[:file_cache].blank? }

  validate :filename_is_unique

  def file?
    true
  end

  def could_contain_viruses?
    false
  end

  def name_for_link
    filename
  end

  def readable_type
    'file'
  end

private

  # Only destroy the associated attachment_data record if no other attachments are using it
  def destroy_unused_attachment_data
    if attachment_data && Attachment.not_deleted.where(attachment_data_id: attachment_data.id).empty?
      attachment_data.destroy
    end
  end

  def filename_is_unique
    if attachable && attachable.attachments.any? { |a| a.file? && a != self && a.filename.downcase == filename.try(:downcase) }
      self.errors[:base] << "This #{attachable_model_name} already has a file called \"#{filename}\""
    end
  end
end
