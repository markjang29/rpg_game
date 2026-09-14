import React from 'react'

/* RELAY-64 공통 — 8009/8017의 _matrix_crumb 관례를 React로 승계.
   트리경로: 8024 홈 → 앱/rpg(또는 studio/assets) → 현재페이지.
   8024 Breadcrumb 컴포넌트 선례(브레드크럼 일원화, 1304147) 참고. */

export const SITE = {
  id: '8009-webapp',
  impl: 'Spring Boot 4.1 · Java 17 · React 18 (RELAY-64)',
}

export const EDGE = 'http://43.201.34.144'

export function Crumb({ trail }) {
  return (
    <nav data-obj-id="rpg-crumb" data-impl={SITE.id + ':' + SITE.impl} aria-label="트리 경로"
         style={{ position: 'sticky', top: 0, zIndex: 9999, background: '#0b1220', color: '#cfe0ff',
                  borderBottom: '1px solid #2a3a5a', padding: '6px 10px',
                  font: '700 11.5px/1.5 system-ui, sans-serif' }}>
      {trail.map((t, i) => (
        <React.Fragment key={i}>
          {i > 0 && ' › '}
          {t.href
            ? <a href={t.href} style={{ color: '#9fc5ff', textDecoration: 'none' }}>{t.label}</a>
            : <span>{t.label}</span>}
        </React.Fragment>
      ))}
      {' · '}
      <span style={{ color: '#93a2bd' }}>기술 {SITE.impl}</span>
      {' · '}
      <span style={{ color: '#93a2bd' }}>ID {SITE.id}</span>
    </nav>
  )
}

export const HOME_TRAIL = [
  { label: '🏠 홈', href: EDGE + ':8024/' },
  { label: '게임', href: EDGE + ':8024/flow' },
]

export const ASSET_TRAIL = [
  { label: '🏠 홈', href: EDGE + ':8024/' },
  { label: '그림·이미지', href: EDGE + ':8024/flow' },
]

/* 모듈 상태 인덱스 — js-set-map-lookups(O(1) 조회, 렌더마다 재구성 안 함) */
export const STATE_TONE = new Map([
  ['done', { label: '✓ 폰 검증', tone: '#3ecf8e' }],
  ['wip', { label: '🔨 진행', tone: '#f2c14e' }],
  ['design', { label: '🔄 설계', tone: '#8fa3b5' }],
  ['planned', { label: '🟡 예정', tone: '#5b6070' }],
])

export function StatePill({ state }) {
  const meta = STATE_TONE.get(state) || STATE_TONE.get('planned')
  return <span style={{ fontSize: 11, color: meta.tone, fontWeight: 600 }}>{meta.label}</span>
}
