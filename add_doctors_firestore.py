import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase app
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

doctors = [
    {"name": "Dr. John Smith", "specialty": "General Medicine"},
    {"name": "Dr. Alice Brown", "specialty": "Cardiology"},
    {"name": "Dr. Priya Patel", "specialty": "Dermatology"},
    {"name": "Dr. Rajesh Kumar", "specialty": "Orthopedics"},
    {"name": "Dr. Emily Chen", "specialty": "Pediatrics"},
    {"name": "Dr. Maria Garcia", "specialty": "Gynecology"},
    {"name": "Dr. David Lee", "specialty": "Neurology"},
    {"name": "Dr. Fatima Noor", "specialty": "Psychiatry"},
    {"name": "Dr. Ahmed Hassan", "specialty": "Radiology"},
    {"name": "Dr. Sarah Wilson", "specialty": "Emergency Medicine"},
]

for doc in doctors:
    db.collection('doctors').add(doc)

print('Doctors added to Firestore.')
