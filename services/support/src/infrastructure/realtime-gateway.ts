// services/support/src/infrastructure/realtime-gateway.ts
// Realtime WebSocket & WebRTC Signaling Gateway for FairGo Support Chat

import { WebSocketServer, WebSocket } from 'ws';
import type { Server, IncomingMessage } from 'http';
import { SupportQueueService } from '../domain/support-queue.service.js';
import {
  SenderRole,
  MessageType,
  type UUID,
  type WebRtcSignalPayload,
} from '@fairgo/shared-types';
import { createLogger } from '@fairgo/logger';

const log = createLogger('support-realtime-gateway');

interface ClientConnection {
  readonly ws: WebSocket;
  readonly userId: UUID;
  readonly role: 'CUSTOMER' | 'AGENT';
  conversationId?: UUID;
  name?: string;
  isAlive: boolean;
}

interface IncomingEventData {
  event: string;
  payload: Record<string, unknown>;
}

export class RealtimeGateway {
  private wss: WebSocketServer;
  private queueService: SupportQueueService;
  private clients: Map<UUID, ClientConnection> = new Map();
  private conversationRooms: Map<UUID, Set<UUID>> = new Map();

  constructor(server: Server, queueService: SupportQueueService) {
    this.queueService = queueService;
    this.wss = new WebSocketServer({ server, path: '/ws/support' });
    this.setupServer();
    this.startHeartbeat();
  }

  private setupServer(): void {
    this.wss.on('connection', (ws: WebSocket, req: IncomingMessage) => {
      const url = new URL(req.url ?? '', `http://${req.headers.host ?? 'localhost'}`);
      const userId = url.searchParams.get('userId') ?? `guest-${Math.floor(Math.random() * 100000)}`;
      const role = (url.searchParams.get('role') ?? 'CUSTOMER').toUpperCase() as
        | 'CUSTOMER'
        | 'AGENT';
      const name = url.searchParams.get('name') ?? (role === 'AGENT' ? 'Support Specialist' : 'Customer');

      const client: ClientConnection = {
        ws,
        userId,
        role,
        name,
        isAlive: true,
      };

      this.clients.set(userId, client);
      log.info('Support WebSocket connected', { userId, role });

      if (role === 'AGENT') {
        void this.queueService.setAgentOnline(userId, name);
      }

      ws.on('pong', () => {
        client.isAlive = true;
      });

      ws.on('message', (raw: Buffer) => {
        try {
          const data = JSON.parse(raw.toString()) as IncomingEventData;
          void this.handleEvent(client, data);
        } catch (err) {
          log.error('Failed to parse WebSocket message', { err: err as Error });
        }
      });

      ws.on('close', () => {
        this.clients.delete(userId);
        if (client.conversationId) {
          this.leaveRoom(client.conversationId, userId);
          this.broadcastToRoom(client.conversationId, {
            event: 'presence:update',
            payload: { userId, status: 'OFFLINE' },
          });
        }
        if (role === 'AGENT') {
          void this.queueService.setAgentOffline(userId);
        }
        log.info('Support WebSocket disconnected', { userId, role });
      });

      this.send(ws, {
        event: 'gateway:connected',
        payload: { userId, status: 'CONNECTED', serverTime: new Date().toISOString() },
      });
    });
  }

