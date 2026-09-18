import * as admin from 'firebase-admin';
import type { Firestore } from 'firebase-admin/firestore';
import type { Auth } from 'firebase-admin/auth';
import { createLogger } from '@fairgo/logger';

const log = createLogger('firebase-admin');

let firestoreInstance: Firestore | null = null;
let authInstance: Auth | null = null;

/**
 * Initializes and returns the Firebase Admin SDK instance
 * Uses individual environment variables (FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY)
 * with graceful fallback to standard GOOGLE_APPLICATION_CREDENTIALS.
 */
export function getFirebaseAdmin(): typeof admin {
  if (!admin.apps.length) {
    const projectId = process.env['FIREBASE_PROJECT_ID'];
    const clientEmail = process.env['FIREBASE_CLIENT_EMAIL'];
    const rawPrivateKey = process.env['FIREBASE_PRIVATE_KEY'];

    if (projectId && clientEmail && rawPrivateKey) {
      const privateKey = rawPrivateKey.replace(/\\n/g, '\n');
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
      log.info(`Firebase Admin initialized from environment variables (project: ${projectId})`);
    } else {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      log.info('Firebase Admin initialized with applicationDefault credentials');
    }
  }
  return admin;
}

/**
 * Returns the singleton Cloud Firestore client instance
 */
export function getFirestore(): Firestore {
  if (!firestoreInstance) {
    getFirebaseAdmin();
    firestoreInstance = admin.firestore();
  }
  return firestoreInstance;
}

/**
 * Returns the singleton Firebase Auth client instance
 */
export function getFirebaseAuth(): Auth {
  if (!authInstance) {
    getFirebaseAdmin();
    authInstance = admin.auth();
  }
  return authInstance;
}
