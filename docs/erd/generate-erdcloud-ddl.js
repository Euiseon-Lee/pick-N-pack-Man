/**
 * ERDCloud 가져오기용 DDL 생성기
 *
 * src/main/resources/db/init/*.sql (PostgreSQL) 을 읽어서 ERDCloud Import(SQL)가 읽기 쉬운 MySQL 스타일 DDL로 변환한다.
 *  - GENERATED ALWAYS AS IDENTITY  → AUTO_INCREMENT
 *  - TIMESTAMP → DATETIME, JSONB → JSON
 *  - COMMENT ON TABLE / COLUMN     → 인라인 COMMENT '...'  (ERDCloud가 논리명으로 표시)
 *  - 인라인 REFERENCES + 98_foreign_keys.sql 의 ALTER TABLE → FOREIGN KEY
 *  - CREATE UNIQUE INDEX            → UNIQUE KEY
 *  - INSERT / 트리거 / 함수는 제외
 *
 * 실행:  node docs/erd/generate-erdcloud-ddl.js
 * 출력:  docs/erd/erdcloud.sql
 */
const fs = require('fs');
const path = require('path');

const INIT_DIR = path.join(__dirname, '..', '..', 'src', 'main', 'resources', 'db', 'init');
const OUT_FILE = path.join(__dirname, 'erdcloud.sql');

const files = fs.readdirSync(INIT_DIR)
    .filter(f => /^\d+_.*\.sql$/.test(f))
    .sort();

const tables = [];          // { name, comment, columns: [], pk: [], uniques: [], fks: [] }
const byName = new Map();

function table(name) {
    if (!byName.has(name)) {
        const t = { name, comment: '', columns: [], pk: [], uniques: [], fks: [] };
        tables.push(t);
        byName.set(name, t);
    }
    return byName.get(name);
}

function mapType(pgType) {
    const t = pgType.toUpperCase();
    if (t === 'TIMESTAMP') return 'DATETIME';
    if (t === 'JSONB' || t === 'JSON') return 'JSON';
    return t; // BIGINT, INT, SMALLINT, VARCHAR(n), DECIMAL(15,2), TEXT
}

function parseCreateTable(body) {
    // body = "CREATE TABLE name ( ... );"
    const m = body.match(/CREATE TABLE\s+(\w+)\s*\(([\s\S]*)\)\s*;/i);
    if (!m) return;
    const t = table(m[1]);
    const lines = m[2].split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('--'));

    for (let line of lines) {
        line = line.replace(/,\s*$/, '');
        const cm = line.match(/^(\w+)\s+([A-Z]+(?:\([\d,\s]+\))?)\s*(.*)$/i);
        if (!cm) continue;
        const [, name, type, rest] = cm;
        const col = { name, type: mapType(type), notNull: false, autoInc: false, def: null, comment: '' };
        const r = rest;

        if (/GENERATED ALWAYS AS IDENTITY/i.test(r)) { col.autoInc = true; col.notNull = true; }
        if (/PRIMARY KEY/i.test(r)) t.pk.push(name);
        if (/NOT NULL/i.test(r)) col.notNull = true;

        const dm = r.match(/DEFAULT\s+('[^']*'|[\w.]+)/i);
        if (dm) col.def = dm[1];

        const fm = r.match(/REFERENCES\s+(\w+)\s*\((\w+)\)/i);
        if (fm) t.fks.push({ col: name, refTable: fm[1], refCol: fm[2] });

        t.columns.push(col);
    }
}

for (const f of files) {
    const sql = fs.readFileSync(path.join(INIT_DIR, f), 'utf8');

    // CREATE TABLE
    for (const m of sql.matchAll(/CREATE TABLE[\s\S]*?\);/gi)) parseCreateTable(m[0]);

    // COMMENT ON TABLE / COLUMN
    for (const m of sql.matchAll(/COMMENT ON TABLE\s+(\w+)\s+IS\s+'((?:[^']|'')*)'/gi)) {
        table(m[1]).comment = m[2];
    }
    for (const m of sql.matchAll(/COMMENT ON COLUMN\s+(\w+)\.(\w+)\s+IS\s+'((?:[^']|'')*)'/gi)) {
        const col = table(m[1]).columns.find(c => c.name === m[2]);
        if (col) col.comment = m[3];
    }

    // CREATE UNIQUE INDEX name ON table (cols)
    for (const m of sql.matchAll(/CREATE UNIQUE INDEX\s+(\w+)\s+ON\s+(\w+)\s*\(([^)]+)\)/gi)) {
        table(m[2]).uniques.push({ name: m[1], cols: m[3].split(',').map(s => s.trim()) });
    }

    // ALTER TABLE t ADD CONSTRAINT n FOREIGN KEY (c) REFERENCES t2 (c2)
    for (const m of sql.matchAll(/ALTER TABLE\s+(\w+)\s+ADD CONSTRAINT\s+(\w+)\s+FOREIGN KEY\s*\((\w+)\)\s*REFERENCES\s+(\w+)\s*\((\w+)\)/gi)) {
        table(m[1]).fks.push({ name: m[2], col: m[3], refTable: m[4], refCol: m[5] });
    }
}

