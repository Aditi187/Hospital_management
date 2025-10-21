# TODO List for Implementing Doctor-Patient Filtering

## 1. Modify signup_page.dart
- [x] Add TextEditingController for disease
- [x] Add disease input field for patients in the form
- [x] Update _signup method to save disease for patients
- [x] Add doctor data to 'doctors' collection when signing up as doctor

## 2. Modify doctor_consultation_page.dart
- [x] Add patientDisease state variable
- [x] Add _fetchPatientDisease method in initState
- [x] Remove specialty selection dropdown and related code
- [x] Update StreamBuilder to filter doctors by patient's disease
- [x] Add selectedSpecialization state variable
- [x] Add _fetchSpecializations method to get unique specializations
- [x] Add specialization selection dropdown in UI
- [x] Update StreamBuilder to filter doctors by selected specialization
- [x] Update _resetForm to reset selectedSpecialization

## 3. Modify doctor_dashboard.dart
- [x] Change _buildPatientList to fetch appointments for the current doctor
- [x] Use FutureBuilder to fetch patient data for appointment patientIds
- [x] Update ListView to display patients with appointments

## 4. Testing
- [x] Test patient signup with disease
- [x] Test doctor signup and check 'doctors' collection
- [x] Test doctor consultation page filtering
- [x] Test doctor dashboard showing only relevant patients
