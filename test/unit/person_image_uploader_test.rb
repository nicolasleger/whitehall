require 'test_helper'

class PersonImageUploaderTest < ActiveSupport::TestCase
  test 'uses the quarantined file storage engine' do
    assert_equal Whitehall::QuarantinedFileStorage, PersonImageUploader.storage
  end
end
