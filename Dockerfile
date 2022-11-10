FROM ruby:2.5
RUN apt-get update && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  postgresql-client \
  yarn \
  default-mysql-client \
  dnsutils \
  iputils-ping \
  net-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
COPY . .
RUN bundle install
RUN rails assets:precompile

ENV SSH_PASSWD "root:Docker!"
RUN apt-get update \
  && apt-get install -y --no-install-recommends dialog \
  && apt-get update \
  && apt-get install -y --no-install-recommends openssh-server \
  && echo "$SSH_PASSWD" | chpasswd
COPY sshd_config /etc/ssh/

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000 2222

CMD ["rails", "server", "-b", "0.0.0.0"]
