# 03. 세계관·주제 (SETTINGS / THEMES) — 비클리셰 방향

> 목적: README 기본값(파랜드/FFT풍 하이판타지)을 탈피해, "전술 SRPG에서 안 쓰인" 구체적·실재 기반 세팅 3선.
> 원칙: 주제(theme)와 메커닉이 서로 강화해야 한다 — 테마가 유닛·충돌·맵의 형태를 제안.
> 금지(포화 클리셰): 중세 유럽 판타지, 애니메이션 전쟁학원, 포스트 아포칼립스 청소부, 그림다크 "전쟁은 지옥" 영웅단, 사이버펑크 반란군, 좀비, 우주해병대 vs 에일리언.
> 작성: 2026-06-26 / 상태: 아이디에이션 (엔진 미확정, Godot 전제).

---

## 세팅 A. 碁盤の影 — 에도 바둑가(囲棋家)의 정치전술

### 2문장 피치
에도 막부(1603–1868)가 바둑 사대가문(本因坊·井上·安井·林)을 관직으로 묶어둔 시대, 당신은 한 가문의 차기 당주로서 치열한 영토 다툼(바둑판 위·정치판 위 양쪽)을 헤쳐나간다. 살인은 검이 아니라 한 수(一手)로 이루어지고, 승부의 결과가 가문의 녹봉·권력·생사를 결정한다.

### 왜 신선한가 / 탈피하는 클리셰
- **탈피**: 중세 검·마법 SRPG. 본작은 "전투 = 살육"이 아니라 **"전투 = 제로섬 지적 결투"**. 유혈 대신 체면(名誉)·명인(名人) 칭호·막부의 은상이 걸린다.
- "사무라이 전쟁 SRPG"(Sekigahara, *Sword of the Samurai*)은 전국/에도 초기 무력 충돌이고, *Onmyoji*(NetEase)는 헤이안 마법 가챠 RPG다. **에도 평화기의 "가문 정치 + 보드게임 결투"** 결합은 전술 SRPG에서 사실상 공백.
- 현실 기반: 本因坊 도사쿠(1645–1702)의 *아마시*(amashi, "영토를 양보하며 두텁게 쌓는") 전략, 도산(道算)·슈사쿠(秀策)의 실존 기보를 전술맵의 뼈대로 쓴다.

### 테마가 제안하는 메커닉 (유닛·충돌·맵)
- **유닛 = 바둑돌이자 가신**: 검은/흰 돌이 그리드 위 "영향력 영역(influence zone)"을 형성. 돌 하나 = 외교·첩보·자금 등의 가신(type)이며, 돌의 종류가 영역 효과(위협·포위·연결)를 결정.
- **맵 = 기보(棋譜)**: 그리드는 바둑판 19×19(또는 축소 13×13). 칸마다 "영향력 게이지"가 있고, 두 돌 사이 연결(連)이 끊기면 그 돌은 무력화(따냄).  즉 *맵 자체가 매 턴 살아 움직이는 영토 그래프*.
- **충돌 = 한 수 두기**: 행동 = "돌 놓기" 한 수. 공격은 포위·끊기·치수(따냄)이지 HP 깎기가 아니다. 보스전 = 명인전(名人戦) 10번기, 한 판이 긴 캠페인의 단위.
- **정치 계층**: 가문 간 혼인·제자 스카우트·막부 중재가 메타 진행. 기보에서 진 가신은 다른 가문으로 "전속"되어 영구 손실.

