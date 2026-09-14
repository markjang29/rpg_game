import React, { useEffect, useMemo, useState, useCallback } from 'react'
import ReactDOM from 'react-dom/client'
import { Crumb, ASSET_TRAIL, SITE } from './common.jsx'

/* /studio/assets — 8017(RETIRED) import. 워크벤치 스파이크 카탈로그를 읽기전용 제공.
   react-best-practices: async-parallel(갤러리+유형 병렬) · rerender-memo(카드) ·
   rendering-conditional-render(로딩/에러/빈) · rerender-memo-with-default-value(limit 기본값). */

const DEFAULT_LIMIT = 60

const AssetRow = React.memo(function AssetRow({ row }) {
  const meta = row.meta || {}
  return (
    <div data-obj-id={row['obj-id']} data-impl={SITE.id + ':' + SITE.impl}
         style={{ background: '#121826', border: '1px solid #1e2637', borderRadius: 10, padding: 10,
                  fontSize: 12, contentVisibility: 'auto' }}>
      <b style={{ color: '#e8eef4' }}>{String(meta.type || '?')}-{String(meta.id || '?')}</b>
      <div style={{ color: '#8b93a7', marginTop: 4, minHeight: 30, overflow: 'hidden' }}>
        {String(meta.prompt || meta.tags || '—')}
      </div>
    </div>
  )
})

function App() {
  const [items, setItems] = useState([])
  const [types, setTypes] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let alive = true
    /* async-parallel — 카탈로그·유형 병렬(폭포 제거) */
    Promise.all([
      fetch('/api/studio/assets/gallery?limit=' + DEFAULT_LIMIT, { cache: 'no-store' }).then(r => r.ok ? r.json() : Promise.reject(new Error('gallery ' + r.status))),
      fetch('/api/studio/assets/types', { cache: 'no-store' }).then(r => r.ok ? r.json() : Promise.reject(new Error('types ' + r.status))).catch(() => ({})),
    ]).then(([g, t]) => {
      if (!alive) return
      setItems(Array.isArray(g.items) ? g.items : [])
      setTypes(t && t.types ? Object.entries(t.types) : [])
      setLoading(false)
    }).catch(e => { if (alive) { setError(e.message); setLoading(false) } })
    return () => { alive = false }
  }, [])

  return (
    <div style={{ background: '#101418', minHeight: '100vh', color: '#e8eef4', padding: 14, fontFamily: 'system-ui, sans-serif' }}>
      <Crumb trail={[...ASSET_TRAIL, { label: 'RPG 자산 (/studio/assets, 8017 import)' }]} />
      <h1 style={{ fontSize: 18, margin: '14px 0 2px' }}>RPG 자산 — 8017 import</h1>
      <p style={{ fontSize: 12, color: '#8fa3b5', marginBottom: 14 }}>
        8017(RETIRED) 워크벤치 스파이크의 저장소를 읽기전용 카탈로그로 흡수. 원본 스파이크는 보존(RELAY-36 정합).
      </p>

      <section aria-label="자산 유형" style={{ marginBottom: 14 }}>
        {types.length === 0 ? null : (
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {types.map(([code, label]) => (
              <span key={code} data-obj-id={'8017-type-' + code}
                    style={{ border: '1px solid #2a3542', borderRadius: 8, padding: '4px 10px', fontSize: 12, color: '#8fa3b5' }}>
                {code} · {label}
              </span>
            ))}
          </div>
        )}
      </section>

      {loading
        ? <p style={{ fontSize: 12, color: '#5b6070' }}>카탈로그 로드 중…</p>
        : error
          ? <p style={{ fontSize: 12.5, color: '#f27d6c' }}>조회 실패: {error}</p>
          : items.length === 0
            ? <p style={{ fontSize: 12.5, color: '#8fa3b5' }}>저장소가 비어 있거나 미마이그레이션 상태입니다(스파이크 원본 우선, 이후 410 전환).</p>
            : (
              <div style={{ display: 'grid', gap: 10, gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))' }}>
                {items.map(row => <AssetRow key={row['obj-id']} row={row} />)}
              </div>
              )}

      <footer style={{ marginTop: 24, fontSize: 11, color: '#5b6070' }}>
        ID 8017-import · {SITE.impl} · 8017 원본: 410(RETIRED) 예정 — 전환기 병행
      </footer>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />)
