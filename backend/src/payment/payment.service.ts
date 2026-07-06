import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FirebaseService } from '../firebase/firebase.service';
import Razorpay from 'razorpay';

@Injectable()
export class PaymentService {
  private razorpay: any;

  constructor(
    private configService: ConfigService,
    private firebaseService: FirebaseService,
  ) {
    const key_id = this.configService.get<string>('RAZORPAY_KEY_ID');
    const key_secret = this.configService.get<string>('RAZORPAY_KEY_SECRET');
    if (key_id && key_secret) {
      this.razorpay = new Razorpay({ key_id, key_secret });
    } else {
      console.warn('Razorpay configuration missing in .env');
    }
  }

  async createRazorpayOrder(userId: string) {
    if (!this.razorpay) {
      throw new HttpException('Payment gateway not configured', HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // 1. Fetch user cart securely from Firestore
    const db = this.firebaseService.getFirestore();
    const cartSnapshot = await db.collection('users').doc(userId).collection('cart').get();
    
    if (cartSnapshot.empty) {
      throw new HttpException('Cart is empty', HttpStatus.BAD_REQUEST);
    }

    // 2. Compute Total (Replicating exact logic from Flutter app)
    let grandTotal = 0;
    cartSnapshot.forEach((doc) => {
      const item = doc.data();
      let priceStr = String(item.price || '0').replace('₹', '').replace(/,/g, '');
      let price = parseFloat(priceStr) || 0;
      let quantity = parseInt(item.quantity) || 1;
      grandTotal += price * quantity;
    });

    // Assume 0 delivery fee for now as we didn't find it dynamically added in checkout.dart total loop
    const amountInPaise = Math.round(grandTotal * 100);

    if (amountInPaise <= 0) {
      throw new HttpException('Invalid cart amount', HttpStatus.BAD_REQUEST);
    }

    // 3. Create server-side order with Razorpay
    const options = {
      amount: amountInPaise,
      currency: 'INR',
      receipt: `receipt_${userId}_${Date.now()}`
    };

    try {
      const order = await this.razorpay.orders.create(options);
      return {
        id: order.id,
        amount: order.amount,
        currency: order.currency
      };
    } catch (error) {
      console.error('Razorpay Error:', error);
      throw new HttpException('Failed to create Razorpay order', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
}
