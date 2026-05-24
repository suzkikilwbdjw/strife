const express = require('express');
const router = express.Router();

// Проверяем наличие sharp
let sharp;
try {
  sharp = require('sharp');
  console.log('Sharp loaded successfully');
} catch (error) {
  console.log('Sharp not available, using SVG only mode');
}

// Генерация случайного цвета
function getRandomColor() {
  const colors = [
    '#1abc9c', '#2ecc71', '#3498db', '#9b59b6', '#34495e', '#f1c40f', '#e67e22',
    '#e74c3c', '#95a5a6', '#16a085', '#27ae60', '#2980b9', '#8e44ad', '#2c3e50',
    '#f39c12', '#d35400', '#c0392b', '#7f8c8d', '#FF6B6B', '#4ECDC4', '#45B7D1',
    '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8'
  ];
  return colors[Math.floor(Math.random() * colors.length)];
}

// GET эндпоинт для генерации аватара
router.get('/get-avatar', async (req, res) => {
  try {
    let {
      name,
      size = 256,
      background,
      color = '#ffffff',
      rounded = 'true',
      length = 1,
      format = 'svg'
    } = req.query;

    // Обработка параметров
    size = Math.min(Math.max(parseInt(size) || 256, 64), 1024);
    length = Math.min(Math.max(parseInt(length) || 1, 1), 3);

    // Декодируем имя из URL
    let decodedName = name ? decodeURIComponent(name) : '';

    // Получаем инициалы
    let initials = '';
    if (decodedName) {
      const words = decodedName.trim().split(/\s+/);
      for (let i = 0; i < Math.min(words.length, length); i++) {
        if (words[i] && words[i][0]) {
          initials += words[i][0].toUpperCase();
        }
      }
    }

    if (!initials) {
      initials = '?';
    }

    // Выбираем цвет фона
    let bgColor = background;
    if (!bgColor || bgColor === 'random') {
      bgColor = getRandomColor();
    }

    // Создаем SVG
    const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
    <rect width="${size}" height="${size}" fill="${bgColor}" rx="${
        rounded === 'true' ? size / 2 : 20}" />
    <text
        x="50%"
        y="50%"
        fill="${color}"
        font-family="Arial, Helvetica, sans-serif"
        font-size="${size * 0.4}px"
        font-weight="bold"
        text-anchor="middle"
        dominant-baseline="middle"
    >${initials}</text>
</svg>`;

    // Если запрошен PNG и sharp доступен
    if (format === 'png' && sharp) {
      try {
        const pngBuffer = await sharp(Buffer.from(svg)).png().toBuffer();

        res.setHeader('Content-Type', 'image/png');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        res.setHeader('Access-Control-Allow-Origin', '*');
        return res.send(pngBuffer);
      } catch (sharpError) {
        console.error('Sharp conversion error:', sharpError);
        // fallback to SVG
      }
    }

    // По умолчанию отдаём SVG
    res.setHeader('Content-Type', 'image/svg+xml');
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.send(svg);

  } catch (error) {
    console.error('Ошибка генерации аватара:', error);
    res.status(500).json({error: 'Ошибка генерации аватара: ' + error.message});
  }
});

// Эндпоинт для проверки работоспособности
router.get('/avatar-health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    service: 'Avatar Generator',
    sharp: sharp ? 'available' : 'not available',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
