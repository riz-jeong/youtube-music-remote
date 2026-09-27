import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const readLocale = (language) =>
  JSON.parse(readFileSync(new URL(`../locales/${language}.json`, import.meta.url)));

const entries = (value, prefix = '') =>
  Object.entries(value).flatMap(([key, child]) => {
    const path = prefix ? `${prefix}.${key}` : key;
    return typeof child === 'string' ? [[path, child]] : entries(child, path);
  });

test('Korean covers every English translation key', () => {
  const englishKeys = entries(readLocale('en')).map(([key]) => key).sort();
  const koreanKeys = entries(readLocale('ko')).map(([key]) => key).sort();

  assert.deepEqual(koreanKeys, englishKeys);
});

test('Korean keeps the interpolation variables used by the UI', () => {
  const english = new Map(entries(readLocale('en')));

  for (const [key, translation] of entries(readLocale('ko'))) {
    const variables = (text) => [...text.matchAll(/{{\s*([^}]+)\s*}}/g)]
      .map((match) => match[1].trim())
      .sort();
    assert.deepEqual(variables(translation), variables(english.get(key)), key);
  }
});
