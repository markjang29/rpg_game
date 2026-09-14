package com.rpg.webapp.api;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.commonmark.ext.gfm.tables.TablesExtension;
import org.commonmark.node.Node;
import org.commonmark.parser.Parser;
import org.commonmark.renderer.html.HtmlRenderer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * RELAY-64 — 자산 정합 API.
 * content/*.md 4파일은 8009 Flask와 동일 원본을 단일 소스로 읽는다(복사 아님).
 * 8017 흡수: 워크벤치 스파이크의 저장소(RELAY-36, store/) 카탈로그를 읽기전용 제공.
 */
@RestController
public class RpgApiController {

    private static final String SITE_ID = "8009-webapp";
    private static final String SITE_IMPL = "Spring Boot 4.1 · Java 17 · React 18 (RELAY-64)";

    private final Parser parser = Parser.builder().extensions(List.of(TablesExtensionHolder.EXT)).build();
    private final HtmlRenderer renderer = HtmlRenderer.builder().extensions(List.of(TablesExtensionHolder.EXT)).build();

    /** 8009의 Flask content 디렉터리 — 단일 소스. 운영 배포본과 repo가 동일 구조라 상대 해석. */
    @Value("${rpg.content-dir:../web/content}")
    private String contentDir;

    @Value("${rpg.workbench-dir:../tools/asset_workbench}")
    private String workbenchDir;

    /** 8017 스파이크 유형 코드 → 라벨/사이즈(RELAY-36 TYPES 대응, 읽기전용). */
    private static final Map<String, String> WORKBENCH_TYPES = Map.of(
            "CHR", "캐릭터", "WLD", "월드/배경", "WPN", "무기·장비",
            "ITM", "소품", "FX", "이펙트", "UIX", "UI·컨셉");

    /**
     * 자산 정합성: 8009 콘텐츠 마크다운을 HTML로 렌더.
     * GET /api/apps/rpg/content?section=hero|core|combat|modules
     */
    @GetMapping("/api/apps/rpg/content")
    public ResponseEntity<Map<String, Object>> content(@RequestParam("section") String section) {
        // 8009와 동일한 4 섹션만 — 파라미터 화이트리스트(과잉 노출 방지)
        if (!List.of("hero", "core", "combat", "modules").contains(section)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "unknown section: " + section));
        }
        Path file = Path.of(contentDir).resolve(section + ".md").toAbsolutePath().normalize();
        if (!Files.isRegularFile(file)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "not found: " + file.getFileName()));
        }
        try {
            String html = renderer.render(parser.parse(Files.readString(file, StandardCharsets.UTF_8)));
            return ResponseEntity.ok(Map.of(
                    "site-id", SITE_ID,
                    "implemented-with", SITE_IMPL,
                    "section", section,
                    "source", "markdown:single-source",
                    "html", html));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", String.valueOf(e.getMessage())));
        }
    }

    /** 모듈 현황(DEVELOPMENT.md §4 기준, 읽기전용) — /apps/rpg 허브 카드. */
    @GetMapping("/api/apps/rpg/modules")
    public ResponseEntity<Map<String, Object>> modules() {
        // 정합: DEVELOPMENT.md §4 표의 값 — 코드에 하드코딩하되 요약이므로 파일을 두지 않음.
        // 향후 DEVELOPMENT.md 파싱으로 대체 가능(단일 소스 원칙).
        List<Map<String, String>> items = List.of(
                Map.of("id", "parry", "label", "parry (패링 손맛)", "state", "done", "entry", "modules/parry/"),
                Map.of("id", "grid_parry", "label", "grid_parry (그리드×패링)", "state", "done", "entry", "modules/grid_parry/"),
                Map.of("id", "reasoning", "label", "reasoning (추론×전술) ⭐", "state", "wip", "entry", "modules/reasoning/"),
                Map.of("id", "duel_advance", "label", "duel_advance (진검승부)", "state", "design", "entry", "modules/(예정)"),
                Map.of("id", "walk", "label", "walk (걷기→예측 버퍼)", "state", "planned", "entry", "-"),
                Map.of("id", "color-dye", "label", "color-dye (색 염색)", "state", "planned", "entry", "-"),
                Map.of("id", "territory", "label", "territory (영토PvP)", "state", "planned", "entry", "-"),
                Map.of("id", "romance", "label", "romance (로맨스)", "state", "planned", "entry", "-"));
        return ResponseEntity.ok(Map.of("items", items, "site-id", SITE_ID, "implemented-with", SITE_IMPL));
    }

    /**
     * 8017(RETIRED→/studio/assets import) — 워크벤치 갤러리 카탈로그 읽기전용.
     * 스파이크 저장소(store/*.json+이미지)를 그대로 읽어 410 없이 import-동결 상태 제공.
     */
    @GetMapping("/api/studio/assets/gallery")
    public ResponseEntity<Map<String, Object>> workbenchGallery(@RequestParam(value = "limit", defaultValue = "60") int limit) {
        Path store = Path.of(workbenchDir).resolve("store").toAbsolutePath().normalize();
        if (!Files.isDirectory(store)) {
            return ResponseEntity.ok(Map.of("items", List.of(), "source", "workbench-store-missing", "site-id", "8017"));
        }
        List<Map<String, Object>> items = new java.util.ArrayList<>();
        try (var stream = Files.list(store)) {
            stream.filter(p -> p.getFileName().toString().endsWith(".json")).sorted().limit(limit).forEach(p -> {
                try {
                    Map<?, ?> meta = java.util.Map.of(); // 안전: 개별 읽기 실패는 skip
                    try (var in = Files.newInputStream(p)) {
                        Object o = new com.fasterxml.jackson.databind.ObjectMapper().readValue(inRead(p), Map.class);
                        if (o instanceof Map) meta = (Map<?, ?>) o;
                    }
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("obj-id", "8017-" + p.getFileName().toString().replaceFirst("\\.json$", ""));
                    row.put("meta", meta);
                    items.add(row);
                } catch (Exception ignore) {
                    // 읽기 실패 레코드는 카탈로그에서 생략(정합성: 빈 카탈로그 오판 방지용 로그는 요청 시)
                }
            });
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", String.valueOf(e.getMessage())));
        }
        return ResponseEntity.ok(Map.of("items", items, "count", items.size(), "site-id", "8017", "implemented-with", "Spring import of RELAY-36 spike store"));
    }

    /** 8017 유형 코드 — import 정합 표(RELAY-36 TYPES 재현, 읽기전용). */
    @GetMapping("/api/studio/assets/types")
    public ResponseEntity<Map<String, Object>> workbenchTypes() {
        return ResponseEntity.ok(Map.of("types", WORKBENCH_TYPES, "site-id", "8017"));
    }

    private static final class TablesExtensionHolder {
        static final org.commonmark.Extension EXT = TablesExtensionHolderHolder.TABLES;
    }

    private static final class TablesExtensionHolderHolder {
        static final org.commonmark.Extension TABLES =
                org.commonmark.ext.gfm.tables.TablesExtension.create();
    }

    private static java.io.InputStream inRead(Path p) throws java.io.IOException {
        return Files.newInputStream(p);
    }
}
