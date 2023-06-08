FROM python:3.9.13
LABEL maintainer="Sudheer Kondla, skondla@me.com"
#RUN apt-get -y install python3-pip
RUN mkdir /app
WORKDIR /app
COPY . /app
RUN groupadd -r app &&\
    useradd -r -g app -d /home/app -s /sbin/nologin -c "Docker image user" app
#RUN pip3 install --upgrade setuptools pip
RUN apt-get update
RUN apt-get install -y openssl 
RUN apt-get install -y libzmq3-dev python3-pip
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
#RUN cp lib/rdsAdmin.py /usr/lib/python3.4
RUN cp lib/rdsAdmin.py /usr/local/lib/python3.9
#RUN apt-get install -y apt-utils && apt-get install -y curl
RUN apt-get -y install curl
RUN chmod +x dbWebAPI.sh
RUN chown -R app:app /app
USER app
EXPOSE 25443
ENTRYPOINT [ "/bin/bash" ]
CMD [ "dbWebAPI.sh" ]
