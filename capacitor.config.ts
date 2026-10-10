import type { CapacitorConfig } from '@capacitor/cli';

/**
 * Markette mobile app (Android + iOS) wrapping the Angular UI.
 * The API server is chosen by the user at first launch (ServerConfigService).
 */
const config: CapacitorConfig = {
  appId: 'app.markette.mobile',
  appName: 'Markette',
  // Filled by `npm run build:web` from the markette-web checkout (see README).
  webDir: 'www',
  android: {
    // Lets the app talk to plain-http servers (e.g. a test install). Prefer HTTPS in production.
    allowMixedContent: true,
  },
  ios: {
    contentInset: 'never',
  },
  plugins: {
    CapacitorShareTarget: {
      // Shared between the app and its Share Extension (see ios/README-share-extension.md).
      appGroupId: 'group.app.markette.mobile',
    },
    SplashScreen: {
      launchAutoHide: false,
      backgroundColor: '#5b4bf5',
      showSpinner: false,
    },
  },
};

export default config;
