#!/bin/bash
# Production setup script for Hospital Management System
# This script helps verify and deploy Firebase rules and configurations

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Hospital Management - Production Setup         ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}✗ Firebase CLI not found${NC}"
    echo -e "${YELLOW}Installing Firebase CLI...${NC}"
    npm install -g firebase-tools
    echo -e "${GREEN}✓ Firebase CLI installed${NC}\n"
else
    echo -e "${GREEN}✓ Firebase CLI found${NC}\n"
fi

# Check if user is logged in
echo -e "${BLUE}Checking Firebase authentication...${NC}"
if firebase projects:list &> /dev/null; then
    echo -e "${GREEN}✓ Already logged in to Firebase${NC}\n"
else
    echo -e "${YELLOW}Please log in to Firebase:${NC}"
    firebase login
    echo -e "${GREEN}✓ Logged in successfully${NC}\n"
fi

# Show current project
echo -e "${BLUE}Current Firebase project:${NC}"
firebase use

echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Deployment Options                              ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

echo "1) Deploy Firestore rules only"
echo "2) Deploy Storage rules only"
echo "3) Deploy both Firestore and Storage rules"
echo "4) Run Flutter app (web)"
echo "5) Build for production"
echo "6) Show Firebase Console URLs"
echo "7) Exit"
echo ""

read -p "Select an option (1-7): " choice

case $choice in
    1)
        echo -e "\n${YELLOW}Deploying Firestore rules...${NC}"
        firebase deploy --only firestore:rules
        echo -e "${GREEN}✓ Firestore rules deployed${NC}"
        ;;
    2)
        echo -e "\n${YELLOW}Deploying Storage rules...${NC}"
        firebase deploy --only storage:rules
        echo -e "${GREEN}✓ Storage rules deployed${NC}"
        ;;
    3)
        echo -e "\n${YELLOW}Deploying Firestore and Storage rules...${NC}"
        firebase deploy --only firestore:rules,storage:rules
        echo -e "${GREEN}✓ Rules deployed${NC}"
        ;;
    4)
        echo -e "\n${YELLOW}Running Flutter app in Chrome...${NC}"
        flutter run -d chrome
        ;;
    5)
        echo -e "\n${YELLOW}Building for production...${NC}"
        flutter build web --release
        echo -e "${GREEN}✓ Build complete: build/web/${NC}"
        echo -e "\n${BLUE}To deploy to Firebase Hosting:${NC}"
        echo "firebase deploy --only hosting"
        ;;
    6)
        echo -e "\n${BLUE}Firebase Console URLs:${NC}"
        echo -e "${GREEN}Project Overview:${NC} https://console.firebase.google.com/project/hospital-management-syst-75183"
        echo -e "${GREEN}Authentication:${NC} https://console.firebase.google.com/project/hospital-management-syst-75183/authentication/users"
        echo -e "${GREEN}Email Templates:${NC} https://console.firebase.google.com/project/hospital-management-syst-75183/authentication/emails"
        echo -e "${GREEN}Firestore:${NC} https://console.firebase.google.com/project/hospital-management-syst-75183/firestore"
        echo -e "${GREEN}Storage:${NC} https://console.firebase.google.com/project/hospital-management-syst-75183/storage"
        echo -e "${GREEN}Storage Rules:${NC} https://console.firebase.google.com/project/hospital-management-syst-75183/storage/rules"
        ;;
    7)
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Setup complete!                                  ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test password reset in the app"
echo "2. Test profile photo upload"
echo "3. Check 'Production Status' in the app drawer"
echo "4. Review PRODUCTION_SETUP.md for detailed instructions"
echo ""
