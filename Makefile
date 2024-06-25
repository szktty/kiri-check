.PHONY: fix format test test-web doc dhttpd pubpoint unicode

fix:
	dart fix --apply lib
	dart fix --apply test
	dart format lib test

format:
	dart format lib test

test:
	dart test

test-web:
	dart test -p chrome

doc:
	dart doc

dhttpd:
	dart pub global run dhttpd --path doc/api

pubpoints:
	pana .

unicode:
	cd unicode_data && python3 generate.py
	cp unicode_data/unicode_data.dart lib/src/util/character
	dart fix --apply lib/src/util/character/unicode_data.dart