#!/usr/bin/env python3
import json, sys, subprocess

data = {}
with open('info.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

subprocess.check_call(['git', 'tag', 'v{}'.format(data['version'])])
subprocess.check_call(['git', 'archive', '--prefix={}_{}/'.format(data['name'], data['version']), '--output=releases/{}_{}.zip'.format(data['name'], data['version']), 'v{}'.format(data['version'])])
