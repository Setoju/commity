Commity.configure do |config|
  config.google_api_key = ENV.fetch('GOOGLE_API_KEY')
  config.model = Commity::GoogleClient::DEFAULT_MODEL
  config.temperature = Commity::GoogleClient::DEFAULT_TEMPERATURE
  config.timeout_seconds = Commity::GoogleClient::DEFAULT_TIMEOUT_SECONDS
  config.open_timeout_seconds = Commity::GoogleClient::DEFAULT_OPEN_TIMEOUT_SECONDS
end