import React, { useEffect, useMemo, useState, useCallback } from 'react'
import ReactDOM from 'react-dom/client'
import { Crumb, HOME_TRAIL, SITE, StatePill } from './common.jsx'

/* RELAY-64 /apps/rpg — RPG 허브(모듈 카드·PLAYABLE 링크·진행 상태, 읽기전용).
   react-best-practices 적용:
   - async-parallel: 모듈+콘텐츠 초기화를 Promise.all 병렬(폭포 제거, CRITICAL)
   - bundle-dynamic-imports: WASM 런처 안내는 정적링크(허브 번들에서 Godot 분리)
   - rerender-memo: ModuleCard memo(리스트 재렌더 최소화)
   - rerender-no-inline-components: 컴포넌트를 모듈 스코프로 분리
   - rendering-conditional-render: 삼항식(loading/error/empty)
   - rendering-content-visibility: 롱리스트 카드에 content-visibility */

const PLAYABLE = [
  { id: 'prototype', label: '▶ 관찰·추론·회피', href: '/apps/rpg/prototype' },
  { id: 'tactics', label: '▶ 파편전기 (등각전술)', href: '/apps/rpg/tactics' },
  { id: 'godot', label: '▶ Godot 전술 (WASM, lazy)', href: '/legacy/godot-tactics/index.html' },
]

function App() {
  const [modules, setModules] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let alive = true
    /* async-parallel — 두 조회를 병렬(8024 portal usePortalData 선례) */
    Promise.all([
      fetch('/api/apps/rpg/modules', { cache: 'no-store' }).then(r => r.ok ? r.json() : Promise.reject(new Error('modules ' + r.status))),
      fetch('/api/apps/rpg/content?section=hero', { cache: 'no-store' }).then(r => r.ok ? r.json() : Promise.reject(new Error('content ' + r.status))),
    ]).then(([m, c]) => {
      if (!alive) return
      setModules(Array.isArray(m.items) ? m.items : [])
      setLoading(false)
    }).catch(e => {
      if (alive) { setError(e.message); setLoading(false) }
    })
    return () => { alive = false }
  }, [])

  const counts = useMemo(() => {
    // 단일 순회 집계(js-combine-iterations) — done/wip/기타
    const acc = { done: 0, wip: 0, other: 0 }
    for (const m of modules) {
      if (m.state === 'done') acc.done++
      else if (m.state === 'wip') acc.wip++
      else acc.other++
    }
    return acc
  }, [modules])

  const onPlayable = useCallback((e, href) => {
    // 내부 전환 — 8024 경로 원장(관제)과 정합. stopPropagation 불필요(단일 핸들러)
    void e; void href
  }, [])

  return (
    <div style={{ background: '#07110f', minHeight: '100vh', color: '#c8cdd8', fontFamily: 'system-ui, sans-serif', padding: 16 }}>
      <Crumb trail={[...HOME_TRAIL, { label: 'RPG (/apps/rpg)' }]} />
      <header style={{ margin: '18px 0 6px' }}>
        <p style={{ fontSize: 11, letterSpacing: 2, color: '#5b6070', margin: 0 }}>RPG GAME 01 · SPRING+RPG (RELAY-64)</p>
        <h1 style={{ fontSize: 24, margin: '4px 0', color: '#e8eef4' }}>걷기×전술 RPG <em style={{ color: '#4da3ff', fontStyle: 'normal' }}>모듈 라이브러리</em></h1>
        <p style={{ fontSize: 12.5, color: '#8b93a7', maxWidth: 640 }}>
          8009(Flask)의 기능·자산을 Spring+React로 재설계한 게임동입니다. 원본 콘텐츠는 단일 소스(markdown)를 그대로 읽습니다.
        </p>
      </header>

      <section aria-label="PLAYABLE">
        <h2 style={{ fontSize: 14, margin: '16px 0 8px', color: '#c8cdd8' }}>PLAYABLE</h2>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          {PLAYABLE.map(p => (
            <a key={p.id} data-obj-id={'rpg-play-' + p.id} href={p.href} onClick={e => onPlayable(e, p.href)}
               style={{ background: '#12202e', border: '1px solid #1e3a5a', color: '#9fc5ff', borderRadius: 10,
                        padding: '10px 16px', fontSize: 13, textDecoration: 'none', fontWeight: 600 }}>
              {p.label}
            </a>
          ))}
        </div>
      </section>

      <section aria-label="모듈 현황">
        <h2 style={{ fontSize: 14, margin: '20px 0 8px', color: '#c8cdd8' }}>
          모듈 현황 <span style={{ color: '#5b6070' }}>({modules.length})</span>
          <span style={{ marginLeft: 10, fontSize: 11, color: '#8b93a7' }}>
            ✓{counts.done} · 🔨{counts.wip} · 대기{counts.other}
          </span>
        </h2>
        {loading
          ? <p style={{ fontSize: 12, color: '#5b6070' }}>모듈 상태 확인 중…</p>
          : error
            ? <p style={{ fontSize: 12.5, color: '#f27d6c' }}>조회 실패: {error} — 8009단일소스 연결 확인 필요</p>
            : modules.length === 0
              ? <p style={{ fontSize: 12.5, color: '#8b93a7' }}>등록된 모듈이 없습니다.</p>
              : (
                <div style={{ display: 'grid', gap: 10, gridTemplateColumns: 'repeat(auto-fill, minmax(210px, 1fr))' }}>
                  {modules.map(m => <ModuleCard key={m.id} m={m} />)}
                </div>
              )}
      </section>

      <footer style={{ marginTop: 28, fontSize: 11, color: '#5b6070' }}>
        <span data-obj-id="rpg-footer-impl" data-impl={SITE.id + ':' + SITE.impl}>
          ID {SITE.id} · {SITE.impl} · 출처: rpg_game repo webapp/ (RELAY-64)
        </span>
      </footer>
    </div>
  )
}

const ModuleCard = React.memo(function ModuleCard({ m }) {
  return (
    <div data-obj-id={'rpg-module-' + m.id} data-impl={SITE.id + ':' + SITE.impl}
         style={{ background: '#121826', border: '1px solid #1e2637', borderRadius: 10, padding: 12,
                  contentVisibility: 'auto' }}>
      <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 4, color: '#e8eef4' }}>{m.label}</div>
      <div style={{ fontSize: 11, color: '#8b93a7', marginBottom: 8, minHeight: 14 }}>{m.entry}</div>
      <StatePill state={m.state} />
    </div>
  )
})

ReactDOM.createRoot(document.getElementById('root')).render(<App />)


