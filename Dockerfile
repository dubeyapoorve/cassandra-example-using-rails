#Use image
FROM centos:7

#Identify the maintainer of an image
LABEL maintainer="dubeyapoorve@gmail.com"

#RUN useradd -d /test test

#Install the required packages
RUN yum install openssl make bzip2 autoconf automake sqlite-devel which perl git curl wget tar sudo -y

RUN wget https://download.java.net/java/GA/jdk13/5b8a42f3905b406298b72d750b6919f6/33/GPL/openjdk-13_linux-x64_bin.tar.gz
RUN tar -xvf openjdk-13_linux-x64_bin.tar.gz


#Install ruby latest
FROM ruby:2.7.1-alpine3.11

# Install your app's runtime dependencies in the container
RUN apk add --update --virtual runtime-deps nodejs libffi-dev readline sqlite

# Install Yarn
ENV PATH=/root/.yarn/bin:$PATH
RUN apk add --virtual build-yarn curl && \
    touch ~/.bashrc && \
    curl -o- -L https://yarnpkg.com/install.sh | sh && \
    apk del build-yarn


# Bundle into the temp directory
WORKDIR /tmp
ADD Gemfile* ./

RUN apk add --virtual build-deps build-base openssl-dev postgresql-dev libc-dev linux-headers libxml2-dev libxslt-dev readline-dev && \
    bundle install --jobs=2 && \
    apk del build-deps


# Copy the app's code into the container
ENV APP_HOME /app
COPY . $APP_HOME
WORKDIR $APP_HOME


#ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin/bash:/bin:


#RUN /bin/bash -lc "gem install bundler && gem install bundle"
#RUN /bin/bash -lc "gem install -N rails"


#RUN /bin/bash -lc "bundle install --force"

#RUN apt-get update \
#&& apt-get install -y \
#apt-utils \
#build-essential \
#libpq-dev \
#libjpeg-dev \
#libpng-dev \
#nodejs \
#yarn

#RUN yarn install --check-files

#Clone the git repo

#RUN mkdir /tmp/app
#RUN git clone https://github.com/dubeyapoorve/cassandra-example-using-rails.git /tmp/test
#RUN cp -R /tmp/test/* /tmp/app/

#WORKDIR /tmp/app/

#RUN bundle install --gemfile=/tmp/app/Gemfile
#RUN apt-get yarn install 

RUN rails new blog --skip-active-record --skip-active-storage -T --skip-bundle


RUN  /bin/bash -lc "bundle add cequel"
RUN  /bin/bash -lc "bundle add activemodel-serializers-xml"
RUN  /bin/bash -lc "/tmp/app/bin/rails g scaffold post title body"


#Add the following as the first route within config/routes.rb file:
RUN echo "'posts#index'" >> /tmp/app/config/routes.rb


#Create app/models/post.rb file with the following content:
RUN echo $'class Post\n\
  include Cequel::Record\n\

  key :id, :timeuuid, auto: true\n\
  column :title, :text\n\
  column :body, :text\n\

  timestamps\n\
end\n'\
>> /tmp/app/app/models/post.rb


#Create a default Cassandra configuration file
RUN /bin/bash -lc "/tmp/app/bin/rails g cequel:configuration"


#Initialize Cassandra keyspace (database)
RUN /bin/bash -lc "/tmp/app/bin/rails cequel:keyspace:create"


RUN /bin/bash -l -c "/tmp/app/bin/rails webpacker:install"

USER root
EXPOSE 3000
CMD [ "/bin/bash -l -c /tmp/app/bin/rails", "s" ]
