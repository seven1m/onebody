require_relative '../rails_helper'

describe Attachment do
  before do
    @person = FactoryGirl.create(:person)
    @other_person = FactoryGirl.create(:person)
    @message = Message.create_with_attachments(
      { to: @person, person: @other_person,
        subject: 'subject', body: 'body' },
      [Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)]
    )
    @attachment = @message.attachments.first
  end

  it 'should save a file' do
    expect(@attachment.file).to be_exists
    expect(@attachment.file.path).to match(/\.pdf$/)
    expect(File.exist?(@attachment.file.path)).to be
  end

  it 'should delete a file' do
    @attachment.file = nil
    expect(@attachment.file).to_not be_exists
  end

  it 'should delete a file when the object is destroyed' do
    file_path = @attachment.file.path
    expect(File.exist?(file_path)).to be
    @attachment.destroy
    @attachment.run_callbacks(:commit)
    expect(File.exist?(file_path)).not_to be
  end

  it 'should create an attachment with file at once' do
    @attachment = Attachment.create_from_file(
      message_id: @message.id,
      file:       Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true)
    )
    expect(@attachment).to be_valid
    expect(@attachment.file).to be_exists
  end

  it 'should recognize whether it is an image or not' do
    img = Attachment.create_from_file(file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true))
    expect(img).to be_image
    file = Attachment.create_from_file(file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true))
    expect(file).to_not be_image
  end

  it 'should know its width and height if an image' do
    img = Attachment.create_from_file(file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true))
    expect(img.width).to eq(2)
    expect(img.height).to eq(2)
    file = Attachment.create_from_file(file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/attachment.pdf'), 'application/pdf', true))
    expect(file.width).to be_nil
    expect(file.height).to be_nil
  end
end
