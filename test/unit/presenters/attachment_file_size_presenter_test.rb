require "test_helper"

class AttachmentFileSizePresenterTest < ActiveSupport::TestCase
  setup do
    @presenter = AttachmentFileSizePresenter.new(1024)
  end

  test '#to_s returns a friendly string representation of the file size' do
    assert_equal '1KB', @presenter.to_s
  end
end
