export const getConnectionBaseUrl = (
  protocol: 'http' | 'ws',
  ipAddress: string,
  port: string,
  webOrigin?: string
) => {
  if (webOrigin) {
    const origin = new URL(webOrigin);
    if (protocol === 'ws') {
      origin.protocol = origin.protocol === 'https:' ? 'wss:' : 'ws:';
    }
    return origin.origin;
  }

  return `${protocol}://${ipAddress}:${port}`;
};

export const isConnectionConfigured = (
  ipAddress: string,
  port: string,
  sameOrigin: boolean
) => sameOrigin || (!!ipAddress && !!port);
