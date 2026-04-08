#!/usr/bin/env python3

import json
import sys
import pathlib

from mako.lookup import TemplateLookup

if len(sys.argv) < 3:
	print('Not enough arguments!', file=sys.stderr)
	print(f'Syntax: {sys.argv[0]} target-file language')
	sys.exit(1)

AVAILABLE_TARGETS = ['content.html', 'search.html']
target = sys.argv[1]
if target not in AVAILABLE_TARGETS:
	print(f'Language "{target}" is not available!', file=sys.stderr)
	print(f'Available languages: {", ".join(AVAILABLE_LANGS)}')
	sys.exit(1)

# Check if target language is supported
AVAILABLE_LANGS = ['de', 'en']
lang = sys.argv[2]
if lang not in AVAILABLE_LANGS:
	print(f'Language "{lang}" is not available!', file=sys.stderr)
	print(f'Available languages: {", ".join(AVAILABLE_LANGS)}')
	sys.exit(1)

cwd = pathlib.Path().resolve()
selfd = pathlib.Path(__file__).parent.resolve()


# Load a file with strings that have to be translated in the output html file
with open(pathlib.PurePath.joinpath(selfd, f'templates/{lang}.i18n.json'), 'r') as f:
	i18n = json.load(f)

lookup = TemplateLookup(directories=[pathlib.PurePath.joinpath(selfd, 'templates')])

print(f'Generating {target} for language "{lang}" ...')
html = lookup.get_template(target).render(lang=lang, i18n=i18n, lookup=lookup)

with open(pathlib.PurePath.joinpath(cwd, f'online/{lang}/{target}'), 'w') as f:
	f.write(html)
