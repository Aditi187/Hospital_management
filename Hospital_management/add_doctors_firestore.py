
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase app
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

doctors = [
    {"name": "Dr. John Smith", "specialization": "general medicine", "role": "doctor"},
    {"name": "Dr. Alice Brown", "specialization": "cardiology", "role": "doctor"},
    {"name": "Dr. Priya Patel", "specialization": "dermatology", "role": "doctor"},
    {"name": "Dr. Rajesh Kumar", "specialization": "orthopedics", "role": "doctor"},
    {"name": "Dr. Emily Chen", "specialization": "pediatrics", "role": "doctor"},
    {"name": "Dr. Maria Garcia", "specialization": "gynecology", "role": "doctor"},
    {"name": "Dr. David Lee", "specialization": "neurology", "role": "doctor"},
    {"name": "Dr. Fatima Noor", "specialization": "psychiatry", "role": "doctor"},
    {"name": "Dr. Ahmed Hassan", "specialization": "radiology", "role": "doctor"},
    {"name": "Dr. Sarah Wilson", "specialization": "emergency medicine", "role": "doctor"},
]

for doc in doctors:
    db.collection('users').add(doc)

print('Doctors added to Firestore.')
