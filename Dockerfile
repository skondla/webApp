FROM python:2.7
LABEL maintainer="Sudheer Kondla, skondla@me.com"
RUN apt-get update
RUN mkdir /app
WORKDIR /app
COPY . /app
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN cp lib/rdsAdmin.py /usr/local/lib/python2.7
RUN apt-get -y install curl
EXPOSE 25443
ENTRYPOINT [ "python" ]
CMD [ "dbWebAPI.py" ]
