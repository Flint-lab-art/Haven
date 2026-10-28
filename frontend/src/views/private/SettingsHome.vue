<script setup lang="ts">
/** 设置概览（docs/frontend/frontend.md 第四节 /settings）。 */
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import PrivateHeader from '@/components/PrivateHeader.vue'
import SettingsNav from '@/components/SettingsNav.vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

const authLabel = computed(() => (auth.authType === 'token' ? 'API Token' : '浏览器会话'))
</script>

<template>
  <PrivateHeader />

  <main class="page page--wide">
    <h1 class="page-title" style="margin-bottom: 24px">设置</h1>

    <div class="settings-layout">
      <SettingsNav />

      <div class="stack">
        <section class="panel panel--padded">
          <dl class="kv">
            <dt>用户名</dt>
            <dd>{{ auth.username }}</dd>
            <dt>登录方式</dt>
            <dd>{{ authLabel }}</dd>
            <dt>双重验证</dt>
            <dd>{{ auth.totpEnabled ? '已启用' : '未启用' }}</dd>
          </dl>
        </section>

        <section class="panel list">
          <RouterLink :to="{ name: 'settings-security' }" class="list__row list__row--link">
            <div class="list__row-main">
              <div class="card__title">账号安全</div>
              <div class="card__meta">修改密码、绑定或关闭动态码</div>
            </div>
          </RouterLink>
          <RouterLink :to="{ name: 'settings-sessions' }" class="list__row list__row--link">
            <div class="list__row-main">
              <div class="card__title">会话</div>
              <div class="card__meta">查看并撤销已登录的浏览器</div>
            </div>
          </RouterLink>
          <RouterLink :to="{ name: 'settings-devices' }" class="list__row list__row--link">
            <div class="list__row-main">
              <div class="card__title">授信设备</div>
              <div class="card__meta">30 天内免动态码的浏览器</div>
            </div>
          </RouterLink>
          <RouterLink :to="{ name: 'settings-tokens' }" class="list__row list__row--link">
            <div class="list__row-main">
              <div class="card__title">API Token</div>
              <div class="card__meta">供脚本长期使用的凭证</div>
            </div>
          </RouterLink>
        </section>
      </div>
    </div>
  </main>
</template>
