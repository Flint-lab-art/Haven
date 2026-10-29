<script setup lang="ts">
/** 设置概览。 */
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import PrivateHeader from '@/components/PrivateHeader.vue'
import SettingsNav from '@/components/SettingsNav.vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

const authLabel = computed(() => (auth.authType === 'token' ? 'API Token' : '浏览器会话'))
</script>

<template>
  <div class="shell">
    <PrivateHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">设置</h1>
          <p class="page-sub">{{ auth.username }} 的账号与凭证</p>
        </div>
      </header>

      <div class="settings-layout">
        <SettingsNav />

        <div class="stack">
          <section class="panel panel--pad">
            <dl class="kv">
              <dt>用户名</dt>
              <dd>{{ auth.username }}</dd>
              <dt>登录方式</dt>
              <dd>{{ authLabel }}</dd>
              <dt>双重验证</dt>
              <dd>
                <span :class="auth.totpEnabled ? 'badge badge--public' : 'badge badge--private'">
                  {{ auth.totpEnabled ? '已启用' : '未启用' }}
                </span>
              </dd>
            </dl>
          </section>

          <section class="panel rows">
            <RouterLink :to="{ name: 'settings-security' }" class="row-item row-item--tappable">
              <div class="row-item__main">
                <div class="row-item__title">账号安全</div>
                <div class="row-item__sub">修改密码、绑定或关闭动态码</div>
              </div>
              <span class="row-item__chevron" aria-hidden="true">›</span>
            </RouterLink>
            <RouterLink :to="{ name: 'settings-sessions' }" class="row-item row-item--tappable">
              <div class="row-item__main">
                <div class="row-item__title">会话</div>
                <div class="row-item__sub">查看并结束已登录的浏览器</div>
              </div>
              <span class="row-item__chevron" aria-hidden="true">›</span>
            </RouterLink>
            <RouterLink :to="{ name: 'settings-devices' }" class="row-item row-item--tappable">
              <div class="row-item__main">
                <div class="row-item__title">授信设备</div>
                <div class="row-item__sub">30 天内免动态码的浏览器</div>
              </div>
              <span class="row-item__chevron" aria-hidden="true">›</span>
            </RouterLink>
            <RouterLink :to="{ name: 'settings-tokens' }" class="row-item row-item--tappable">
              <div class="row-item__main">
                <div class="row-item__title">API Token</div>
                <div class="row-item__sub">供脚本长期使用的凭证</div>
              </div>
              <span class="row-item__chevron" aria-hidden="true">›</span>
            </RouterLink>
          </section>
        </div>
      </div>
    </main>
  </div>
</template>
