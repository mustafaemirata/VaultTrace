require('dotenv').config();
const mysql = require('mysql2');
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'vaultrace_secret_key_2024';

const db = mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'bank_db'
});

db.connect(err => {
  if (err) {
    console.error('MySQL Baglanti Hatasi: ' + err.stack);
    return;
  }
  console.log('MySQL baglantisi basarili. ID: ' + db.threadId);
  createTables();
});

function createTables() {
  const queries = [
    `CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      tc_no VARCHAR(11) UNIQUE NOT NULL,
      ad VARCHAR(50) NOT NULL,
      soyad VARCHAR(50) NOT NULL,
      email VARCHAR(100),
      telefon VARCHAR(15),
      sifre VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,
    `CREATE TABLE IF NOT EXISTS accounts (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      hesap_no VARCHAR(20) UNIQUE NOT NULL,
      iban VARCHAR(26) UNIQUE NOT NULL,
      bakiye DECIMAL(15,2) DEFAULT 0.00,
      doviz_tipi VARCHAR(5) DEFAULT 'TRY',
      hesap_turu VARCHAR(20) DEFAULT 'vadesiz',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS transactions (
      id INT AUTO_INCREMENT PRIMARY KEY,
      from_account INT,
      to_account INT,
      tutar DECIMAL(15,2) NOT NULL,
      islem_tipi VARCHAR(20) NOT NULL,
      aciklama VARCHAR(255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (from_account) REFERENCES accounts(id),
      FOREIGN KEY (to_account) REFERENCES accounts(id)
    )`,
    `CREATE TABLE IF NOT EXISTS cards (
      id INT AUTO_INCREMENT PRIMARY KEY,
      account_id INT NOT NULL,
      kart_no VARCHAR(16) UNIQUE NOT NULL,
      cvv VARCHAR(3) NOT NULL,
      son_kullanma VARCHAR(5) NOT NULL,
      kart_tipi VARCHAR(10) DEFAULT 'debit',
      kart_limit DECIMAL(15,2) DEFAULT 5000.00,
      harcanan DECIMAL(15,2) DEFAULT 0.00,
      aktif TINYINT DEFAULT 1,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (account_id) REFERENCES accounts(id)
    )`,
    `CREATE TABLE IF NOT EXISTS loans (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      tutar DECIMAL(15,2) NOT NULL,
      faiz_orani DECIMAL(5,2) DEFAULT 2.49,
      vade_ay INT NOT NULL,
      aylik_taksit DECIMAL(15,2) NOT NULL,
      kalan_taksit INT NOT NULL,
      durum VARCHAR(20) DEFAULT 'aktif',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS bills (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      kurum VARCHAR(50) NOT NULL,
      abone_no VARCHAR(20) NOT NULL,
      tutar DECIMAL(15,2) NOT NULL,
      son_odeme DATE,
      odendi TINYINT DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS logs (
      id INT AUTO_INCREMENT PRIMARY KEY,
      action_type VARCHAR(50),
      device_info VARCHAR(100),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`
  ];

  queries.forEach(q => {
    db.query(q, err => {
      if (err) console.error('Tablo olusturma hatasi:', err.message);
    });
  });
  console.log('Tablolar kontrol edildi.');
}

function authMiddleware(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Token gerekli' });
  }
  try {
    const decoded = jwt.verify(auth.split(' ')[1], JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (e) {
    return res.status(401).json({ success: false, error: 'Gecersiz token' });
  }
}

function generateAccountNo() {
  return Array.from({ length: 16 }, () => Math.floor(Math.random() * 10)).join('');
}

function generateIBAN() {
  const num = Array.from({ length: 24 }, () => Math.floor(Math.random() * 10)).join('');
  return 'TR' + num;
}

function generateCardNo() {
  return Array.from({ length: 16 }, () => Math.floor(Math.random() * 10)).join('');
}

function generateCVV() {
  return String(Math.floor(100 + Math.random() * 900));
}

function generateExpiry() {
  const m = String(Math.floor(1 + Math.random() * 12)).padStart(2, '0');
  const y = String(new Date().getFullYear() + Math.floor(2 + Math.random() * 4)).slice(2);
  return `${m}/${y}`;
}

app.post('/api/auth/register', async (req, res) => {
  const { tc_no, ad, soyad, sifre, email, telefon } = req.body;
  if (!tc_no || !ad || !soyad || !sifre) {
    return res.json({ success: false, error: 'Tum zorunlu alanlari doldurun' });
  }

  try {
    const hash = await bcrypt.hash(sifre, 10);

    db.query(
      'INSERT INTO users (tc_no, ad, soyad, sifre, email, telefon) VALUES (?, ?, ?, ?, ?, ?)',
      [tc_no, ad, soyad, hash, email || null, telefon || null],
      (err, result) => {
        if (err) {
          if (err.code === 'ER_DUP_ENTRY') {
            return res.json({ success: false, error: 'Bu TC No ile kayitli hesap var' });
          }
          return res.json({ success: false, error: 'Kayit hatasi' });
        }

        const userId = result.insertId;
        const hesapNo = generateAccountNo();
        const iban = generateIBAN();

        db.query(
          'INSERT INTO accounts (user_id, hesap_no, iban, bakiye, doviz_tipi) VALUES (?, ?, ?, 10000.00, ?)',
          [userId, hesapNo, iban, 'TRY'],
          (err2) => {
            if (err2) console.error('Hesap olusturma hatasi:', err2);

            db.query('SELECT id FROM accounts WHERE user_id = ? LIMIT 1', [userId], (err3, accs) => {
              if (!err3 && accs.length > 0) {
                db.query(
                  'INSERT INTO transactions (to_account, tutar, islem_tipi, aciklama) VALUES (?, 10000, ?, ?)',
                  [accs[0].id, 'yatirma', 'Hosgeldin bakiyesi']
                );
              }
            });

            const faturalar = [
              ['Elektrik', 'E' + Math.floor(1000000 + Math.random() * 9000000), 245.90],
              ['Su', 'S' + Math.floor(1000000 + Math.random() * 9000000), 89.50],
              ['Dogalgaz', 'D' + Math.floor(1000000 + Math.random() * 9000000), 380.00],
              ['Internet', 'I' + Math.floor(1000000 + Math.random() * 9000000), 199.00],
            ];
            faturalar.forEach(([kurum, abone, tutar]) => {
              db.query(
                'INSERT INTO bills (user_id, kurum, abone_no, tutar) VALUES (?, ?, ?, ?)',
                [userId, kurum, abone, tutar]
              );
            });

            const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '30d' });
            res.json({
              success: true,
              token,
              user: { id: userId, tc_no, ad, soyad, email, telefon },
            });
          }
        );
      }
    );
  } catch (e) {
    res.json({ success: false, error: 'Sunucu hatasi' });
  }
});

app.post('/api/auth/login', (req, res) => {
  const { tc_no, sifre } = req.body;
  if (!tc_no || !sifre) {
    return res.json({ success: false, error: 'TC No ve sifre zorunlu' });
  }

  db.query('SELECT * FROM users WHERE tc_no = ?', [tc_no], async (err, rows) => {
    if (err || rows.length === 0) {
      return res.json({ success: false, error: 'Kullanici bulunamadi' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(sifre, user.sifre);
    if (!match) {
      return res.json({ success: false, error: 'Sifre hatali' });
    }

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '30d' });
    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        tc_no: user.tc_no,
        ad: user.ad,
        soyad: user.soyad,
        email: user.email,
        telefon: user.telefon,
      },
    });
  });
});

app.get('/api/dashboard', authMiddleware, (req, res) => {
  const userId = req.userId;

  db.query('SELECT * FROM accounts WHERE user_id = ?', [userId], (err, accounts) => {
    if (err) return res.json({ hesaplar: [], toplam_bakiye: 0 });

    const toplamBakiye = accounts.reduce((sum, a) => sum + parseFloat(a.bakiye || 0), 0);

    db.query('SELECT COUNT(*) as c FROM cards WHERE account_id IN (SELECT id FROM accounts WHERE user_id = ?)', [userId], (err2, cardRes) => {
      db.query('SELECT COUNT(*) as c FROM bills WHERE user_id = ? AND odendi = 0', [userId], (err3, billRes) => {
        db.query('SELECT COUNT(*) as c FROM loans WHERE user_id = ? AND durum = "aktif"', [userId], (err4, loanRes) => {
          const accIds = accounts.map(a => a.id);
          if (accIds.length === 0) {
            return res.json({
              hesaplar: accounts,
              toplam_bakiye: toplamBakiye,
              kart_sayisi: 0,
              odenmemis_fatura: 0,
              aktif_kredi: 0,
              son_islemler: [],
            });
          }

          db.query(
            `SELECT * FROM transactions WHERE from_account IN (?) OR to_account IN (?) ORDER BY created_at DESC LIMIT 10`,
            [accIds, accIds],
            (err5, transactions) => {
              res.json({
                hesaplar: accounts,
                toplam_bakiye: toplamBakiye,
                kart_sayisi: cardRes?.[0]?.c || 0,
                odenmemis_fatura: billRes?.[0]?.c || 0,
                aktif_kredi: loanRes?.[0]?.c || 0,
                son_islemler: transactions || [],
              });
            }
          );
        });
      });
    });
  });
});

app.get('/api/accounts', authMiddleware, (req, res) => {
  db.query('SELECT * FROM accounts WHERE user_id = ?', [req.userId], (err, rows) => {
    res.json(err ? [] : rows);
  });
});

app.get('/api/accounts/:id/transactions', authMiddleware, (req, res) => {
  const accId = parseInt(req.params.id);
  db.query(
    `SELECT * FROM transactions WHERE from_account = ? OR to_account = ? ORDER BY created_at DESC`,
    [accId, accId],
    (err, rows) => {
      res.json(err ? [] : rows);
    }
  );
});

app.post('/api/transfer', authMiddleware, (req, res) => {
  const { from_account_id, to_iban, tutar, aciklama } = req.body;

  if (!from_account_id || !to_iban || !tutar || tutar <= 0) {
    return res.json({ success: false, error: 'Gecersiz transfer bilgileri' });
  }

  db.query('SELECT * FROM accounts WHERE id = ? AND user_id = ?', [from_account_id, req.userId], (err, fromAccs) => {
    if (err || fromAccs.length === 0) {
      return res.json({ success: false, error: 'Gonderen hesap bulunamadi' });
    }

    const fromAcc = fromAccs[0];
    if (parseFloat(fromAcc.bakiye) < tutar) {
      return res.json({ success: false, error: 'Yetersiz bakiye' });
    }

    db.query('SELECT * FROM accounts WHERE iban = ?', [to_iban], (err2, toAccs) => {
      if (err2 || toAccs.length === 0) {
        return res.json({ success: false, error: 'Alici IBAN bulunamadi' });
      }

      const toAcc = toAccs[0];

      db.query('UPDATE accounts SET bakiye = bakiye - ? WHERE id = ?', [tutar, fromAcc.id]);
      db.query('UPDATE accounts SET bakiye = bakiye + ? WHERE id = ?', [tutar, toAcc.id]);

      db.query(
        'INSERT INTO transactions (from_account, to_account, tutar, islem_tipi, aciklama) VALUES (?, ?, ?, ?, ?)',
        [fromAcc.id, toAcc.id, tutar, 'havale', aciklama || 'Havale']
      );

      res.json({ success: true, message: 'Transfer basarili' });
    });
  });
});

app.get('/api/cards', authMiddleware, (req, res) => {
  db.query(
    'SELECT c.* FROM cards c JOIN accounts a ON c.account_id = a.id WHERE a.user_id = ?',
    [req.userId],
    (err, rows) => {
      res.json(err ? [] : rows);
    }
  );
});

app.post('/api/cards', authMiddleware, (req, res) => {
  const { account_id, kart_tipi } = req.body;

  db.query('SELECT id FROM accounts WHERE id = ? AND user_id = ?', [account_id, req.userId], (err, accs) => {
    if (err || accs.length === 0) {
      return res.json({ success: false, error: 'Hesap bulunamadi' });
    }

    const kartNo = generateCardNo();
    const cvv = generateCVV();
    const skt = generateExpiry();
    const limit = kart_tipi === 'kredi' ? 15000.00 : 5000.00;

    db.query(
      'INSERT INTO cards (account_id, kart_no, cvv, son_kullanma, kart_tipi, kart_limit) VALUES (?, ?, ?, ?, ?, ?)',
      [account_id, kartNo, cvv, skt, kart_tipi || 'debit', limit],
      (err2, result) => {
        if (err2) return res.json({ success: false, error: 'Kart olusturulamadi' });
        res.json({ success: true, id: result.insertId });
      }
    );
  });
});

app.put('/api/cards/:id', authMiddleware, (req, res) => {
  const cardId = parseInt(req.params.id);
  const { aktif, kart_limit } = req.body;

  const updates = [];
  const vals = [];
  if (aktif !== undefined) { updates.push('aktif = ?'); vals.push(aktif ? 1 : 0); }
  if (kart_limit !== undefined) { updates.push('kart_limit = ?'); vals.push(kart_limit); }

  if (updates.length === 0) return res.json({ success: false, error: 'Guncellenecek alan yok' });

  vals.push(cardId);
  db.query(`UPDATE cards SET ${updates.join(', ')} WHERE id = ?`, vals, (err) => {
    if (err) return res.json({ success: false, error: 'Guncelleme hatasi' });
    res.json({ success: true });
  });
});

app.get('/api/loans', authMiddleware, (req, res) => {
  db.query('SELECT * FROM loans WHERE user_id = ? ORDER BY created_at DESC', [req.userId], (err, rows) => {
    res.json(err ? [] : rows);
  });
});

app.post('/api/loans/apply', authMiddleware, (req, res) => {
  const { tutar, vade_ay } = req.body;
  if (!tutar || !vade_ay || tutar <= 0 || vade_ay < 3) {
    return res.json({ success: false, error: 'Gecersiz kredi bilgileri' });
  }

  const faiz = 2.49 / 100;
  const aylikTaksit = (tutar * faiz * Math.pow(1 + faiz, vade_ay)) / (Math.pow(1 + faiz, vade_ay) - 1);

  db.query(
    'INSERT INTO loans (user_id, tutar, vade_ay, aylik_taksit, kalan_taksit) VALUES (?, ?, ?, ?, ?)',
    [req.userId, tutar, vade_ay, aylikTaksit.toFixed(2), vade_ay],
    (err, result) => {
      if (err) return res.json({ success: false, error: 'Kredi basvurusu basarisiz' });

      db.query('SELECT id FROM accounts WHERE user_id = ? AND doviz_tipi = "TRY" LIMIT 1', [req.userId], (err2, accs) => {
        if (!err2 && accs.length > 0) {
          db.query('UPDATE accounts SET bakiye = bakiye + ? WHERE id = ?', [tutar, accs[0].id]);
          db.query(
            'INSERT INTO transactions (to_account, tutar, islem_tipi, aciklama) VALUES (?, ?, ?, ?)',
            [accs[0].id, tutar, 'kredi', `Kredi - ${vade_ay} ay vadeli`]
          );
        }
      });

      res.json({ success: true, id: result.insertId });
    }
  );
});

app.get('/api/bills', authMiddleware, (req, res) => {
  db.query('SELECT * FROM bills WHERE user_id = ? ORDER BY odendi ASC, created_at DESC', [req.userId], (err, rows) => {
    res.json(err ? [] : rows);
  });
});

app.post('/api/bills/:id/pay', authMiddleware, (req, res) => {
  const billId = parseInt(req.params.id);
  const { account_id } = req.body;

  db.query('SELECT * FROM bills WHERE id = ? AND user_id = ? AND odendi = 0', [billId, req.userId], (err, bills) => {
    if (err || bills.length === 0) {
      return res.json({ success: false, error: 'Fatura bulunamadi veya zaten odendi' });
    }

    const bill = bills[0];

    db.query('SELECT * FROM accounts WHERE id = ? AND user_id = ?', [account_id, req.userId], (err2, accs) => {
      if (err2 || accs.length === 0) {
        return res.json({ success: false, error: 'Hesap bulunamadi' });
      }

      if (parseFloat(accs[0].bakiye) < parseFloat(bill.tutar)) {
        return res.json({ success: false, error: 'Yetersiz bakiye' });
      }

      db.query('UPDATE accounts SET bakiye = bakiye - ? WHERE id = ?', [bill.tutar, account_id]);
      db.query('UPDATE bills SET odendi = 1 WHERE id = ?', [billId]);
      db.query(
        'INSERT INTO transactions (from_account, tutar, islem_tipi, aciklama) VALUES (?, ?, ?, ?)',
        [account_id, bill.tutar, 'fatura', `${bill.kurum} fatura odemesi`]
      );

      res.json({ success: true, message: 'Fatura odendi' });
    });
  });
});

const baseRates = {
  USD: { alis: 32.45, satis: 32.65 },
  EUR: { alis: 35.10, satis: 35.35 },
  GBP: { alis: 41.20, satis: 41.55 },
  JPY: { alis: 0.218, satis: 0.222 },
  CHF: { alis: 37.80, satis: 38.10 },
};

app.get('/api/exchange-rates', authMiddleware, (req, res) => {
  const rates = {};
  Object.entries(baseRates).forEach(([key, val]) => {
    const fluctuation = 1 + (Math.random() - 0.5) * 0.01;
    rates[key] = {
      alis: parseFloat((val.alis * fluctuation).toFixed(4)),
      satis: parseFloat((val.satis * fluctuation).toFixed(4)),
    };
  });
  res.json(rates);
});

app.post('/api/exchange', authMiddleware, (req, res) => {
  const { from_account_id, to_doviz, tutar } = req.body;

  if (!from_account_id || !to_doviz || !tutar || tutar <= 0) {
    return res.json({ success: false, error: 'Gecersiz doviz islemi bilgileri' });
  }

  db.query('SELECT * FROM accounts WHERE id = ? AND user_id = ?', [from_account_id, req.userId], (err, fromAccs) => {
    if (err || fromAccs.length === 0) {
      return res.json({ success: false, error: 'Kaynak hesap bulunamadi' });
    }

    const fromAcc = fromAccs[0];
    const fromDoviz = fromAcc.doviz_tipi;

    let convertedAmount;
    if (fromDoviz === 'TRY') {
      const rate = baseRates[to_doviz];
      if (!rate) return res.json({ success: false, error: 'Gecersiz doviz' });
      convertedAmount = tutar / rate.satis;
    } else {
      const rate = baseRates[fromDoviz];
      if (!rate) return res.json({ success: false, error: 'Gecersiz doviz' });
      convertedAmount = tutar * rate.alis;
    }

    if (parseFloat(fromAcc.bakiye) < tutar) {
      return res.json({ success: false, error: 'Yetersiz bakiye' });
    }

    db.query('SELECT * FROM accounts WHERE user_id = ? AND doviz_tipi = ?', [req.userId, to_doviz], (err2, toAccs) => {
      const processExchange = (toAccId) => {
        db.query('UPDATE accounts SET bakiye = bakiye - ? WHERE id = ?', [tutar, fromAcc.id]);
        db.query('UPDATE accounts SET bakiye = bakiye + ? WHERE id = ?', [convertedAmount.toFixed(2), toAccId]);
        db.query(
          'INSERT INTO transactions (from_account, to_account, tutar, islem_tipi, aciklama) VALUES (?, ?, ?, ?, ?)',
          [fromAcc.id, toAccId, tutar, 'doviz', `${fromDoviz} -> ${to_doviz} doviz islemi`]
        );
        res.json({ success: true, message: 'Doviz islemi basarili' });
      };

      if (!err2 && toAccs.length > 0) {
        processExchange(toAccs[0].id);
      } else {
        const hesapNo = generateAccountNo();
        const iban = generateIBAN();
        db.query(
          'INSERT INTO accounts (user_id, hesap_no, iban, bakiye, doviz_tipi) VALUES (?, ?, ?, 0, ?)',
          [req.userId, hesapNo, iban, to_doviz],
          (err3, result) => {
            if (err3) return res.json({ success: false, error: 'Hesap olusturulamadi' });
            processExchange(result.insertId);
          }
        );
      }
    });
  });
});

app.get('/api/add-log', (req, res) => {
  const sql = "INSERT INTO logs (action_type, device_info) VALUES ('VAULT_TRACE_CHECK', 'Flutter_Device')";
  db.query(sql, (err, result) => {
    if (err) return res.status(500).json({ success: false, error: "Veritabani hatasi olustu" });
    res.json({ success: true, message: "Islem Basarili: Yeni log eklendi" });
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`VaultTrace Sunucusu ${PORT} portunda calisiyor...`);
});