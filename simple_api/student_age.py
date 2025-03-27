from flask import Flask, jsonify, abort, make_response, request
from flask_httpauth import HTTPBasicAuth
import json
import os

app = Flask(__name__)
auth = HTTPBasicAuth()

# Définition des utilisateurs autorisés
USERS = {
    "jean": "agree"
}

@auth.get_password
def get_password(username):
    return USERS.get(username)

@auth.error_handler
def unauthorized():
    return make_response(jsonify({'error': 'Unauthorized access'}), 401)

# Définition du chemin du fichier JSON avec valeur par défaut
student_age_file_path = os.getenv('STUDENT_AGE_FILE_PATH', '/data/student_age.json')

try:
    with open(student_age_file_path, "r") as student_age_file:
        student_age = json.load(student_age_file)
except FileNotFoundError:
    student_age = {}

@app.route('/simple-jean/api/v1.0/get_student_ages', methods=['GET'])
@auth.login_required
def get_student_ages():
    return jsonify({'student_ages': student_age})

@app.route('/simple-jean/api/v1.0/get_student_ages/<student_name>', methods=['GET'])
@auth.login_required
def get_student_age(student_name):
    if student_name not in student_age:
        abort(404)
    return jsonify({student_name: student_age[student_name]})

@app.errorhandler(404)
def not_found(error):
    return make_response(jsonify({'error': 'Not found'}), 404)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
