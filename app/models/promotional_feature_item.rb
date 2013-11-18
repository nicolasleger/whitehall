class PromotionalFeatureItem < ActiveRecord::Base
  LINK_LIMIT = 6

  belongs_to :promotional_feature, inverse_of: :promotional_feature_items
  has_one :organisation, through: :promotional_feature
  has_many :links, class_name: 'PromotionalFeatureLink', dependent: :destroy, inverse_of: :promotional_feature_item

  validates :summary, presence: true, length: { maximum: 500 }
  validates :image, :image_alt_text, presence: true, on: :create
  validates_with ImageValidator, method: :image, size: [960, 640], if: :image_changed?
  validates :title_url, uri: true, allow_blank: true
  validates :links, length: { maximum: LINK_LIMIT, message: "are limited to a maximum of #{LINK_LIMIT}" }

  accepts_nested_attributes_for :links, allow_destroy: true, reject_if: -> attributes { attributes['url'].blank? }

  mount_uploader :image, ImageUploader
end
