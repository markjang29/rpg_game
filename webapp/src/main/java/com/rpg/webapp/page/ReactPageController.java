package com.rpg.webapp.page;

import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Explicit SPA entry routes — 8024 ReactPageController allow-list 관례 승계.
 * catch-all forward 없이 API·정적자산·actuator를 지키기 위한 허용목록 방식.
 *
 * 8009(Flask) 경로 패리티 + RELAY-64 신규 재설계 경로:
 *  - /apps/rpg        ← 정본 타깃(DONOR_IMPORT, MATRIX-P0-OWN-01) — RPG 허브
 *  - /apps/rpg/prototype · /apps/rpg/tactics ← 기존 /prototype, /prototype/tactics
 *  - /apps/rpg/godot-tactics/ ← WASM(React 정적 경유, 경로 패리티)
 *  - /legacy/prototype* ← 8009 Flask 원본 경로 병행(전환기)
 */
@Controller
public class ReactPageController {

    @GetMapping({"/apps/rpg", "/apps/rpg/"})
    public String hub(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store");
        return "forward:/react/apps.html";
    }

    @GetMapping({"/apps/rpg/prototype", "/legacy/prototype"})
    public String prototype(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store");
        return "forward:/react/prototype.html";
    }

    @GetMapping({"/apps/rpg/tactics", "/legacy/prototype/tactics"})
    public String tactics(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store");
        return "forward:/react/tactics.html";
    }

    @GetMapping({"/studio/assets", "/legacy/8017/"})
    public String assets(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store");
        return "forward:/react/assets.html";
    }
}
