require 'twitter'
require 'xmpp4r'

class TwitterBot
  def initialize(account, password)
    account = account + '/' + account unless account =~ /\//
    @jid = Jabber::JID::new(account)
    @password = password
    @client = Jabber::Client::new(@jid)
    @client.connect
    @client.auth(@password)
    @client.send(Jabber::Presence::new)
  end
  
  def run
    @mainthread = Thread.current
    Thread.abort_on_exception = true
    @client.add_message_callback do |m|
      if m.type.to_s != 'error' and m.from.to_s == 'twitter@twitter.com'
        if m.body.to_s =~ /Direct from ([^\s]+):/
          from = $1
          body = m.body.to_s.sub(/Direct from .+:\n/, '').sub(/Reply with [^\n]+/, '')
          msg = TwitterMessage.create(:twitter_screen_name => from, :message => body)
          if msg.errors.any?
            if msg.errors.on(:twitter_screen_name) == 'Twitter screen name unknown.'
              msg.reply = "I don't recognize your Twitter account. Update your account at #{Setting.get(:url, :site)}"
              send(from, msg.reply)
            end
          else
            msg.build_reply
            send(msg.person.twitter_account, msg.reply)
          end
          msg.save
        end
      end
    end
    Thread.stop
    @client.close
  end
  
  def send_via_jabber(to, body)
    puts "sending #{body} to #{to}"
    m = Jabber::Message::new('twitter@twitter.com', "d #{to} #{body}")
    m.type = 'chat'
    @client.send(m)
  end  
  
  def send_via_twitter_api(to, body)
    puts "sending #{body} to #{to}"
    begin
      twitter.d(to.strip, body)
    rescue => e
      puts e.inspect
    end
  end
  
  def send(to, body)
    send_via_twitter_api(to, body)
  end
  
  def twitter
    @twitter ||= TwitterBot.twitter
  end
  
  def self.twitter
    Twitter::Base.new(Setting.get(:features, :twitter_account), Setting.get(:features, :twitter_password))
  end
  
  def self.follow(twitter_account)
    twitter.create_friendship twitter_account
  end
end