#!/usr/bin/env python3

import json

with open('tsconfig.json', 'r') as f:
	tsconfig = json.load(f)

first = True
for [key, value] in tsconfig['compilerOptions'].items():
	if type(value) == bool:
		if value == True:
			escaped_value = 'true'
		else:
			escaped_value = 'false'
	else:
		escaped_value = str(value)
	# escape double-quotes
	escaped_value = escaped_value.replace('"', '\\"')
	
	if first:
		first = False
	else:
		# print a space before each argument other than the first one
		print(' ', end='')
	
	print(f'--{key} "{escaped_value}"', end='')
