const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const cron = require('node-cron')

// Пути
const authRoute = require('./routes/auth');
const notificationRoute = require('./routes/notifications');
const avatarRoute = require('./routes/avatar');
const livekitRoute = require('./routes/livekit');
const userRoute = require('./routes/user');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({extended: true}));

// Регистрируем пути
app.use('/auth', authRoute);
app.use('/notifications', notificationRoute);
app.use('/avatar', avatarRoute);
app.use('/livekit', livekitRoute);
app.use('/user', userRoute);

app.get('/', (req, res) => {
  res.json({
    message: 'Server is running',
    endpoints: {livekit: '/livekit/getToken, /livekit/kickParticipant, etc.'}
  });
});

// Задача для проверки не начались ли встречи
cron.schedule('* * * * *', async () => {
  console.log(`[${new Date().toISOString()}] Отправка запроса...`);
  try {
    const response = await fetch(
        `https://seva.danilkin2244.fvds.ru/notifications/check-meeting-reminders`,
        {method: 'POST'});

    if (!response.ok) {
      throw new Error(`Ошибка сервера: ${response.status}`);
    }
    const data = await response.json();
    console.log('Ответ успешно получен:', data);
  } catch (error) {
    console.error('Ошибка при отправке запроса:', error.message);
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
