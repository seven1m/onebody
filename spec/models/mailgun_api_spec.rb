require_relative '../rails_helper'

describe MailgunApi do
  before do
    @body = {
      priority: 0,
      description: 'Catch All Route - Created By OneBody',
      expression: "match_recipient('.*@example.com')",
      action: ["forward('http://example.com/emails.mime')", 'stop()']
    }
  end

  subject { described_class.new('key') }

  context 'without email host' do
    it 'sends an api request to mailgun' do
      expect(subject).to receive(:show_routes) {
        { 'total_count' => 0, 'items' => [] }
      }

      expect(subject).to receive(:post).with(
        'https://api.mailgun.net/v2/routes',
        body: @body
      )
      result = subject.create_catch_all
      expect(result).to eq(true)
    end
  end

  context 'with alternate email host' do
    before do
      Site.current.email_host = 'mg.example.com'
    end

    after do
      Site.current.email_host = nil
    end

    it 'sends an api request to mailgun' do
      expect(subject).to receive(:show_routes).and_return(
        'total_count' => 0, 'items' => []
      )

      expect(subject).to receive(:post).with(
        'https://api.mailgun.net/v2/routes',
        body: @body.merge(expression: "match_recipient('.*@mg.example.com')")
      )
      result = subject.create_catch_all
      expect(result).to eq(true)
    end
  end

  context 'route already exists' do
    it 'does not create a route on mailgun and raises an error' do
      expect(subject).to receive(:show_routes).and_return(
        'total_count' => 1,
        'items' => [
          {
            'description' => 'Catch All Route - Created By OneBody',
            'created_at'  => 'Thu, 31 Jul 2014 04:14:02 GMT',
            'actions'     => [
              "forward('http://example.com/emails.mime')", 'stop()'
            ],
            'priority'    => 0,
            'expression'  => "match_recipient('.*@example.com')",
            'id'          => '53d9c28a125730632f288aa1'
          }
        ]
      )

      expect(subject.class).not_to receive(:post)
      expect {
        subject.create_catch_all
      }.to raise_error(MailgunApi::RouteAlreadyExists)
    end
  end

  context 'forbidden error during get' do
    before do
      stub_request(:get, 'https://api.mailgun.net/v2/routes')
        .to_return(status: 401)
    end

    it 'raises an error' do
      expect {
        subject.create_catch_all
      }.to raise_error(MailgunApi::Forbidden)
    end
  end

  context 'forbidden error during post' do
    before do
      allow(subject).to receive(:show_routes)
        .and_return('items' => [])
      stub_request(:post, 'https://api.mailgun.net/v2/routes')
        .to_return(status: 401)
    end

    it 'raises an error' do
      expect {
        subject.create_catch_all
      }.to raise_error(MailgunApi::Forbidden)
    end
  end
end
