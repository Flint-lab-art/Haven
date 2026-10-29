<script setup lang="ts">
/** 设置概览。 */
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

const authLabel = computed(() => (auth.authType === 'token' ? 'API Token' : '浏览器会话'))
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">设置</h1>
      <p class="detail-sub">{{ auth.username }} 的账号与凭证</p>
    </header>

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

    <p class="field__hint" style="margin-top: 16px">
      左侧列表可进入账号安全、会话、授信设备与 API Token 管理。
    </p>
  </div>
</template>
