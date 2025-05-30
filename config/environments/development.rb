# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.after_initialize do
    Bullet.enable = true
    Bullet.rails_logger = true
  end

  # Settings specified here will take precedence over those in config/application.rb.
  config.middleware.use(ActionDispatch::Cookies)
  config.middleware.use(ActionDispatch::Session::CookieStore, key: "_lago_dev")
  config.middleware.use(Rack::MethodOverride)

  config.eager_load_paths += %W[
    #{config.root}/dev
  ]

  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  config.cache_store = :redis_cache_store, {url: ENV["LAGO_REDIS_CACHE_URL"], db: 3}

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.active_storage.service = if ENV["LAGO_USE_AWS_S3"].present? && ENV["LAGO_USE_AWS_S3"] == "true"
    if ENV["LAGO_AWS_S3_ENDPOINT"].present?
      :amazon_compatible_endpoint
    else
      :amazon
    end
  else
    :local
  end

  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_job.verbose_enqueue_logs = true

  config.logger = ActiveSupport::Logger.new($stdout)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.action_view.annotate_rendered_view_with_filenames = true
  config.action_controller.raise_on_missing_callback_actions = true

  config.hosts << "api.lago.dev"
  config.hosts << "api"

  # Allow Gitpod hostname for development
  if ENV["GITPOD_WORKSPACE_ID"].present? && ENV["GITPOD_WORKSPACE_CLUSTER_HOST"].present?
    gitpod_host = "3000-#{ENV["GITPOD_WORKSPACE_ID"]}.#{ENV["GITPOD_WORKSPACE_CLUSTER_HOST"]}"
    config.hosts << gitpod_host
  end

  # Allow localhost variations
  config.hosts << "localhost"
  config.hosts << "127.0.0.1"

  config.license_url = ENV.fetch("LAGO_LICENSE_URL", "http://license:3000")

  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: "mailhog",
    port: 1025
  }
  config.action_mailer.preview_paths << Rails.root.join("spec/mailers/previews").to_s

  Dotenv.load
end
