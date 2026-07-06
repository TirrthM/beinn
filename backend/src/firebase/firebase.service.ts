import { Injectable, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class FirebaseService implements OnModuleInit {
  constructor(private configService: ConfigService) {}

  onModuleInit() {
    if (!admin.apps.length) {
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
      const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
      const privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n');

      if (projectId && clientEmail && privateKey) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
        console.log('Firebase Admin initialized successfully');
      } else {
        console.warn('Firebase Admin SDK missing configuration in .env');
      }
    }
  }

  getFirestore() {
    return admin.firestore();
  }
}
