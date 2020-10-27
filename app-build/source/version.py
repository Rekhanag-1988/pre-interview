#!/usr/bin/env python3
import os
from flask import (
	Flask,
	request,
	jsonify,
	render_template
)


app = Flask(__name__, template_folder='/app/templates')

@app.route('/')
def home():
	return render_template('Welcome.html')

@app.route('/version', methods=['GET'])
def app_version():
	commitid = open('/app/commit_id','r').readlines()[0].strip()
	version = os.environ.get('APP_VERSION')
	data = {
			"Application_Details": [
				{
					"version":version,
					"lastcommithash":commitid,
					"description":"Pre Interview Technical Test"
				}
			]
		}
	return data

if __name__ == "__main__":
	app.run(debug=True, host='0.0.0.0')