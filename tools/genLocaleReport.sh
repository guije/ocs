#!/bin/bash

#
# genLocaleReport.sh
#
# Copyright (c) 2000-2007 John Willinsky
# Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
#
# CLI tool to search the codebase against a user-specified locale file to
# find unused keys in the locale file, and keys not defined in the locale
# file that are used in the PHP code and/or templates.
#
# Usage: genLocaleReport.sh locale_file_use path_to_search_for_code
#
# For example, "genLocaleReport.sh ../locales/en_US/locale.xml .." would search
# all subdirectories of the parent directory (..) for PHP and TPL files and
# scrutinize all translation requests against the ../locales/en_US/locale.xml
# locale file.
#
# This script is very inefficient with CPU time.
#
# $Id$
#

if ! [ -n "$1" ] || ! [ -n "$2" ]; then
	echo "Incorrect usage."
	echo "USAGE: genLocaleReport.sh locale_file_to_use path_to_search_for_code"
	exit -1;
fi

echo -n "Finding duplicate keys in XML..."
XMLKEYS=`sed -n 's/^.*key\="\([^"]*\)".*/\1/p' "$1" | sort | uniq -d`
if [ ! -z "$XMLKEYS" ]; then
	echo "Duplicate keys found!"
	echo "$XMLKEYS"
	exit
fi
echo "None"

# This is a bit kludge-y right now. Templates use locales mostly in 3 ways:
# in {translate} tags, in {fieldlabel} tags, and in {assign var} tags for
# page titles. Since scanning templates is a reasonably quick process, doing
# it three times is redundant but doesn't substantially add to the script's
# run time.

echo "Finding keys used in templates..."
TEMPLATEKEYS_TRANSLATE=`sed -n 's/translate/\ntranslate/gp' \`find "$2" -name \*.tpl 2>/dev/null\` | sed -n 's/translate key\="\([^"]*\)".*/\1/p' | sort | uniq`;
TEMPLATEKEYS_FIELDLABEL=`sed -n 's/fieldLabel/\nfieldLabel/gp' \`find "$2" -name \*.tpl 2>/dev/null\` | sed -n 's/fieldLabel [^}]*key\="\([^"]*\)".*/\1/p' | sort | uniq`;
TEMPLATEKEYS_PAGETITLE=`sed -n 's/assign var="pageTitle"/\nassign var="pageTitle"/gp' \`find "$2" -name \*.tpl 2>/dev/null\` | sed -n 's/assign var="pageTitle" [^}]*value\="\([^"]*\)".*/\1/p' | sort | uniq`;
TEMPLATEKEYS_PAGEID=`sed -n 's/assign var="pageId"/\nassign var="pageId"/gp' \`find "$2" -name \*.tpl 2>/dev/null\` | sed -n 's/assign var="pageId" value\="\([^"]*\)".*/\1/p' | sort | uniq`;

TEMPLATEKEYS=`echo $TEMPLATEKEYS_TRANSLATE $TEMPLATEKEYS_FIELDLABEL $TEMPLATEKEYS_PAGETITLE $TEMPLATEKEYS_PAGEID| sort | uniq`;

echo "Finding keys used in PHP..."
PHPKEYS=`sed -n 's/Locale::translate/\nLocale::translate/gp' \`find "$2" -name \*.php 2>/dev/null\` | sed -n 's/Locale::translate[ ]\?(['\''"]\([^'\''"]*\)['\''"])/\1\n/gp' | sort | uniq`;

echo "Getting keys from XML..."
XMLKEYS=`sed -n 's/^.*key\="\([^"]*\)".*/\1/p' "$1" | sort | uniq`

echo "Searching for unused keys..."
for keyname in $XMLKEYS; do
	FOUND=0;
	for templatekey in $TEMPLATEKEYS; do
		if [ $keyname == $templatekey ]; then
			FOUND=1
		fi
	done

	for templatekey in $PHPKEYS; do
		if [ $keyname == $templatekey ]; then
			FOUND=1
		fi
	done

	if [ $FOUND == 0 ]; then
		echo "Found an unused key: $keyname"
	fi
done

echo "Searching for keys in the PHP code that are not defined in the XML..."
for keyname in $PHPKEYS; do
	FOUND=0;
	for xmlkey in $XMLKEYS; do
		if [ $keyname == $xmlkey ]; then
			FOUND=1
		fi
	done

	if [ $FOUND == 0 ]; then
		echo "Found an undefined key: $keyname"
	fi
done

echo "Searching for keys in the templates that are not defined in the XML..."
for keyname in $TEMPLATEKEYS; do
	FOUND=0;
	for xmlkey in $XMLKEYS; do
		if [ $keyname == $xmlkey ]; then
			FOUND=1
		fi
	done

	if [ $FOUND == 0 ]; then
		echo "Found an undefined key: $keyname"
	fi
done


