require('dotenv').config();

const express = require('express');
const axios = require('axios');
const admin = require('../firebase');
const router = express.Router();

const CLIENT_ID = process.env.YANDEX_CLIENT_ID;
const CLIENT_SECRET = process.env.YANDEX_CLIENT_SECRET;

router.post('/yandex', async (req, res) => {
  const {code} = req.body;

  if (!code) {
    return res.status(400).json({error: 'Authorization code is required'});
  }

  try {
    // Обмен code на access_token
    const tokenParams = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
    });

    const tokenResponse = await axios.post(
        'https://oauth.yandex.ru/token', tokenParams.toString(), {
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        });

    const accessToken = tokenResponse.data.access_token;

    // Получение данных пользователя
    const userResponse =
        await axios.get('https://login.yandex.ru/info?format=json', {
          headers: {Authorization: `OAuth ${accessToken}`},
        });


    const userData = userResponse.data;
    if (!userData || !userData.id) {
      throw new Error('Failed to fetch valid user profile from Yandex');
    }

    const uid = `yandex:${userData.id}`;

    // Формируем аватарку
    const picture = userData.default_avatar_id ?
        `https://avatars.yandex.net/get-yapic/${
            userData.default_avatar_id}/islands-200` :
        undefined

    //  Передаем данные профиля внутрь
    const additionalClaims = {
      email: userData.default_email,
      name: userData.display_name,
      picture: picture
    };

    // Создаем токен
    const firebaseToken =
        await admin.auth().createCustomToken(uid, additionalClaims);
    try {
      await admin.auth().updateUser(uid, {
        email: userData.default_email,
      });
    } catch (e) {
      // Если пользователя еще нет, создаем его
      await admin.auth().createUser({
        uid: uid,
        email: userData.default_email,
      });
    }

    return res.json({
      firebaseToken,
      displayName: userData.display_name,
      photoURL: picture,
      email: userData.default_email
    });

  } catch (error) {
    const errorDetails = error.response?.data || error.message;
    console.error('Yandex Auth Error:', errorDetails);

    return res.status(500).json({
      error: 'Authentication failed',
      details: process.env.NODE_ENV === 'development' ? errorDetails : undefined
    });
  }
});

module.exports = router;
