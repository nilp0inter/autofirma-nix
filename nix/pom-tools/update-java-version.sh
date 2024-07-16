#!/usr/bin/env bash
shopt -s globstar

xmlstarlet edit \
    --inplace \
    -N mvn=http://maven.apache.org/POM/4.0.0 \
    --update "//mvn:plugin/mvn:configuration/*[self::mvn:source or self::mvn:target]" \
    --value "$1" \
    ./pom.xml ./**/pom.xml
