xmlstarlet \
	edit \
	--inplace \
	-N mvn=http://maven.apache.org/POM/4.0.0 \
	--delete '/mvn:project/mvn:profiles/mvn:profile[mvn:id="'"$1"'"]/mvn:modules/mvn:module[text()="'"$2"'"]' \
	pom.xml ./**/pom.xml
