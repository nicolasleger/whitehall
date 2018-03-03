require 'test_helper'
require 'capybara/rails'

class AttachmentDeletionIntegrationTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL
  include Capybara::DSL
  include Rails.application.routes.url_helpers

  let(:filename) { 'sample.docx' }
  let(:file) { File.open(path_to_attachment(filename)) }
  let(:attachment) { build(:file_attachment, attachable: attachable, file: file) }
  let(:asset_id) { 'asset-id' }

  before do
    create(:government)
    login_as(user)
    attachable.attachments << attachment
    stub_whitehall_asset(filename, id: asset_id)
    VirusScanHelpers.simulate_virus_scan
  end

  context 'given a draft document with a file attachment' do
    let(:user) { create(:managing_editor) }
    let(:edition) { create(:news_article) }
    let(:attachable) { edition }

    before do
      setup_publishing_api_for(edition)

      visit admin_news_article_path(edition)
      click_link 'Modify attachments'
      @attachment_url = find('.existing-attachments a', text: filename)[:href]
    end

    context 'when attachment is deleted' do
      before do
        visit admin_news_article_path(edition)
        click_link 'Modify attachments'
        within '.existing-attachments' do
          click_link 'Delete'
        end
        assert_text 'Attachment deleted'
      end

      it 'responds with 404 Not Found for attachment URL' do
        logout

        assert_raises(ActiveRecord::RecordNotFound) do
          get @attachment_url
        end
      end

      it 'deletes attachment in Asset Manager' do
        Services.asset_manager.expects(:delete_asset)
          .with(asset_id)
        AssetManagerDeleteAssetWorker.drain
      end
    end

    context 'when draft document is discarded' do
      before do
        visit admin_news_article_path(edition)
        click_button 'Discard draft'
      end

      it 'responds with 404 Not Found for attachment URL' do
        logout

        assert_raises(ActiveRecord::RecordNotFound) do
          get @attachment_url
        end
      end

      it 'deletes attachment in Asset Manager' do
        Services.asset_manager.expects(:delete_asset)
          .with(asset_id)
        AssetManagerDeleteAssetWorker.drain
      end
    end

    context 'when draft document is published and a new draft is created' do
      before do
        visit admin_news_article_path(edition)
        force_publish_document

        visit admin_news_article_path(edition)
        click_button 'Create new edition to edit'

        fill_in 'Public change note', with: 'testing'
        click_button 'Save'
        assert_text 'The document has been saved'
      end

      context 'when attachment is deleted' do
        let(:new_edition) { edition.latest_edition }

        before do
          visit admin_news_article_path(new_edition)
          click_link 'Modify attachments'
          within '.existing-attachments' do
            click_link 'Delete'
          end
          assert_text 'Attachment deleted'
        end

        it 'responds with 200 OK for attachment URL' do
          logout

          get @attachment_url
          assert_response :success
        end

        it 'does not delete attachment in Asset Manager' do
          Services.asset_manager.expects(:delete_asset)
            .with(asset_id).never
          AssetManagerDeleteAssetWorker.drain
        end

        context 'when draft document is published and a new draft is created' do
          before do
            visit admin_news_article_path(new_edition)
            force_publish_document
          end

          it 'responds with 404 Not Found for attachment URL' do
            logout

            assert_raises(ActiveRecord::RecordNotFound) do
              get @attachment_url
            end
          end

          it 'deletes attachment in Asset Manager' do
            Services.asset_manager.expects(:delete_asset)
              .with(asset_id)
            AssetManagerDeleteAssetWorker.drain
          end
        end
      end
    end
  end

  context 'given a policy group with a file attachment' do
    let(:user) { create(:gds_editor) }
    let(:policy_group) { create(:policy_group) }
    let(:attachable) { policy_group }

    before do
      visit admin_policy_group_attachments_path(policy_group)
      @attachment_url = find('.existing-attachments a', text: filename)[:href]
    end

    context 'when attachment is deleted' do
      before do
        visit admin_policy_group_attachments_path(policy_group)
        within '.existing-attachments' do
          click_link 'Delete'
        end
        assert_text 'Attachment deleted'
      end

      it 'responds with 404 Not Found for attachment URL' do
        logout

        assert_raises(ActiveRecord::RecordNotFound) do
          get @attachment_url
        end
      end

      it 'deletes attachment in Asset Manager' do
        Services.asset_manager.expects(:delete_asset)
          .with(asset_id)
        AssetManagerDeleteAssetWorker.drain
      end
    end

    context 'when policy group is deleted' do
      before do
        visit admin_policy_groups_path
        within record_css_selector(policy_group) do
          click_button 'Delete'
        end
        assert_text %{"#{policy_group.name}" deleted.}
      end

      it 'responds with 404 Not Found for attachment URL' do
        logout

        get @attachment_url
        assert_response :not_found
      end
    end
  end

private

  def ends_with(expected)
    ->(actual) { actual.end_with?(expected) }
  end

  def setup_publishing_api_for(edition)
    publishing_api_has_links(
      content_id: edition.document.content_id,
      links: {}
    )
    publishing_api_has_linkables([], document_type: "topic")
  end

  def path_to_attachment(filename)
    fixture_path.join(filename)
  end

  def stub_whitehall_asset(filename, attributes = {})
    url_id = "http://asset-manager/assets/#{attributes[:id]}"
    Services.asset_manager.stubs(:whitehall_asset)
      .with(&ends_with(filename))
      .returns(attributes.merge(id: url_id).stringify_keys)
  end

  def force_publish_document
    click_link 'Force publish'
    fill_in 'Reason for force publishing', with: 'testing'
    click_button 'Force publish'
    assert_text %r{The document .* has been published}
  end
end
