package com.haven.backend.note.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.core.io.Resource;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;

/**
 * 上传文件静态托管的安全测试：越界路径、目录、软链接都必须 404，正常文件可读。
 */
class UploadsStaticControllerTest {

    @TempDir
    private Path uploadRoot;

    private UploadsStaticController controller;

    @BeforeEach
    void setUp() throws IOException {
        Files.createDirectories(uploadRoot.resolve("notes/2026/01"));
        Files.writeString(uploadRoot.resolve("notes/2026/01/a.png"), "png-bytes");
        Files.createDirectories(uploadRoot.resolve("notes/dir"));
        controller = new UploadsStaticController();
        ReflectionTestUtils.setField(controller, "uploadRoot", uploadRoot.toString());
    }

    @Test
    @DisplayName("正常文件返回 200")
    void servesExistingFile() {
        ResponseEntity<Resource> response = serve("/uploads/notes/2026/01/a.png");

        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
    }

    @Test
    @DisplayName("目录穿越被拒绝")
    void rejectsTraversal() {
        assertNull(serve("/uploads/../../etc/passwd").getBody());
        assertNull(serve("/uploads/notes/../../../etc/passwd").getBody());
    }

    @Test
    @DisplayName("空路径与目录本身返回 404")
    void rejectsEmptyAndDirectory() {
        assertNull(serve("/uploads/").getBody());
        assertNull(serve("/uploads/notes/dir").getBody());
    }

    @Test
    @DisplayName("不存在的文件返回 404")
    void missingFileIs404() {
        assertNull(serve("/uploads/notes/2026/01/missing.png").getBody());
    }

    private ResponseEntity<Resource> serve(String path) {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", path);
        request.setRequestURI(path);
        return controller.serveFile(request);
    }
}
