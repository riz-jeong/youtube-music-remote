import assert from 'node:assert/strict';
import test from 'node:test';

import {
  getConnectionBaseUrl,
  isConnectionConfigured,
} from '../utils/connectionUrl.ts';

test('same-origin mode connects without a saved desktop address', () => {
  assert.equal(isConnectionConfigured('', '26538', true), true);
  assert.equal(isConnectionConfigured('', '26538', false), false);
  assert.equal(isConnectionConfigured('192.168.1.10', '26538', false), true);
  assert.equal(isConnectionConfigured('192.168.1.10', '', false), false);
});

test('HTTPS self-hosted pages use their own origin for REST and WSS', () => {
  assert.equal(
    getConnectionBaseUrl('http', '192.168.1.10', '26538', 'https://remote.example.com'),
    'https://remote.example.com'
  );
  assert.equal(
    getConnectionBaseUrl('ws', '192.168.1.10', '26538', 'https://remote.example.com'),
    'wss://remote.example.com'
  );
});

test('HTTP self-hosted pages use their own origin for REST and WS', () => {
  assert.equal(
    getConnectionBaseUrl('http', '', '26538', 'http://192.168.1.10:8080'),
    'http://192.168.1.10:8080'
  );
  assert.equal(
    getConnectionBaseUrl('ws', '', '26538', 'http://192.168.1.10:8080'),
    'ws://192.168.1.10:8080'
  );
});

test('standard mode keeps the configured API server address', () => {
  assert.equal(
    getConnectionBaseUrl('http', '192.168.1.10', '26538'),
    'http://192.168.1.10:26538'
  );
  assert.equal(
    getConnectionBaseUrl('ws', '192.168.1.10', '26538'),
    'ws://192.168.1.10:26538'
  );
});
