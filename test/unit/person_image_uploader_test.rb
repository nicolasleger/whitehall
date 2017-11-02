require 'test_helper'

class PersonImageUploaderTest < ActiveSupport::TestCase
  test 'uses the asset manager and quarantined file storage engine' do
    assert_equal Whitehall::AssetManagerAndQuarantinedFileStorage, PersonImageUploader.storage
  end
end
