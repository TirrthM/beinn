import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { TrackingService } from './tracking.service';
import { Logger } from '@nestjs/common';

export interface LocationUpdatePayload {
  driver_id: string;
  lat: number;
  lng: number;
  bearing: number;
  speed?: number;
}

@WebSocketGateway({
  cors: {
    origin: '*', // Allow Flutter client to connect
  },
})
export class TrackingGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(TrackingGateway.name);

  constructor(private readonly trackingService: TrackingService) {}

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /**
   * Driver sends location updates here.
   * Example payload: { "driver_id": "drv_9842", "lat": 19.076, "lng": 72.877, "bearing": 120.5 }
   */
  @SubscribeMessage('driver_location_update')
  async handleLocationUpdate(@MessageBody() data: LocationUpdatePayload) {
    const { driver_id, lat, lng, bearing, speed } = data;

    // 1. In-Memory Write to Redis
    await this.trackingService.updateDriverLocation(
      driver_id,
      lat,
      lng,
      bearing,
      speed,
    );

    // 2. Broadcast immediately to the specific customer room watching that delivery
    // Customers join a room named 'delivery_${driver_id}' to track
    this.server.to(`delivery_${driver_id}`).emit('location_update', {
      driver_id,
      lat,
      lng,
      bearing,
      speed,
    });
  }

  /**
   * Customer app calls this to start listening to a specific driver's location.
   */
  @SubscribeMessage('subscribe_delivery')
  handleSubscribeDelivery(
    @MessageBody() data: { driver_id: string },
    @ConnectedSocket() client: Socket,
  ) {
    const room = `delivery_${data.driver_id}`;
    client.join(room);
    this.logger.log(`Client ${client.id} joined room ${room}`);
  }

  /**
   * Customer app calls this to stop listening.
   */
  @SubscribeMessage('unsubscribe_delivery')
  handleUnsubscribeDelivery(
    @MessageBody() data: { driver_id: string },
    @ConnectedSocket() client: Socket,
  ) {
    const room = `delivery_${data.driver_id}`;
    client.leave(room);
    this.logger.log(`Client ${client.id} left room ${room}`);
  }
}
