const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

db = admin.firestore();

const AFERCON_PAY_ACCOUNT_ID = "sHpXj1WTpdXBDdYQMMu7Xs4s2OK2";
const WITHDRAWAL_FEE_PERCENTAGE = 0.10; // 10%
const CREDIT_APPLICATION_FEE = 1000; // 1000 Kz

exports.transferFunds = onCall({region: "europe-west1"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "A função só pode ser chamada por um utilizador autenticado.");
  }
  const senderId = request.auth.uid;
  const {recipientId, amount, note} = request.data;
  if (!recipientId || typeof recipientId !== "string" || !amount || typeof amount !== "number" || amount <= 0) {
    throw new HttpsError("invalid-argument", "Os dados fornecidos são inválidos.");
  }
  if (senderId === recipientId) {
    throw new HttpsError("invalid-argument", "Não pode enviar dinheiro para si mesmo.");
  }
  const senderRef = db.collection("users").doc(senderId);
  const recipientRef = db.collection("users").doc(recipientId);
  try {
    await db.runTransaction(async (transaction) => {
      const senderDoc = await transaction.get(senderRef);
      const recipientDoc = await transaction.get(recipientRef);
      if (!senderDoc.exists) {
        throw new HttpsError("not-found", "Remetente não encontrado.");
      }
      if (!recipientDoc.exists) {
        throw new HttpsError("not-found", "Destinatário não encontrado.");
      }
      const senderData = senderDoc.data();
      const recipientData = recipientDoc.data();
      const senderBalance = senderData.balance || 0;
      if (senderBalance < amount) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente.");
      }
      const timestamp = admin.firestore.FieldValue.serverTimestamp();
      transaction.update(senderRef, {balance: senderBalance - amount});
      transaction.update(recipientRef, {balance: (recipientData.balance || 0) + amount});
      const senderTransactionRef = senderRef.collection("transactions").doc();
      transaction.set(senderTransactionRef, {amount, type: "debit", description: `Transferência para ${recipientData.displayName}`, note: note || null, relatedUserId: recipientId, timestamp});
      const recipientTransactionRef = recipientRef.collection("transactions").doc();
      transaction.set(recipientTransactionRef, {amount, type: "credit", description: `Recebido de ${senderData.displayName}`, note: note || null, relatedUserId: senderId, timestamp});
      const senderNotificationRef = senderRef.collection("notifications").doc();
      transaction.set(senderNotificationRef, {title: "Transferência Enviada", body: `Enviou ${amount.toFixed(2)} Kz para ${recipientData.displayName}.`, type: "transfer_out", isRead: false, timestamp});
      const recipientNotificationRef = recipientRef.collection("notifications").doc();
      transaction.set(recipientNotificationRef, {title: "Dinheiro Recebido", body: `Recebeu ${amount.toFixed(2)} Kz de ${senderData.displayName}.`, type: "transfer_in", isRead: false, timestamp});
    });
    logger.info(`Transferência de ${amount} de ${senderId} para ${recipientId} concluída.`);
    return {success: true, message: "Transferência bem-sucedida"};
  } catch (error) {
    logger.error("A transação de transferência de fundos falhou:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Ocorreu um erro interno.");
  }
});

