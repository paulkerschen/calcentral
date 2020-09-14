Rails.application.config.middleware.insert_before 0, Rack::Cors do
  if Settings.vue.localhost_base_url
    allow do
      origins 'localhost:8080'
      resource '*', headers: :any, methods: [:get, :post, :patch, :put], credentials: true
    end
  end
end
