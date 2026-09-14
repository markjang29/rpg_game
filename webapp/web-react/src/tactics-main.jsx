import React, { useEffect, useState } from 'react'
import ReactDOM from 'react-dom/client'
import { Crumb, HOME_TRAIL, SITE } from './common.jsx'

/* /apps/rpg/tactics — 파편전기(등각전술). 8009 tactics.js·assets을 단일 소스로 서빙(복사 없음). */

function App() {
  const [mounted, setMounted] = useState(false)
  useEffect(() => { setMounted(true) }, [])
  return (
    <div style={{ background: '#11121a', minHeight: '100vh', color: '#c8cdd8', padding: 16, fontFamily: 'system-ui, sans-serif' }}>
      <Crumb trail={[...HOME_TRAIL, { label: 'RPG (/apps/rpg)', href: '/apps/rpg' }, { label: '파편전기 (tactics)' }]} />
      <p className="kicker" style={{ fontSize: 11, letterSpacing: 2, color: '#5b6070' }}>RPG GAME 01 · TACTICAL SLICE</p>
      <h1 style={{ fontSize: 22, margin: '4px 0' }}>파편전기 <small style={{ color: '#8b93a7', fontWeight: 400 }}>부유 유적의 봉인</small></h1>
      <p style={{ fontSize: 12.5, color: mounted ? '#3ecf8e' : '#8b93a7' }}>
        {mounted ? 'React 셸 마운트 — 등각전술 캔버스는 /legacy/prototype-assets/tactics/* 단일소스 로드' : '초기화 중…'}
      </p>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />)
