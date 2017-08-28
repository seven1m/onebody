Authority.configure do |config|
  config.logger = Rails.logger

  config.abilities.merge!(
    rotate: 'rotatable',
    reorder: 'reorderable',
    edit: 'updatable'
  )
end
