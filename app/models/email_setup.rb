class EmailSetup
  def initialize(key)
    @key = key
  end

  attr_accessor :domain

  def domains
    api.domains
  end

  def save!
    return false unless domain
    create_catch_all
    write_config
    set_email_host
  end

  private

  def domain_details
    @domain_details ||= domains.detect { |d| d['name'] == domain }
  end

  def api
    @api ||= MailgunApi.new(@key)
  end

  def create_catch_all
    api.create_catch_all(domain)
  end

  def write_config
    File.open(Rails.root.join('config/email.yml'), 'w') do |file|
      file.write(YAML.dump(config))
    end
  end

  def config
    {
      Rails.env.to_s => {
        'smtp' => {
          'address'        => 'smtp.mailgun.org',
          'port'           => 587,
          'domain'         => domain,
          'authentication' => 'plain',
          'user_name'      => domain_details['smtp_login'],
          'password'       => domain_details['smtp_password']
        }
      }
    }
  end

  def set_email_host
    Site.current.update!(email_host: domain)
  end
end
