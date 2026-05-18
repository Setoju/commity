Commiti.configure do |config|
  config.google_api_key = ENV.fetch('GOOGLE_API_KEY')
  config.model = Commiti::GoogleClient::DEFAULT_MODEL
  config.temperature = Commiti::GoogleClient::DEFAULT_TEMPERATURE
  config.timeout_seconds = Commiti::GoogleClient::DEFAULT_TIMEOUT_SECONDS
  config.open_timeout_seconds = Commiti::GoogleClient::DEFAULT_OPEN_TIMEOUT_SECONDS
end