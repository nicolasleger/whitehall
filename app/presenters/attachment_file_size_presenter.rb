class AttachmentFileSizePresenter
  include ActiveSupport::NumberHelper

  attr_reader :size

  def initialize(size)
    @size = size
  end

  def to_s
    number_to_human_size(size)
  end

  class Null
    def to_s
      ''
    end
  end
end
