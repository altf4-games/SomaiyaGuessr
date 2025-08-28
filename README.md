# SomaiyaGuessr

SomaiyaGuessr is a multiplayer location-based guessing game inspired by GeoGuessr, built with Flutter for the frontend and Node.js for the backend. Players join rooms, view images, and guess locations to compete for the highest score.

## Features

- Real-time multiplayer gameplay
- Room and lobby system
- Location guessing with images
- Score tracking and game rounds
- Cross-platform support (Web, Android, iOS, Desktop)
- Admin panel for managing games and content

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Node.js, Express, Socket.io
- **Database:** (Add your DB here, e.g., MongoDB)
- **Cloudinary** for image hosting

## Getting Started

### Prerequisites

- Flutter SDK
- Node.js & npm
- (Optional) MongoDB or your chosen database

### Setup

#### 1. Clone the repository

```sh
git clone https://github.com/altf4-games/SomaiyaGuessr.git
cd SomaiyaGuessr
```

#### 2. Backend Setup

```sh
cd backend
npm install
cp sample.env .env
# Edit .env with your configuration
npm start
```

#### 3. Frontend (Flutter App) Setup

```sh
cd app
flutter pub get
flutter run
```

#### 4. Web

```sh
cd app
flutter run -d chrome
```

## Usage

- Start the backend server.
- Run the Flutter app on your desired platform.
- Create or join a game room.
- Guess the location based on the image shown.
- Compete with friends and top the leaderboard!

## Project Structure

- `app/` - Flutter frontend
- `backend/` - Node.js backend

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

## License

[MIT](LICENSE)
