package audit

import (
	"github.com/gin-gonic/gin"

	"github.com/kairo/haven/internal/notes"
)

// UseNoteHooks 把审计写入器接到笔记包的 publish / unpublish 钩子。
//
// 笔记 CRUD（创建 / 编辑 / 删除）不审计，只有公开状态变化写事件（audit.md 第三节）。
func UseNoteHooks(h *notes.Handler, w *Writer) {
	if w == nil || h == nil {
		return
	}

	h.OnNotePublished = func(c *gin.Context, ac notes.AuditContext, noteID, title string) {
		w.Record(c.Request.Context(), Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventNotePublished,
			TargetType:    TargetNote,
			TargetID:      noteID,
			Metadata:      map[string]any{"title": title},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}

	h.OnNoteUnpublished = func(c *gin.Context, ac notes.AuditContext, noteID, title string) {
		w.Record(c.Request.Context(), Event{
			ActorUserID:   ac.UserID,
			ActorUsername: ac.Username,
			EventType:     EventNoteUnpublished,
			TargetType:    TargetNote,
			TargetID:      noteID,
			Metadata:      map[string]any{"title": title},
			IP:            ac.IP,
			UserAgent:     ac.UA,
		})
	}
}
