if ENV.has_key? 'STRIPE_PUBLISHABLE_KEY' and ENV.has_key? 'STRIPE_SECRET_KEY'
  OneBody::Application.config.x.stripe = {
    publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
    secret_key: ENV['STRIPE_SECRET_KEY']
  }

  Stripe.api_key = Rails.configuration.x.stripe[:secret_key]
end