exports.processQrTransaction = onCall({region: "europe-west1"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "A autenticação é necessária.");
  }
  const senderId = request.auth.uid;
  const {recipientId, amount} = request.data;
  if (!recipientId || !amount || amount <= 0) {
    throw new HttpsError("invalid-argument", "Dados da transação inválidos.");
  }
  const senderRef = db.collection("users").doc(senderId);
  const recipientRef = db.collection("users").doc(recipientId);
  try {
    await db.runTransaction(async (transaction) => {
      const senderDoc = await transaction.get(senderRef);
      const recipientDoc = await transaction.get(recipientRef);
      if (!senderDoc.exists) throw new Error("Remetente não encontrado.");
      if (!recipientDoc.exists) throw new Error("Comerciante não encontrado.");
      const senderData = senderDoc.data();
      const recipientData = recipientDoc.data();
      const senderBalance = senderData.balance || 0;
      if (senderBalance < amount) throw new Error("Saldo insuficiente.");
      transaction.update(senderRef, {balance: senderBalance - amount});
      transaction.update(recipientRef, {balance: (recipientData.balance || 0) + amount});
      const timestamp = admin.firestore.FieldValue.serverTimestamp();
      transaction.set(senderRef.collection("transactions").doc(), {amount, type: "debit", description: `Pagamento para ${recipientData.displayName}`, relatedUserId: recipientId, timestamp});
      transaction.set(recipientRef.collection("transactions").doc(), {amount, type: "credit", description: `Pagamento recebido de ${senderData.displayName}`, relatedUserId: senderId, timestamp});
      transaction.set(senderRef.collection("notifications").doc(), {title: "Pagamento Efetuado", body: `Pagou ${amount.toFixed(2)} Kz a ${recipientData.displayName}.`, type: "payment_out", isRead: false, timestamp});
      transaction.set(recipientRef.collection("notifications").doc(), {title: "Pagamento Recebido", body: `Recebeu ${amount.toFixed(2)} Kz de ${senderData.displayName}.`, type: "payment_in", isRead: false, timestamp});
    });
    return {success: true, message: "Pagamento processado com sucesso."};
  } catch (error) {
    logger.error("Falha na transação do pagamento QR:", error);
    throw new HttpsError("internal", error.message || "Ocorreu um erro.");
  }
});

exports.createWithdrawalRequest = onCall({region: "europe-west1"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "A autenticação é necessária.");
  }

  const userId = request.auth.uid;
  const {amount, fullName, iban} = request.data;

  if (!amount || typeof amount !== "number" || amount <= 0 || !fullName || !iban) {
    throw new HttpsError("invalid-argument", "O montante, nome do beneficiário e IBAN são obrigatórios.");
  }

  if (!/^AO06\d{21}$/.test(iban)) {
    throw new HttpsError("invalid-argument", "O formato do IBAN é inválido. Deve ser AO06 seguido de 21 dígitos.");
  }

  const userRef = db.collection("users").doc(userId);

  try {
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Utilizador não encontrado.");
      }

      const userData = userDoc.data();
      const userBalance = userData.balance || 0;
      const withdrawalFee = amount * WITHDRAWAL_FEE_PERCENTAGE;
      const totalDebitAmount = amount + withdrawalFee;

      if (userBalance < totalDebitAmount) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente para cobrir o levantamento e a taxa.");
      }

      const timestamp = admin.firestore.FieldValue.serverTimestamp();
      const requestId = db.collection("withdrawal_requests").doc().id; 

      const requestRef = db.collection("withdrawal_requests").doc(requestId);
      transaction.set(requestRef, {
        userId: userId,
        userName: userData.displayName,
        amount: amount,
        fee: withdrawalFee,
        totalAmount: totalDebitAmount,
        fullName: fullName,
        iban: iban,
        status: "pending",
        requestDate: timestamp,
      });

      const userTransactionRef = userRef.collection("transactions").doc();
      transaction.set(userTransactionRef, {
        amount: amount,
        type: "withdrawal_pending",
        description: "Pedido de Levantamento",
        status: "pending",
        relatedRequestId: requestId, 
        timestamp: timestamp,
      });

      const userNotificationRef = userRef.collection("notifications").doc();
      transaction.set(userNotificationRef, {
        title: "Pedido de Levantamento Submetido",
        body: `O seu pedido para levantar ${amount.toFixed(2)} Kz foi recebido e está a ser processado.`,
        type: "withdrawal_request",
        isRead: false,
        timestamp: timestamp,
      });
    });

    logger.info(`Pedido de levantamento de ${amount} para ${userId} criado com sucesso.`);
    return {success: true, message: "Pedido de levantamento submetido com sucesso." };

  } catch (error) {
    logger.error(`Falha ao criar pedido de levantamento para ${userId}:`, error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Ocorreu um erro interno ao processar o seu pedido.");
  }
});


