Gem::Specification.new do |s|
  s.name     = "acts_as_scoped_globally"
  s.version  = "0.2.2"
  s.summary  = "Change scope of AR model instance."
  s.email    = "tim@timmorgan.org"
  s.homepage = "http://github.com/seven1m/acts_as_scoped_globally"
  s.description = "Rails plugin that allows the scope of queries to be defined in the AR model definition rather than in individual finds, inserts, updates, and deletes."
  s.has_rdoc = false
  s.authors  = ["Tim Morgan"]
  s.files    = [
    "README.markdown",
    "lib/acts_as_scoped_globally.rb"
  ]
end
