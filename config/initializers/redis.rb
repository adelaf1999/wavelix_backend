# frozen_string_literal: true

Redis.current = Redis.new(
    url:  ENV.fetch('REDIS_URL'),
    port: ENV.fetch('REDIS_PORT'),
    db:   ENV.fetch('REDIS_DB')
)