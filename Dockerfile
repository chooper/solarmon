FROM ruby:2.2
ADD . /app/
WORKDIR /app
RUN bundle install
CMD ["ruby", "bin/energy"]
