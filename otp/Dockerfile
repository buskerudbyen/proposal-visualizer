FROM docker.io/opentripplanner/opentripplanner:2.5.0_2024-03-04T09-14

## need to override the data location because /var/opentripplanner/ is a volume
WORKDIR /var/otp/
COPY *.json /var/otp/

RUN java $JAVA_OPTS -cp @/app/jib-classpath-file @/app/jib-main-class-file /var/otp/ --build --save

ENTRYPOINT java $JAVA_OPTS -cp @/app/jib-classpath-file @/app/jib-main-class-file /var/otp/ --load --serve
