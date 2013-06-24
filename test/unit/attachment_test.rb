require_relative '../test_helper'

class AttachmentTest < ActiveSupport::TestCase

  def setup
    @person = FactoryGirl.create(:person)
    @other_person = FactoryGirl.create(:person)
    @message = Message.create_with_attachments(
      {to: @person, person: @other_person,
      subject: 'subject', body: 'body'},
      [Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    )
    @attachment = @message.attachments.first
  end

  should "save a file" do
    assert @attachment.file.exists?
    assert_match /\.pdf$/, @attachment.file.path
    assert File.exist?(@attachment.file.path)
  end

  should "delete a file" do
    @attachment.file = nil
    assert !@attachment.file.exists?
  end

  should "delete a file when the object is destroyed" do
    file_path = @attachment.file.path
    assert File.exist?(file_path)
    @attachment.destroy
    assert !File.exist?(file_path)
  end

  should "create an attachment with file at once" do
    @attachment = Attachment.create_from_file(
      message_id: @message.id,
      file:       Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)
    )
    assert @attachment.valid?
    assert @attachment.file.exists?
  end

  should "recognize whether it is an image or not" do
    img = Attachment.create_from_file(file: Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true))
    assert img.image?
    assert_equal 2, img.width
    assert_equal 2, img.height
    assert !Attachment.create_from_file(file: Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/attachment.pdf'), 'application/pdf', true)).image?
  end

end