// COMMENT ON 이 없는 공통 컬럼의 논리명
const DEFAULT_LOGICAL = {
    id: 'ID',
    created_user_id: '생성자', created_at: '생성일',
    updated_user_id: '수정자', updated_at: '수정일',
    is_canceled: '취소 여부', canceled_user_id: '취소자', canceled_at: '취소 일시',
    is_deleted: '삭제 여부', deleted_user_id: '삭제자', deleted_at: '삭제 일시',
    is_shipment_on_hold: '출고보류 여부', shipment_hold_user_id: '보류자', shipment_hold_at: '보류 일시',
};

// 논리명 = 주석 첫 구절 (괄호 설명 제외). 주석 없으면 기본 사전 → 컬럼명 순.
function logicalName(c) {
    if (!c.comment) return DEFAULT_LOGICAL[c.name] || c.name;
    return c.comment.replace(/\s*\(.*$/, '').trim() || c.name;
}

// 참조되는 테이블이 먼저 오도록 정렬 (자기 참조는 무시). 파일 순서상 order(02)가 product(03)보다 앞이라 필요.
function topoSort(list) {
    const sorted = [], done = new Set();
    const visit = (t, stack = new Set()) => {
        if (done.has(t.name) || stack.has(t.name)) return;
        stack.add(t.name);
        for (const fk of t.fks) {
            if (fk.refTable !== t.name && byName.has(fk.refTable)) visit(byName.get(fk.refTable), stack);
        }
        done.add(t.name);
        sorted.push(t);
    };
    list.forEach(t => visit(t));
    return sorted;
}

const out = [];
out.push('-- ============================================');
out.push('-- ERDCloud 가져오기용 DDL (자동 생성, 직접 수정하지 말 것)');
out.push('-- 원천: src/main/resources/db/init/*.sql  |  생성: node docs/erd/generate-erdcloud-ddl.js');
out.push('-- ============================================');
out.push('');

for (const t of topoSort(tables)) {
    const defs = [];
    for (const c of t.columns) {
        let d = `    ${c.name} ${c.type}`;
        if (c.notNull) d += ' NOT NULL';
        if (c.autoInc) d += ' AUTO_INCREMENT';
        if (c.def !== null && !c.autoInc) d += ` DEFAULT ${c.def}`;
        d += ` COMMENT '${logicalName(c).replace(/'/g, "''")}'`;
        defs.push(d);
    }
    if (t.pk.length) defs.push(`    PRIMARY KEY (${t.pk.join(', ')})`);
    for (const u of t.uniques) defs.push(`    UNIQUE KEY ${u.name} (${u.cols.join(', ')})`);
    for (const fk of t.fks) {
        const name = fk.name || `FK_${t.name}_${fk.col}`;
        defs.push(`    CONSTRAINT ${name} FOREIGN KEY (${fk.col}) REFERENCES ${fk.refTable} (${fk.refCol})`);
    }
    out.push(`CREATE TABLE ${t.name} (`);
    out.push(defs.join(',\n'));
    out.push(`) COMMENT '${(t.comment || t.name).replace(/'/g, "''")}';`);
    out.push('');
}

fs.writeFileSync(OUT_FILE, out.join('\n'), 'utf8');
console.log(`generated ${path.relative(process.cwd(), OUT_FILE)}: ${tables.length} tables, ` +
    `${tables.reduce((n, t) => n + t.columns.length, 0)} columns, ` +
    `${tables.reduce((n, t) => n + t.fks.length, 0)} foreign keys`);