  private async handleEvent(client: ClientConnection, data: IncomingEventData): Promise<void> {
    const { event, payload } = data;

    switch (event) {
      case 'conversation:join': {
        const convId = payload['conversationId'] as UUID;
        client.conversationId = convId;
        this.joinRoom(convId, client.userId);

        const messages = await this.queueService.getMessages(convId);
        this.send(client.ws, {
          event: 'conversation:history',
          payload: { conversationId: convId, messages },
        });

        this.broadcastToRoom(
          convId,
          {
            event: 'presence:update',
            payload: { userId: client.userId, role: client.role, status: 'ONLINE', name: client.name },
          },
          client.userId
        );
        break;
      }

      case 'chat:send_message': {
        const convId = client.conversationId ?? (payload['conversationId'] as UUID);
        if (!convId) return;

        const senderRole = client.role === 'AGENT' ? SenderRole.AGENT : SenderRole.CUSTOMER;
        const msgType = ((payload['type'] as string) ?? MessageType.TEXT) as MessageType;

        const saved = await this.queueService.saveMessage({
          conversationId: convId,
          senderId: client.userId,
          senderRole,
          type: msgType,
          content: (payload['content'] as string) ?? '',
          attachmentUrl: payload['attachmentUrl'] as string | undefined,
          attachmentMetadata: payload['attachmentMetadata'] as Record<string, unknown> | undefined,
        });

        this.broadcastToRoom(convId, {
          event: 'chat:message',
          payload: saved,
        });
        break;
      }

      case 'chat:typing': {
        const convId = client.conversationId ?? (payload['conversationId'] as UUID);
        if (!convId) return;

        this.broadcastToRoom(
          convId,
          {
            event: 'chat:typing',
            payload: {
              userId: client.userId,
              name: client.name,
              isTyping: !!payload['isTyping'],
            },
          },
          client.userId
        );
        break;
      }

      case 'webrtc:signal': {
        const signal = payload as unknown as WebRtcSignalPayload;
        const targetId = signal.targetId;

        if (targetId && this.clients.has(targetId)) {
          const target = this.clients.get(targetId)!;
          this.send(target.ws, {
            event: 'webrtc:signal',
            payload: {
              ...signal,
              senderId: client.userId,
            },
          });
        } else if (client.conversationId) {
          this.broadcastToRoom(
            client.conversationId,
            {
              event: 'webrtc:signal',
              payload: { ...signal, senderId: client.userId },
            },
            client.userId
          );
        }
        break;
      }

      case 'agent:accept_conversation': {
        if (client.role !== 'AGENT') return;
        const convId = payload['conversationId'] as UUID;
        const conversation = await this.queueService.acceptConversation(
          client.userId,
          client.name ?? 'Support Agent',
          convId
        );

        client.conversationId = convId;
        this.joinRoom(convId, client.userId);

        this.broadcastToRoom(convId, {
          event: 'conversation:accepted',
          payload: {
            conversation,
            agentName: client.name,
            agentId: client.userId,
          },
        });
        break;
      }

      case 'conversation:end': {
        const convId = client.conversationId ?? (payload['conversationId'] as UUID);
        if (!convId) return;

        await this.queueService.endConversation(convId, client.role);
        this.broadcastToRoom(convId, {
          event: 'conversation:ended',
          payload: { conversationId: convId, endedBy: client.role },
        });
        break;
      }
    }
  }

  private joinRoom(conversationId: UUID, userId: UUID): void {
    if (!this.conversationRooms.has(conversationId)) {
      this.conversationRooms.set(conversationId, new Set());
    }
    this.conversationRooms.get(conversationId)!.add(userId);
  }

  private leaveRoom(conversationId: UUID, userId: UUID): void {
    const room = this.conversationRooms.get(conversationId);
    if (room) {
      room.delete(userId);
      if (room.size === 0) {
        this.conversationRooms.delete(conversationId);
      }
    }
  }

  private broadcastToRoom(conversationId: UUID, message: unknown, excludeUserId?: UUID): void {
    const room = this.conversationRooms.get(conversationId);
    if (!room) return;

    for (const memberId of room) {
      if (memberId === excludeUserId) continue;
      const client = this.clients.get(memberId);
      if (client && client.ws.readyState === WebSocket.OPEN) {
        this.send(client.ws, message);
      }
    }
  }

  private send(ws: WebSocket, message: unknown): void {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(message));
    }
  }

  private startHeartbeat(): void {
    const interval = setInterval(() => {
      this.wss.clients.forEach((ws: WebSocket) => {
        const client = Array.from(this.clients.values()).find((c) => c.ws === ws);
        if (!client) return;

        if (!client.isAlive) {
          ws.terminate();
          this.clients.delete(client.userId);
          return;
        }

        client.isAlive = false;
        ws.ping();
      });
    }, 30000);

    this.wss.on('close', () => clearInterval(interval));
  }
}
