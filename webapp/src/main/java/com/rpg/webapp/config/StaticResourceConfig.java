package com.rpg.webapp.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;

/**
 * 8009 원본 자산(prototype.js/tactics.js·godot-tactics WASM)의 단일 소스 서빙.
 * Flask 원본(8009)과 같은 디렉터리를 직접 참조 — 복사본을 만들지 않는다(RELAY-64 자산정합).
 */
@Configuration
public class StaticResourceConfig implements WebMvcConfigurer {

    @Value("${rpg.legacy-static-dir:../web/static}")
    private String legacyStaticDir;

    @Value("${rpg.workbench-dir:../tools/asset_workbench}")
    private String workbenchDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // /legacy/prototype-assets/** → 8009 Flask의 static/ (원본 경로패리티: /static/...)
        registry.addResourceHandler("/legacy/prototype-assets/**")
                .addResourceLocations("file:" + new java.io.File(legacyStaticDir).getAbsolutePath() + "/")
                .setCachePeriod(3600)
                .resourceChain(true)
                .addResolver(new PathResourceResolver());

        // /legacy/godot-tactics/** → 8009의 WASM 47MB+PCK(단일 소스, 복사 없음)
        registry.addResourceHandler("/legacy/godot-tactics/**")
                .addResourceLocations("file:" + new java.io.File(legacyStaticDir + "/godot-tactics").getAbsolutePath() + "/")
                .setCachePeriod(3600)
                .resourceChain(true)
                .addResolver(new PathResourceResolver());

        // /studio/assets/img/** → 8017 스파이크 저장소 이미지(RELAY-36)
        registry.addResourceHandler("/studio/assets/img/**")
                .addResourceLocations("file:" + new java.io.File(workbenchDir + "/store").getAbsolutePath() + "/")
                .setCachePeriod(600)
                .resourceChain(true)
                .addResolver(new PathResourceResolver());
    }
}
