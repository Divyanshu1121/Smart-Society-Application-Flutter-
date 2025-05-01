<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
 
</head>
<body>

  <h1>🏠 Smart Society App</h1>
  <p><strong>A modern mobile app to manage residential societies using Flutter & Firebase.</strong></p>

  <div class="section">
    <h2>🚀 Features</h2>
    <ul class="feature-list">
      <li><strong>👤 Login/Signup:</strong> Secure Firebase Authentication with attractive UI</li>
      <li><strong>📋 Notice Board:</strong> Admins post notices; users view them in real-time</li>
      <li><strong>🛠️ Maintenance:</strong> Flat-wise billing and maintenance updates</li>
      <li><strong>📅 Events:</strong> View upcoming society events</li>
      <li><strong>🙋 Complaints:</strong> Residents submit complaints with tracking</li>
      <li><strong>🧾 Balance Sheet:</strong> Shows income/expense ledger with totals</li>
      <li><strong>🧑‍🤝‍🧑 Members:</strong> Directory of all society residents</li>
      <li><strong>🗳️ Polls:</strong> Admins create polls, users vote once</li>
      <li><strong>🏢 Building Resources:</strong> Bookings for gym, hall, etc.</li>
      <li><strong>🚪 Visitors:</strong> Guard logs entry/exit with filters</li>
      <li><strong>🧵 Timeline:</strong> Global feed of all society activities</li>
      <li><strong>💬 Chat:</strong> Real-time global chat for all members</li>
    </ul>
  </div>

  <div class="section">
    <h2>🛠️ Tech Stack</h2>
    <ul>
      <li><strong>Frontend:</strong> Flutter (Material Design, Firebase UI)</li>
      <li><strong>Backend:</strong> Firebase (Auth, Firestore, Storage)</li>
      <li><strong>Realtime:</strong> Firestore Streams for chat & updates</li>
    </ul>
  </div>

  <div class="section">
    <h2>📂 Folder Structure (Simplified)</h2>
    <ul>
      <li><code>lib/screens/</code> — All UI screens (Login, Signup, Home, etc.)</li>
      <li><code>lib/utils/</code> — Shared helpers (e.g. timeline logger)</li>
      <li><code>main.dart</code> — App entry point</li>
      <li><code>pubspec.yaml</code> — Dependencies and asset config</li>
    </ul>
  </div>

  <div class="section">
    <h2>🚀 Getting Started</h2>
    <ol>
      <li>Install Flutter SDK</li>
      <li>Connect Firebase project to the app (via Firebase Console)</li>
      <li>Run <code>flutter pub get</code></li>
      <li>Use <code>flutter run</code> to launch the app</li>
    </ol>
  </div>

  <div class="section">
    <h2>📦 Firestore Collections Used</h2>
    <ul>
      <li><code>users</code>, <code>members</code></li>
      <li><code>complaints</code>, <code>notices</code>, <code>events</code></li>
      <li><code>maintenance</code>, <code>resources</code>, <code>visitors</code></li>
      <li><code>balanceSheet</code>, <code>polls</code>, <code>timeline</code>, <code>chat</code></li>
    </ul>
  </div>

  <div class="section">
    <h2>📌 Credits</h2>
    <p>Developed as a final-year BTech project using Flutter and Firebase.</p>
    <p>UI inspiration from Material Design 3 and community-driven app needs.</p>
  </div>

</body>
</html>
