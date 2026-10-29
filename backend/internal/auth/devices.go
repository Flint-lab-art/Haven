package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

// 授信设备管理（api.md 第四节 / auth.md 第四节）。
//
// 不提供创建设备接口：授信只能在登录时通过 trust_device=true 在那台
// 浏览器上创建（api.md 4.2 说明）。

// ErrTrustedDeviceNotFound 表示设备不存在或不属于当前用户（404）。
var ErrTrustedDeviceNotFound = errors.New("授信设备不存在")

// TrustedDeviceSummary 是 GET /api/trusted-devices 的列表项（api.md 4.1）。
type TrustedDeviceSummary struct {
	ID         string    `json:"id"`
	DeviceName string    `json:"device_name"`
	CreatedAt  time.Time `json:"created_at"`
	LastUsedAt time.Time `json:"last_used_at"`
	ExpiresAt  time.Time `json:"expires_at"`
}

// ListTrustedDevices 返回当前用户的全部授信设备，按最近使用倒序。
func (s *Service) ListTrustedDevices(ctx context.Context, userID string) ([]TrustedDeviceSummary, error) {
	const q = `
		SELECT id, device_name, created_at, last_used_at, expires_at
		FROM trusted_devices
		WHERE user_id = $1
		ORDER BY last_used_at DESC`

	rows, err := s.db.QueryContext(ctx, q, userID)
	if err != nil {
		return nil, fmt.Errorf("查询授信设备失败: %w", err)
	}
	defer rows.Close()

	out := make([]TrustedDeviceSummary, 0, 4)
	for rows.Next() {
		var item TrustedDeviceSummary
		if err := rows.Scan(&item.ID, &item.DeviceName, &item.CreatedAt, &item.LastUsedAt, &item.ExpiresAt); err != nil {
			return nil, fmt.Errorf("扫描授信设备失败: %w", err)
		}
		out = append(out, item)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("读取授信设备失败: %w", err)
	}
	return out, nil
}

// FindTrustedDevice 返回设备的展示名，用于撤销时写审计事件（audit.md 第三节）。
func (s *Service) FindTrustedDevice(ctx context.Context, userID, deviceID string) (TrustedDeviceSummary, error) {
	const q = `
		SELECT id, device_name, created_at, last_used_at, expires_at
		FROM trusted_devices WHERE id = $1 AND user_id = $2`

	var item TrustedDeviceSummary
	err := s.db.QueryRowContext(ctx, q, deviceID, userID).Scan(
		&item.ID, &item.DeviceName, &item.CreatedAt, &item.LastUsedAt, &item.ExpiresAt)
	if errors.Is(err, sql.ErrNoRows) {
		return TrustedDeviceSummary{}, ErrTrustedDeviceNotFound
	}
	if err != nil {
		return TrustedDeviceSummary{}, fmt.Errorf("查询授信设备失败: %w", err)
	}
	return item, nil
}

// RevokeTrustedDevice 撤销即硬删除（api.md 4.2）。
func (s *Service) RevokeTrustedDevice(ctx context.Context, userID, deviceID string) error {
	const q = `DELETE FROM trusted_devices WHERE id = $1 AND user_id = $2`
	res, err := s.db.ExecContext(ctx, q, deviceID, userID)
	if err != nil {
		return fmt.Errorf("删除授信设备失败: %w", err)
	}
	n, err := res.RowsAffected()
	if err != nil {
		return fmt.Errorf("读取删除结果失败: %w", err)
	}
	if n == 0 {
		return ErrTrustedDeviceNotFound
	}
	return nil
}
