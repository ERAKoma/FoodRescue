import uuid
from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
import bcrypt
from firebase_admin import credentials, firestore
from datetime import datetime
from google.cloud import storage
from werkzeug.utils import secure_filename


app = Flask(__name__)
CORS(app)  # Enable CORS

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r'private_key/foodrescue_key.json')
firebase_admin.initialize_app(cred)
gcp_cred = r'private_key/app_inventor.json'

# Initialize Google Cloud Storage client
gcp_client = storage.Client.from_service_account_json(gcp_cred)
BUCKET_NAME = 'foodrescue-bucket'
bucket = gcp_client.get_bucket(BUCKET_NAME)

# Get Firestore client
db = firestore.client()


############ Users ####################
# Create a user
@app.route('/create_user', methods=['POST'])
def create_user():
    data = request.get_json()
    name = data['name']
    email = data['email']
    password = data['passwordHash']
    phone = data['phone']


    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    # Create user data dictionary
    user_data = {
        'name': name,
        'email': email,
        'passwordHash': password_hash,
        'phone': phone,
        # 'image': 'assets/images/profile.jpg',  # Default profile image
    }

    # Check if email is already in use
    user_ref = db.collection('users').document(email)
    user_data_check = user_ref.get()
    if user_data_check.exists:
        return jsonify({'message': 'User already exists!'}), 409
    else:
        # Add user data to Firestore
        user_ref.set(user_data)
        return jsonify({'message': 'User created successfully!'}), 200

# update user details
@app.route('/update_user', methods=['PUT'])
def update_user():
    data = request.get_json()
    email = data['email']
    user_ref = db.collection('users').document(email)

    if not user_ref.get().exists:
        return jsonify({'message': 'User does not exist!'}), 404

    update_data = {key: value for key, value in data.items() if key != 'email' and value is not None}

    user_ref.update(update_data)
    return jsonify({'message': 'User updated successfully!'}), 200

# API for login
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email']
    password = data['passwordHash']
    
    # Get user data from Firestore
    user_ref = db.collection('users').document(email)
    user_data = user_ref.get()
    
    if user_data.exists:
        user_data = user_data.to_dict()
        if bcrypt.checkpw(password.encode('utf-8'), user_data['passwordHash'].encode('utf-8')):
            # Exclude sensitive keys when sending user data back to the client
            user_info = {key: val for key, val in user_data.items() if key not in ['passwordHash', 'profileImage']}
            return jsonify({'message': 'Login successful!', 'user': user_info}), 200
        else:
            return jsonify({'message': 'Invalid password!'}), 401
    else:
        return jsonify({'message': 'User does not exist!'}), 404
        
#Get all user details
@app.route('/get_user/<email>', methods=['GET'])
def get_user(email):
    user_ref = db.collection('users').document(email)
    user_data = user_ref.get()
    
    if user_data.exists:
        user_data = user_data.to_dict()        
        return jsonify(user_data), 200
    
    else:
        return jsonify({'message': 'User does not exist!'}), 404
    
#Delete user
@app.route('/delete_user/<email>', methods=['DELETE'])
def delete_user(email):
    user_ref = db.collection('users').document(email)
    user_ref.delete()
    
    return jsonify({'message': 'User deleted successfully!'}), 200

#Change password
@app.route('/change_password/<email>', methods=['PUT'])
def change_password(email):
    data = request.get_json()
    old_password = data['oldPassword']
    new_password = data['newPassword']
    
    user_ref = db.collection('users').document(email)
    user_data = user_ref.get().to_dict()
    
    if bcrypt.checkpw(old_password.encode('utf-8'), user_data['passwordHash'].encode('utf-8')):
        new_password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        user_ref.update({'passwordHash': new_password_hash})
        return jsonify({'message': 'Password changed successfully!'}), 200
    else:
        return jsonify({'message': 'Invalid password!'}), 401


