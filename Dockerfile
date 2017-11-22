FROM ruby:2.2
ADD . /app/
WORKDIR /app
RUN bundle install
CMD ["rackup", "-p 8080"]
EXPOSE 8080
