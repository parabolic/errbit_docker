FROM ruby:2.4.1-slim
MAINTAINER Nikola Velkovski <nvelkovski@gmail.com>

ENV PORT="8080"
ENV WORK_DIR="/app"

RUN set -x && \
    addgroup errbit && \
    useradd -d $WORK_DIR -s /bin/false -g errbit -M errbit

## throw errors if Gemfile has been modified since Gemfile.lock
RUN echo "gem: --no-document" >> /etc/gemrc \
  && bundle config --global frozen 1 \
  && bundle config --global clean true \
  && bundle config --global disable_shared_gems false

RUN mkdir -p $WORK_DIR \
  && chown -R errbit:errbit $WORK_DIR \
  && chmod 700 $WORK_DIR/

WORKDIR $WORK_DIR

RUN gem update --system &&\
    apt-get update &&\
    apt-get install -y bundler \
    curl \
    less \
    libxml2 \
    libcurl4-openssl-dev \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    tzdata \
    pkg-config \
    git

EXPOSE $PORT

# Clone the repo.
RUN git clone https://github.com/errbit/errbit.git .

RUN bundle config build.nokogiri --use-system-libraries && \
    bundle install \
    -j "$(getconf _NPROCESSORS_ONLN)" \
    --retry 5 \
    --without test development no_docker

RUN RAILS_ENV=production bundle exec rake assets:precompile
RUN chown -R errbit:errbit $WORK_DIR

USER errbit

COPY ./entrypoint.sh /

HEALTHCHECK CMD curl --fail http://localhost:$PORT/users/sign_in || exit 1

ENTRYPOINT ["/entrypoint.sh"]
