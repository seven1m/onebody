require_relative '../rails_helper'

describe Email do

  before do
    @body = {priority: 0,
             description: 'Catch All Route - Created By OneBody',
             expression: "match_recipient('.*@example.com')",
             action: ["forward('http://example.com/emails.mime')", 'stop()'] }
  end

  context 'without email host' do
    it 'sends an api request to mailgun' do

      expect(Email).to receive(:show_routes) {
        # Yes the keys really are strings.
        { 'total_count' => 0, 'items' => [] }
      }

      expect(Email).to receive(:post).with('https://api.mailgun.net/v2/routes',
                                           basic_auth: { username: 'api', password: nil },
                                           body: @body
                                          ) { :Do_Nothing }
      Email.create_catch_all
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

      expect(Email).to receive(:show_routes) {
        { 'total_count' => 0, 'items' => [] }
      }

      expect(Email).to receive(:post).with('https://api.mailgun.net/v2/routes',
                                           basic_auth: { username: 'api', password: nil },
                                           body: @body.merge(expression: "match_recipient('.*@mg.example.com')")
                                          ) { :Do_Nothing }
      Email.create_catch_all
    end
  end

  context 'route already exists' do
    it 'does not create a route on mailgun' do

      expect(Email).to receive(:show_routes) {
       {"total_count" => 1,
        "items" =>
         [{"description" => "Catch All Route - Created By OneBody",
           "created_at" => "Thu, 31 Jul 2014 04:14:02 GMT",
           "actions" => ["forward('http://example.com/emails.mime')", "stop()"],
           "priority" => 0,
           "expression" => "match_recipient('.*@example.com')",
           "id" => "53d9c28a125730632f288aa1"}]}
       }

      expect(Email).not_to receive(:post)
      Email.create_catch_all
    end
  end

end
