import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const html=fs.readFileSync(new URL('../index.html',import.meta.url),'utf8');
const schema=fs.readFileSync(new URL('../supabase/schema.sql',import.meta.url),'utf8');
const config=fs.readFileSync(new URL('../js/supabase-config.js',import.meta.url),'utf8');

describe('Supabase cloud backup',()=>{
  it('uses only a public browser key and authenticated REST requests',()=>{
    assert.match(config,/sb_publishable_/);
    assert.doesNotMatch(config,/service_role|postgresql:\/\//);
    assert.match(html,/Authorization':'Bearer '/);
    assert.match(html,/auth\/v1\/otp\?redirect_to=/);
  });

  it('does not auto-upload until initial cloud state has been checked',()=>{
    assert.match(html,/if\(!cloudSession\|\|!cloudUser\|\|!cloudReady\)return/);
    assert.match(html,/No cloud copy exists yet\. Upload this device/);
  });

  it('keeps authenticated snapshot history behind row-level security',()=>{
    assert.match(schema,/alter table public\.mise_snapshots enable row level security/);
    assert.match(schema,/auth\.uid\(\) = user_id/);
    assert.match(schema,/archive_mise_snapshot_after_write/);
    assert.match(schema,/revoke all on public\.mise_snapshots from anon/);
  });
});
