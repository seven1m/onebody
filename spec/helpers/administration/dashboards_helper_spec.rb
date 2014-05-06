require_relative '../../spec_helper'

describe Administration::DashboardsHelper do

  describe 'display_metric' do
    before do
      @alerts = []
    end
    it 'should output its content' do
      html = display_metric false do
        concat 'content'
      end
      expect(html).to eq("<p>content</p>")
    end
    it 'should output its content inside the specified tag' do
      html = display_metric false, content_tag: 'div' do
        concat 'content'
      end
      expect(html).to eq("<div>content</div>")
    end
    it 'should add to alerts if alert=true' do
      html = display_metric true do
        concat 'content'
      end
      expect(html).to eq("<p>content</p>")
      expect(@alerts).to eq(["content"])
    end
  end

end
