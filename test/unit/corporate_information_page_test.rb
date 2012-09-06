require "test_helper"

class CorporateInformationPageTest < ActiveSupport::TestCase

  def self.should_be_invalid_without(type, attribute_name)
    test "#{type} should be invalid without #{attribute_name}" do
      document = build(type, attribute_name => nil)
      refute document.valid?
    end
  end

  should_be_invalid_without(:corporate_information_page, :type)
  should_be_invalid_without(:corporate_information_page, :body)
  should_be_invalid_without(:corporate_information_page, :organisation)

  test "should be invalid if same type already exists for this organisation" do
    organisation = create(:organisation)
    first = create(:corporate_information_page, 
      type: CorporateInformationPageType::TermsOfReference, 
      organisation: organisation)
    second = build(:corporate_information_page, 
      type: CorporateInformationPageType::TermsOfReference, 
      organisation: organisation)
    refute second.valid?
  end

  test "should be valid if same type already exists for another organisation" do
    first = create(:corporate_information_page, 
      type: CorporateInformationPageType::TermsOfReference, 
      organisation: create(:organisation))
    second = build(:corporate_information_page, 
      type: CorporateInformationPageType::TermsOfReference, 
      organisation: create(:organisation))
    assert second.valid?
  end

  test "should derive title from type" do
    corporate_information_page = build(:corporate_information_page, type: CorporateInformationPageType::TermsOfReference)
    assert_equal "Terms of reference", corporate_information_page.title
  end

  test "should derive slug from type" do
    corporate_information_page = build(:corporate_information_page, type: CorporateInformationPageType::TermsOfReference)
    assert_equal "terms-of-reference", corporate_information_page.slug
  end
end