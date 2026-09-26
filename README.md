<h1 align='center'>
  <img src="https://github.com/franz-dc/youtube-music-remote/blob/main/images/logo.webp" width="120px" style="max-width: 100%" alt="YouTube Music Remote">
  <br>
  YouTube Music Remote
</h1>

Control [YouTube Music Desktop](https://github.com/pear-devs/pear-desktop) from your phone, tablet, or another computer.

Download the app [here](https://github.com/franz-dc/youtube-music-remote/releases/latest)!

For the web version, see the [dedicated section](#web-version) below.

## Screenshots

<p float="left">
  <img src="https://github.com/franz-dc/youtube-music-remote/blob/main/images/player.webp" width="200" style="max-width: 100%; margin-right: 8px;" alt="Player">
  <img src="https://github.com/franz-dc/youtube-music-remote/blob/main/images/queue.webp" width="200" style="max-width: 100%;" alt="Queue">
</p>

## Prerequisites

You should have YouTube Music Desktop installed. You can get it from [here](https://github.com/pear-devs/pear-desktop/releases/latest).

## Getting Started

1. From YouTube Music Desktop, enable the API Server plugin.
2. Set the authorization strategy to `No authorization`.
3. Install YouTube Music Remote to your device or access the web version.
4. Configure the connection settings.
5. Enjoy controlling YouTube Music remotely!

## Web Version

The web version can be accessed [here](https://youtube-music-remote.vercel.app) after doing some configuration on your browser.

You need to disable a security feature for the site first. YouTube Music's API Server is hosted locally using HTTP and the browser blocks requests to the server for that reason.

### Self-hosting for iPhone Safari (same Wi-Fi network)

The public HTTPS web app cannot call the desktop server's HTTP and `ws://` endpoints from Safari. Host the web app on the computer running YouTube Music Desktop and put the API behind the **same origin**. The included Caddy configuration serves the app and forwards `/api/*` (including WebSockets) and `/auth/*` to the desktop plugin.

1. Install Node.js and [Caddy](https://caddyserver.com/docs/install). Enable Corepack with `corepack enable` (if `corepack` is missing, run `npm install -g corepack` first). Start YouTube Music Desktop and enable its API Server plugin on port `26538`. Keep the desktop computer and iPhone on the same Wi-Fi network. If the API plugin uses a different port, edit `deploy/Caddyfile.lan`.
2. From this repository's root, build the web app and start Caddy:

   ```bash
   yarn install --immutable
   EXPO_PUBLIC_SAME_ORIGIN_API=true yarn expo export -p web
   caddy run --config deploy/Caddyfile.lan
   ```

3. Find the computer's LAN IP address (on macOS Wi-Fi, `ipconfig getifaddr en0`). Open `http://COMPUTER_LAN_IP:8080` in iPhone Safari. Allow incoming connections to Caddy in the computer's firewall if prompted. You do not need to enter the desktop IP or port in the web app's settings in this build.

The web page, REST requests, and WebSocket all use `http://COMPUTER_LAN_IP:8080` (WebSocket uses `ws://`). This avoids an HTTPS page making mixed-content requests. The page is still plain HTTP, so **keep this listener on a trusted LAN**. The desktop plugin's `No authorization` mode allows anyone who can reach this listener to control playback. Do not forward port 8080 from your router or expose it publicly.

For access outside your LAN, one private option is [Tailscale Serve](https://tailscale.com/docs/features/tailscale-serve): install Tailscale on both the desktop and iPhone, sign in to the same tailnet, keep Caddy running, and run `tailscale serve 8080` on the desktop. Open the HTTPS `*.ts.net` URL printed by Tailscale on the iPhone. The app will use `https://` and `wss://` through that same hostname. If you only use Tailscale, add `bind 127.0.0.1` inside the Caddy site block to stop direct LAN access. Do **not** use Tailscale Funnel here: it makes the unauthenticated playback API public. A static host such as Vercel cannot proxy to a private LAN address by itself. Rebuild with `EXPO_PUBLIC_SAME_ORIGIN_API=true` for any same-origin deployment; the value is baked into the static bundle.

### Chrome (and other Chromium-based browsers)

1. Go to the web app.
2. Click the lock or settings icon on the left side of the address bar.
3. Click `Site settings`.
4. Scroll down to `Insecure content` and select `Allow`.
5. Reload the page.

### Firefox

1. Go to the web app and go to the [settings page](https://youtube-music-remote.vercel.app/settings).
2. Configure your connection settings.
3. Click the lock icon on the left side of the address bar.
4. Click `Connection secure`.
5. Click `Disable protection for now`.

For Firefox, you have to disable the protection every time you reopen your browser.

## Development

```bash
yarn
yarn android # or yarn web
```

- Note that this will not work on Expo Go, as some libraries used are not supported by it.
- iOS is not yet tested to work due to no access to an Apple device.

## Limitations

There are some limitations to the app mostly due to the limitations of the API server:

- Authorization strategy must be set to `No authorization` in the plugin configuration (for now).
- Only songs are shown in the search results.