exports.requestCredit = onCall({region: "europe-west1"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "A autenticação é necessária.");
  }
  const userId = request.auth.uid;
  const {creditAmount, reason} = request.data;
  if (!creditAmount || typeof creditAmount !== "number" || creditAmount <= 0 || !reason) {
    throw new HttpsError("invalid-argument", "O montante e o motivo do crédito são obrigatórios.");
  }
  const userRef = db.collection("users").doc(userId);
  const aferconPayRef = db.collection("users").doc(AFERCON_PAY_ACCOUNT_ID);
  try {
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      const aferconPayDoc = await transaction.get(aferconPayRef);
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Utilizador não encontrado.");
      }
      if (!aferconPayDoc.exists) {
        throw new HttpsError("internal", "A conta principal da Afercon Pay não foi configurada. Contacte o suporte.");
      }
      const userData = userDoc.data();
      const aferconPayData = aferconPayDoc.data();
      const userBalance = userData.balance || 0;
      if (userBalance < CREDIT_APPLICATION_FEE) {
        throw new HttpsError("failed-precondition", `Saldo insuficiente. É necessária uma taxa de ${CREDIT_APPLICATION_FEE} Kz.`);
      }
      const timestamp = admin.firestore.FieldValue.serverTimestamp();
      transaction.update(userRef, {balance: userBalance - CREDIT_APPLICATION_FEE});
      transaction.update(aferconPayRef, {balance: (aferconPayData.balance || 0) + CREDIT_APPLICATION_FEE});
      const creditRequestRef = db.collection("credit_requests").doc();
      transaction.set(creditRequestRef, {userId: userId, userName: userData.displayName, amount: creditAmount, reason: reason, status: "pending", createdAt: timestamp});
      const userTransactionRef = userRef.collection("transactions").doc();
      transaction.set(userTransactionRef, {amount: CREDIT_APPLICATION_FEE, type: "debit", description: "Taxa de Pedido de Crédito", relatedUserId: AFERCON_PAY_ACCOUNT_ID, timestamp});
      const aferconPayTransactionRef = aferconPayRef.collection("transactions").doc();
      transaction.set(aferconPayTransactionRef, {amount: CREDIT_APPLICATION_FEE, type: "credit", description: `Taxa de pedido de crédito de ${userData.displayName}`, relatedUserId: userId, timestamp});
      const userNotificationRef = userRef.collection("notifications").doc();
      transaction.set(userNotificationRef, {title: "Pedido de Crédito Recebido", body: `O seu pedido de crédito de ${creditAmount.toFixed(2)} Kz foi submetido. A taxa de ${CREDIT_APPLICATION_FEE} Kz foi cobrada.`, type: "credit_request", isRead: false, timestamp});
    });
    logger.info(`Pedido de crédito de ${creditAmount} para ${userId} processado.`);
    return {success: true, message: "Pedido de crédito submetido com sucesso." };
  } catch (error) {
    logger.error(`Falha no pedido de crédito para o utilizador ${userId}:`, error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Ocorreu um erro interno ao processar o seu pedido.");
  }
});

exports.sendPushNotification = onDocumentCreated({document: "users/{userId}/notifications/{notificationId}", region: "europe-west1"}, async (event) => {
  const {userId} = event.params;
  logger.log(`Nova notificação para o utilizador: ${userId}`);
  const snapshot = event.data;
  if (!snapshot) {
    logger.log("Nenhum dado associado ao evento. A abortar.");
    return;
  }
  const notificationData = snapshot.data();
  const {title, body} = notificationData;
  if (!title || !body) {
    logger.log("Notificação sem título ou corpo. A abortar.");
    return;
  }
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    logger.error(`Documento do utilizador não encontrado para userId: ${userId}`);
    return;
  }
  const fcmTokens = userDoc.data().fcmTokens;
  if (!fcmTokens || !Array.isArray(fcmTokens) || fcmTokens.length === 0) {
    logger.log(`Utilizador ${userId} não tem tokens FCM válidos. A abortar.`);
    return;
  }
  logger.log(`Encontrados ${fcmTokens.length} tokens FCM para ${userId}.`);
  const payload = {notification: {title, body}, data: {click_action: "FLUTTER_NOTIFICATION_CLICK", type: notificationData.type || "general"}};
  const response = await admin.messaging().sendToDevice(fcmTokens, payload);
  const tokensToRemove = [];
  response.results.forEach((result, index) => {
    const error = result.error;
    if (error) {
      logger.error("Falha ao enviar notificação para", fcmTokens[index], error);
      if (error.code === "messaging/invalid-registration-token" || error.code === "messaging/registration-token-not-registered") {
        tokensToRemove.push(fcmTokens[index]);
      }
    }
  });
  if (tokensToRemove.length > 0) {
    logger.log(`A remover ${tokensToRemove.length} tokens inválidos.`);
    await userDoc.ref.update({fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove)});
  }
  logger.log("Notificações enviadas com sucesso.");
});
