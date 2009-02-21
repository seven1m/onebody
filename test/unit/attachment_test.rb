require File.dirname(__FILE__) + '/../test_helper'

class AttachmentTest < ActiveSupport::TestCase
  fixtures :attachments

  def setup
    @person, @other_person = Person.forge, Person.forge
    @message = Message.create_with_attachments(
      {:to => @person, :person => @other_person,
      :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph},
      [fixture_file_upload('files/attachment.pdf')]
    )
    @attachment = @message.attachments.first
  end
  
  should "save a file" do
    assert @attachment.has_file?
    assert_equal "#{@attachment.id}.test.pdf", @attachment.file_name
    assert File.exist?(@attachment.file_path)
  end
  
  should "delete a file" do
    @attachment.file = nil
    assert !@attachment.has_file?
  end
  
  should "delete a file when the object is destroyed" do
    file_path = @attachment.file_path
    assert File.exist?(file_path)
    @attachment.destroy
    assert !File.exist?(file_path)
  end
  
  should "create an attachment with file at once" do
    @attachment = Attachment.create_from_file(:message_id => @message.id, :file => fixture_file_upload('files/attachment.pdf'))
    assert @attachment.valid?
    assert @attachment.has_file?
  end
  
  should "recognize whether it is an image or not" do
    img = Attachment.create_from_file(:file => fixture_file_upload('files/image.jpg'))
    assert img.image?
    assert_equal 2, img.width
    assert_equal 2, img.height
    assert !Attachment.create_from_file(:file => fixture_file_upload('files/attachment.pdf')).image?
  end
  
end
