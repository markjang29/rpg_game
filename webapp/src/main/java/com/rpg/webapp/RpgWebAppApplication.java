package com.rpg.webapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * RELAY-64 — 8009 RPG 웹 Spring+React 재설계.
 * 8024(matrix-studio-spring)의 Modulith 관례를 승계한 단독 게임동 앱.
 * 운영: 8009 포트 승계(신규 포트 생성 없음) / 테스트: 8031(매니저 지정, 실측 비어있음).
 */
@SpringBootApplication
public class RpgWebAppApplication {

    public static void main(String[] args) {
        SpringApplication.run(RpgWebAppApplication.class, args);
    }
}
