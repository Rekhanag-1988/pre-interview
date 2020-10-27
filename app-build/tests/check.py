#!/usr/bin/env python3

import flask
import os

def basic_test():
	''' Checks module import/version  '''
	print("Flask module imported with version:{}".format(flask.__version__))
	print("Checking if commit file exists with content.")
	if os.path.isfile('/app/commit_id'):
		stream=open('/app/commit_id','r').readlines()[0].strip()
		if stream:
			print("Commit ID exists with value:{}".format(stream))
		else:
			raise Exception("Commit-file has null content.")
	else:
		raise Exception("commit-file does not exit on the image.")
		


def main():
	basic_test()

if __name__=='__main__':
	main()
