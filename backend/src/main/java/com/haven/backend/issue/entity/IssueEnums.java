package com.haven.backend.issue.entity;

/**
 * 需求 / Bug 的类型、状态、优先级取值（与数据库 CHECK 约束一致）。
 */
public final class IssueEnums {

    /** 类型。 */
    public static final class Type {
        public static final String BUG = "bug";
        public static final String FEATURE = "feature";

        private Type() {}
    }

    /** 状态。 */
    public static final class Status {
        public static final String TODO = "todo";
        public static final String IN_PROGRESS = "in_progress";
        public static final String DONE = "done";

        private Status() {}
    }

    /** 优先级。 */
    public static final class Priority {
        public static final String LOW = "low";
        public static final String MEDIUM = "medium";
        public static final String HIGH = "high";

        private Priority() {}
    }

    private IssueEnums() {}
}
