#!/usr/bin/env bash

set -e
# parsing of current version
export CURRENT_VERSION=$(grep "version" hydromt/__init__.py | cut -d= -f 2 | tr -d "\" ")
export CURRENT_MAJOR=$(echo $CURRENT_VERSION | cut -d'.' -f 1)
export CURRENT_MINOR=$(echo $CURRENT_VERSION | cut -d'.' -f 2)
export CURRENT_PATHCH=$(echo $CURRENT_VERSION | cut -d'.' -f 3)

BUMP="minor"

## calculate new release number
case $BUMP in

"patch")
	export NEW_VERSION="$CURRENT_MAJOR.$CURRENT_MINOR.$((CURRENT_PATHCH + 1))"
	;;

"minor")
	export NEW_VERSION="$CURRENT_MAJOR.$(($CURRENT_MINOR + 1)).0"
	;;

"major")
	export NEW_VERSION="$((CURRENT_MAJOR + 1)).0.0"
	;;

*)
	echo "invalid bump"
	exit 1
	;;
esac

## seting up git
# git config user.name "GitHub Actions Bot"
# git config user.email "<>"

# create release branch
# git checkout -b "release/v$NEW_VERSION"

# update version in python file
# sed -i "s/.*__version__.*/__version__ = \"$NEW_VERSION\"/" hydromt/__init__.py

sed -i "s/.*__version__.*/__version__ = \"$NEW_VERSION\"/" docs/changelog.rst
export NEW_CHANGELOG_HEADER="v$NEW_VERSION ($(date -I))"
export NEW_HEADER_UNDERLINE=$(printf '=%.0s' $(seq 1 $(echo $NEW_CHANGELOG_HEADER | awk '{print length}')))

# update chagnelog with new header
sed -i "/Unreleased/{s/Unreleased/$NEW_CHANGELOG_HEADER/;n;s/=*/$NEW_HEADER_UNDERLINE/}" docs/changelog.rst

# update switcher.json while maintianing the correct order with some black jq incantations. I'll try and explain below
cat docs/switcher.json | jq "map(select(.version != \"latest\")) | . + [{\"name\":\"v$NEW_VERSION\",\"version\":\"$NEW_VERSION\",\"url\":\"https://deltares.github.io/hydromt/v$NEW_VERSION/\"}] | sort_by(.version|split(\".\")|map(tonumber)) | . + [{\"name\":\"latest\",\"version\":\"latest\",\"url\":\"https://deltares.github.io/hydromt/latest\"}]" >tmp.json

# map(select(.version != \"latest\"))
# removes the "latest" entry, since we'll need to sort numerically by number in a later step

#| . +
# take the result of the previous operation and add the following array to it

# [{\"name\":\"v$NEW_VERSION\",\"version\":\"$NEW_VERSION\",\"url\":\"https://deltares.github.io/hydromt/v$NEW_VERSION/\"}]
# an array with the new entry we want to add

# sort_by(.version|split(\".\")|map(tonumber))
# take the array, split the version field by the "." char and make numbers out of the components. then sort the whole array by these numbers
# this is why we had to remove the latest field earlier,
# otherwise the number conversion would fail here.

#| . + [{\"name\":\"latest\",\"version\":\"latest\",\"url\":\"https://deltares.github.io/hydromt/latest\"}]
# add teh latest field back in at the end

# avoid race conditions by using a tmp file
mv tmp.json docs/switcher.json

git add .
git commit -m "prepare for release v$NEW_VERSION"
git push

gh pr create -B "main" -H "release/v$NEW_VERSION" -t "Release v$NEW_VERSION" -T ".github/templates/release_pr.md"