#API for uploading user picture
@app.route('/upload_profile_pic/<email>', methods=['PUT'])
def upload_profile_pic(email):
    if 'file' not in request.files:
        return jsonify({"error": "No file part in the request"}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({"error": "No file selected for uploading"}), 400
    
    filename = secure_filename(file.filename)
    unique_filename = str(uuid.uuid4()) + "_" + filename
    filepath = f'profile_pictures/{unique_filename}'
    
    try:
        bucket = gcp_client.get_bucket(BUCKET_NAME)
        blob = bucket.blob(filepath)
        blob.upload_from_file(file)
        
        
        # Update Firestore with the URL of the uploaded image
        user_ref = db.collection('users').document(email)
        user_ref.update({'image': blob.public_url, 'updatedAt': datetime.now()})
        
        return jsonify({"message": "File uploaded successfully", "file_url": blob.public_url}), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

   
#API for deleting profile picture 
@app.route('/delete_profile_pic/<email>', methods=['PUT'])
def delete_profile_pic(email):
    try:
        user_ref = db.collection('users').document(email)
        user_data = user_ref.get()
        
        if user_data.exists:
            user_data = user_data.to_dict()
            profile_image_url = user_data.get('profileImage', '')
            
            if profile_image_url:
                file_path = profile_image_url.split(f"https://storage.googleapis.com/{BUCKET_NAME}/")[-1]
                
                bucket = gcp_client.get_bucket(BUCKET_NAME)
                blob = bucket.blob(file_path)
                blob.delete()
                
                user_ref.update({'profileImage': '', 'updatedAt': datetime.now()})
                
                return jsonify({'message': 'Profile image deleted successfully!'}), 200
            else:
                return jsonify({'message': 'Profile image not found!'}), 404
        else:
            return jsonify({'message': 'User does not exist!'}), 404
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


#################### Rescues ####################

# Create an rescue
@app.route('/create_rescue', methods=['POST'])
def create_rescue():
    data = request.get_json()
    rescue_id = data.get('rescue_id')
    title = data.get('title')
    desc = data.get('desc')
    date = data.get('date')
    email = data.get('email')
    location = data.get('location')
    phone = data.get('phone')
    image = data.get('image', 'assets/images/rescue.jpeg')  # Use default image if not provided

    # Create rescue data dictionary\
    rescue_data = {
        'rescue_id': rescue_id,
        'title': title,
        'desc': desc,
        'date': date,
        'email': email,
        'image': image,
        'location': location,
        'phone': phone,
    }

    # Check if the rescue with the same ID already exists to avoid duplication
    rescue_ref = db.collection('rescues').document(rescue_id)
    if rescue_ref.get().exists:
        return jsonify({'message': 'rescue already exists!'}), 409

    # Add rescue data to Firestore with provided rescue_id
    rescue_ref.set(rescue_data)

    return jsonify({'message': 'rescue created successfully!', 'rescue_id': rescue_id}), 200

# Get all rescues and store in a list
@app.route('/get_rescues', methods=['GET'])
def get_rescues():
    rescues = []
    rescue_ref = db.collection('rescues').get()
    
    for rescue in rescue_ref:
        rescue_data = rescue.to_dict()
        rescues.append(rescue_data)
    
    return jsonify(rescues), 200



# Get rescue details
@app.route('/get_rescue/<rescue_id>', methods=['GET'])
def get_rescue(rescue_id):
    rescue_ref = db.collection('rescues').document(rescue_id)
    rescue_data = rescue_ref.get()
    
    if rescue_data.exists:
        rescue_data = rescue_data.to_dict()
        return jsonify(rescue_data), 200
    else:
        return jsonify({'message': 'rescue does not exist!'}), 404

# Update an rescue
@app.route('/update_rescue', methods=['PUT'])
def update_rescue():
    data = request.get_json()
    rescue_id = data.get('rescue_id')
    rescue_ref = db.collection('rescues').document(rescue_id)

    if not rescue_ref.get().exists:
        return jsonify({'message': 'rescue does not exist!'}), 404

    update_data = {key: value for key, value in data.items() if key != 'rescue_id' and value is not None}
    update_data['updatedAt'] = datetime.now()

    rescue_ref.update(update_data)
    return jsonify({'message': 'Rescue updated successfully!'}), 200



#Get all rescues created by a specific user
@app.route('/get_user_rescues/<email>', methods=['GET'])
def get_user_rescues(email):
    rescues = []
    rescue_ref = db.collection('rescues').where('email', '==', email).get()
    
    for rescue in rescue_ref:
        rescue_data = rescue.to_dict()
        rescues.append(rescue_data)
    
    return jsonify(rescues), 200

# Delete rescue  
@app.route('/delete_rescue/<rescue_id>', methods=['DELETE'])
def delete_rescue(rescue_id):
    rescue_ref = db.collection('rescues').document(rescue_id)
    rescue_ref.delete()
    
    return jsonify({'message': 'rescue deleted successfully!'}), 200

#API for uploading rescue picture
@app.route('/upload_rescue_pic/<rescue_id>', methods=['POST'])
def upload_rescue_pic(rescue_id):
    if 'file' not in request.files:
        return jsonify({"error": "No file part in the request"}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({"error": "No file selected for uploading"}), 400
    
    filename = secure_filename(file.filename)
    unique_filename = str(uuid.uuid4()) + "_" + filename
    filepath = f'rescues/{unique_filename}'
    
    try:
        bucket = gcp_client.get_bucket(BUCKET_NAME)
        blob = bucket.blob(filepath)
        blob.upload_from_file(file)
        
        
        # Update Firestore with the URL of the uploaded image
        rescue_ref = db.collection('rescues').document(rescue_id)
        rescue_ref.update({'image': blob.public_url, 'updatedAt': datetime.now()})
        
        return jsonify({"message": "File uploaded successfully", "file_url": blob.public_url}), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)  # Ensures the server is accessible on the network

