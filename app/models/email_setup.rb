class EmailSetup
  def initialize(key)
    @key = key
  end

  def domains
    api.domains
  end

  def save!
    create_catch_all
    write_config
  end

  private

  def api
    @api ||= MailgunApi.new(@key)
  end

  delegate :create_catch_all, to: :api

  def write_config
    # TODO
  end

  def config
    {
      Rails.env.to_s => {
        'smtp' => {
          'address'        => 'smtp.mailgun.org',
          'port'           => 587,
          'domain'         => Site.current.email_host,
          'authentication' => 'plain',
          'user_name'      => 'TODO',
          'password'       => 'TODO'
        }
      }
    }
  end
end
