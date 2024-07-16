shopt -s globstar

xmlstarlet \
	edit \
	--inplace \
	-N mvn=http://maven.apache.org/POM/4.0.0 \
	--update '/mvn:project//mvn:dependencies/mvn:dependency/mvn:version[../mvn:groupId[text()='\'"$1"\'']]' \
	--value "$2" \
	./pom.xml ./**/pom.xml
