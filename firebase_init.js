/**
 * ============================================================================
 * FAIRGO PLATFORM — FIREBASE FIRESTORE CONNECTION & SCHEMA VERIFIER
 * Single-file Node.js script using Firebase Admin SDK.
 * 
 * Usage:
 *   node firebase_init.js
 * ============================================================================
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// Load environment variables from .env
try {
  require('dotenv').config();
} catch (e) {
  // dotenv optional fallback
}

// Initialize Firebase Admin using environment variables, GOOGLE_APPLICATION_CREDENTIALS, or local JSON
if (!admin.apps.length) {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && rawPrivateKey) {
    const privateKey = rawPrivateKey.replace(/\\n/g, '\n');
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
    console.log(`[Firebase] Initialized successfully using individual environment variables for project: ${projectId}`);
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS && fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    console.log(`[Firebase] Initialized using GOOGLE_APPLICATION_CREDENTIALS: ${process.env.GOOGLE_APPLICATION_CREDENTIALS}`);
  } else if (fs.existsSync(path.join(__dirname, 'serviceAccountKey.json'))) {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log(`[Firebase] Initialized using local serviceAccountKey.json file`);
  } else {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    console.log(`[Firebase] Initialized using applicationDefault credentials`);
  }
}

const db = admin.firestore();

// ----------------------------------------------------------------------------
// SCHEMA STRUCTURE REFERENCE (NO DATA SEEDED AUTOMATICALLY)
// ----------------------------------------------------------------------------

const SCHEMA_COLLECTIONS = [
  { name: 'users', description: 'User identity & RBAC (RIDER, DRIVER, ADMIN)' },
  { name: 'rider_profiles', description: 'Rider preferences, saved places, ratings' },
  { name: 'driver_profiles', description: 'Driver KYC, live geohash location, ratings' },
  { name: 'vehicles', description: 'Vehicle registry (RC, PUC, insurance)' },
  { name: 'trips', description: 'Trip state machine & live tracking' },
  { name: 'pricing_cities', description: 'Operational metro cities' },
  { name: 'pricing_rules', description: 'Transparent fare calculation matrices' },
  { name: 'wallets', description: 'Financial balances & immutable ledgers' },
  { name: 'payments', description: 'Payment intents, UPI & Gateway captures' },
  { name: 'support_cases', description: 'Customer support tickets & live chat' },
  { name: 'support_faqs', description: 'Self-help FAQ library' },
  { name: 'sos_alerts', description: 'Emergency SOS events & dispatch tracking' },
  { name: 'notifications', description: 'Multi-channel notification delivery log' },
];

async function verifyFirebaseConnection() {
  console.log('\n🔍 Verifying Firestore connection...');
  
  const collections = await db.listCollections();
  const existingCollectionNames = new Set(collections.map((c) => c.id));

  console.log('\n================================================================');
  console.log('✨ Firestore connection verified successfully!');
  console.log('================================================================\n');
  console.log('Project ID:', admin.app().options.projectId || process.env.FIREBASE_PROJECT_ID);
  console.log(`Existing collections in Firestore (${collections.length}):`);
  
  for (const c of collections) {
    console.log(` • ${c.id}`);
  }

  console.log('\nDeclared FairGo Schema Collections:');
  for (const item of SCHEMA_COLLECTIONS) {
    const exists = existingCollectionNames.has(item.name) ? '✓ Present' : '○ Pending manual load';
    console.log(` [${exists}] ${item.name.padEnd(20)} - ${item.description}`);
  }
  console.log('\n(No automated data seeded — load data via Firebase Console or manual scripts as needed.)\n');
}

if (require.main === module) {
  verifyFirebaseConnection()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('❌ Failed to verify Firebase connection:', err);
      process.exit(1);
    });
}

module.exports = { verifyFirebaseConnection, SCHEMA_COLLECTIONS };
