FROM docker.io/opentripplanner/opentripplanner:d93077cf802e13503a2e5b55c116d82c5262b3b2

## need to override the data location because /var/opentripplanner/ is a volume
WORKDIR /var/otp/
COPY *.json /var/otp/

ENV BIKELY_TOKEN=""
ENV BIKELY_AUTHORIZATION=""

RUN java $JAVA_OPTS -cp @/app/jib-classpath-file @/app/jib-main-class-file /var/otp/ --build --save

ENTRYPOINT java $JAVA_OPTS -cp @/app/jib-classpath-file @/app/jib-main-class-file /var/otp/ --load --serve
