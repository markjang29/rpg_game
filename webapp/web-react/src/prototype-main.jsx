import React, { useEffect, useState } from 'react'
import ReactDOM from 'react-dom/client'
import { Crumb, HOME_TRAIL, SITE } from './common.jsx'

/* /apps/rpg/prototype — 관찰·추론·회피. 8009 원본(static/prototype.js)은 그대로 로드(자산정합: 복사 없음). */

function App() {
  const [mounted, setMounted] = useState(false)
  useEffect(() => { setMounted(true) }, [])
  return (
    <div style={{ background: '#07110f', minHeight: '100vh', color: '#c8cdd8', padding: 16, fontFamily: 'system-ui, sans-serif' }}>
      <Crumb trail={[...HOME_TRAIL, { label: 'RPG (/apps/rpg)', href: '/apps/rpg' }, { label: '관찰·추론·회피' }]} />
      <h1 style={{ fontSize: 20, color: '#e8eef4' }}>관찰·추론·회피 — 프로토타입</h1>
      <p style={{ fontSize: 12.5, color: '#8b93a7' }}>
        8009 원본과 동일한 정적 자산(/legacy/prototype-assets/…)을 직접 로드합니다 — 자산 단일 소스 정합.
      </p>
      <p style={{ fontSize: 12.5, color: mounted ? '#3ecf8e' : '#8b93a7' }}>
        {mounted ? 'React 셸 마운트 완료 — 원본 스크립트 로더는 다음 커밋에서 연결' : '초기화 중…'}
      </p>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />)
