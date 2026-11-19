# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.3
FROM ruby:${RUBY_VERSION}-bookworm

ARG RAILS_VERSION=7.1
ENV RAILS_VERSION=${RAILS_VERSION}

RUN apt-get update -qq \
  && apt-get install --no-install-recommends -y build-essential libsqlite3-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN bundle install \
  && chmod +x docker/entrypoint.sh \
  && mkdir -p spec/dummy/lib spec/dummy/db spec/dummy/log spec/dummy/tmp

ENV RAILS_ENV=test \
    APP_HOST=www.example.com \
    BUNDLE_JOBS=4

ENTRYPOINT ["docker/entrypoint.sh"]
CMD ["bundle", "exec", "rspec"]
