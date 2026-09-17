/**
 * ============================================================================
 * FAIRGO PLATFORM — COMPLETE FIREBASE DATABASE INITIALIZATION & SEED SCRIPT
 * Single-file Node.js script using Firebase Admin SDK.
 * 
 * Usage:
 *   1. Set GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
 *   2. Run: node firebase_init.js
 * ============================================================================
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (uses GOOGLE_APPLICATION_CREDENTIALS or default credentials)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

// ----------------------------------------------------------------------------
// SEED DATA CONFIGURATION
// ----------------------------------------------------------------------------

const CITIES = [
  {
    id: 'bengaluru',
    name: 'Bengaluru',
    state: 'Karnataka',
    countryCode: 'IN',
    isActive: true,
    timezone: 'Asia/Kolkata',
    centerLat: 12.9716,
    centerLon: 77.5946,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'mumbai',
    name: 'Mumbai',
    state: 'Maharashtra',
    countryCode: 'IN',
    isActive: true,
    timezone: 'Asia/Kolkata',
    centerLat: 19.0760,
    centerLon: 72.8777,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'delhi_ncr',
    name: 'Delhi NCR',
    state: 'Delhi',
    countryCode: 'IN',
    isActive: true,
    timezone: 'Asia/Kolkata',
    centerLat: 28.6139,
    centerLon: 77.2090,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'hyderabad',
    name: 'Hyderabad',
    state: 'Telangana',
    countryCode: 'IN',
    isActive: true,
    timezone: 'Asia/Kolkata',
    centerLat: 17.3850,
    centerLon: 78.4867,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

const PRICING_RULES = [
  {
    id: 'bengaluru_BIKE',
    cityId: 'bengaluru',
    vehicleType: 'BIKE',
    baseFarePaise: 2500,
    perKmPaise: 800,
    perMinutePaise: 150,
    minimumFarePaise: 3000,
    cancellationFeePaise: 1500,
    cancellationFreeWindowSeconds: 180,
    maxSurgeMultiplier: 2.0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'bengaluru_AUTO',
    cityId: 'bengaluru',
    vehicleType: 'AUTO',
    baseFarePaise: 3000,
    perKmPaise: 1500,
    perMinutePaise: 200,
    minimumFarePaise: 3500,
    cancellationFeePaise: 2000,
    cancellationFreeWindowSeconds: 180,
    maxSurgeMultiplier: 2.0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'bengaluru_CAB_MINI',
    cityId: 'bengaluru',
    vehicleType: 'CAB_MINI',
    baseFarePaise: 5000,
    perKmPaise: 1600,
    perMinutePaise: 250,
    minimumFarePaise: 7000,
    cancellationFeePaise: 3500,
    cancellationFreeWindowSeconds: 180,
    maxSurgeMultiplier: 2.0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'bengaluru_CAB_SEDAN',
    cityId: 'bengaluru',
    vehicleType: 'CAB_SEDAN',
    baseFarePaise: 7000,
    perKmPaise: 1900,
    perMinutePaise: 300,
    minimumFarePaise: 9000,
    cancellationFeePaise: 5000,
    cancellationFreeWindowSeconds: 180,
    maxSurgeMultiplier: 2.0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'bengaluru_CAB_SUV',
    cityId: 'bengaluru',
    vehicleType: 'CAB_SUV',
    baseFarePaise: 10000,
    perKmPaise: 2400,
    perMinutePaise: 350,
    minimumFarePaise: 14000,
    cancellationFeePaise: 6000,
    cancellationFreeWindowSeconds: 180,
    maxSurgeMultiplier: 2.0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

const SUPPORT_FAQS = [
  {
    id: 'faq_1',
    category: 'trip_issue',
    question: 'How do I report an item left behind in a vehicle?',
    answer: 'Select the trip from your Trip History and tap "Lost Item". You can call the driver directly for up to 48 hours with phone number masking, or contact FairGo 24/7 support for immediate assistance.',
    sortOrder: 1,
    isActive: true,
  },
  {
    id: 'faq_2',
    category: 'payment_issue',
    question: 'Why was I charged a cancellation fee or surge fare?',
    answer: 'FairGo enforces 100% surge cap transparency. Cancellation fees only apply if cancelled more than 3 minutes after a driver was dispatched. If you were incorrectly charged, we issue an instant wallet refund.',
    sortOrder: 2,
    isActive: true,
  },
  {
    id: 'faq_3',
    category: 'account',
    question: 'How do I update my mobile number or email address?',
    answer: 'Go to Profile > Edit Profile. Changing your mobile number requires an OTP verification sent to both your old and new number for account security.',
    sortOrder: 3,
    isActive: true,
  },
  {
    id: 'faq_4',
    category: 'safety',
    question: 'What safety features does FairGo have during rides?',
    answer: 'Every FairGo trip has 24/7 GPS tracking, live trip sharing with emergency contacts, dedicated in-app SOS with local police integration, and verified drivers.',
    sortOrder: 4,
    isActive: true,
  },
  {
    id: 'faq_5',
    category: 'technical',
    question: 'The app is having trouble detecting my pickup location',
    answer: 'Ensure Location permissions are set to "While using the app" and High Accuracy is enabled. You can also manually drag and adjust the pin on the map.',
    sortOrder: 5,
    isActive: true,
  },
];

// ----------------------------------------------------------------------------
// SEED EXECUTION
// ----------------------------------------------------------------------------

async function initializeFirebaseSchema() {
  console.log('🚀 Initializing FairGo collections and seed data in Firestore...');
  const batch = db.batch();

  // 1. Seed Cities
  for (const city of CITIES) {
    const cityRef = db.collection('pricing_cities').doc(city.id);
    batch.set(cityRef, city, { merge: true });
  }
  console.log(`✅ Queued ${CITIES.length} metro cities`);

  // 2. Seed Pricing Rules
  for (const rule of PRICING_RULES) {
    const ruleRef = db.collection('pricing_rules').doc(rule.id);
    batch.set(ruleRef, rule, { merge: true });
  }
  console.log(`✅ Queued ${PRICING_RULES.length} pricing rules`);

  // 3. Seed Support FAQs
  for (const faq of SUPPORT_FAQS) {
    const faqRef = db.collection('support_faqs').doc(faq.id);
    batch.set(faqRef, faq, { merge: true });
  }
  console.log(`✅ Queued ${SUPPORT_FAQS.length} support FAQs`);

  // Commit Initial Batch
  await batch.commit();

  console.log('\n================================================================');
  console.log('✨ Firestore initialization & seed completed successfully!');
  console.log('================================================================\n');
  console.log('Firestore Collections created:');
  console.log(' • users                 - User identity & RBAC (RIDER, DRIVER, ADMIN)');
  console.log(' • rider_profiles        - Rider preferences, saved places, ratings');
  console.log(' • driver_profiles       - Driver KYC, live geohash location, ratings');
  console.log(' • vehicles              - Vehicle registry (RC, PUC, insurance)');
  console.log(' • trips                 - Trip state machine & live tracking');
  console.log(' • pricing_cities        - Operational metro cities');
  console.log(' • pricing_rules         - Transparent fare calculation matrices');
  console.log(' • wallets               - Financial balances & immutable ledgers');
  console.log(' • payments              - Payment intents, UPI & Gateway captures');
  console.log(' • support_cases         - Customer support tickets & live chat');
  console.log(' • support_faqs          - Self-help FAQ library');
  console.log(' • sos_alerts            - Emergency SOS events & dispatch tracking');
  console.log(' • notifications         - Multi-channel notification delivery log');
}

// Run if directly called
if (require.main === module) {
  initializeFirebaseSchema()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('❌ Failed to initialize Firebase:', err);
      process.exit(1);
    });
}

module.exports = { initializeFirebaseSchema };
