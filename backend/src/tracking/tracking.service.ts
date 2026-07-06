import { Injectable, Logger } from '@nestjs/common';
import { Redis } from 'ioredis';

@Injectable()
export class TrackingService {
  private readonly redis: Redis;
  private readonly logger = new Logger(TrackingService.name);

  constructor() {
    // In production, configure with Redis URL from env variables
    this.redis = new Redis({
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379', 10),
    });
  }

  /**
   * Updates driver location in Redis with geospatial index and also stores
   * the payload as JSON to quickly retrieve details like bearing and speed.
   */
  async updateDriverLocation(
    driverId: string,
    lat: number,
    lng: number,
    bearing: number,
    speed?: number,
  ) {
    const key = 'drivers:locations';
    const payloadKey = `driver:${driverId}:data`;
    const payload = JSON.stringify({
      lat,
      lng,
      bearing,
      speed,
      timestamp: Date.now(),
    });

    try {
      // Geo Add: key, longitude, latitude, member
      await this.redis.geoadd(key, lng, lat, driverId);
      // Store additional properties separately
      await this.redis.set(payloadKey, payload);
    } catch (error) {
      this.logger.error(
        `Failed to update driver location for ${driverId}`,
        error instanceof Error ? error.stack : String(error),
      );
    }
  }

  async getDriverData(driverId: string): Promise<any> {
    try {
      const data = await this.redis.get(`driver:${driverId}:data`);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      this.logger.error(
        `Failed to retrieve driver location for ${driverId}`,
        error instanceof Error ? error.stack : String(error),
      );
      return null;
    }
  }
}