### 톤/미학 참조 (웹 검증)
- 미술/분위기: 에도 풍속화·*반초 갓파*(盤上の銀河), NHK 대하드라마 *光る君へ*의 귀족 사투리 연기 톤.
- 기보·전략 참조: [Honinbo Dosaku — Go Magic](https://gomagic.org/dosaku-the-go-saint/) (amashi 전략), [Four Go Houses — Wikipedia](https://en.wikipedia.org/wiki/Four_Go_houses) (가문 제도), [국회국립도서관 "System of Go"](https://www.ndl.go.jp/kaleido/e/entry/22/2.html) (iemoto 세습제).
- 학술 톤(정치·게임 연결): [Rhetoric of Game Practices: Go in Tokugawa Japan — ResearchGate](https://www.researchgate.net/publication/356178327_The_Rhetoric_of_Game_Practices_Go_and_Discursive_Control_in_Tokugawa_Japan).
- 가장 가까운 게임: *Sword of the Samurai*(MicroProse, 1989) — 무력 사무라이 정치/결투. 보드게임 결투 메커닉 없음. Sekigahara(보드게임) — 전투 중심.

### 리스크
- "싸우지 않는 전술"의 진입장벽 — 바둑 규칙을 모르면 거부감. 튜토리얼이 곧 장벽.
- 바둑 AI 평가함수 구현이 무거움; 인디에선 "가짜 바둑"(단순 영역·연결 그래프)으로 단순화 필수.
- 일본 역사적 정확성 연구 비용 (용어·의례·복식).

### 인디/Godot 실현가능성
**중상**. 그리드 + 영향력 맵은 Godot TileMap + 2D 배열로 구현 용이, 물리·셰이더 부담 최소. 에셋은 수묵/우키요에 톤의 2D 스프라이트. 진짜 병목은 (1) 바둑 규칙 단순화 설계, (2) 가문·정치 메타 콘텐츠. 소규모 팀엔 9×9 또는 13×13 판 + 4가문으로 MVP 권장. 물리 의존도 없어 엔진 자유도 높음.

---

## 세팅 B. Tonalpohualli — 260일의 그림자 (멕시카 점성·력법)

### 2문장 피치
정복 직전(15세기 말)의 테노치티틀란, 당신은 점성사(tonalpouhque)로서 신성력(tonalpohualli, 260일 주기)의 20 일짜(日兆, day signs) × 13 숫자로 매일의 길흉을 읽고, 그 해석이 전쟁·제물·수확을 결정하는 보드 위에서 벌어진다. 적은 단순한 병사가 아니라 "역일(逆日)의 악령"이며, 그날의 일지장(day-lord)이 적에게 가호를 주면 칼이 닿지 않는다.

### 왜 신선한가 / 탈피하는 클리셰
- **탈피**: 중남미 = "잃어버린 고대 문명 탐험"(툼 레이더식) 클리셰를 버리고, **멕시카인의 주체적 세계관 내부**에서 게임을 펼친다 (식민자 시점 아님).
- *Shadow of the Tomb Raider*는 "Mayincatec"(마야+잉카 뒤섞기) 트로피, 행동 어드벤처. 전술 SRPG로는 멕소아메리카 세팅 자체가 **확인되지 않음**(웹 검색 2024–2025 결과 없음).
- 현실 기반: 260일 주기 tonalpohualli(실존 역법), 20 일짜(악어·바람·집·도마뱀…), 13 숫자, trecena(13일 구간), Codex Borbonicus의 실존 도상(圖像). [tonalpohualli 개요](https://en.wikipedia.org/wiki/Tonalpohualli).

### 테마가 제안하는 메커닉 (유닛·충돌·맵)
- **유닛 = 일지장(day-lord)의 현현(化身)**: 20종 일지장이 13단계로 강해지는 "적/아군 유형". 예: "바람(에헤카틀)" 유닛은 이동 빠름, "비(틀랄록)" 유닛은 수확/치유, "죽음(미크틀란테쿠틀리)"은 제물 흡수.
- **맵 = 역법 캘린더 보드**: 그리드 자체가 260칸(또는 축소 4×13 trecena)의 **"날짜 보드"**. 매 턴 = 하루가 지나고, "오늘의 일지장"이 전장의 물리법칙을 바꾼다 (예: "비의 날"엔 화염 무효, "죽음의 날"엔 제물 1회 보너스).
- **충돌 = 길흉 해석 + 제물(pilli)**: 행동 전 "점치기" 1회로 오늘 행동의 성패 확률이 드러나고, 제물 유닛을 바쳐 일지장의 가호를 뒤집을 수 있다. 즉 *정보(해석) + 자원희생(제물) = 전술*.
- **캠페인 = 52년 묶음(xiuhmolpilli)**: 52년마다 "세계 재생" 이벤트 — 세이브포인트·난이도 리셋의 서사적 정당화.

### 톤/미학 참조 (웹 검증)
- 미술: Codex Borbonicus·Mendoza의 채색 도상, 멕시카 도자기·석조 부조의 강렬한 원색(진홍·청록·흑).
- 역법/종교 참조: [Tonalpohualli — Wikipedia](https://en.wikipedia.org/wiki/Tonalpohualli), [Aztec calendar stone · day signs](https://www.britannica.com/topic/Aztec-calendar).
- 톤: 다큐멘터리 *Mesoamerica* 시리즈의 경건·무거운 분위기; *Gris*(Nomada)의 색채 언어 적용 가능.
- 가장 가까운 게임: 사실상 동일 세팅의 전술 SRPG **확인 안 됨** (웹 검증). *Aztech*(에듀테인먼트, 1990s)은 거리가 멀다.

### 리스크
- 문화적 민감성 최상 — 멕시카 종교를 "게임 메커니즘"으로 쓰는 것에 원주민 커뮤니티 비판 가능. 자문·연구 필수.
- 260일 주기 학습곡선 — 캘린더 시스템 자체가 진입장벽.
- 정치적 민감 (식민 담론); 마케팅·현지화 리스크.

### 인디/Godot 실현가능성
**중상**. 그리드 + 캘린더 상태머신은 Godot에 자연스럽고, 2D 도상 스프라이트는 Codex 이미지에서 영감. 물리 부담 없음. 진짜 비용은 (1) 도상·일지장 20종의 독창 에셋(의뢰 또는 합성), (2) 문화 자문. MVP는 일지장 8종 + 13일 trecena 1구간 권장.

---

## 세팅 C. Restauratio — 프레스코 복원가 (일상직업 세계의 승격)

### 2문장 피치
르네상스 직후(16세기 이탈리아)의 한 성당, 당신은 프레스코(fresco) 복원팀의 수석 보존가로서 곰팡이·소금 결정·이전 "복원"의 흉터와 싸우며, 매 턴 그림의 한 구역을 살려낸다. 적은 살아있는 적이 아니라 **시간·습도·화학 반응**이며, 유닛은 붓·용제·붕대·스트레소(strappo) 도구이다.

### 왜 신선한가 / 탈피하는 클리셰
- **탈피**: "영웅이 악을 벤다"를 완전히 버리고, **평범한 직업(복원가)을 영웅적 행위로 승격**. 적 = 인간이 아니라 엔트로피·화학·시간.
- 예술/복원 게임은 *Touch the Artwork*(퍼즐), *Fiasco Restoration & Repair*(코미디 시뮬)처럼 **캐주얼·퍼즐**에 머물러 있고, **그리드 전술 SRPG로 복원을 다룬 사례는 없다**(웹 검증).
- 현실 기반: 이탈리아 보존 과학(strappo 기법, solubility parameter, Baumgartner 복원 스튜디오 실제 기록), Brancacci 예배당 최신 진단 기술. [How tech revolutionises fresco conservation — The Art Newspaper](https://www.theartnewspaper.com/2025/03/18/how-technologies-applied-in-florence-are-revolutionising-fresco-conservation).

### 테마가 제안하는 메커닉 (유닛·충돌·맵)
- **유닛 = 도구/기법**: 붓(세척), 용제(레이어 제거), 붕대(strappo 이식), LED(곰팡이 억제), 문서(원본 대조). 각 도구는 "레이어"에 대해 특정 화학 반응(용해·결합·건조)을 일으킨다.
- **맵 = 프레스코 벽면(2D 평면)**: 그리드 = 벽화의 구역. 각 칸은 다층 구조(원본 안료/이전 복원층/먼지/곰팡이/소금)이고, **"공격" = 레이어 제거**. 잘못된 도구 쓰면 원본이 녹아 영구 손실 (HP가 아니라 "진정성 authenticity" 게이지).
- **충돌 = 화학 역학 퍼즐**: 물+용제 = 확산, 열+습기 = 곰팡이 가속, 소금은 건조해야 역결정(再結晶) 해소. 즉 *화학물리 반응을 그리드 위에서 예측* (Into the Breach의 "적 이동 예고"가 "화학 반응 예고"로 치환).
- **승리 = 진정성 복원**: 적을 죽이는 게 아니라 **원본 안료가 드러나는 칸 %** 로 승패. 보스 = "역사적 덧칠하기" (이전 세대의 잘못된 복원층 전체).

### 톤/미학 참조 (웹 검증)
- 미술: 르네상스 프레스코(미켈란젤로 시스티나·마사초 Brancacci)의 채색 + 보존 과학의 "현미경/자외선/적외선" 이미지 위계.
- 분위기: *The Forgery rings Japan's fine art scene — NHK WORLD](https://www3.nhk.or.jp/nhkworld/en/news/backstories/434/) (위조·진정성의 무게), *Aftershocks of an Art Crime — NYT*(2025)](https://www.nytimes.com/2025/11/28/world/asia/japan-art-forgeries.html).
- 가장 가까운 게임: *Fiasco Restoration & Repair*([Chep Site](https://chepegagamedev.com/projects/fiasco-restoration-repair/)) — 코미디 복원 시뮬, 그리드 전술 아님. *Touch the Artwork* — 그림 속 퍼즐 어드벤처.

### 리스크
- "전투 없는 SRPG" 마케팅 거부감 (A·B와 동일한 안티디자인 리스크).
- 화학 반응 시뮬레이션 밸런스 — "재미있는 복잡도" vs "학술적 정확성" 충돌.
- 미술 에셋 비용 — 르네상스 풍 프레스코 + 손상 레이어 다수. 대안: 실존 퍼블릭 도메인 벽화 + 디지털 손상 오버레이.

### 인디/Godot 실현가능성
**중상(에셋 주의)**. 화학 반응은 단순 상태머신(용해도·결정화 룰 5~8종)으로 충분하고 물리 엔진 불필요. Godot의 레이어/셰이더로 다층 프레스코 표현 우수. 진짜 병목은 미술(프레스코 원본 + 손상 단계별 스프라이트). 퍼블릭 도메인 고미술 + 절차적 손상 절감 권장. 소규모 팀·1인 개발에 적합한 가벼운 방향.

---

## 비교 요약 (결정 지원)

| 세팅 | 원본성 | 인디 실현성 | 주요 리스크 | 추천 팀 |
|---|---|---|---|---|
| A. 에도 바둑가문 | 높음 | 중상 | 바둑 단순화·일본사 연구 | 2인, 디자이너 강 |
| B. 멕시카 역법 | 매우 높음 | 중상 | 문화 민감성·에셋 | 자문 가능한 팀 |
| C. 프레스코 복원가 | 높음(안티디자인) | 중상(에셋) | "전투 없음" 마케팅 | 1인/미술 강한 팀 |

> 공통: 셋 모두 README의 파랜드/FFT 하이판타지 기본값에서 명확히 이탈하며, **테마가 곧 메커닉을 제안** (바둑→영토그래프 / 역법→날짜 상태 / 복원→레이어 화학). 04-genrehybrid의 A·B·C(메커닉)와는 직교하는 "세계관" 축이며, 교차 결합 가능 (예: 04-B 구조역학 × 03-C 복원 = "무너지는 성당 벽화의 구조·화학 복합 전술").
> 다음: 03 세팅 중 1개 × 04 메커닉 중 1개를 짝지어 `05-prototype-scope.md`로 전개 권장.

### 웹 검증 소스 (URL)
- 세팅 A: [Honinbo Dosaku — Go Magic](https://gomagic.org/dosaku-the-go-saint/) · [Four Go Houses — Wikipedia](https://en.wikipedia.org/wiki/Four_Go_houses) · [System of Go — NDL](https://www.ndl.go.jp/kaleido/e/entry/22/2.html) · [Go & Discursive Control in Tokugawa Japan — ResearchGate](https://www.researchgate.net/publication/356178327_The_Rhetoric_of_Game_Practices_Go_and_Discursive_Control_in_Tokugawa_Japan)
- 세팅 B: [Tonalpohualli — Wikipedia](https://en.wikipedia.org/wiki/Tonalpohualli) · [Aztec calendar — Britannica](https://www.britannica.com/topic/Aztec-calendar) · [Shadow of the Tomb Raider cultural critique — Reddit r/GirlGamers](https://www.reddit.com/r/GirlGamers/comments/ajtfr2/)
- 세팅 C: [Fresco conservation tech — The Art Newspaper](https://www.theartnewspaper.com/2025/03/18/how-technologies-applied-in-florence-are-revolutionising-fresco-conservation) · [Art forgery in Japan — NHK WORLD](https://www3.nhk.or.jp/nhkworld/en/news/backstories/434/) · [Aftershocks of an Art Crime — NYT 2025](https://www.nytimes.com/2025/11/28/world/asia/japan-art-forgeries.html) · [Fiasco Restoration & Repair](https://chepegagamedev.com/projects/fiasco-restoration-repair/)
