#!/usr/bin/python

import os, codecs
from time import strftime

strings = {}

def locate(root = os.getcwd()):
	for path, dirs, files in os.walk(root):
		for filename in [os.path.join(path, filename) for filename in files]:
			yield filename

# get source strings
path = '../../src'
for filename in locate(path):
	#print filename
	file = open(filename, 'r')
	line = file.readline()
	lineid = 1
	while line != '':
		values = line.split('lang("')
		if len(values) == 2:
			value = values[1].rstrip('");\n');
			info = '#: ' + filename.replace('\\', '/') + ':' + str(lineid) + '\n'
			if value not in strings:
				strings[value] = info
			else:
				strings[value] = strings[value] + info
		line = file.readline()
		lineid = lineid + 1
	file.close()			
			
# get simple menu strings
path = '../skins/simple/menus'
for filename in locate(path):
	#print filename
	file = open(filename, 'r')
	line = file.readline()
	lineid = 1
	while line != '':
		if line.startswith('text'):
			namevalue = line.split('=')
			if len(namevalue) == 2:
				value = namevalue[1].strip();
				if not value.endswith('.str') and value != 'none' and not value.startswith('car.') and not value.startswith('game.'):
					info = '#: ' + filename.replace('\\', '/') + ':' + str(lineid) + '\n'
					if value not in strings:
						strings[value] = info
					else:
						strings[value] = strings[value] + info
		elif line.startswith('on'):
			values = line.split(':"')
			if len(values) == 2:
				value = values[1].rstrip('"\n');
				info = '#: ' + filename.replace('\\', '/') + ':' + str(lineid) + '\n'
				if value not in strings:
					strings[value] = info
				else:
					strings[value] = strings[value] + info
		line = file.readline()
		lineid = lineid + 1
	file.close()

# get options strings 
filename = '../settings/options.config'
#print filename
file = open(filename, 'r')
line = file.readline()
lineid = 1
while line != '':
	if line.startswith('opt') or line.startswith('true') or line.startswith('false'):
		namevalue = line.split('=')
		if len(namevalue) == 2:
			value = namevalue[1].strip();
			info = '#: ' + filename.replace('\\', '/') + ':' + str(lineid) + '\n'
			if value not in strings:
				strings[value] = info
			else:
				strings[value] = strings[value] + info
	line = file.readline()
	lineid = lineid + 1
file.close()

file = codecs.open('vdrift.pot', 'w', 'utf-8')

# write header
date = strftime('%Y-%m-%d %H:%M+0100')
file.write('# SOME DESCRIPTIVE TITLE.\n')
file.write('# Copyright (C) YEAR THE PACKAGE\'S COPYRIGHT HOLDER\n')
file.write('# This file is distributed under the same license as the PACKAGE package.\n')
file.write('# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.\n')
file.write('msgid \"\"\nmsgstr \"\"\n')
file.write('\"Project-Id-Version: VDrift\\n\"\n')
file.write('\"Report-Msgid-Bugs-To: \\n\"\n')
file.write('\"POT-Creation-Date: ' + date + '\\n\"\n')
file.write('\"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n\"\n')
file.write('\"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n\"\n')
file.write('\"Language-Team: LANGUAGE <LL@li.org>\\n\"\n')
file.write('\"Language: \\n\"\n')
file.write('\"MIME-Version: 1.0\\n\"\n')
file.write('\"Content-Type: text/plain; charset=UTF-8\\n\"\n')
file.write('\"Content-Transfer-Encoding: 8bit\\n\"\n\n')
file.write('#. TRANSLATORS: Set this to the language codepage (character encoding). It is used to select the font texture.\n')
file.write('msgid \"_CODEPAGE_\"\n')
file.write('msgstr \"\"\n\n')

# write strings
for item in sorted(strings.items()):
	file.write(item[1] + 'msgid \"' + item[0] + '\"\nmsgstr \"\"\n\n')
file.close()
