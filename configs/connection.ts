import { Platform } from 'react-native';

export const USE_SAME_ORIGIN_API =
  Platform.OS === 'web' && process.env.EXPO_PUBLIC_SAME_ORIGIN_API === 'true';

export const getWebOrigin = () =>
  USE_SAME_ORIGIN_API && typeof window !== 'undefined'
    ? window.location.origin
    : undefined;
