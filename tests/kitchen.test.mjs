import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

function loadKitchen() {
  const html = fs.readFileSync(new URL('../index.html', import.meta.url), 'utf8');
  const start = html.indexOf('const Kitchen = (() => {');
  const end = html.indexOf('\n})();', start);
  assert.notEqual(start, -1, 'Kitchen module should exist in index.html');
  assert.notEqual(end, -1, 'Kitchen module should have a closing boundary');

  const source = `${html.slice(start, end + 6)}\nKitchen;`;
  let saveCount = 0;
  const context = {
    uid: () => 'generated-id',
    save: () => { saveCount += 1; },
    saveRecipes: () => {},
    saveStaples: () => {},
    clearDemo: () => {},
    daysUntilExpiry: () => null,
    Planner: { consumption: () => ({ plan: [], skipped: [] }) },
  };

  return {
    Kitchen: vm.runInNewContext(source, context),
    saveCount: () => saveCount,
  };
}

describe('Kitchen restock threshold', () => {
  it('defaults new items to zero and preserves an explicit zero on update', () => {
    const { Kitchen, saveCount } = loadKitchen();

    const item = Kitchen.addItem({ name: 'Flour', qty: 2 });
    assert.equal(item.threshold, 0);

    let updated = Kitchen.updateItem(item.id, { threshold: 3 });
    assert.equal(updated.threshold, 3);

    updated = Kitchen.updateItem(item.id, { threshold: 0 });
    assert.equal(updated.threshold, 0);
    assert.equal(saveCount(), 3, 'each mutation should still persist');
  });

  it('presents zero as the default when opening the new-item form', () => {
    const html = fs.readFileSync(new URL('../index.html', import.meta.url), 'utf8');
    assert.match(html, /id="f-thresh" value="0"/);
    assert.match(html, /function openAddSheet[\s\S]*?getElementById\('f-thresh'\)\.value=0;/);
  });
});
