class PersonImageUploader < ImageUploader
  storage :asset_manager_and_quarantined_file_storage
end
