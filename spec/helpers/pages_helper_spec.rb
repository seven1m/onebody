require 'rails_helper'

describe PagesHelper, type: :helper do
  describe 'render_page_content' do
    before do
      Page.find('system/unauthorized').update_attributes!(body: 'safe<script>notsafe</script>')
    end

    it 'should return sanitized content' do
      content = render_page_content('system/unauthorized')
      expect(content).to eq('safe')
    end

    it 'should be html_safe' do
      expect(render_page_content('system/unauthorized')).to be_html_safe
    end

    it 'should return nil if no page found' do
      expect(render_page_content('system/nonexistent_page')).to be_nil
    end
  end
end
