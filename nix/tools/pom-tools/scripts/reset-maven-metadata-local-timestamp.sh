shopt -s globstar

xmlstarlet \
	edit \
	--inplace \
	--update '/metadata/versioning/lastUpdated' \
	--value "19800101000002" \
	./**/maven-metadata-local.xml

