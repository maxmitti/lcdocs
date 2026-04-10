#!/usr/bin/env python3

import collections
import datetime
import json
import os
import sys
import xml.dom.minidom as minidom

if len(sys.argv) < 2:
	print(f'Not enough arguments!\nSyntax: {sys.argv[0]} path', file=sys.stderr)
	sys.exit(1)

root_dir = os.path.normpath(sys.argv[1])

if not os.path.isdir(root_dir):
	print(f'"{root_dir}" is not a directory or not accessible!', file=sys.stderr)
	sys.exit(1)

po_i18n = {}
with open('en.po', 'r') as f:
	en_po = f.read().split('\n')
for line in en_po:
	if line.startswith('msgid'):
		msgid = line[7:-1]
	elif line.startswith('msgstr'):
		po_i18n[msgid] = line[8:-1]

def get_unique_tag(node, tag, file_path):
	'''Return the first node with name *tag* of *node* or print a warning and return None in the case of none or multiple tags with the name *tag*
	   example: <versions><version>I want this!</version><extversion></extversion></versions>'''
	
	elements = node.getElementsByTagName(tag)
	
	if len(elements) != 1:
		print(f'None or multiple <{tag}> elements found in "{file_path}"!', file=sys.stderr)
		return None
	
	return elements[0]

def get_unique_value(node, tag, file_path):
	'''Return the text contained in *node* or print a warning and return None in the case of none or multiple tags with the name *tag*
	   example: <title>FooBar</title> -> "FooBar"
	   detailed explanation: Get value of first child node of *node* and strip whitespace. This won't work if *node* doesn't have a child node or if that child node is not a text node)'''
	
	element = get_unique_tag(node, tag, file_path)
	
	if not element:
		return None
	
	return element.firstChild.nodeValue.strip()

categories = []

def create_entry(entries, path, node):
	tag_name = node.tagName
	
	category = get_unique_value(node, 'category', path)
	if category not in categories:
		categories.append(category)
	deprecated_tags = node.getElementsByTagName('deprecated')
	deprecated_version = None
	if len(deprecated_tags) > 0:
		deprecated_version = get_unique_value(deprecated_tags[0], 'version', path)
	if tag_name == 'const':
		name = get_unique_value(node, 'name', path)
		version = get_unique_value(node, 'version', path)
	elif tag_name == 'func':
		name = get_unique_value(node, 'title', path)
		version = get_unique_value(get_unique_tag(node, 'versions', path), 'version', path)
	
	if not (name and category and version):
		print(f'Skipping <{tag_name}> in {path}', file=sys.stderr)
		return
	
	# this is the object which is later exported to the summary JSON file
	entry = {
		'path': path,
		'name': name,
		'category': category,
		'version': version,
		'deprecated_version': deprecated_version
	}
	entries.append(entry)

# search recursively in a given path for XML files
constants = []
functions = []
doc_files = {}
for path, dir_names, files in os.walk(root_dir):
	for file_name in files:
		# ignore non-XML files
		if not file_name.endswith('.xml'):
			continue
		
		file_path = os.path.join(path, file_name).replace(os.path.sep, '/') # replace os specific seperators with / so it's usable in an URL
		rel_file_path = file_path[len(root_dir) + 1:] # cut off the root directory
		
		if rel_file_path.startswith('script/'):
			# parse the XML file into a DOM object
			document = minidom.parse(file_path)
			
			# find <const> tags in the current document
			for const in document.getElementsByTagName('const'):
				create_entry(constants, rel_file_path, const)
			
			# find <func> tags in the current document
			for func in document.getElementsByTagName('func'):
				create_entry(functions, rel_file_path, func)

		if rel_file_path.startswith('script/fn/') or rel_file_path.startswith('script/constants/'):
			continue

		if path == root_dir:
			dir_path = '.'
		else:
			dir_path = path.replace(os.path.sep, '/')[len(root_dir) + 1:]

		if dir_path not in doc_files:
			doc_files[dir_path] = {'i18n': {}, 'files': {}}

		doc_file = doc_files[dir_path]

		document = minidom.parse(file_path)

		title = get_unique_value(document, 'title', file_path)

		if file_name == 'index.xml':
			# write i18n for directory
			doc_file['i18n']['de'] = title
			doc_file['i18n']['en'] = po_i18n[title]

			continue

		doc_file['files'][file_name] = {'de': title, 'en': po_i18n[title]}

# sort by name first, then group by file (one constgroup-file can have multiple constants)
constants.sort(key=lambda item: item['name'])
constants.sort(key=lambda item: item['path'])
# only sort by path for functions
functions.sort(key=lambda item: item['path'])

# data integrity check: print a list of duplicate entries by the "name"-key (this is an empty array when the data is correct)
flattened_names = [*[const['name'] for const in constants], *[func['name'] for func in functions]]
print('Duplicates:', [item for item, count in collections.Counter(flattened_names).items() if count > 1])

categories.sort()

category_i18n = {'de': {}, 'en': {}}
for category in categories:
	category_i18n['de'][category] = category.split('/')
for category in categories:
	category_i18n['en'][category] = po_i18n[category].split('/')

# sort files ascending
for dir_name in doc_files:
	directory = doc_files[dir_name]
	
	dir_files = directory['files']
	files_sorted_keys = list(dir_files.keys())
	files_sorted_keys.sort()
	directory['files'] = {name: dir_files[name] for name in files_sorted_keys}

# sort directories ascending
doc_files_sorted_keys = list(doc_files.keys())
doc_files_sorted_keys.sort()
doc_files = {name: doc_files[name] for name in doc_files_sorted_keys}

# also export the current date and time into the JSON file
# WARNING: datetime is in local timezone
out = {'created': datetime.datetime.now().isoformat(), 'generated_from': root_dir, 'files': doc_files, 'category_i18n': category_i18n, 'script': {'constants': constants, 'functions': functions}}
with open('lcdocs_summary.json', 'w') as f:
	# disable "ensure_ascii" so UTF-8 chars are output correctly
	f.write(json.dumps(out, ensure_ascii=False, indent='\t'))
