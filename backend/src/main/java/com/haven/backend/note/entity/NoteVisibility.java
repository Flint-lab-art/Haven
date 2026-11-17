package com.haven.backend.note.entity;

/**
 * 笔记可见性（对应 {@code notes.visibility} 列的取值）。
 * <p>
 * 用常量而不是裸字符串，避免 {@code "public"} / {@code "private"} 散落在查询条件和业务判断里。
 */
public final class NoteVisibility {

    /** 仅作者可见。 */
    public static final String PRIVATE = "private";
    /** 已发布，出现在公开站。 */
    public static final String PUBLIC = "public";

    private NoteVisibility() {}
}
