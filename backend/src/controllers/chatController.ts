import { Response } from 'express';
import prisma from '../config/db';
import { AuthenticatedRequest } from '../middlewares/auth';

// [POST] /conversation/get_list_conversation
export const getConversations = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  const index = parseInt(req.body.index as string) || 0;
  const count = parseInt(req.body.count as string) || 20;

  try {
    // Tìm tất cả hội thoại của user hiện tại (với tư cách là user_id hoặc partner_id)
    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [
          { user_id: userId },
          { partner_id: userId },
        ],
      },
      skip: index,
      take: count,
      orderBy: { updated_at: 'desc' },
    });

    const formattedList = [];

    for (const conv of conversations) {
      // Xác định ID của partner
      const partnerId = conv.user_id === userId ? conv.partner_id : conv.user_id;

      // Lấy thông tin partner
      const partnerUser = await prisma.user.findUnique({
        where: { id: partnerId },
        select: { username: true, avatar: true },
      });

      const partnerName = partnerUser?.username || 'Người dùng Army';

      // Tính số lượng tin nhắn chưa đọc đối với user hiện tại
      const unreadCount = await prisma.message.count({
        where: {
          conversation_id: conv.id,
          receiver_id: userId,
          is_read: false,
        },
      });

      // Tìm tin nhắn cuối cùng để lấy product_id (nếu có)
      const lastMsg = await prisma.message.findFirst({
        where: { conversation_id: conv.id },
        orderBy: { created_at: 'desc' },
        select: { product_id: true },
      });

      formattedList.push({
        id: conv.id.toString(),
        conversation_id: conv.id.toString(),
        partner_id: partnerId.toString(),
        partnerId: partnerId.toString(),
        partner_name: partnerName,
        partnerName: partnerName,
        last_message: conv.last_message || '',
        lastMessage: conv.last_message || '',
        product_id: lastMsg?.product_id ? lastMsg.product_id.toString() : undefined,
        productId: lastMsg?.product_id ? lastMsg.product_id.toString() : undefined,
        unread: unreadCount > 0,
        is_unread: unreadCount > 0,
      });
    }

    return res.status(200).json({
      code: '1000',
      message: 'OK',
      data: formattedList,
    });
  } catch (error) {
    console.error('getConversations error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [POST] /conversation/get_conversation
export const getConversation = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  // FE truyền ID dưới dạng linh hoạt, có thể là string hoặc number
  const partnerId = parseInt(req.body.partner_id as string);
  let conversationId = parseInt(req.body.conversation_id as string);
  const index = parseInt(req.body.index as string) || 0;
  const count = parseInt(req.body.count as string) || 20;

  if (isNaN(partnerId)) {
    return res.status(200).json({
      code: '1004',
      message: 'Parameter partner_id value is invalid',
      data: null,
    });
  }

  try {
    // Nếu conversationId bị thiếu hoặc không hợp lệ, tìm cuộc hội thoại hiện có giữa 2 người
    if (isNaN(conversationId) || conversationId <= 0) {
      const existingConv = await prisma.conversation.findFirst({
        where: {
          OR: [
            { user_id: userId, partner_id: partnerId },
            { user_id: partnerId, partner_id: userId },
          ],
        },
      });
      
      if (existingConv) {
        conversationId = existingConv.id;
      } else {
        // Trả về danh sách rỗng nếu chưa có cuộc hội thoại nào
        return res.status(200).json({
          code: '1000',
          message: 'OK',
          data: [],
        });
      }
    }

    // Lấy lịch sử tin nhắn
    const messages = await prisma.message.findMany({
      where: { conversation_id: conversationId },
      skip: index,
      take: count,
      orderBy: { created_at: 'desc' },
    });

    const formattedMessages = messages.map((m) => ({
      id: m.id.toString(),
      message_id: m.id.toString(),
      sender_id: m.sender_id.toString(),
      from_id: m.sender_id.toString(),
      user_id: m.sender_id.toString(),
      message: m.message,
      content: m.message,
      type_message: m.type_message,
      type: m.type_message,
      created_at: m.created_at.toISOString(),
      createdAt: m.created_at.toISOString(),
    }));

    return res.status(200).json({
      code: '1000',
      message: 'OK',
      data: formattedMessages,
    });
  } catch (error) {
    console.error('getConversation error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [POST] /conversation/send_message
export const sendMessage = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  const { message, type_message } = req.body;
  const toId = parseInt(req.body.to_id as string);
  const productId = parseInt(req.body.product_id as string) || null;

  if (isNaN(toId) || !message) {
    return res.status(200).json({
      code: '1002',
      message: 'Parameter is not enough or invalid',
      data: null,
    });
  }

  try {
    // 1. Kiểm tra / Tạo cuộc hội thoại
    let conv = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user_id: userId, partner_id: toId },
          { user_id: toId, partner_id: userId },
        ],
      },
    });

    if (!conv) {
      conv = await prisma.conversation.create({
        data: {
          user_id: userId,
          partner_id: toId,
          last_message: message,
          updated_at: new Date(),
        },
      });
    } else {
      await prisma.conversation.update({
        where: { id: conv.id },
        data: {
          last_message: message,
          updated_at: new Date(),
        },
      });
    }

    // 2. Tạo tin nhắn mới trong DB
    const newMsg = await prisma.message.create({
      data: {
        conversation_id: conv.id,
        sender_id: userId,
        receiver_id: toId,
        message: message,
        type_message: type_message || 'text',
        product_id: productId,
        is_read: false,
      },
    });

    // 3. Trả về MessageModel vừa tạo cho FE
    const formatted = {
      id: newMsg.id.toString(),
      message_id: newMsg.id.toString(),
      sender_id: newMsg.sender_id.toString(),
      from_id: newMsg.sender_id.toString(),
      user_id: newMsg.sender_id.toString(),
      message: newMsg.message,
      content: newMsg.message,
      type_message: newMsg.type_message,
      type: newMsg.type_message,
      created_at: newMsg.created_at.toISOString(),
      createdAt: newMsg.created_at.toISOString(),
    };

    return res.status(200).json({
      code: '1000',
      message: 'OK',
      data: formatted,
    });
  } catch (error) {
    console.error('sendMessage error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};

// [POST] /conversation/set_read_message
export const markConversationRead = async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(200).json({
      code: '9998',
      message: 'Token is invalid',
      data: null,
    });
  }

  const partnerId = parseInt(req.body.partner_id as string);

  if (isNaN(partnerId)) {
    return res.status(200).json({
      code: '1004',
      message: 'Parameter partner_id is invalid',
      data: null,
    });
  }

  try {
    // Tìm hội thoại
    const conv = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user_id: userId, partner_id: partnerId },
          { user_id: partnerId, partner_id: userId },
        ],
      },
    });

    if (conv) {
      // Đánh dấu tất cả tin nhắn gửi từ partner tới user hiện tại là đã đọc
      await prisma.message.updateMany({
        where: {
          conversation_id: conv.id,
          sender_id: partnerId,
          receiver_id: userId,
          is_read: false,
        },
        data: {
          is_read: true,
        },
      });
    }

    return res.status(200).json({
      code: '1000',
      message: 'OK',
      data: null,
    });
  } catch (error) {
    console.error('markConversationRead error:', error);
    return res.status(200).json({
      code: '1005',
      message: 'Database error',
      data: null,
    });
  }
};
