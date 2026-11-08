.PHONY: all frontend backend clean help

# 默认目标：全量构建
all: backend

# 前端产物：dist 目录
frontend: frontend/dist
frontend/dist:
	@echo "===== Building frontend ====="
	cd frontend && pnpm install && pnpm run build

# 后端依赖前端产物，先保证 frontend/dist 存在
backend: frontend
	@echo "===== Building backend ====="
	# 清空旧静态资源
	rm -rf backend/src/main/resources/static/*
	# 递归复制 dist 全部内容
	cp -r frontend/dist/* backend/src/main/resources/static/
	cd backend && ./mvnw clean package -DskipTests

# 清理
clean:
	@echo "===== Clean artifacts ====="
	rm -rf frontend/dist
	cd backend && ./mvnw clean && rm -rf src/main/resources/static/*

help:
	@echo "Targets:"
	@echo "  make all        构建全部（前端+后端）"
	@echo "  make frontend   仅构建前端"
	@echo "  make backend    仅构建后端（自动先构建前端）"
	@echo "  make clean      清理构建产物"
