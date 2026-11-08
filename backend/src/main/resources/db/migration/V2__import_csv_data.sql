-- V2: 从 Go 后端 csv_export 导入历史数据
-- 由 scripts/generate_migration.py 自动生成

BEGIN;

-- 延迟外键约束检查，允许乱序插入（folders 父子关系）
SET CONSTRAINTS ALL DEFERRED;

-- users: 1 条（密码: kairo123）
INSERT INTO users (id, username, password_hash, totp_secret, totp_enabled, created_at, updated_at) VALUES
  ('dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'kairo', '$2a$12$teWl5/8LR3R7Xj.d3pRvCuQE4gs9fCvZMeg4cZrXgKuVyKS81oRGe', 'IMX4ICSS5FVQDFEIEZGMLPNN2PIA472N', true, '2026-10-29 18:13:08.358799+08'::timestamptz, '2026-11-05 11:31:17.345535+08'::timestamptz);

-- folders: 22 条
INSERT INTO folders (id, user_id, parent_id, name, sort_order, created_at, updated_at, icon, is_inbox) VALUES
  ('75ea30a2-6b56-499b-8a67-2bdf0a8ce5fc'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '006a70ab-a05d-4344-ad08-8f2c6849835c'::uuid, 'Windows', 0, '2026-11-01 14:16:35.691937+08'::timestamptz, '2026-11-06 15:32:58.800765+08'::timestamptz, '/uploads/icons/2026/11/892abf1434f5c6666aed191f54123b31.png', false),
  ('006a70ab-a05d-4344-ad08-8f2c6849835c'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'c90abd3b-f2ac-4c9d-8c19-51609746b886'::uuid, '操作系统', 1, '2026-10-31 11:00:59.743484+08'::timestamptz, '2026-11-06 15:34:14.392339+08'::timestamptz, '/uploads/icons/2026/11/15737e50e4d7271c0c8c5bb6575012b5.png', false),
  ('9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, NULL, '收件箱', 0, '2026-10-31 07:19:02.454274+08'::timestamptz, '2026-10-31 07:50:24.935128+08'::timestamptz, '🗂️', true),
  ('5eee4f85-0aaf-4fb0-9447-cc7dc089047b'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'c90abd3b-f2ac-4c9d-8c19-51609746b886'::uuid, '漏洞学习', 2, '2026-11-06 14:56:02.071981+08'::timestamptz, '2026-11-06 15:35:09.132507+08'::timestamptz, '/uploads/icons/2026/11/556eaada3546becf711203211f33eed0.png', false),
  ('16ac2a59-568e-4e00-8c9f-ed995cc3c929'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'c90abd3b-f2ac-4c9d-8c19-51609746b886'::uuid, 'AI相关', 3, '2026-10-31 11:01:22.524898+08'::timestamptz, '2026-11-06 15:35:39.952431+08'::timestamptz, '/uploads/icons/2026/11/728676a9ea65007e9154189bb43d2d7b.png', false),
  ('d9cce6e1-5212-4cd2-93ff-f6e80f265088'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'c90abd3b-f2ac-4c9d-8c19-51609746b886'::uuid, '网络 & 服务器', 4, '2026-10-31 11:01:16.626172+08'::timestamptz, '2026-11-06 15:36:04.901841+08'::timestamptz, '/uploads/icons/2026/11/0b17246fc3e08c9713fc912eec997bf2.png', false),
  ('2f7dd925-bcbf-449f-9a1e-b5d2766a1af7'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'c90abd3b-f2ac-4c9d-8c19-51609746b886'::uuid, '通用知识', 5, '2026-10-31 11:01:05.733918+08'::timestamptz, '2026-11-06 15:36:45.520163+08'::timestamptz, '📁', false),
  ('c90abd3b-f2ac-4c9d-8c19-51609746b886'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, NULL, '知识库', 1, '2026-10-30 09:49:11.123726+08'::timestamptz, '2026-10-31 11:06:47.210004+08'::timestamptz, '📚', false),
  ('3cc12372-708e-4c08-9745-1e6b518d8519'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'c90abd3b-f2ac-4c9d-8c19-51609746b886'::uuid, '编程语言', 0, '2026-10-31 11:00:46.983484+08'::timestamptz, '2026-11-06 15:37:19.030964+08'::timestamptz, '/uploads/icons/2026/11/b7c930ba154f82917efed6d3cfe58d84.png', false),
  ('57475bc4-ef3c-4e7e-a8b7-17b5526dc5a2'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '598d17ef-9f99-415b-8070-ea95237c72eb'::uuid, '官网检索器', 0, '2026-10-31 11:07:08.696886+08'::timestamptz, '2026-10-31 11:07:08.696886+08'::timestamptz, NULL, false),
  ('f99572ef-3288-4dca-bebd-e424a93436d8'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '3cc12372-708e-4c08-9745-1e6b518d8519'::uuid, 'JavaScript', 0, '2026-11-05 13:06:40.677016+08'::timestamptz, '2026-11-06 15:37:41.815647+08'::timestamptz, '/uploads/icons/2026/11/cb4c848529b8612e33dd9f9585983bfe.png', false),
  ('598d17ef-9f99-415b-8070-ea95237c72eb'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, NULL, '项目', 2, '2026-10-31 11:06:39.860067+08'::timestamptz, '2026-10-31 17:19:53.954754+08'::timestamptz, '📝', false),
  ('9e43d5aa-00e9-4619-a51d-1195d25ea739'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '3cc12372-708e-4c08-9745-1e6b518d8519'::uuid, 'Python', 1, '2026-10-31 11:01:51.011605+08'::timestamptz, '2026-11-06 15:37:48.64199+08'::timestamptz, 'python', false),
  ('ca102ac5-74c2-4b46-827a-b74dc322c7f9'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, NULL, '归档', 3, '2026-10-31 17:19:41.875599+08'::timestamptz, '2026-10-31 17:19:57.825527+08'::timestamptz, '🔒', false),
  ('a1e7e98b-f958-4d11-9727-964a23a0415e'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'ca102ac5-74c2-4b46-827a-b74dc322c7f9'::uuid, 'gogs-diary', 0, '2026-10-31 11:07:16.415344+08'::timestamptz, '2026-11-05 18:05:12.293224+08'::timestamptz, NULL, false),
  ('41db51c3-af76-448c-9ef0-69fe40e25bae'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '3cc12372-708e-4c08-9745-1e6b518d8519'::uuid, 'Shell', 2, '2026-10-31 11:01:55.389025+08'::timestamptz, '2026-11-06 15:38:11.4666+08'::timestamptz, '/uploads/icons/2026/11/220ffbfde3cea578c3b852f3988d0c9e.png', false),
  ('1298a12a-a471-41df-aa57-e3f2ef56e992'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '5eee4f85-0aaf-4fb0-9447-cc7dc089047b'::uuid, 'Linux', 0, '2026-11-06 15:17:59.411774+08'::timestamptz, '2026-11-06 15:17:59.411774+08'::timestamptz, NULL, false),
  ('6f9b36f3-b5ee-4cd6-aeb0-1c011a524893'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'f99572ef-3288-4dca-bebd-e424a93436d8'::uuid, 'NodeJs', 0, '2026-10-31 11:01:47.244542+08'::timestamptz, '2026-11-06 15:38:53.86363+08'::timestamptz, '/uploads/icons/2026/11/7b696c9c22585ff3e04829f43f1d34fe.png', false),
  ('ff85d7aa-2b79-4a66-88a7-117ae477873d'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '006a70ab-a05d-4344-ad08-8f2c6849835c'::uuid, 'Linux', 0, '2026-11-06 09:43:23.225908+08'::timestamptz, '2026-11-06 15:32:04.328485+08'::timestamptz, '/uploads/icons/2026/11/a3dfbf2910d566bbbc0016795f65c531.png', false),
  ('c59ba8f6-bf7e-4c30-81e4-327ea96f7fa4'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'ff85d7aa-2b79-4a66-88a7-117ae477873d'::uuid, 'ArchLinux', 0, '2026-11-06 09:43:31.16251+08'::timestamptz, '2026-11-06 15:32:18.141354+08'::timestamptz, '/uploads/icons/2026/11/9320c1255d5da3c43709a14a5be36752.png', false),
  ('4da8644b-2afb-428e-b02f-21aa06e8bdeb'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'ff85d7aa-2b79-4a66-88a7-117ae477873d'::uuid, 'Other', 1, '2026-11-06 09:43:41.582207+08'::timestamptz, '2026-11-06 15:32:41.666312+08'::timestamptz, '/uploads/icons/2026/11/cd7fb41cfa9116c08233edef679d2ead.png', false),
  ('19a87a99-6972-4f5d-9a6e-6797fa054ae8'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'f99572ef-3288-4dca-bebd-e424a93436d8'::uuid, '油猴', 0, '2026-11-05 13:07:06.997359+08'::timestamptz, '2026-11-06 15:39:10.602665+08'::timestamptz, '📁', false);

-- tags: 34 条
INSERT INTO tags (id, user_id, name, created_at) VALUES
  ('9075fcb6-c1f0-49c5-a7b7-c9970bec24b3'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Playwright', '2026-10-31 11:04:47.779581+08'::timestamptz),
  ('e8423ea4-8068-4be0-a0ab-8bf5ebb4b450'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'SQLite', '2026-10-31 11:04:52.039257+08'::timestamptz),
  ('570ba71b-e352-460f-852e-722462579e2f'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Vue3', '2026-10-31 11:04:56.927013+08'::timestamptz),
  ('42a9a8a7-8362-4a04-b654-16869832ccc9'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '爬虫', '2026-10-31 11:05:01.045931+08'::timestamptz),
  ('af010e50-e6f8-4baa-a377-dc96a5f57f93'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '开发记录', '2026-10-31 17:43:08.798278+08'::timestamptz),
  ('9681d3b8-48a7-480e-83c4-6200ee284713'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'DeepSeek', '2026-10-31 17:43:08.999141+08'::timestamptz),
  ('946ac7b7-f0bf-45de-bb64-841e3b576425'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'AI', '2026-10-31 17:43:09.118241+08'::timestamptz),
  ('89465eb5-3afc-46f6-b5f4-7d7f6d026c41'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Python', '2026-10-31 17:43:09.233588+08'::timestamptz),
  ('39a8213f-2aeb-405d-be6b-46da2be66a11'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'gogs', '2026-10-31 17:43:09.350246+08'::timestamptz),
  ('b15e4dc4-6bba-4756-aeef-7bccf61a8195'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '思源笔记', '2026-10-31 17:43:09.470838+08'::timestamptz),
  ('5e055b7c-a86d-431e-befd-12fc20efe7f9'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Linux', '2026-10-31 17:43:10.045759+08'::timestamptz),
  ('ad0abb97-30ed-4c5b-9214-b4f284e55da6'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'cron', '2026-10-31 17:43:10.162222+08'::timestamptz),
  ('74cf4d60-cb10-4ccf-affc-52e0d112245d'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '部署', '2026-10-31 17:43:10.278729+08'::timestamptz),
  ('3aa752ed-37d3-481f-9c54-b2b675268341'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '重构', '2026-10-31 17:43:10.511994+08'::timestamptz),
  ('851a701b-b49d-4ce6-8b1d-c211570aa741'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'API', '2026-10-31 17:43:10.8532+08'::timestamptz),
  ('510b60dd-7256-427f-b83b-b35c5cb0ca59'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '架构', '2026-10-31 17:43:11.043945+08'::timestamptz),
  ('de2e29eb-0948-49f1-81da-7c83fb12064f'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '并行调度', '2026-10-31 17:43:11.475348+08'::timestamptz),
  ('53675993-ee21-4980-9d3b-5d66b31d4816'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '命中判定', '2026-10-31 17:43:11.742732+08'::timestamptz),
  ('5557fdfc-b99c-488f-97ae-1d5deee7612d'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '状态机', '2026-10-31 17:43:11.858235+08'::timestamptz),
  ('83663bcb-0c24-4440-8d8f-466c2541276c'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '断点续跑', '2026-10-31 17:43:11.979375+08'::timestamptz),
  ('8d89061c-aeba-4dfa-9767-e3750fb326ea'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Vite', '2026-10-31 17:43:12.404759+08'::timestamptz),
  ('b767bb06-ef15-450f-9943-68e887972679'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Windows', '2026-11-05 11:23:57.700141+08'::timestamptz),
  ('49e2ecbb-5626-4a2a-9096-7fb9789b728d'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'macOS', '2026-11-05 11:24:09.749021+08'::timestamptz),
  ('7d6af0eb-8ea0-40ba-9c21-d19b280bbf40'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '油猴', '2026-11-05 13:05:54.778101+08'::timestamptz),
  ('cd8c8114-2847-4f91-95ea-34371f555fc1'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'tampermonkey', '2026-11-05 13:06:00.75641+08'::timestamptz),
  ('46c2112e-23a4-4326-9ff6-209dfe846532'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'js脚本', '2026-11-05 13:06:07.43774+08'::timestamptz),
  ('056e5d4d-db31-47dd-9966-c4585abc861a'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '浏览器脚本', '2026-11-05 13:06:13.012478+08'::timestamptz),
  ('1c15d77e-9812-4118-a33b-64f011ca8409'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '搜索查重', '2026-11-05 13:06:17.789147+08'::timestamptz),
  ('48a09afc-cc0f-4a48-bc10-4a5bdbd4dcc4'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'ArchLinux', '2026-11-06 13:12:54.489145+08'::timestamptz),
  ('0e919136-6a50-458d-ae70-3a2cde87d866'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'musl libc', '2026-11-06 14:58:00.839557+08'::timestamptz),
  ('7657dad3-b0bb-4cd3-8b7a-4ea382aef526'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Alpine', '2026-11-06 14:58:08.108329+08'::timestamptz),
  ('a8bdd31d-6a36-4ba4-941a-cc0bdefb123e'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'openssh', '2026-11-06 14:58:16.650204+08'::timestamptz),
  ('7b5f1d69-c6c9-4733-84c8-6c395f23199d'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '漏洞', '2026-11-06 14:58:27.990509+08'::timestamptz),
  ('6c1df245-5e8a-42e2-86b7-8c82dfa5b737'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'CVE', '2026-11-06 15:01:18.02433+08'::timestamptz);

-- notes: 32 条
INSERT INTO notes (id, user_id, title, content, visibility, published_at, search_text, created_at, updated_at, folder_id, sort_order, deleted_at) VALUES
  ('1b81688f-7adc-4704-a659-93ba65d04be0'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '官网检索器 · V1到V2重构记录', '<blockquote>
<p>从 V1 到 V2 的重构决策、清理与脱敏发布历程。</p>
</blockquote>
<h2>1. 为什么重构</h2>
<table>
<thead>
<tr>
<th>痛点（V1）</th>
<th>V2 方案</th>
</tr>
</thead>
<tbody>
<tr>
<td>任务不能重跑</td>
<td>失败词/引擎可单独重跑 + 「重试失败项」</td>
</tr>
<tr>
<td>有「本轮上限」</td>
<td>移除，开始即跑全部待处理关键词</td>
</tr>
<tr>
<td>创建任务不关弹窗不跳转</td>
<td>创建成功自动关闭并跳转任务页</td>
</tr>
<tr>
<td>创建任务平台默认全选</td>
<td>改为默认全不勾选</td>
</tr>
<tr>
<td>完成态显示 0/0</td>
<td><code>finished</code> 优先 → 进度 100%</td>
</tr>
<tr>
<td>无法按日期筛选/打包</td>
<td>下载中心按日期筛选 + 按日期打包</td>
</tr>
</tbody>
</table>
<h2>2. 重构关键决策</h2>
<ol>
<li><strong>保留后端核心逻辑</strong>：四平台采集、命中判定、断点续跑的设计延续到 V2，重构重点是前端交互 + 后端并发健壮性。</li>
<li><strong>每任务独立隔离</strong>：独立 db / profile / 截图目录，实现多任务并行不污染。</li>
<li><strong>判定三态化 + 熔断</strong>：​<code>_next_page</code> 三态（True/False/&#34;stuck&#34;）+ 连续 3 页 0 条熔断，解决&#34;真到底 vs 被拦截&#34;误判。</li>
<li><strong>状态分类严格</strong>：​<code>hit/none/error/restricted/malfunction</code> 五态，结论聚合不把&#34;判不出来&#34;写成&#34;未命中&#34;。</li>
<li><strong>脱敏分离</strong>：config.py 占位 + config_local.py（gitignore）覆盖，为公开做准备。</li>
</ol>
<h2>3. 清理清单（发布前）</h2>
<table>
<thead>
<tr>
<th>项</th>
<th>处理</th>
</tr>
</thead>
<tbody>
<tr>
<td>死配置 ​<code>SCREENSHOT_DIR</code>​（桌面带品牌路径）/​<code>DB_PATH</code>​/​<code>KEYWORDS_FILE</code>​/​<code>ST_PENDING</code></td>
<td>整段删除，零引用</td>
</tr>
<tr>
<td>死函数 ​<code>profile_helper.ensure_task_profiles</code></td>
<td>删除（server 走 ​<code>tab_profile_dir</code>）</td>
</tr>
<tr>
<td><code>engine</code>​ 的 ​<code>cdp_full_screenshot</code>​ / ​<code>par_profile_dir</code>​ / ​<code>stop_playwright</code></td>
<td>死代码（无调用）</td>
</tr>
<tr>
<td><code>scripts/install.bat</code>​、​<code>start.bat</code></td>
<td>删除，只留 ​<code>start_panel.bat</code>（相对路径 + 项目自带 venv）</td>
</tr>
<tr>
<td>并发问题 A1/A2/A3</td>
<td>修复（临界区 / 加锁 / 连接关闭）</td>
</tr>
<tr>
<td><code>skip</code>（跳过验证码）全链路</td>
<td>删除，遇验证码记错误 + 重试兜底</td>
</tr>
<tr>
<td><code>/api/shutdown</code> 无鉴权端点</td>
<td>删除</td>
</tr>
</tbody>
</table>
<h2>4. 脱敏与公开</h2>
<h3>4.1 建干净副本</h3>
<p>robocopy 复制独立发布副本（排除 ​<code>.git/.venv/node_modules/dist/__pycache__/data/shots/profile_sessions/logs</code>​ 及 ​<code>*.db</code>），原运行目录不再改动。</p>
<h3>4.2 脱敏清单</h3>
<table>
<thead>
<tr>
<th>位置</th>
<th>处理</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>core/config.py</code> 注释</td>
<td>改为&#34;占位示例值，真实值写在 config_local.py&#34;</td>
</tr>
<tr>
<td><code>TARGET_DOMAIN</code></td>
<td>真实域名 → ​<code>example.com</code></td>
</tr>
<tr>
<td><code>BAIDU_OFFICIAL_MARKS</code></td>
<td>真实标识 → ​<code>[&#34;示例官网&#34;,&#34;example.com&#34;]</code></td>
</tr>
<tr>
<td><code>bing_m.py</code>​ / ​<code>baidu_m.py</code> 注释</td>
<td>去品牌</td>
</tr>
<tr>
<td><code>baidu.py</code> 函数名</td>
<td>去掉品牌前缀 → ​<code>_is_official</code>（定义+调用 3 处）</td>
</tr>
<tr>
<td>新建 ​<code>core/config_local.py</code></td>
<td>放真实值，被 gitignore 挡住不进库</td>
</tr>
</tbody>
</table>
<h3>4.3 配套</h3>
<ul>
<li><code>.gitignore</code>​ 完善：待提交 285 → 33 个文件；​<code>node_modules/profile_sessions/data/shots/logs/.venv/web/dist</code>​ 全部命中 + ​<code>*.db</code> 兜底。</li>
<li><code>package.json</code>​ / ​<code>package-lock.json</code>​（两处）name 统一 ​<code>official-website-search-web</code>​（三处一致，否则 ​<code>npm ci</code> 报错）。</li>
<li>补 ​<code>README.md</code>​（英文）+ ​<code>README-zh.md</code>​（中文）、​<code>LICENSE</code>​（MIT）、​<code>.gitattributes</code>​、​<code>.editorconfig</code>​、​<code>config_local.example.py</code>​、​<code>SECURITY.md</code>​、​<code>CONTRIBUTING.md</code>、CI。</li>
<li><code>pyproject.toml</code>​ 对齐 ​<code>readme</code>​、playwright 版本统一 ​<code>==1.62.0</code>、清掉指向不存在文件的配置。</li>
</ul>
<h2>5. 发布</h2>
<ul>
<li>双远程：gitee + GitHub，​<code>origin</code>​ push 配双 url → ​<code>git push</code> 一次双推。</li>
<li>SSH 首次连接 ​<code>Host key verification failed</code>​ → ​<code>ssh-keyscan</code>​ 加入 ​<code>known_hosts</code>。</li>
<li>CI：pytest + ruff + npm build，全绿。</li>
</ul>
<h2>6. 迁移后的稳定态</h2>
<ul>
<li>仓库内 0 命中真实品牌（​<code>git grep</code> 校验）。</li>
<li>冒烟测试 ​<code>1 passed</code>​；ruff ​<code>All checks passed</code>；CI 全绿。</li>
<li>原运行目录（含真实数据）保持独立，不受公开仓库影响。</li>
</ul>
', 'private', NULL, '官网检索器 · V1到V2重构记录 从 V1 到 V2 的重构决策、清理与脱敏发布历程。 1. 为什么重构 痛点（V1） V2 方案 任务不能重跑 失败词/引擎可单独重跑 + 「重试失败项」 有「本轮上限」 移除，开始即跑全部待处理关键词 创建任务不关弹窗不跳转 创建成功自动关闭并跳转任务页 创建任务平台默认全选 改为默认全不勾选 完成态显示 0/0 finished 优先 → 进度 100% 无法按日期筛选/打包 下载中心按日期筛选 + 按日期打包 2. 重构关键决策 保留后端核心逻辑 ：四平台采集、命中判定、断点续跑的设计延续到 V2，重构重点是前端交互 + 后端并发健壮性。 每任务独立隔离 ：独立 db / profile / 截图目录，实现多任务并行不污染。 判定三态化 + 熔断 ：​ _next_page 三态（True/False/&#34;stuck&#34;）+ 连续 3 页 0 条熔断，解决&#34;真到底 vs 被拦截&#34;误判。 状态分类严格 ：​ hit/none/error/restricted/malfunction 五态，结论聚合不把&#34;判不出来&#34;写成&#34;未命中&#34;。 脱敏分离 ：config.py 占位 + config_local.py（gitignore）覆盖，为公开做准备。 3. 清理清单（发布前） 项 处理 死配置 ​ SCREENSHOT_DIR ​（桌面带品牌路径）/​ DB_PATH ​/​ KEYWORDS_FILE ​/​ ST_PENDING 整段删除，零引用 死函数 ​ profile_helper.ensure_task_profiles 删除（server 走 ​ tab_profile_dir ） engine ​ 的 ​ cdp_full_screenshot ​ / ​ par_profile_dir ​ / ​ stop_playwright 死代码（无调用） scripts/install.bat ​、​ start.bat 删除，只留 ​ start_panel.bat （相对路径 + 项目自带 venv） 并发问题 A1/A2/A3 修复（临界区 / 加锁 / 连接关闭） skip （跳过验证码）全链路 删除，遇验证码记错误 + 重试兜底 /api/shutdown 无鉴权端点 删除 4. 脱敏与公开 4.1 建干净副本 robocopy 复制独立发布副本（排除 ​ .git/.venv/node_modules/dist/__pycache__/data/shots/profile_sessions/logs ​ 及 ​ *.db ），原运行目录不再改动。 4.2 脱敏清单 位置 处理 core/config.py 注释 改为&#34;占位示例值，真实值写在 config_local.py&#34; TARGET_DOMAIN 真实域名 → ​ example.com BAIDU_OFFICIAL_MARKS 真实标识 → ​ [&#34;示例官网&#34;,&#34;example.com&#34;] bing_m.py ​ / ​ baidu_m.py 注释 去品牌 baidu.py 函数名 去掉品牌前缀 → ​ _is_official （定义+调用 3 处） 新建 ​ core/config_local.py 放真实值，被 gitignore 挡住不进库 4.3 配套 .gitignore ​ 完善：待提交 285 → 33 个文件；​ node_modules/profile_sessions/data/shots/logs/.venv/web/dist ​ 全部命中 + ​ *.db 兜底。 package.json ​ / ​ package-lock.json ​（两处）name 统一 ​ official-website-search-web ​（三处一致，否则 ​ npm ci 报错）。 补 ​ README.md ​（英文）+ ​ README-zh.md ​（中文）、​ LICENSE ​（MIT）、​ .gitattributes ​、​ .editorconfig ​、​ config_local.example.py ​、​ SECURITY.md ​、​ CONTRIBUTING.md 、CI。 pyproject.toml ​ 对齐 ​ readme ​、playwright 版本统一 ​ ==1.62.0 、清掉指向不存在文件的配置。 5. 发布 双远程：gitee + GitHub，​ origin ​ push 配双 url → ​ git push 一次双推。 SSH 首次连接 ​ Host key verification failed ​ → ​ ssh-keyscan ​ 加入 ​ known_hosts 。 CI：pytest + ruff + npm build，全绿。 6. 迁移后的稳定态 仓库内 0 命中真实品牌（​ git grep 校验）。 冒烟测试 ​ 1 passed ​；ruff ​ All checks passed ；CI 全绿。 原运行目录（含真实数据）保持独立，不受公开仓库影响。', '2026-10-31 17:43:10.43372+08'::timestamptz, '2026-10-31 17:43:10.43372+08'::timestamptz, '57475bc4-ef3c-4e7e-a8b7-17b5526dc5a2'::uuid, 0, NULL),
  ('663f783f-a60a-499d-b197-5d46379d0c36'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'CVE-2026-123158 漏洞学习笔记（sshole / OpenSSH + musl libc 密码绕过）', '<p><strong>📌 基础信息概览</strong><br>漏洞代号：sshole｜披露时间：2026-11-05｜补丁版本：OpenSSH ≥ 10.6p2</p><h2>触发条件（全部满足才可利用）</h2><ol><li><p>OpenSSH 版本 &lt; 10.6p2（未合并补丁）</p></li><li><p>系统 libc 为 musl（Alpine、OpenWrt 默认；glibc 不受影响）</p></li><li><p><code>sshd_config</code> 开启 <code>UsePAM no</code>，走传统 crypt 认证路径</p></li><li><p>目标用户在 <code>/etc/shadow</code> 的密码字段为 <code>*</code>，账号锁定、禁止密码登录</p></li><li><p>系统内至少存在一个正常用户，拥有合法 sha512 哈希，为 crypt 提供 salt</p></li></ol><h2>漏洞原理</h2><p>这是一个<strong>跨组件语义冲突漏洞</strong>，不是代码崩溃，也不是哈希算法被破解。</p><ul><li><p>Unix 标准函数 <code>crypt()</code>，规范约定：计算失败时应当返回 <code>NULL</code></p></li><li><p>musl 的实现取舍：密码长度 ≥ 257 字节时超限，不返回 NULL，返回静态字符串 <code>*</code><br>musl 设计者本意：<code>*</code> 是密码生态公认的「哈希计算失败标记」，避免上层无判空代码直接空指针崩溃。</p></li><li><p>shadow 体系约定：<code>*</code> / <code>!</code> 代表<strong>账号锁定，禁止密码登录</strong>，两套语义撞在了同一个字符串上。</p></li><li><p>旧 OpenSSH 校验逻辑：拿到 crypt 返回值，只判断不为 NULL，直接做字符串相等对比。</p></li></ul><blockquote><p>攻击链路：传入257字节超长密码 → musl crypt 返回 <code>*</code> → 和 shadow 里锁定标记 <code>*</code> 字符串相等 → 认证放行，绕过锁定限制。</p></blockquote><h2>三段核心C代码对比</h2><h3>1. 存在漏洞的原始校验逻辑</h3><pre class="hljs"><code>char *computed = crypt(password, stored_hash);
if (computed &amp;&amp; strcmp(computed, stored_hash) == 0) {
    return 1; // 校验通过，放行
}
</code></pre><p>缺陷：没有提前判断账号锁定标记，不区分 crypt 返回值是正常哈希，还是错误标记。</p><h3>2. musl crypt 超长密码分支（简化）</h3><pre class="hljs"><code>if (keylen &gt; 256) {
    strcpy(result, "*");
    return result;
}
</code></pre><h3>3. OpenSSH 官方补丁逻辑（修复方案）</h3><pre class="hljs"><code>// 调用crypt之前，优先判断账号锁定语义
if (stored_hash[0] == ''*'' || stored_hash[0] == ''!'') {
    return 0; // 直接拒绝，不再执行密码哈希计算
}
// 再往下才调用 crypt 做比对
</code></pre><p><strong>💡 重点区分：</strong> 不是限制密码长度（只针对musl的hack方案），而是<strong>遵循shadow语义，锁定账号直接拦截</strong>，通用、可移植，不受libc差异影响。</p><h2>本次复现失败原因</h2><p>Alpine官方源已经升级 OpenSSH 至带补丁的版本，读到 <code>*</code> 锁定标记就直接打印日志：</p><p><code>User testuser not allowed because account is locked</code></p><p>直接跳出，根本不会进入 crypt 函数调用，漏洞无法触发。</p><h2>Python逻辑模拟代码（仅演示原理，非可利用EXP）</h2><pre class="hljs"><code>def musl_crypt_sim(password: str, salt: str):
    if len(password) &gt;= 257:
        # musl超长密码的异常行为：返回 *
        return "*"
    import hashlib
    return hashlib.sha512((password + salt).encode()).hexdigest()

shadow = {
    "testuser": "*",
    "normaluser": "$6$rounds=5000$abc123$FAKEHASH"
}
real_hash = shadow["normaluser"]
salt = real_hash.split("$")[2]

print("=== 短密码 aaaa ===")
ret1 = musl_crypt_sim("aaaa", salt)
print(f"crypt返回：{ret1}")
print(f"比对结果：{''放行'' if ret1 == shadow[''testuser''] else ''拒绝''}")

print("\n=== payload：257个A ===")
ret2 = musl_crypt_sim("A"*257, salt)
print(f"比对结果：{''放行'' if ret2 == shadow[''testuser''] else ''拒绝''}")
</code></pre><h2>开发学习收获 &amp; 教训</h2><ul><li><p>第三方库、系统调用返回值<strong>不可无条件信任</strong>，文档契约和不同平台实现经常不一致。</p></li><li><p>异常分支是高危点：报错时有可能返回一个具备业务含义的字符串，而不是NULL。</p></li><li><p>单纯字符串相等是非常弱的校验，优先校验<strong>数据语义、状态</strong>，而不是只比对内容。</p></li><li><p>跨组件边界是漏洞高发区：单独看每个组件逻辑都合理，但隐性行为组合之后产生绕过。</p></li><li><p>修复优先选择语义层拦截，尽量避免写死平台私有阈值的临时hack。</p></li></ul><h2>官方参考链接</h2><ul><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="http://CVE.org">CVE.org</a><a target="_blank" rel="noopener noreferrer nofollow" href="https://cve.org/CVERecord?id=CVE-2026-123158"> 官方记录</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://nvd.nist.gov/vuln/detail/cve-2026-123158">NVD 漏洞详情</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://www.openssh.com/releasenotes.html#10.6p2">OpenSSH Release Notes 10.6p2</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://sshhole.com/">sshhole 漏洞专题页</a></p></li></ul><p></p>', 'private', NULL, 'CVE-2026-123158 漏洞学习笔记（sshole / OpenSSH + musl libc 密码绕过） 📌 基础信息概览 漏洞代号：sshole｜披露时间：2026-11-05｜补丁版本：OpenSSH ≥ 10.6p2 触发条件（全部满足才可利用） OpenSSH 版本 &lt; 10.6p2（未合并补丁） 系统 libc 为 musl（Alpine、OpenWrt 默认；glibc 不受影响） sshd_config 开启 UsePAM no ，走传统 crypt 认证路径 目标用户在 /etc/shadow 的密码字段为 * ，账号锁定、禁止密码登录 系统内至少存在一个正常用户，拥有合法 sha512 哈希，为 crypt 提供 salt 漏洞原理 这是一个 跨组件语义冲突漏洞 ，不是代码崩溃，也不是哈希算法被破解。 Unix 标准函数 crypt() ，规范约定：计算失败时应当返回 NULL musl 的实现取舍：密码长度 ≥ 257 字节时超限，不返回 NULL，返回静态字符串 * musl 设计者本意： * 是密码生态公认的「哈希计算失败标记」，避免上层无判空代码直接空指针崩溃。 shadow 体系约定： * / ! 代表 账号锁定，禁止密码登录 ，两套语义撞在了同一个字符串上。 旧 OpenSSH 校验逻辑：拿到 crypt 返回值，只判断不为 NULL，直接做字符串相等对比。 攻击链路：传入257字节超长密码 → musl crypt 返回 * → 和 shadow 里锁定标记 * 字符串相等 → 认证放行，绕过锁定限制。 三段核心C代码对比 1. 存在漏洞的原始校验逻辑 char *computed = crypt(password, stored_hash); if (computed &amp;&amp; strcmp(computed, stored_hash) == 0) { return 1; // 校验通过，放行 } 缺陷：没有提前判断账号锁定标记，不区分 crypt 返回值是正常哈希，还是错误标记。 2. musl crypt 超长密码分支（简化） if (keylen &gt; 256) { strcpy(result, "*"); return result; } 3. OpenSSH 官方补丁逻辑（修复方案） // 调用crypt之前，优先判断账号锁定语义 if (stored_hash[0] == ''*'' || stored_hash[0] == ''!'') { return 0; // 直接拒绝，不再执行密码哈希计算 } // 再往下才调用 crypt 做比对 💡 重点区分： 不是限制密码长度（只针对musl的hack方案），而是 遵循shadow语义，锁定账号直接拦截 ，通用、可移植，不受libc差异影响。 本次复现失败原因 Alpine官方源已经升级 OpenSSH 至带补丁的版本，读到 * 锁定标记就直接打印日志： User testuser not allowed because account is locked 直接跳出，根本不会进入 crypt 函数调用，漏洞无法触发。 Python逻辑模拟代码（仅演示原理，非可利用EXP） def musl_crypt_sim(password: str, salt: str): if len(password) &gt;= 257: # musl超长密码的异常行为：返回 * return "*" import hashlib return hashlib.sha512((password + salt).encode()).hexdigest() shadow = { "testuser": "*", "normaluser": "$6$rounds=5000$abc123$FAKEHASH" } real_hash = shadow["normaluser"] salt = real_hash.split("$")[2] print("=== 短密码 aaaa ===") ret1 = musl_crypt_sim("aaaa", salt) print(f"crypt返回：{ret1}") print(f"比对结果：{''放行'' if ret1 == shadow[''testuser''] else ''拒绝''}") print("\n=== payload：257个A ===") ret2 = musl_crypt_sim("A"*257, salt) print(f"比对结果：{''放行'' if ret2 == shadow[''testuser''] else ''拒绝''}") 开发学习收获 &amp; 教训 第三方库、系统调用返回值 不可无条件信任 ，文档契约和不同平台实现经常不一致。 异常分支是高危点：报错时有可能返回一个具备业务含义的字符串，而不是NULL。 单纯字符串相等是非常弱的校验，优先校验 数据语义、状态 ，而不是只比对内容。 跨组件边界是漏洞高发区：单独看每个组件逻辑都合理，但隐性行为组合之后产生绕过。 修复优先选择语义层拦截，尽量避免写死平台私有阈值的临时hack。 官方参考链接 CVE.org 官方记录 NVD 漏洞详情 OpenSSH Release Notes 10.6p2 sshhole 漏洞专题页', '2026-11-06 15:10:15.951904+08'::timestamptz, '2026-11-06 15:10:45.898471+08'::timestamptz, '5eee4f85-0aaf-4fb0-9447-cc7dc089047b'::uuid, 0, '2026-11-06 15:11:04.586872+08'::timestamptz),
  ('26561010-f249-4b0d-a786-f9114ec06230'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '油猴｜搜索查重脚本（百度+必应双版本）', '<blockquote><p>用途：百度/必应搜索页本地扫描搜索结果，检测目标作者、匹配已发布标题库；控制台输出日志 + 浏览器桌面通知。 运行环境：Tampermonkey油猴，<strong>全部逻辑浏览器本地执行，不上传任何数据</strong>。 脱敏调整：<code>TARGET_AUTHOR</code>、<code>PUBLISHED_TITLES</code>仅保留示例占位，业务实际数据不在笔记内硬编码，使用时自行填入。</p></blockquote><h2>能力总览</h2><ol><li><p><strong>文本归一化</strong>：剔除全部标点，只保留中文、英文、数字，转小写做匹配</p></li><li><p><strong>两套命中规则</strong></p><ul><li><p>标题匹配：页面标题归一化后包含库内标题片段则命中</p></li><li><p>作者匹配：搜索结果来源作者等于配置目标作者则命中</p></li></ul></li><li><p><strong>去重机制</strong>：Set集合，同一标题只打印一次日志、只触发一次通知</p></li><li><p><strong>防抖扫描</strong>：DOM变动、滚动事件防抖，避免高频重复执行</p></li><li><p><strong>通知提醒</strong>：命中触发浏览器系统通知；通知被禁用时仅保留控制台日志</p></li><li><p>百度版：适配PC新旧卡片、移动端，无自动滚动</p></li><li><p>必应版：PC+移动端，自动逐屏下滑停顿人工复核，遍历完毕回滚页面顶部</p></li></ol><h2>脚本1：百度搜索查重 baidu‑check.user.js</h2><pre class="hljs"><code>// ==UserScript==
// @name         内容查重（百度PC+移动端兼容｜浏览器本地通知）
// @namespace    [http://tampermonkey.net/](http://tampermonkey.net/)
// @version      2.14
// @description  适配百度新旧搜索卡片、移动端搜索；忽略标点，仅比对中英文字数字；控制台日志输出，浏览器系统通知提醒，全部本地运算不上传数据
// @author       You
// @match        *://www.baidu.com/*
// @match        *://m.baidu.com/*
// @grant        none
// ==/UserScript==
(function() {
    ''use strict'';
    console.log("=====内容查重脚本【百度】启动=====");
    const CONFIG = {
        // 使用时替换为实际目标作者名称
        TARGET_AUTHOR: "示例作者名称"
    };
    // 使用时替换为真实已发布标题列表
    const PUBLISHED_TITLES = [
        "示例标题一",
        "示例标题二",
        "示例标题三"
    ];

    /**
     * 文本归一化：清除全部标点符号，仅保留中文/英文/数字，转小写
     * @param {string} str
     * @returns {string}
     */
    function normalize(str){
        return str.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '''')
            .trim()
            .toLowerCase();
    }
    const libNormalized = PUBLISHED_TITLES.map(t=&gt;normalize(t));

    // 获取搜索词
    function getSearchWord() {
        const urlParams = new URLSearchParams(location.search);
        return urlParams.get(''word'') || urlParams.get(''wd'') || '''';
    }

    let isRunning = false;
    let debounceTimer = null;
    const notifiedSet = new Set();
    const printedSet = new Set();

    /**
     * 触发浏览器桌面通知
     * @param {string} titleText 命中标题
     * @param {string} matchText 命中原因
     */
    function sendNotify(titleText, matchText){
        const msg = `标题：${titleText}\n${matchText}`;
        if("Notification" in window &amp;&amp; Notification.permission === "granted"){
            new Notification(''查重命中【百度】'', { body: msg });
        }
    }

    /**
     * 扫描页面搜索结果卡片
     */
    function scan(){
        if(isRunning) return;
        isRunning = true;
        try{
            const keyword = getSearchWord();
            // 百度三类结果卡片选择器
            const pcOldCards = document.querySelectorAll(''a.normal-sub_11u5j'');
            const pcNewCards = document.querySelectorAll(''div.cosc-card'');
            const mobileCards = document.querySelectorAll(''section.cosc-card-content'');
            const allCards = [...pcOldCards, ...pcNewCards, ...mobileCards];

            console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`);

            allCards.forEach(card=&gt;{
                let rawTitle = "";
                let linkUrl = "";
                let hitReason = null;

                // 旧版卡片 a.normal‑sub_11u5j
                if (card.tagName === "A") {
                    const titleEl = card.querySelector(''h3[data-module="top_title"]'');
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    linkUrl = card.href;
                    const titleNorm = normalize(rawTitle);
                    for(const s of libNormalized){
                        if(titleNorm.includes(s)){
                            hitReason = `标题库匹配：${s}`;
                            break;
                        }
                    }
                    // 匹配作者来源
                    if(!hitReason){
                        const sourceWrap = card.querySelector(''div[data-module="source"]'');
                        if(sourceWrap){
                            const authorDiv = sourceWrap.querySelector(''div.source-left_J1XTH div'');
                            if(authorDiv &amp;&amp; authorDiv.innerText.trim() === CONFIG.TARGET_AUTHOR){
                                hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`;
                            }
                        }
                    }
                }
                // PC新版 cosc‑card
                else if (card.classList.contains(''cosc-card'')) {
                    const titleEl = card.querySelector(''h3[data-module="title"]'');
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    const aTag = titleEl.querySelector(''a'');
                    linkUrl = aTag?.href || "";
                    const titleNorm = normalize(rawTitle);
                    for(const s of libNormalized){
                        if(titleNorm.includes(s)){
                            hitReason = `标题库匹配：${s}`;
                            break;
                        }
                    }
                    if(!hitReason){
                        const sourceWrap = card.querySelector(''div[data-module="source"]'');
                        if(sourceWrap){
                            const authorSpan = sourceWrap.querySelector(''span.cosc-source-text'');
                            if(authorSpan &amp;&amp; authorSpan.innerText.trim() === CONFIG.TARGET_AUTHOR){
                                hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`;
                            }
                        }
                    }
                }
                // 移动端 section.cosc‑card‑content
                else {
                    const titleEl = card.querySelector(''div[data-module="title"] h3'');
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    const aTag = card.querySelector("a");
                    linkUrl = aTag?.href || "";
                    const titleNorm = normalize(rawTitle);
                    for(const s of libNormalized){
                        if(titleNorm.includes(s)){
                            hitReason = `标题库匹配：${s}`;
                            break;
                        }
                    }
                    if(!hitReason){
                        const sourceWrap = card.querySelector(''div[data-module="source"]'');
                        if(sourceWrap){
                            const authorSpan = sourceWrap.querySelector(''span.cosc-source-text'');
                            if(authorSpan &amp;&amp; authorSpan.innerText.trim() === CONFIG.TARGET_AUTHOR){
                                hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`;
                            }
                        }
                    }
                }

                const titleKey = rawTitle;
                if(printedSet.has(titleKey)) return;
                printedSet.add(titleKey);

                if(hitReason){
                    notifiedSet.add(titleKey);
                    console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl} | 原因：${hitReason}`);
                    sendNotify(rawTitle, hitReason);
                }else{
                    console.log(`- 普通 | 标题：${rawTitle} | 链接：${linkUrl}`);
                }
            })
        }finally{
            isRunning = false;
        }
    }

    // 防抖调度
    function debounceScan(){
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(scan, 400);
    }

    function start(){
        // 请求通知权限
        if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){
            Notification.requestPermission();
        }
        // 监听DOM变化
        const observer = new MutationObserver(()=&gt; debounceScan());
        observer.observe(document.body, {childList:true, subtree:true});
        window.addEventListener(''scroll'', debounceScan, {passive:true});
        scan();
        setTimeout(scan, 1200);
    }

    if(document.body) start();
    else document.addEventListener(''DOMContentLoaded'', start);
})();
</code></pre><h2>脚本2：必应搜索查重 bing‑check.user.js</h2><pre class="hljs"><code>// ==UserScript==
// @name         内容查重（必应Bing版｜PC移动端｜自动逐屏复核）
// @namespace    [http://tampermonkey.net/](http://tampermonkey.net/)
// @version      1.8
// @description  必应搜索查重；搜索结果自动分段缓慢下滑，每屏停顿人工复核，扫描完成回顶部；控制台输出标题与链接，浏览器本地通知提醒，全部本地运算不上传
// @author       You
// @match        *://cn.bing.com/search*
// @match        *://www.bing.com/search*
// @grant        none
// ==/UserScript==
(function() {
    ''use strict'';
    console.log("=====内容查重脚本【必应】启动=====");
    const CONFIG = {
        // 使用时替换实际目标作者
        TARGET_AUTHOR: "示例作者名称",
        scrollSegmentTime: 800,     // 单段滑动动画毫秒
        pausePerScreen: 1600,       // 每屏停留复核时间毫秒（主要调参）
        scrollUpTime: 1200          // 全部扫描完回顶部滚动时长
    };

    // 使用时替换为真实已发布标题列表
    const PUBLISHED_TITLES = [
        "示例标题一",
        "示例标题二",
        "示例标题三"
    ];

    /**
     * 文本归一化：清除全部标点符号，仅保留中文/英文/数字，转小写
     * @param {string} str
     * @returns {string}
     */
    function normalize(str){
        return str.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '''')
            .trim()
            .toLowerCase();
    }
    const libNormalized = PUBLISHED_TITLES.map(t=&gt;normalize(t));

    function getSearchWord() {
        const urlParams = new URLSearchParams(location.search);
        return urlParams.get(''q'') || '''';
    }

    let isRunning = false;
    let debounceTimer = null;
    const notifiedSet = new Set();
    const printedSet = new Set();
    let lastQuery = "";

    function sendNotify(titleText, matchText){
        const msg = `标题：${titleText}\n${matchText}`;
        if("Notification" in window &amp;&amp; Notification.permission === "granted"){
            new Notification(''查重命中【必应】'', { body: msg });
        }
    }

    /**
     * 平滑滚动Promise封装，自定义缓动
     * @param {number} targetTop
     * @param {number} duration
     * @returns {Promise&lt;void&gt;}
     */
    function smoothScrollTo(targetTop, duration) {
        return new Promise(resolve =&gt; {
            const startTop = window.scrollY;
            const distance = targetTop - startTop;
            const startTime = performance.now();
            function step(now) {
                const elapsed = now - startTime;
                const progress = Math.min(elapsed / duration, 1);
                const ease = 1 - Math.pow(1 - progress, 2);
                window.scrollTo(0, startTop + distance * ease);
                if (progress &lt; 1) {
                    requestAnimationFrame(step);
                } else {
                    resolve();
                }
            }
            requestAnimationFrame(step);
        });
    }

    /**
     * 自动逐屏下滑复核，到底返回顶部
     */
    async function runScrollCycle() {
        const viewH = window.innerHeight;
        let currentY = window.scrollY;
        const maxY = document.documentElement.scrollHeight - viewH;
        while(currentY &lt; maxY - 50){
            currentY = currentY + viewH * 0.85; // 屏幕重叠系数，避免漏看
            if(currentY &gt; maxY) currentY = maxY;
            await smoothScrollTo(currentY, CONFIG.scrollSegmentTime);
            await new Promise(r =&gt; setTimeout(r, CONFIG.pausePerScreen));
        }
        await smoothScrollTo(0, CONFIG.scrollUpTime);
    }

    function scan(){
        if(isRunning) return;
        isRunning = true;
        try{
            const keyword = getSearchWord();
            // 必应多类型卡片选择器
            const pcCards = document.querySelectorAll(''li.b_algo'');
            const mobileCards = document.querySelectorAll(''div.algocore, div.b_mcard, div.b_richcard'');
            const pcNewsCards = document.querySelectorAll(''.na_card_wrp'');
            const mobileNewsCards = document.querySelectorAll(''.nnews_card, .b_news_card'');
            const allCards = [...pcCards, ...mobileCards, ...pcNewsCards, ...mobileNewsCards];

            // 搜索词变化时重置状态并启动自动滚动
            if (keyword !== lastQuery) {
                console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`);
                lastQuery = keyword;
                printedSet.clear();
                runScrollCycle();
            }

            allCards.forEach(card=&gt;{
                let rawTitle = "";
                let linkUrl = "";
                let hitReason = null;
                let sourceText = "";

                const titleLink = card.querySelector(''a[href] h2 a, h2 &gt; a, a.title, a[href]:has(h2)'');
                if(titleLink){
                    rawTitle = titleLink.innerText.trim();
                    linkUrl = titleLink.href;
                }else{
                    const directA = card.querySelector(''a[href]'');
                    if(directA){
                        rawTitle = directA.innerText.trim();
                        linkUrl = directA.href;
                    }
                }
                const sourceEl = card.querySelector(''.b_attribution, .source, .na_footer_name, .cap_txt, .b_caption'');
                sourceText = sourceEl?.innerText.trim() || '''';

                if (!rawTitle || !linkUrl) return;

                const titleNorm = normalize(rawTitle);
                for(const s of libNormalized){
                    if(titleNorm.includes(s)){
                        hitReason = `标题库匹配：${s}`;
                        break;
                    }
                }
                if(!hitReason &amp;&amp; sourceText === CONFIG.TARGET_AUTHOR){
                    hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`;
                }

                const titleKey = rawTitle;
                if(printedSet.has(titleKey)) return;
                printedSet.add(titleKey);

                if(hitReason){
                    notifiedSet.add(titleKey);
                    console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl} | 原因：${hitReason}`);
                    sendNotify(rawTitle, hitReason);
                }else{
                    console.log(`- 普通 | 标题：${rawTitle} | 链接：${linkUrl}`);
                }
            })
        }finally{
            isRunning = false;
        }
    }

    function debounceScan(){
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(scan, 400);
    }

    function start(){
        if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){
            Notification.requestPermission();
        }
        const observer = new MutationObserver(()=&gt; debounceScan());
        observer.observe(document.body, {childList:true, subtree:true});
        window.addEventListener(''scroll'', debounceScan, {passive:true});
        scan();
        setTimeout(scan, 1200);
    }

    if(document.body) start();
    else document.addEventListener(''DOMContentLoaded'', start);
})();
</code></pre><h2>使用说明</h2><h3>安装步骤</h3><ol><li><p>浏览器安装 Tampermonkey（油猴）扩展</p></li><li><p>新建脚本，复制对应版本全部代码保存</p></li><li><p>打开百度/必应搜索页自动加载；首次运行允许<strong>浏览器通知权限</strong>，否则无弹窗提醒</p></li></ol><h3>配置替换（每次新建脚本必须改）</h3><ol><li><p><code>CONFIG.TARGET_AUTHOR</code>：替换为实际要监控的作者名字</p></li><li><p><code>PUBLISHED_TITLES</code>数组：填入真实业务标题字符串</p><blockquote><p>新增/删减文章，直接修改此数组，保存脚本即生效</p></blockquote></li></ol><h3>必应版可调参数（CONFIG对象）</h3><table style="min-width: 50px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th><p>参数</p></th><th><p>含义</p></th></tr><tr><td><p>pausePerScreen</p></td><td><p>每屏停留时间ms，越大人工复核越从容，推荐1200‑2000</p></td></tr><tr><td><p>scrollSegmentTime</p></td><td><p>单段滑动动画耗时</p></td></tr><tr><td><p>scrollUpTime</p></td><td><p>全部遍历完成回顶部动画时长</p></td></tr></tbody></table><h3>查看输出结果</h3><ol><li><p>F12 → Console控制台查看完整日志；<code>✅</code>代表命中条目</p></li><li><p>命中会弹出浏览器桌面通知，显示标题与命中原因；通知被屏蔽仅保留控制台输出</p></li></ol><h3>限制与风险</h3><ol><li><p>纯前端本地运行，不上传任何数据</p></li><li><p>搜索引擎前端改版会导致DOM选择器失效，需要更新卡片querySelector</p></li><li><p>浏览器全局/站点通知权限关闭，则只有控制台日志</p></li><li><p>必应切换搜索关键词会重新执行完整自动滚动复核</p></li></ol><h3>故障排查</h3><ol><li><p>没有通知：检查网站通知权限是否允许</p></li><li><p>扫描不到结果：Console确认脚本已启动；判断是否搜索引擎DOM改版，选择器失效</p></li><li><p>重复打印日志：页面DOM频繁刷新触发，脚本自带Set去重，极端场景仍会出现</p></li></ol><blockquote><p>Haven使用提示：笔记保存后，实际业务标题库不要写进笔记正文；新建油猴脚本时，手动粘贴真实作者与标题数组。</p></blockquote><p></p>', 'private', NULL, '油猴｜搜索查重脚本（百度+必应双版本） 用途：百度/必应搜索页本地扫描搜索结果，检测目标作者、匹配已发布标题库；控制台输出日志 + 浏览器桌面通知。 运行环境：Tampermonkey油猴， 全部逻辑浏览器本地执行，不上传任何数据 。 脱敏调整： TARGET_AUTHOR 、 PUBLISHED_TITLES 仅保留示例占位，业务实际数据不在笔记内硬编码，使用时自行填入。 能力总览 文本归一化 ：剔除全部标点，只保留中文、英文、数字，转小写做匹配 两套命中规则 标题匹配：页面标题归一化后包含库内标题片段则命中 作者匹配：搜索结果来源作者等于配置目标作者则命中 去重机制 ：Set集合，同一标题只打印一次日志、只触发一次通知 防抖扫描 ：DOM变动、滚动事件防抖，避免高频重复执行 通知提醒 ：命中触发浏览器系统通知；通知被禁用时仅保留控制台日志 百度版：适配PC新旧卡片、移动端，无自动滚动 必应版：PC+移动端，自动逐屏下滑停顿人工复核，遍历完毕回滚页面顶部 脚本1：百度搜索查重 baidu‑check.user.js // ==UserScript== // @name 内容查重（百度PC+移动端兼容｜浏览器本地通知） // @namespace [http://tampermonkey.net/](http://tampermonkey.net/) // @version 2.14 // @description 适配百度新旧搜索卡片、移动端搜索；忽略标点，仅比对中英文字数字；控制台日志输出，浏览器系统通知提醒，全部本地运算不上传数据 // @author You // @match *://www.baidu.com/* // @match *://m.baidu.com/* // @grant none // ==/UserScript== (function() { ''use strict''; console.log("=====内容查重脚本【百度】启动====="); const CONFIG = { // 使用时替换为实际目标作者名称 TARGET_AUTHOR: "示例作者名称" }; // 使用时替换为真实已发布标题列表 const PUBLISHED_TITLES = [ "示例标题一", "示例标题二", "示例标题三" ]; /** * 文本归一化：清除全部标点符号，仅保留中文/英文/数字，转小写 * @param {string} str * @returns {string} */ function normalize(str){ return str.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '''') .trim() .toLowerCase(); } const libNormalized = PUBLISHED_TITLES.map(t=&gt;normalize(t)); // 获取搜索词 function getSearchWord() { const urlParams = new URLSearchParams(location.search); return urlParams.get(''word'') || urlParams.get(''wd'') || ''''; } let isRunning = false; let debounceTimer = null; const notifiedSet = new Set(); const printedSet = new Set(); /** * 触发浏览器桌面通知 * @param {string} titleText 命中标题 * @param {string} matchText 命中原因 */ function sendNotify(titleText, matchText){ const msg = `标题：${titleText}\n${matchText}`; if("Notification" in window &amp;&amp; Notification.permission === "granted"){ new Notification(''查重命中【百度】'', { body: msg }); } } /** * 扫描页面搜索结果卡片 */ function scan(){ if(isRunning) return; isRunning = true; try{ const keyword = getSearchWord(); // 百度三类结果卡片选择器 const pcOldCards = document.querySelectorAll(''a.normal-sub_11u5j''); const pcNewCards = document.querySelectorAll(''div.cosc-card''); const mobileCards = document.querySelectorAll(''section.cosc-card-content''); const allCards = [...pcOldCards, ...pcNewCards, ...mobileCards]; console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`); allCards.forEach(card=&gt;{ let rawTitle = ""; let linkUrl = ""; let hitReason = null; // 旧版卡片 a.normal‑sub_11u5j if (card.tagName === "A") { const titleEl = card.querySelector(''h3[data-module="top_title"]''); if(!titleEl) return; rawTitle = titleEl.innerText.trim(); linkUrl = card.href; const titleNorm = normalize(rawTitle); for(const s of libNormalized){ if(titleNorm.includes(s)){ hitReason = `标题库匹配：${s}`; break; } } // 匹配作者来源 if(!hitReason){ const sourceWrap = card.querySelector(''div[data-module="source"]''); if(sourceWrap){ const authorDiv = sourceWrap.querySelector(''div.source-left_J1XTH div''); if(authorDiv &amp;&amp; authorDiv.innerText.trim() === CONFIG.TARGET_AUTHOR){ hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`; } } } } // PC新版 cosc‑card else if (card.classList.contains(''cosc-card'')) { const titleEl = card.querySelector(''h3[data-module="title"]''); if(!titleEl) return; rawTitle = titleEl.innerText.trim(); const aTag = titleEl.querySelector(''a''); linkUrl = aTag?.href || ""; const titleNorm = normalize(rawTitle); for(const s of libNormalized){ if(titleNorm.includes(s)){ hitReason = `标题库匹配：${s}`; break; } } if(!hitReason){ const sourceWrap = card.querySelector(''div[data-module="source"]''); if(sourceWrap){ const authorSpan = sourceWrap.querySelector(''span.cosc-source-text''); if(authorSpan &amp;&amp; authorSpan.innerText.trim() === CONFIG.TARGET_AUTHOR){ hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`; } } } } // 移动端 section.cosc‑card‑content else { const titleEl = card.querySelector(''div[data-module="title"] h3''); if(!titleEl) return; rawTitle = titleEl.innerText.trim(); const aTag = card.querySelector("a"); linkUrl = aTag?.href || ""; const titleNorm = normalize(rawTitle); for(const s of libNormalized){ if(titleNorm.includes(s)){ hitReason = `标题库匹配：${s}`; break; } } if(!hitReason){ const sourceWrap = card.querySelector(''div[data-module="source"]''); if(sourceWrap){ const authorSpan = sourceWrap.querySelector(''span.cosc-source-text''); if(authorSpan &amp;&amp; authorSpan.innerText.trim() === CONFIG.TARGET_AUTHOR){ hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`; } } } } const titleKey = rawTitle; if(printedSet.has(titleKey)) return; printedSet.add(titleKey); if(hitReason){ notifiedSet.add(titleKey); console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl} | 原因：${hitReason}`); sendNotify(rawTitle, hitReason); }else{ console.log(`- 普通 | 标题：${rawTitle} | 链接：${linkUrl}`); } }) }finally{ isRunning = false; } } // 防抖调度 function debounceScan(){ clearTimeout(debounceTimer); debounceTimer = setTimeout(scan, 400); } function start(){ // 请求通知权限 if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){ Notification.requestPermission(); } // 监听DOM变化 const observer = new MutationObserver(()=&gt; debounceScan()); observer.observe(document.body, {childList:true, subtree:true}); window.addEventListener(''scroll'', debounceScan, {passive:true}); scan(); setTimeout(scan, 1200); } if(document.body) start(); else document.addEventListener(''DOMContentLoaded'', start); })(); 脚本2：必应搜索查重 bing‑check.user.js // ==UserScript== // @name 内容查重（必应Bing版｜PC移动端｜自动逐屏复核） // @namespace [http://tampermonkey.net/](http://tampermonkey.net/) // @version 1.8 // @description 必应搜索查重；搜索结果自动分段缓慢下滑，每屏停顿人工复核，扫描完成回顶部；控制台输出标题与链接，浏览器本地通知提醒，全部本地运算不上传 // @author You // @match *://cn.bing.com/search* // @match *://www.bing.com/search* // @grant none // ==/UserScript== (function() { ''use strict''; console.log("=====内容查重脚本【必应】启动====="); const CONFIG = { // 使用时替换实际目标作者 TARGET_AUTHOR: "示例作者名称", scrollSegmentTime: 800, // 单段滑动动画毫秒 pausePerScreen: 1600, // 每屏停留复核时间毫秒（主要调参） scrollUpTime: 1200 // 全部扫描完回顶部滚动时长 }; // 使用时替换为真实已发布标题列表 const PUBLISHED_TITLES = [ "示例标题一", "示例标题二", "示例标题三" ]; /** * 文本归一化：清除全部标点符号，仅保留中文/英文/数字，转小写 * @param {string} str * @returns {string} */ function normalize(str){ return str.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '''') .trim() .toLowerCase(); } const libNormalized = PUBLISHED_TITLES.map(t=&gt;normalize(t)); function getSearchWord() { const urlParams = new URLSearchParams(location.search); return urlParams.get(''q'') || ''''; } let isRunning = false; let debounceTimer = null; const notifiedSet = new Set(); const printedSet = new Set(); let lastQuery = ""; function sendNotify(titleText, matchText){ const msg = `标题：${titleText}\n${matchText}`; if("Notification" in window &amp;&amp; Notification.permission === "granted"){ new Notification(''查重命中【必应】'', { body: msg }); } } /** * 平滑滚动Promise封装，自定义缓动 * @param {number} targetTop * @param {number} duration * @returns {Promise&lt;void&gt;} */ function smoothScrollTo(targetTop, duration) { return new Promise(resolve =&gt; { const startTop = window.scrollY; const distance = targetTop - startTop; const startTime = performance.now(); function step(now) { const elapsed = now - startTime; const progress = Math.min(elapsed / duration, 1); const ease = 1 - Math.pow(1 - progress, 2); window.scrollTo(0, startTop + distance * ease); if (progress &lt; 1) { requestAnimationFrame(step); } else { resolve(); } } requestAnimationFrame(step); }); } /** * 自动逐屏下滑复核，到底返回顶部 */ async function runScrollCycle() { const viewH = window.innerHeight; let currentY = window.scrollY; const maxY = document.documentElement.scrollHeight - viewH; while(currentY &lt; maxY - 50){ currentY = currentY + viewH * 0.85; // 屏幕重叠系数，避免漏看 if(currentY &gt; maxY) currentY = maxY; await smoothScrollTo(currentY, CONFIG.scrollSegmentTime); await new Promise(r =&gt; setTimeout(r, CONFIG.pausePerScreen)); } await smoothScrollTo(0, CONFIG.scrollUpTime); } function scan(){ if(isRunning) return; isRunning = true; try{ const keyword = getSearchWord(); // 必应多类型卡片选择器 const pcCards = document.querySelectorAll(''li.b_algo''); const mobileCards = document.querySelectorAll(''div.algocore, div.b_mcard, div.b_richcard''); const pcNewsCards = document.querySelectorAll(''.na_card_wrp''); const mobileNewsCards = document.querySelectorAll(''.nnews_card, .b_news_card''); const allCards = [...pcCards, ...mobileCards, ...pcNewsCards, ...mobileNewsCards]; // 搜索词变化时重置状态并启动自动滚动 if (keyword !== lastQuery) { console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`); lastQuery = keyword; printedSet.clear(); runScrollCycle(); } allCards.forEach(card=&gt;{ let rawTitle = ""; let linkUrl = ""; let hitReason = null; let sourceText = ""; const titleLink = card.querySelector(''a[href] h2 a, h2 &gt; a, a.title, a[href]:has(h2)''); if(titleLink){ rawTitle = titleLink.innerText.trim(); linkUrl = titleLink.href; }else{ const directA = card.querySelector(''a[href]''); if(directA){ rawTitle = directA.innerText.trim(); linkUrl = directA.href; } } const sourceEl = card.querySelector(''.b_attribution, .source, .na_footer_name, .cap_txt, .b_caption''); sourceText = sourceEl?.innerText.trim() || ''''; if (!rawTitle || !linkUrl) return; const titleNorm = normalize(rawTitle); for(const s of libNormalized){ if(titleNorm.includes(s)){ hitReason = `标题库匹配：${s}`; break; } } if(!hitReason &amp;&amp; sourceText === CONFIG.TARGET_AUTHOR){ hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`; } const titleKey = rawTitle; if(printedSet.has(titleKey)) return; printedSet.add(titleKey); if(hitReason){ notifiedSet.add(titleKey); console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl} | 原因：${hitReason}`); sendNotify(rawTitle, hitReason); }else{ console.log(`- 普通 | 标题：${rawTitle} | 链接：${linkUrl}`); } }) }finally{ isRunning = false; } } function debounceScan(){ clearTimeout(debounceTimer); debounceTimer = setTimeout(scan, 400); } function start(){ if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){ Notification.requestPermission(); } const observer = new MutationObserver(()=&gt; debounceScan()); observer.observe(document.body, {childList:true, subtree:true}); window.addEventListener(''scroll'', debounceScan, {passive:true}); scan(); setTimeout(scan, 1200); } if(document.body) start(); else document.addEventListener(''DOMContentLoaded'', start); })(); 使用说明 安装步骤 浏览器安装 Tampermonkey（油猴）扩展 新建脚本，复制对应版本全部代码保存 打开百度/必应搜索页自动加载；首次运行允许 浏览器通知权限 ，否则无弹窗提醒 配置替换（每次新建脚本必须改） CONFIG.TARGET_AUTHOR ：替换为实际要监控的作者名字 PUBLISHED_TITLES 数组：填入真实业务标题字符串 新增/删减文章，直接修改此数组，保存脚本即生效 必应版可调参数（CONFIG对象） 参数 含义 pausePerScreen 每屏停留时间ms，越大人工复核越从容，推荐1200‑2000 scrollSegmentTime 单段滑动动画耗时 scrollUpTime 全部遍历完成回顶部动画时长 查看输出结果 F12 → Console控制台查看完整日志； ✅ 代表命中条目 命中会弹出浏览器桌面通知，显示标题与命中原因；通知被屏蔽仅保留控制台输出 限制与风险 纯前端本地运行，不上传任何数据 搜索引擎前端改版会导致DOM选择器失效，需要更新卡片querySelector 浏览器全局/站点通知权限关闭，则只有控制台日志 必应切换搜索关键词会重新执行完整自动滚动复核 故障排查 没有通知：检查网站通知权限是否允许 扫描不到结果：Console确认脚本已启动；判断是否搜索引擎DOM改版，选择器失效 重复打印日志：页面DOM频繁刷新触发，脚本自带Set去重，极端场景仍会出现 Haven使用提示：笔记保存后，实际业务标题库不要写进笔记正文；新建油猴脚本时，手动粘贴真实作者与标题数组。', '2026-11-05 13:04:58.715687+08'::timestamptz, '2026-11-05 13:07:10.170332+08'::timestamptz, '19a87a99-6972-4f5d-9a6e-6797fa054ae8'::uuid, 0, NULL),
  ('2a0e9fc4-421d-4e43-8362-0556bc4b1e56'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '功能', '<ul><li><p>新的页面，复制展示保存的网页。</p></li></ul><p></p>', 'private', NULL, '功能 新的页面，复制展示保存的网页。', '2026-11-02 17:50:29.196149+08'::timestamptz, '2026-11-04 14:10:02.263459+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-04 17:52:01.861815+08'::timestamptz),
  ('5c4272b6-bb10-40ab-a07c-e3cf267721c4'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '官网检索器 · 部署与运行', '<h2>环境要求</h2>
<table>
<thead>
<tr>
<th>软件</th>
<th>版本</th>
<th>说明</th>
</tr>
</thead>
<tbody>
<tr>
<td>Python</td>
<td>&gt;= 3.10</td>
<td>后端</td>
</tr>
<tr>
<td>Node.js</td>
<td>&gt;= 18</td>
<td>仅前端构建需要</td>
</tr>
<tr>
<td>Chromium</td>
<td>由 Playwright 安装</td>
<td>浏览器自动化</td>
</tr>
</tbody>
</table>
<h2>安装</h2>
<pre><code class="language-bash"># 1) 后端
python -m venv .venv
.venv\Scripts\activate            # Windows；Linux/mac 用 source .venv/bin/activate
pip install -r requirements.txt
.venv\Scripts\playwright install chromium

# 2) 前端
cd web
npm install
npm run build
cd ..
</code></pre>
<h2>配置目标品牌（关键）</h2>
<p><strong>仓库里的</strong> ​<strong>​<code>core/config.py</code>​</strong>​ <strong>只放占位值</strong>（​<code>example.com</code> / 示例标识），真实品牌写在本机文件：</p>
<ol>
<li>复制样例：​<code>copy core\config_local.example.py core\config_local.py</code>​（Linux: ​<code>cp ...</code>）</li>
<li>编辑 ​<code>core/config_local.py</code>，填入真实目标：</li>
</ol>
<pre><code class="language-python">TARGET_DOMAIN = &#34;yourbrand.com&#34;
BAIDU_OFFICIAL_MARKS = [&#34;你的官网标识&#34;, &#34;yourbrand.com&#34;]
</code></pre>
<ul>
<li><code>config_local.py</code>​ 被 ​<code>.gitignore</code>​ 忽略，<strong>不会误提交</strong>。</li>
<li><strong>启动自检</strong>：服务启动时检测配置是否仍是占位值，若是会打印醒目警告——防止&#34;配置没生效 → 全部静默判未命中&#34;。</li>
</ul>
<blockquote>
<p>适配其他品牌（fork）：只改 ​<code>config_local.py</code>​ 的 ​<code>TARGET_DOMAIN</code>​ 和 ​<code>BAIDU_OFFICIAL_MARKS</code>，采集代码零改动。</p>
</blockquote>
<h2>一键启动（Windows）</h2>
<p>双击 ​<code>scripts/start_panel.bat</code>：</p>
<pre><code class="language-bat">cd /d &#34;%~dp0..&#34;
set VENV=%~dp0..\.venv
... (后台拉起服务 + 自动打开浏览器)
</code></pre>
<p>脚本用相对路径定位项目根与 ​<code>.venv</code>，可在任意位置双击运行。</p>
<p>或命令行：</p>
<pre><code class="language-bash">.venv\Scripts\pythonw.exe server.py --no-browser
</code></pre>
<p>打开 <strong>http://127.0.0.1:27532/</strong> （默认端口 27532）。</p>
<h2>常用命令</h2>
<table>
<thead>
<tr>
<th>命令</th>
<th>作用</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>scripts/start_panel.bat</code></td>
<td>一键启动（后台 + 开浏览器）</td>
</tr>
<tr>
<td><code>python server.py --no-browser</code></td>
<td>后台启动不自动开浏览器</td>
</tr>
<tr>
<td><code>npm run build</code>（web/ 下）</td>
<td>构建前端到 ​<code>dist/</code></td>
</tr>
<tr>
<td><code>python -m pytest tests/test_v2_smoke.py -v</code></td>
<td>跑冒烟测试</td>
</tr>
<tr>
<td><code>ruff check .</code></td>
<td>lint</td>
</tr>
</tbody>
</table>
<h2>使用流程</h2>
<ol>
<li><strong>创建任务</strong>：命名 + 勾选平台（默认全不勾选）→ 创建成功自动关闭弹窗并跳转任务页。</li>
<li><strong>导入关键词</strong>：粘贴/导入关键词列表。</li>
<li><strong>开始</strong>：任务并行跑批，逐关键词在所选平台前 10 页检索。</li>
<li><strong>查看结果</strong>：状态 = 命中（含排名/页码/证据/截图）/ 未命中 / 受限 / 解析异常 / 错误。</li>
<li><strong>重试失败项</strong>：​<code>错误/受限/解析异常</code> 可一键重跑；未命中不重试。</li>
<li><strong>导出</strong>：下载中心——单任务 Excel、截图 zip、汇总 Excel、或按日期打包（截图 + 汇总表格）。</li>
</ol>
<h2>数据位置（运行时）</h2>
<table>
<thead>
<tr>
<th>目录</th>
<th>内容</th>
<th>是否入库</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>data/tasks.json</code></td>
<td>任务注册表</td>
<td>否</td>
</tr>
<tr>
<td><code>data/t&lt;id&gt;.db</code></td>
<td>每任务 SQLite</td>
<td>否</td>
</tr>
<tr>
<td><code>shots/</code></td>
<td>截图</td>
<td>否</td>
</tr>
<tr>
<td><code>profile_sessions/</code></td>
<td>浏览器 profile</td>
<td>否</td>
</tr>
<tr>
<td><code>logs/</code></td>
<td>日志</td>
<td>否</td>
</tr>
</tbody>
</table>
<blockquote>
<p>这些是真实运行数据，备份/迁移任务时整体拷贝即可，不要提交到 git。</p>
</blockquote>
<h2>常见问题</h2>
<p><strong>Q：所有关键词都判「未命中」？</strong><br/>
→ 看启动时有没有&#34;占位值警告&#34;。若 ​<code>config_local.py</code>​ 未生效，程序在匹配 ​<code>example.com</code>，必然全未命中。确认文件存在且字段正确。</p>
<p><strong>Q：任务点「开始」没反应？</strong><br/>
→ 该任务可能已在运行（​<code>running</code>​）；或没有 pending 的词（全跑完了，​<code>finished</code>）。</p>
<p><strong>Q：某平台一直</strong> ​<strong>​<code>error</code>​</strong>​ <strong>？</strong><br/>
→ 多为翻页卡住/被风控。用「重试失败项」重跑；仍失败可人工打开确认是否验证码/页面改版。</p>
<p><strong>Q：想在别的机器跑？</strong><br/>
→ clone 后按「安装 + 配置品牌」执行；​<code>data/</code>​、​<code>shots/</code> 等需迁移可整体拷贝。</p>
', 'private', NULL, '官网检索器 · 部署与运行 环境要求 软件 版本 说明 Python &gt;= 3.10 后端 Node.js &gt;= 18 仅前端构建需要 Chromium 由 Playwright 安装 浏览器自动化 安装 # 1) 后端 python -m venv .venv .venv\Scripts\activate # Windows；Linux/mac 用 source .venv/bin/activate pip install -r requirements.txt .venv\Scripts\playwright install chromium # 2) 前端 cd web npm install npm run build cd .. 配置目标品牌（关键） 仓库里的 ​ ​ core/config.py ​ ​ 只放占位值 （​ example.com / 示例标识），真实品牌写在本机文件： 复制样例：​ copy core\config_local.example.py core\config_local.py ​（Linux: ​ cp ... ） 编辑 ​ core/config_local.py ，填入真实目标： TARGET_DOMAIN = &#34;yourbrand.com&#34; BAIDU_OFFICIAL_MARKS = [&#34;你的官网标识&#34;, &#34;yourbrand.com&#34;] config_local.py ​ 被 ​ .gitignore ​ 忽略， 不会误提交 。 启动自检 ：服务启动时检测配置是否仍是占位值，若是会打印醒目警告——防止&#34;配置没生效 → 全部静默判未命中&#34;。 适配其他品牌（fork）：只改 ​ config_local.py ​ 的 ​ TARGET_DOMAIN ​ 和 ​ BAIDU_OFFICIAL_MARKS ，采集代码零改动。 一键启动（Windows） 双击 ​ scripts/start_panel.bat ： cd /d &#34;%~dp0..&#34; set VENV=%~dp0..\.venv ... (后台拉起服务 + 自动打开浏览器) 脚本用相对路径定位项目根与 ​ .venv ，可在任意位置双击运行。 或命令行： .venv\Scripts\pythonw.exe server.py --no-browser 打开 http://127.0.0.1:27532/ （默认端口 27532）。 常用命令 命令 作用 scripts/start_panel.bat 一键启动（后台 + 开浏览器） python server.py --no-browser 后台启动不自动开浏览器 npm run build （web/ 下） 构建前端到 ​ dist/ python -m pytest tests/test_v2_smoke.py -v 跑冒烟测试 ruff check . lint 使用流程 创建任务 ：命名 + 勾选平台（默认全不勾选）→ 创建成功自动关闭弹窗并跳转任务页。 导入关键词 ：粘贴/导入关键词列表。 开始 ：任务并行跑批，逐关键词在所选平台前 10 页检索。 查看结果 ：状态 = 命中（含排名/页码/证据/截图）/ 未命中 / 受限 / 解析异常 / 错误。 重试失败项 ：​ 错误/受限/解析异常 可一键重跑；未命中不重试。 导出 ：下载中心——单任务 Excel、截图 zip、汇总 Excel、或按日期打包（截图 + 汇总表格）。 数据位置（运行时） 目录 内容 是否入库 data/tasks.json 任务注册表 否 data/t&lt;id&gt;.db 每任务 SQLite 否 shots/ 截图 否 profile_sessions/ 浏览器 profile 否 logs/ 日志 否 这些是真实运行数据，备份/迁移任务时整体拷贝即可，不要提交到 git。 常见问题 Q：所有关键词都判「未命中」？ → 看启动时有没有&#34;占位值警告&#34;。若 ​ config_local.py ​ 未生效，程序在匹配 ​ example.com ，必然全未命中。确认文件存在且字段正确。 Q：任务点「开始」没反应？ → 该任务可能已在运行（​ running ​）；或没有 pending 的词（全跑完了，​ finished ）。 Q：某平台一直 ​ ​ error ​ ​ ？ → 多为翻页卡住/被风控。用「重试失败项」重跑；仍失败可人工打开确认是否验证码/页面改版。 Q：想在别的机器跑？ → clone 后按「安装 + 配置品牌」执行；​ data/ ​、​ shots/ 等需迁移可整体拷贝。', '2026-10-31 17:43:12.094321+08'::timestamptz, '2026-10-31 17:43:12.094321+08'::timestamptz, '57475bc4-ef3c-4e7e-a8b7-17b5526dc5a2'::uuid, 0, NULL),
  ('658d28be-4798-49af-83a7-50b99d145613'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '官网检索器 · 开发记录', '<h2>Git 提交历史</h2>
<pre><code class="language-git">8969f6b  chore: enable ruff lint in CI, add SECURITY/CONTRIBUTING and CI badge
c53e293  fix: tolerate missing web/dist in smoke test so backend CI job passes
43f3280  ci: add GitHub Actions workflow, config_local example and .editorconfig
48a232d  chore: add .gitattributes for line-ending normalization
c727de5  docs: add English README and Chinese README-zh
f5df183  官网检索器：初始干净提交（脱敏 + smoke 修复）
</code></pre>
<h2>阶段一：V1 → V2 前端与功能重构</h2>
<h3>背景</h3>
<p>V1 存在多个使用痛点，全部在 V2 解决。</p>
<h3>当时解决的问题</h3>
<table>
<thead>
<tr>
<th>痛点</th>
<th>V2 方案</th>
</tr>
</thead>
<tbody>
<tr>
<td>任务不能重跑</td>
<td>失败词/引擎可单独重跑 + 「重试失败项」</td>
</tr>
<tr>
<td>有「本轮上限」</td>
<td>移除，开始即跑全部待处理关键词</td>
</tr>
<tr>
<td>创建任务不关弹窗不跳转</td>
<td>创建成功自动关闭并跳转任务页</td>
</tr>
<tr>
<td>创建任务平台默认全选</td>
<td>改为<strong>默认全不勾选</strong>，用户手动选</td>
</tr>
<tr>
<td>完成态显示 0/0</td>
<td><code>finished</code>​ 优先 → 进度条 100%、文本 ​<code>total/total</code></td>
</tr>
</tbody>
</table>
<h3>前端交互沉淀</h3>
<ul>
<li>总览页 <strong>2×2 坐标系</strong>：左上 百度PC / 右上 必应PC / 左下 百度移动 / 右下 必应移动；未完成直接展示、已完成折叠（折叠按钮在块标题栏右侧）、顶部日期筛选。</li>
<li>所有任务页：浏览器式 <strong>4 个标签</strong> + <strong>按日期分组</strong>（date-h 标题）。</li>
<li>下载中心：<strong>按日期筛选</strong> + 「打包所选日期（截图 + 表格，sheet 分任务）」。</li>
<li>截图归档：不按任务名分文件夹，直接 ​<code>平台/PC|MOB</code>；打包时截图按「第一页 / 其他页」× 平台分层。</li>
</ul>
<h2>阶段二：后端架构（并行 / 断点续跑 / 判定三态）</h2>
<ul>
<li>每任务独立 profile / SQLite / 截图目录，​<code>Worker</code> 线程并行。</li>
<li>pending 驱动断点续跑 + 导入 upsert 不重置已跑结果。</li>
<li><code>conclusion()</code>​ 聚合：只要存在 ​<code>error/restricted/malfunction</code> 就不下「未命中」结论。</li>
<li>百度 ​<code>_next_page</code>​ <strong>三态化</strong>：​<code>False</code>​（真到底→none）/ ​<code>&#34;stuck&#34;</code>（翻页失效→error）。</li>
<li>熔断：连续 3 页 0 条 → ​<code>malfunction</code>，防空结果误判未命中。</li>
</ul>
<h2>阶段三：发布前清理、脱敏与公开</h2>
<ul>
<li>建干净副本发布（排除 ​<code>.git/.venv/node_modules/dist/__pycache__/data/shots/profile_sessions/logs/*.db</code>），原运行目录不再改动。</li>
<li>脱敏：​<code>config.py</code>​ 占位化、​<code>_is_official</code>​ 去品牌前缀、新建 ​<code>config_local.py</code>（gitignore）+ 启动自检。</li>
<li>并发修复 A1/A2/A3；删 ​<code>skip</code>​ 全链路；删 ​<code>/api/shutdown</code>。</li>
<li>双远程发布（gitee + GitHub，​<code>git push</code> 双推）、补 README 双语文档 / LICENSE / .gitattributes / .editorconfig / SECURITY / CONTRIBUTING / CI。</li>
</ul>
<h2>踩坑记录</h2>
<h3>坑 1：CI 冒烟测试 500（缺 web/dist）</h3>
<p>GitHub Actions backend job 是全新 clone，无 ​<code>web/dist</code>​（gitignore 且 backend job 不构建前端），根路由 ​<code>/</code> 读不到 index.html → 500。</p>
<p>修复：smoke test 根页面断言在 <strong>dist 缺失时容错跳过</strong>——前端正确性由 frontend job 的 ​<code>npm build</code> 单独保证，后端 job 专注测 API。</p>
<h3>坑 2：ruff 一次报 78 错</h3>
<p><code>pyproject</code>​ 规则集很严格（select 含 ​<code>UP/S/SIM/C4</code>​），初始 ​<code>ruff check</code>​ 报 78 错，其中 59 处 ​<code>UP031</code>（% 格式化）。</p>
<p>处理：</p>
<ul>
<li><strong>规则调优</strong>：​<code>UP031</code>​（% 是项目既有风格）、​<code>E501</code>​、​<code>S310</code>​（urlopen 爬虫）、​<code>S608</code>（SQL 硬编码）加入 ignore；</li>
<li><strong>修真问题</strong>：未用变量/import、import 排序、无用 if-else、冗余 noqa。</li>
</ul>
<h3>坑 3：SSH 首次连接 Host key verification failed</h3>
<p>push 到 gitee/GitHub 首次连接报 ​<code>Host key verification failed</code>​。解决：​<code>ssh-keyscan gitee.com/github.com &gt;&gt; ~/.ssh/known_hosts</code>，认证通过后正常推送。</p>
<h3>坑 4：smoke 断言与懒创建实现冲突</h3>
<p>发布副本冒烟测试第一次失败：断言「建任务即复制 profile」与 ​<code>profile_helper</code>​ 的<strong>懒创建</strong>实现冲突——语法检查发现不了的逻辑 bug。删除该过时断言，重跑通过。</p>
<h3>坑 5：PowerShell heredoc 内嵌 python 失败</h3>
<p>用 PowerShell heredoc + ​<code>python -c</code>​ + ​<code>&#34;&#34;&#34;</code>​ docstring 批量补丁 → SyntaxError、零修改。改用临时 ​<code>.py</code> 脚本文件成功（后已删）。</p>
<h2>待办 / 未来改进</h2>
<ul data-type="taskList">
<li data-type="taskItem" data-checked="false">浏览器层未在 CI 真跑（冒烟测试不起 Chromium，只测 HTTP 服务层），可补 Playwright 端到端</li>
<li data-type="taskItem" data-checked="false">并发修复 A1/A2/A3 无专门并发测试，靠代码评审保证</li>
<li data-type="taskItem" data-checked="false"><code>cookie_tools.py</code> 为低价值防御代码，可评估删除</li>
<li data-type="taskItem" data-checked="false"><code>web/dist</code>​ 本地需 ​<code>npm run build</code> 才有（gitignore），clone 后要自行构建</li>
<li data-type="taskItem" data-checked="false">可考虑 ruff 更细粒度规则（当前已豁免较多风格规则）</li>
</ul>
', 'private', NULL, '官网检索器 · 开发记录 Git 提交历史 8969f6b chore: enable ruff lint in CI, add SECURITY/CONTRIBUTING and CI badge c53e293 fix: tolerate missing web/dist in smoke test so backend CI job passes 43f3280 ci: add GitHub Actions workflow, config_local example and .editorconfig 48a232d chore: add .gitattributes for line-ending normalization c727de5 docs: add English README and Chinese README-zh f5df183 官网检索器：初始干净提交（脱敏 + smoke 修复） 阶段一：V1 → V2 前端与功能重构 背景 V1 存在多个使用痛点，全部在 V2 解决。 当时解决的问题 痛点 V2 方案 任务不能重跑 失败词/引擎可单独重跑 + 「重试失败项」 有「本轮上限」 移除，开始即跑全部待处理关键词 创建任务不关弹窗不跳转 创建成功自动关闭并跳转任务页 创建任务平台默认全选 改为 默认全不勾选 ，用户手动选 完成态显示 0/0 finished ​ 优先 → 进度条 100%、文本 ​ total/total 前端交互沉淀 总览页 2×2 坐标系 ：左上 百度PC / 右上 必应PC / 左下 百度移动 / 右下 必应移动；未完成直接展示、已完成折叠（折叠按钮在块标题栏右侧）、顶部日期筛选。 所有任务页：浏览器式 4 个标签 + 按日期分组 （date-h 标题）。 下载中心： 按日期筛选 + 「打包所选日期（截图 + 表格，sheet 分任务）」。 截图归档：不按任务名分文件夹，直接 ​ 平台/PC|MOB ；打包时截图按「第一页 / 其他页」× 平台分层。 阶段二：后端架构（并行 / 断点续跑 / 判定三态） 每任务独立 profile / SQLite / 截图目录，​ Worker 线程并行。 pending 驱动断点续跑 + 导入 upsert 不重置已跑结果。 conclusion() ​ 聚合：只要存在 ​ error/restricted/malfunction 就不下「未命中」结论。 百度 ​ _next_page ​ 三态化 ：​ False ​（真到底→none）/ ​ &#34;stuck&#34; （翻页失效→error）。 熔断：连续 3 页 0 条 → ​ malfunction ，防空结果误判未命中。 阶段三：发布前清理、脱敏与公开 建干净副本发布（排除 ​ .git/.venv/node_modules/dist/__pycache__/data/shots/profile_sessions/logs/*.db ），原运行目录不再改动。 脱敏：​ config.py ​ 占位化、​ _is_official ​ 去品牌前缀、新建 ​ config_local.py （gitignore）+ 启动自检。 并发修复 A1/A2/A3；删 ​ skip ​ 全链路；删 ​ /api/shutdown 。 双远程发布（gitee + GitHub，​ git push 双推）、补 README 双语文档 / LICENSE / .gitattributes / .editorconfig / SECURITY / CONTRIBUTING / CI。 踩坑记录 坑 1：CI 冒烟测试 500（缺 web/dist） GitHub Actions backend job 是全新 clone，无 ​ web/dist ​（gitignore 且 backend job 不构建前端），根路由 ​ / 读不到 index.html → 500。 修复：smoke test 根页面断言在 dist 缺失时容错跳过 ——前端正确性由 frontend job 的 ​ npm build 单独保证，后端 job 专注测 API。 坑 2：ruff 一次报 78 错 pyproject ​ 规则集很严格（select 含 ​ UP/S/SIM/C4 ​），初始 ​ ruff check ​ 报 78 错，其中 59 处 ​ UP031 （% 格式化）。 处理： 规则调优 ：​ UP031 ​（% 是项目既有风格）、​ E501 ​、​ S310 ​（urlopen 爬虫）、​ S608 （SQL 硬编码）加入 ignore； 修真问题 ：未用变量/import、import 排序、无用 if-else、冗余 noqa。 坑 3：SSH 首次连接 Host key verification failed push 到 gitee/GitHub 首次连接报 ​ Host key verification failed ​。解决：​ ssh-keyscan gitee.com/github.com &gt;&gt; ~/.ssh/known_hosts ，认证通过后正常推送。 坑 4：smoke 断言与懒创建实现冲突 发布副本冒烟测试第一次失败：断言「建任务即复制 profile」与 ​ profile_helper ​ 的 懒创建 实现冲突——语法检查发现不了的逻辑 bug。删除该过时断言，重跑通过。 坑 5：PowerShell heredoc 内嵌 python 失败 用 PowerShell heredoc + ​ python -c ​ + ​ &#34;&#34;&#34; ​ docstring 批量补丁 → SyntaxError、零修改。改用临时 ​ .py 脚本文件成功（后已删）。 待办 / 未来改进 浏览器层未在 CI 真跑（冒烟测试不起 Chromium，只测 HTTP 服务层），可补 Playwright 端到端 并发修复 A1/A2/A3 无专门并发测试，靠代码评审保证 cookie_tools.py 为低价值防御代码，可评估删除 web/dist ​ 本地需 ​ npm run build 才有（gitignore），clone 后要自行构建 可考虑 ruff 更细粒度规则（当前已豁免较多风格规则）', '2026-10-31 17:43:10.626205+08'::timestamptz, '2026-10-31 17:43:10.626205+08'::timestamptz, '57475bc4-ef3c-4e7e-a8b7-17b5526dc5a2'::uuid, 0, NULL),
  ('cdada194-4a76-42dd-b258-f21040e60c5d'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '分析报告：Windows 登录微软账户时要求“上次锁屏密码”的意义与安全边界', '<h2 style="text-align: left;">一、摘要</h2><p>Windows 在登录微软账户时要求输入“上次锁屏密码”，并不是简单的重复验证，而是 <strong>本地凭据缓存</strong> 与 <strong>高风险场景降级验证</strong> 两种机制共同作用的结果。</p><p>但这一机制存在一个清晰的边界：<strong>当一个人拥有本地管理员权限并能物理接触设备时，他可以通过创建本地管理员账户、删除原微软账户的方式，改变系统需要验证的“身份主体”本身。</strong> 此时“上次密码”机制并非被攻破，而是被验证对象已经被替换。</p><p>这与 macOS 的设计形成鲜明对比：macOS 将本地 UNIX 账户与 Apple ID 分离，并在启用 FileVault 时把登录密码与数据解密密钥深度绑定。结果是：<strong>Windows 中“获得管理员权限”更接近获得设备控制权；macOS 中“重置登录密码”不等于获得原有数据的访问权。</strong></p><hr><h2>二、Windows 要求“上次锁屏密码”的核心意义</h2><h3>1. 离线可用性：本地缓存的账户凭据</h3><p>Windows 允许设备在没有网络连接时登录微软账户。为了实现这一点，系统会在上次成功登录后，将账户密码或其派生验证信息加密缓存在本地。</p><p>当设备离线、无法连接微软服务器时，系统无法实时验证微软账户，只能使用本地缓存的凭据核对用户输入。</p><p>因此，该提示的含义可以理解为：</p><blockquote><p>“当前无法连接微软服务器，只能依赖本机缓存的上次登录凭据来验证身份。”</p></blockquote><p>如果用户在另一台设备上修改了微软账户密码，而这台 Windows 设备仍处于离线状态，则可能需要输入修改前的旧密码才能通过本地验证。</p><h3>2. 高风险场景下的安全降级验证</h3><p>Windows Hello PIN 是设备绑定的本地便捷凭证，适合日常登录和锁屏解锁。但它不是完整账户密码，权限边界有限。</p><p>当系统判断当前场景属于高风险或超出 PIN 的授权范围时，会要求使用与微软账户直接绑定的账户密码重新证明身份。典型场景包括：</p><ul><li><p>多次输错密码或 PIN；</p></li><li><p>更改 PIN、重置 Windows Hello 凭据；</p></li><li><p>执行涉及账户凭据变更的敏感操作；</p></li><li><p>远程桌面、访问某些网络资源或需要完整账户授权的场景。</p></li></ul><p>因此，“上次密码”机制的本质是：<strong>在便捷性与更高等级身份验证之间进行动态权衡。</strong></p><hr><h2>三、同事操作复盘：为什么创建本地账号并删除微软账户可以绕过</h2><h3>1. 操作路径的本质</h3><p>同事的操作大致是：</p><ol><li><p>拥有本地管理员权限；</p></li><li><p>创建一个新的本地管理员账户；</p></li><li><p>使用新账户登录；</p></li><li><p>删除原来的微软账户及其关联登录凭据；</p></li><li><p>为新本地账户设置密码；</p></li><li><p>再次登录时，系统要求验证的是这个新本地账户的密码。</p></li></ol><h3>2. 被绕过的不是密码验证，而是验证对象</h3><p>关键点在于：<strong>系统后来验证的已经不再是原来的微软账户，而是新建的本地账户。</strong></p><p>原来的微软账户被删除后，针对该账户的“上次密码”验证自然失去意义。此时系统要求为新本地账户设置密码，并验证这个新密码，逻辑上是自洽的。</p><p>所以，这不是“上次密码机制失效”，而是：</p><blockquote><p><strong>拥有本地管理员权限的人，重新定义了“谁可以登录这台设备”。</strong></p></blockquote><h3>3. Windows 安全模型的固有边界</h3><p>Windows 的消费级设计优先保障账户体系的可管理性与可恢复性。本地管理员权限在软件层面接近设备配置的最终权限。</p><p>当一个人已经拥有管理员权限，并且能物理接触设备时，他可以：</p><ul><li><p>创建新的本地管理员账户；</p></li><li><p>删除原微软账户；</p></li><li><p>替换登录凭据；</p></li><li><p>重置 Windows Hello 容器；</p></li><li><p>重新配置安全规则。</p></li></ul><p>因此，针对旧账户的验证机制无法阻止这种操作，因为操作者已经越过了“正常登录验证”的边界，进入了“重新配置身份体系”的层级。</p><hr><h2>四、Windows 与 macOS 的安全哲学差异</h2><table style="min-width: 75px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th style="text-align: left;"><p>维度</p></th><th style="text-align: left;"><p>Windows</p></th><th style="text-align: left;"><p>macOS</p></th></tr><tr><td style="text-align: left;"><p>身份模型</p></td><td style="text-align: left;"><p>消费级版本强力推行微软账户作为系统登录身份</p></td><td style="text-align: left;"><p>本地 UNIX 账户与 Apple ID 分离，登录密码是本地账户密码</p></td></tr><tr><td style="text-align: left;"><p>管理员权限意义</p></td><td style="text-align: left;"><p>本地管理员权限接近设备安全配置的最终控制权</p></td><td style="text-align: left;"><p>管理员权限可重置访问权，但不自动等于解密原有数据</p></td></tr><tr><td style="text-align: left;"><p>数据加密绑定</p></td><td style="text-align: left;"><p>BitLocker 可选，需另行启用</p></td><td style="text-align: left;"><p>FileVault 与登录密码、硬件 UID、Secure Enclave 深度绑定</p></td></tr><tr><td style="text-align: left;"><p>忘记密码后的结果</p></td><td style="text-align: left;"><p>管理员可通过替换账户等方式恢复设备可用性</p></td><td style="text-align: left;"><p>可重置登录密码，但无恢复密钥时可能无法解密原有数据</p></td></tr><tr><td style="text-align: left;"><p>安全优先级</p></td><td style="text-align: left;"><p>账户可管理性、可恢复性</p></td><td style="text-align: left;"><p>静态数据机密性、防物理接触泄露</p></td></tr><tr><td style="text-align: left;"><p>核心边界</p></td><td style="text-align: left;"><p>拥有管理员权限≈获得设备控制权</p></td><td style="text-align: left;"><p>获得登录密码≠获得原有数据访问权</p></td></tr></tbody></table><hr><h2>五、macOS 为什么不同</h2><h3>1. 本地账户与 Apple ID 分离</h3><p>macOS 的登录账户本质上是本地 UNIX 账户，和 Apple ID 是两个可以独立存在的身份。删除 Apple ID 不会自动动摇本地账户的根基。</p><h3>2. FileVault 与 Secure Enclave 的密钥保护</h3><p>在 Apple Silicon 或带 T2 芯片的 Mac 上，启用 FileVault 后，解密硬盘的密钥由登录密码和硬件 UID 共同保护，密钥派生与验证在 Secure Enclave 中完成。</p><p>这意味着：</p><ul><li><p>可以重置登录密码；</p></li><li><p>但如果没有 FileVault 恢复密钥或 Apple ID 解锁能力；</p></li><li><p>可能无法解密硬盘原有数据；</p></li><li><p>登入的可能是无法访问原有数据的空壳环境。</p></li></ul><h3>3. 关键结论</h3><blockquote><p><strong>Windows：权限可以替换验证主体，管理员权限接近最终控制权。</strong><br><strong>macOS：访问权可以重置，但数据解密权不会自动随之恢复。</strong></p></blockquote><hr><h2>六、安全启示</h2><h3>对个人设备</h3><ol><li><p><strong>保护好本地管理员账户密码</strong>，不要随意让陌生人物理接触已登录设备。</p></li><li><p><strong>启用 BitLocker</strong>，降低设备被物理接触后通过 PE 等方式重置密码、访问数据的风险。</p></li><li><p>理解“登录密码”“PIN”“微软账户密码”不是同一层级凭证。</p></li><li><p>重要数据应额外备份，不能只依赖系统登录安全。</p></li></ol><h3>对公司或共享设备</h3><ol><li><p><strong>限制普通用户的本地管理员权限</strong>，从根源上阻止“创建管理员账户→删除原账户”的路径。</p></li><li><p>物理管控不可替代：软件登录验证无法完全替代对设备实体的控制。</p></li><li><p>对共享设备应使用标准用户权限、集中账户管理和磁盘加密策略。</p></li></ol><hr><h2>七、最终结论</h2><p>Windows 要求“上次锁屏密码”的意义，主要在于：</p><ol><li><p><strong>离线时使用本地缓存凭据验证身份</strong>；</p></li><li><p><strong>高风险或越权场景下要求更高等级账户密码验证</strong>。</p></li></ol><p>同事通过创建本地账号并删除微软账户来绕过锁屏密码，说明的不是该机制本身无效，而是揭示了 Windows 安全模型的边界：</p><blockquote><p><strong>当本地管理员权限与物理接触同时具备时，操作者可以替换被验证的身份主体，而不是攻破某一次密码验证。</strong></p></blockquote><p>与 macOS 相比，两者体现了不同的安全优先级：</p><ul><li><p><strong>Windows 更重视账户体系的可管理性与可恢复性；</strong></p></li><li><p><strong>macOS 更重视静态数据的机密性，将登录密码与数据解密密钥深度绑定。</strong></p></li></ul><p>因此，真正的安全启示不是依赖单一登录验证，而是：<strong>保护管理员权限、启用磁盘加密、限制共享设备权限，并做好数据备份与物理管控。</strong></p>', 'private', NULL, '分析报告：Windows 登录微软账户时要求“上次锁屏密码”的意义与安全边界 一、摘要 Windows 在登录微软账户时要求输入“上次锁屏密码”，并不是简单的重复验证，而是 本地凭据缓存 与 高风险场景降级验证 两种机制共同作用的结果。 但这一机制存在一个清晰的边界： 当一个人拥有本地管理员权限并能物理接触设备时，他可以通过创建本地管理员账户、删除原微软账户的方式，改变系统需要验证的“身份主体”本身。 此时“上次密码”机制并非被攻破，而是被验证对象已经被替换。 这与 macOS 的设计形成鲜明对比：macOS 将本地 UNIX 账户与 Apple ID 分离，并在启用 FileVault 时把登录密码与数据解密密钥深度绑定。结果是： Windows 中“获得管理员权限”更接近获得设备控制权；macOS 中“重置登录密码”不等于获得原有数据的访问权。 二、Windows 要求“上次锁屏密码”的核心意义 1. 离线可用性：本地缓存的账户凭据 Windows 允许设备在没有网络连接时登录微软账户。为了实现这一点，系统会在上次成功登录后，将账户密码或其派生验证信息加密缓存在本地。 当设备离线、无法连接微软服务器时，系统无法实时验证微软账户，只能使用本地缓存的凭据核对用户输入。 因此，该提示的含义可以理解为： “当前无法连接微软服务器，只能依赖本机缓存的上次登录凭据来验证身份。” 如果用户在另一台设备上修改了微软账户密码，而这台 Windows 设备仍处于离线状态，则可能需要输入修改前的旧密码才能通过本地验证。 2. 高风险场景下的安全降级验证 Windows Hello PIN 是设备绑定的本地便捷凭证，适合日常登录和锁屏解锁。但它不是完整账户密码，权限边界有限。 当系统判断当前场景属于高风险或超出 PIN 的授权范围时，会要求使用与微软账户直接绑定的账户密码重新证明身份。典型场景包括： 多次输错密码或 PIN； 更改 PIN、重置 Windows Hello 凭据； 执行涉及账户凭据变更的敏感操作； 远程桌面、访问某些网络资源或需要完整账户授权的场景。 因此，“上次密码”机制的本质是： 在便捷性与更高等级身份验证之间进行动态权衡。 三、同事操作复盘：为什么创建本地账号并删除微软账户可以绕过 1. 操作路径的本质 同事的操作大致是： 拥有本地管理员权限； 创建一个新的本地管理员账户； 使用新账户登录； 删除原来的微软账户及其关联登录凭据； 为新本地账户设置密码； 再次登录时，系统要求验证的是这个新本地账户的密码。 2. 被绕过的不是密码验证，而是验证对象 关键点在于： 系统后来验证的已经不再是原来的微软账户，而是新建的本地账户。 原来的微软账户被删除后，针对该账户的“上次密码”验证自然失去意义。此时系统要求为新本地账户设置密码，并验证这个新密码，逻辑上是自洽的。 所以，这不是“上次密码机制失效”，而是： 拥有本地管理员权限的人，重新定义了“谁可以登录这台设备”。 3. Windows 安全模型的固有边界 Windows 的消费级设计优先保障账户体系的可管理性与可恢复性。本地管理员权限在软件层面接近设备配置的最终权限。 当一个人已经拥有管理员权限，并且能物理接触设备时，他可以： 创建新的本地管理员账户； 删除原微软账户； 替换登录凭据； 重置 Windows Hello 容器； 重新配置安全规则。 因此，针对旧账户的验证机制无法阻止这种操作，因为操作者已经越过了“正常登录验证”的边界，进入了“重新配置身份体系”的层级。 四、Windows 与 macOS 的安全哲学差异 维度 Windows macOS 身份模型 消费级版本强力推行微软账户作为系统登录身份 本地 UNIX 账户与 Apple ID 分离，登录密码是本地账户密码 管理员权限意义 本地管理员权限接近设备安全配置的最终控制权 管理员权限可重置访问权，但不自动等于解密原有数据 数据加密绑定 BitLocker 可选，需另行启用 FileVault 与登录密码、硬件 UID、Secure Enclave 深度绑定 忘记密码后的结果 管理员可通过替换账户等方式恢复设备可用性 可重置登录密码，但无恢复密钥时可能无法解密原有数据 安全优先级 账户可管理性、可恢复性 静态数据机密性、防物理接触泄露 核心边界 拥有管理员权限≈获得设备控制权 获得登录密码≠获得原有数据访问权 五、macOS 为什么不同 1. 本地账户与 Apple ID 分离 macOS 的登录账户本质上是本地 UNIX 账户，和 Apple ID 是两个可以独立存在的身份。删除 Apple ID 不会自动动摇本地账户的根基。 2. FileVault 与 Secure Enclave 的密钥保护 在 Apple Silicon 或带 T2 芯片的 Mac 上，启用 FileVault 后，解密硬盘的密钥由登录密码和硬件 UID 共同保护，密钥派生与验证在 Secure Enclave 中完成。 这意味着： 可以重置登录密码； 但如果没有 FileVault 恢复密钥或 Apple ID 解锁能力； 可能无法解密硬盘原有数据； 登入的可能是无法访问原有数据的空壳环境。 3. 关键结论 Windows：权限可以替换验证主体，管理员权限接近最终控制权。 macOS：访问权可以重置，但数据解密权不会自动随之恢复。 六、安全启示 对个人设备 保护好本地管理员账户密码 ，不要随意让陌生人物理接触已登录设备。 启用 BitLocker ，降低设备被物理接触后通过 PE 等方式重置密码、访问数据的风险。 理解“登录密码”“PIN”“微软账户密码”不是同一层级凭证。 重要数据应额外备份，不能只依赖系统登录安全。 对公司或共享设备 限制普通用户的本地管理员权限 ，从根源上阻止“创建管理员账户→删除原账户”的路径。 物理管控不可替代：软件登录验证无法完全替代对设备实体的控制。 对共享设备应使用标准用户权限、集中账户管理和磁盘加密策略。 七、最终结论 Windows 要求“上次锁屏密码”的意义，主要在于： 离线时使用本地缓存凭据验证身份 ； 高风险或越权场景下要求更高等级账户密码验证 。 同事通过创建本地账号并删除微软账户来绕过锁屏密码，说明的不是该机制本身无效，而是揭示了 Windows 安全模型的边界： 当本地管理员权限与物理接触同时具备时，操作者可以替换被验证的身份主体，而不是攻破某一次密码验证。 与 macOS 相比，两者体现了不同的安全优先级： Windows 更重视账户体系的可管理性与可恢复性； macOS 更重视静态数据的机密性，将登录密码与数据解密密钥深度绑定。 因此，真正的安全启示不是依赖单一登录验证，而是： 保护管理员权限、启用磁盘加密、限制共享设备权限，并做好数据备份与物理管控。', '2026-11-01 14:16:42.171722+08'::timestamptz, '2026-11-05 11:24:09.773285+08'::timestamptz, '75ea30a2-6b56-499b-8a67-2bdf0a8ce5fc'::uuid, 0, NULL),
  ('7d338283-a450-4153-abcc-4690fdff38ca'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '官网检索器 · 架构设计', '<h2>1. 设计目标</h2>
<table>
<thead>
<tr>
<th>目标</th>
<th>说明</th>
</tr>
</thead>
<tbody>
<tr>
<td>本地工具</td>
<td>跑在用户自己机器上，数据不出本机，不部署公网</td>
</tr>
<tr>
<td>多任务并行</td>
<td>同时跑多个任务，互不干扰、互不污染</td>
</tr>
<tr>
<td>判定准确</td>
<td>命中/未命中/受限/解析异常/错误五态区分，不把&#34;被拦截&#34;误判成&#34;官网没收录&#34;</td>
</tr>
<tr>
<td>断点续跑</td>
<td>中断后重新开始只跑未完成的，不重跑已完成</td>
</tr>
<tr>
<td>结果留证</td>
<td>命中页截图 + 来源行证据，导出 Excel/zip 归档</td>
</tr>
</tbody>
</table>
<h2>2. 技术选型</h2>
<h3>2.1 后端：Python 标准库 ​<code>http.server</code>​ + ​<code>ThreadingHTTPServer</code></h3>
<p>选标准库而非 Web 框架的理由：</p>
<ul>
<li>零依赖、启动快，作为单人运维工具足够</li>
<li>每任务一个线程并行跑批，​<code>ThreadingHTTPServer</code> 天然支持并发请求</li>
<li>单进程多线程：既是 HTTP 服务也是任务调度器，部署极简</li>
</ul>
<h3>2.2 浏览器自动化：Playwright（Chromium ​<code>==1.62.0</code>）</h3>
<ul>
<li>跨平台、API 稳定，适合可控的爬取与截图</li>
<li>支持独立 user_data_dir（每任务独立 profile 隔离 cookie）</li>
</ul>
<h3>2.3 存储：SQLite（每任务独立 ​<code>.db</code>）+ openpyxl</h3>
<ul>
<li>每任务一个 ​<code>data/t&lt;id&gt;.db</code>，天然隔离</li>
<li><code>openpyxl</code> 生成带样式的 Excel 导出</li>
</ul>
<h3>2.4 前端：Vue 3 + Vite + vue-router（hash 模式）</h3>
<table>
<thead>
<tr>
<th>选型</th>
<th>理由</th>
</tr>
</thead>
<tbody>
<tr>
<td>Vue 3</td>
<td><code>&lt;script setup&gt;</code> 简洁，单文件组件够用</td>
</tr>
<tr>
<td>Vite</td>
<td>构建快、产物小</td>
</tr>
<tr>
<td>hash 路由</td>
<td>后端只需托管 ​<code>dist</code>，无需为深链做 history 回退</td>
</tr>
</tbody>
</table>
<h2>3. 模块划分</h2>
<pre><code>server.py (约 1300 行，唯一服务进程)
├── 常量与工具
│   ├── conclusion(*st)          # 五态聚合结论
│   ├── _open_conn / _tab_rows / _tab_summary
│   └── Excel 导出（_build_tab_workbook / _build_all_workbook / _build_date_workbook）
│
├── 任务模型与注册表
│   ├── TabState（id/name/db_path/shot_dir/platforms/pause_evt/stop_evt）
│   ├── create_tab / close_tab / delete_tab / rename_tab
│   └── _next_id（带 REG_LOCK）/ _save_registry / _load_registry
│
├── Worker(threading.Thread)     # 每任务一个并行跑批线程
│   ├── _run_one_own(kw, eng, sess, page, conn)   # 单关键词×单引擎
│   └── _pipeline_eng(eng, conn)                  # 一个引擎下逐词处理
│
├── HTTP 层
│   ├── Handler._do_GET / _do_POST               # 路由分发
│   ├── _import / _start / _retry / _export_*    # 业务动作
│   └── _serve_index / _serve_static / _serve_shot / _serve_favicon
│
└── core/ 模块（被 server 调用）
    ├── config.py / config_local.py      # 配置（占位值 + 本机覆盖）
    ├── baidu.py / bing.py / baidu_m.py / bing_m.py   # 四平台采集
    ├── engine.py                        # Playwright BrowserSession 封装
    ├── db.py                            # SQLite 读写
    ├── logger.py / cookie_tools.py
    └── profile_helper.py                # 每任务独立 profile 目录
</code></pre>
<h2>4. 请求生命周期</h2>
<h3>4.1 开始跑批（POST /api/tabs/<id>/start）</id></h3>
<pre><code>前端点开始 → _start(tab, data)
  │ 校验未在运行 → 新建 Worker
  ▼
Worker.run()
  └─ for engine in tab.platforms:
       for keyword in load_pending(conn):      # 只取仍 pending 的词×引擎
           打开搜索页(engine, keyword)
           for page in 1..MAX_PAGES(10):
               解析自然结果
               命中? → 记 hit(rank,page,evidence,shot) → break
               翻页三态: 无下一页→none; stuck→error
           # 熔断: 连续3页0条 → malfunction
           update_result(...)
</code></pre>
<h3>4.2 导出（GET /api/export_date）</h3>
<pre><code>前端选日期 → _export_date()
  └─ 筛选该日任务 → 收集截图（按 第一页|其他页 × 平台 分层）
     + _build_date_workbook（汇总工作簿，每任务一 sheet）
  → zip 打包返回
</code></pre>
<h2>5. 多任务并行与隔离设计</h2>
<ul>
<li><strong>每任务完全隔离</strong>：独立 ​<code>data/t&lt;id&gt;.db</code>、独立截图目录、独立浏览器 profile 子目录 → 并行互不污染。</li>
<li><strong>pending 驱动断点续跑</strong>：​<code>load_pending()</code> 只取「仍 pending 且该词需要跑该引擎」的组合。</li>
<li><strong>导入 upsert 不重置</strong>：​<code>ON CONFLICT(keyword) DO UPDATE SET engines=...</code>，已跑过的平台不因重新导入而重跑。</li>
<li><strong>暂停/停止</strong>：​<code>pause_evt</code>​（当前词完成后停）、​<code>stop_evt</code>。</li>
</ul>
<h2>6. 并发一致性（易踩坑，已修复）</h2>
<table>
<thead>
<tr>
<th>坑</th>
<th>修复</th>
</tr>
</thead>
<tbody>
<tr>
<td>「已在运行」检查与 worker 赋值不在同一临界区 → 双标签重复跑抢 profile</td>
<td>收敛到同一临界区</td>
</tr>
<tr>
<td><code>_next_id</code> 无锁 → 并发建任务 tid 重复覆盖数据</td>
<td>加 ​<code>REG_LOCK</code></td>
</tr>
<tr>
<td><code>load_pending</code> 连接从不 close → 泄漏 SQLite 句柄</td>
<td><code>finally: conn.close()</code></td>
</tr>
</tbody>
</table>
<h2>7. 目录结构</h2>
<pre><code>official-website-search-publish/
├─ server.py                    # 服务入口（HTTP + 并行调度 + 导出）
├─ profile_helper.py            # 每任务独立 profile 目录
├─ core/
│  ├─ config.py                 # 全局配置（占位值）
│  ├─ config_local.py           # 本机真实配置（gitignore）
│  ├─ config_local.example.py   # 样例模板
│  ├─ baidu.py / baidu_m.py / bing.py / bing_m.py
│  ├─ engine.py / db.py / logger.py / cookie_tools.py
├─ web/                         # Vue3 前端（src/views/ 四个页面）
├─ scripts/start_panel.bat      # 一键启动
├─ tests/test_v2_smoke.py       # 冒烟测试
├─ data/ · shots/ · profile_sessions/ · logs/   # 运行时（gitignore）
├─ docs/                        # 本文档目录（00-06 + 知识沉淀）
└─ .github/workflows/ci.yml     # pytest + ruff + npm build
</code></pre>
', 'private', NULL, '官网检索器 · 架构设计 1. 设计目标 目标 说明 本地工具 跑在用户自己机器上，数据不出本机，不部署公网 多任务并行 同时跑多个任务，互不干扰、互不污染 判定准确 命中/未命中/受限/解析异常/错误五态区分，不把&#34;被拦截&#34;误判成&#34;官网没收录&#34; 断点续跑 中断后重新开始只跑未完成的，不重跑已完成 结果留证 命中页截图 + 来源行证据，导出 Excel/zip 归档 2. 技术选型 2.1 后端：Python 标准库 ​ http.server ​ + ​ ThreadingHTTPServer 选标准库而非 Web 框架的理由： 零依赖、启动快，作为单人运维工具足够 每任务一个线程并行跑批，​ ThreadingHTTPServer 天然支持并发请求 单进程多线程：既是 HTTP 服务也是任务调度器，部署极简 2.2 浏览器自动化：Playwright（Chromium ​ ==1.62.0 ） 跨平台、API 稳定，适合可控的爬取与截图 支持独立 user_data_dir（每任务独立 profile 隔离 cookie） 2.3 存储：SQLite（每任务独立 ​ .db ）+ openpyxl 每任务一个 ​ data/t&lt;id&gt;.db ，天然隔离 openpyxl 生成带样式的 Excel 导出 2.4 前端：Vue 3 + Vite + vue-router（hash 模式） 选型 理由 Vue 3 &lt;script setup&gt; 简洁，单文件组件够用 Vite 构建快、产物小 hash 路由 后端只需托管 ​ dist ，无需为深链做 history 回退 3. 模块划分 server.py (约 1300 行，唯一服务进程) ├── 常量与工具 │ ├── conclusion(*st) # 五态聚合结论 │ ├── _open_conn / _tab_rows / _tab_summary │ └── Excel 导出（_build_tab_workbook / _build_all_workbook / _build_date_workbook） │ ├── 任务模型与注册表 │ ├── TabState（id/name/db_path/shot_dir/platforms/pause_evt/stop_evt） │ ├── create_tab / close_tab / delete_tab / rename_tab │ └── _next_id（带 REG_LOCK）/ _save_registry / _load_registry │ ├── Worker(threading.Thread) # 每任务一个并行跑批线程 │ ├── _run_one_own(kw, eng, sess, page, conn) # 单关键词×单引擎 │ └── _pipeline_eng(eng, conn) # 一个引擎下逐词处理 │ ├── HTTP 层 │ ├── Handler._do_GET / _do_POST # 路由分发 │ ├── _import / _start / _retry / _export_* # 业务动作 │ └── _serve_index / _serve_static / _serve_shot / _serve_favicon │ └── core/ 模块（被 server 调用） ├── config.py / config_local.py # 配置（占位值 + 本机覆盖） ├── baidu.py / bing.py / baidu_m.py / bing_m.py # 四平台采集 ├── engine.py # Playwright BrowserSession 封装 ├── db.py # SQLite 读写 ├── logger.py / cookie_tools.py └── profile_helper.py # 每任务独立 profile 目录 4. 请求生命周期 4.1 开始跑批（POST /api/tabs/ /start） 前端点开始 → _start(tab, data) │ 校验未在运行 → 新建 Worker ▼ Worker.run() └─ for engine in tab.platforms: for keyword in load_pending(conn): # 只取仍 pending 的词×引擎 打开搜索页(engine, keyword) for page in 1..MAX_PAGES(10): 解析自然结果 命中? → 记 hit(rank,page,evidence,shot) → break 翻页三态: 无下一页→none; stuck→error # 熔断: 连续3页0条 → malfunction update_result(...) 4.2 导出（GET /api/export_date） 前端选日期 → _export_date() └─ 筛选该日任务 → 收集截图（按 第一页|其他页 × 平台 分层） + _build_date_workbook（汇总工作簿，每任务一 sheet） → zip 打包返回 5. 多任务并行与隔离设计 每任务完全隔离 ：独立 ​ data/t&lt;id&gt;.db 、独立截图目录、独立浏览器 profile 子目录 → 并行互不污染。 pending 驱动断点续跑 ：​ load_pending() 只取「仍 pending 且该词需要跑该引擎」的组合。 导入 upsert 不重置 ：​ ON CONFLICT(keyword) DO UPDATE SET engines=... ，已跑过的平台不因重新导入而重跑。 暂停/停止 ：​ pause_evt ​（当前词完成后停）、​ stop_evt 。 6. 并发一致性（易踩坑，已修复） 坑 修复 「已在运行」检查与 worker 赋值不在同一临界区 → 双标签重复跑抢 profile 收敛到同一临界区 _next_id 无锁 → 并发建任务 tid 重复覆盖数据 加 ​ REG_LOCK load_pending 连接从不 close → 泄漏 SQLite 句柄 finally: conn.close() 7. 目录结构 official-website-search-publish/ ├─ server.py # 服务入口（HTTP + 并行调度 + 导出） ├─ profile_helper.py # 每任务独立 profile 目录 ├─ core/ │ ├─ config.py # 全局配置（占位值） │ ├─ config_local.py # 本机真实配置（gitignore） │ ├─ config_local.example.py # 样例模板 │ ├─ baidu.py / baidu_m.py / bing.py / bing_m.py │ ├─ engine.py / db.py / logger.py / cookie_tools.py ├─ web/ # Vue3 前端（src/views/ 四个页面） ├─ scripts/start_panel.bat # 一键启动 ├─ tests/test_v2_smoke.py # 冒烟测试 ├─ data/ · shots/ · profile_sessions/ · logs/ # 运行时（gitignore） ├─ docs/ # 本文档目录（00-06 + 知识沉淀） └─ .github/workflows/ci.yml # pytest + ruff + npm build', '2026-10-31 17:43:10.967441+08'::timestamptz, '2026-10-31 17:43:10.967441+08'::timestamptz, '57475bc4-ef3c-4e7e-a8b7-17b5526dc5a2'::uuid, 0, NULL),
  ('83becb42-97fb-4fd6-96bb-c7669b309634'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '日报自动化 · 全流程与代码', '<blockquote>
<p>一套把「口头简写」变成公司日报的自动化：<strong>解析简写 → 成句扩写 → 预演确认 → 双平台发布（火云台 + 思源笔记）→ 回查归档</strong>。<br/>
附带 Windows 系统通知提醒、单双休排班判断、历史回填与三级小结。</p>
<p>更新：2026-10-19（新增「周」层级、碎片周模板）　代码量：约 2400 行　依赖：零</p>
</blockquote>
<hr/>
<h2>1. 它解决什么问题</h2>
<p>每天要写日报，但真实的记录是零散的：</p>
<pre><code class="language-text">沙利文_10.14 头条更新文章
沙利文_10.14 AI更新文章 2篇
新世界_舆情提交反馈并跟进反馈情况
</code></pre>
<p>公司要的是成句的项目制写法：</p>
<pre><code class="language-text">沙利文项目：完成 10.14 头条更新文章发布，完成 10.14 AI 主题更新文章 2 篇。
新世界项目：整理并提交 10.14 舆情反馈，同时跟进反馈情况。
</code></pre>
<p>中间这段翻译以前靠人脑，现在靠规则 + 一次人工确认。同一份内容写进两个地方（公司系统 + 个人思源），并按周/月/年归档。</p>
<hr/>
<h2>2. 整体架构</h2>
<pre><code class="language-text">   口头简写 / 便签
        ↓
   parse-text.mjs   解析成五个板块
        ↓
   expand.mjs       成句扩写（项目制句式）
        ↓
   render.mjs       渲成富文本 / Markdown
        ↓
     预演（给人看）
        ↓ 人工确认
   ┌────┴────┐
   ↓         ↓
火云台      思源笔记
部门人员报告  工作日志/年/月/第N周/日期
   ↓         ↓
   └────┬────┘
        ↓
   回查确认 → 归档 reports/
</code></pre>
<p>四个独立的部分围绕同一份内容：</p>
<table>
<thead>
<tr>
<th style="text-align:left">组件</th>
<th style="text-align:left">作用</th>
<th style="text-align:left">触发</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">日报流水线</td>
<td style="text-align:left">写日报到两个平台</td>
<td style="text-align:left">人工说「提交」</td>
</tr>
<tr>
<td style="text-align:left">Windows 通知</td>
<td style="text-align:left">到点提醒，写过了不吵</td>
<td style="text-align:left">计划任务，工作日 17:40</td>
</tr>
<tr>
<td style="text-align:left">排班判断</td>
<td style="text-align:left">单双休轮换，决定哪天算工作日</td>
<td style="text-align:left">被通知和人工查询共用</td>
</tr>
<tr>
<td style="text-align:left">回填 / 小结</td>
<td style="text-align:left">历史数据搬家、周月年总结</td>
<td style="text-align:left">手动或定时</td>
</tr>
</tbody>
</table>
<hr/>
<h2>3. 三个平台的接口</h2>
<h3>3.1 火云台（huoyuntai.com）</h3>
<p>前端是 Vue SPA，真实接口在 ​<code>https://app-api.suwork.com</code>，接口逆向还原。</p>
<table>
<thead>
<tr>
<th style="text-align:left">方法</th>
<th style="text-align:left">路径</th>
<th style="text-align:left">用途</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/Login/login</code></td>
<td style="text-align:left">登录，​<code>{user_phone, user_pwd}</code>，无验证码</td>
</tr>
<tr>
<td style="text-align:left">GET</td>
<td style="text-align:left"><code>/api/user/getUserInfo</code></td>
<td style="text-align:left">校验登录态</td>
</tr>
<tr>
<td style="text-align:left">GET</td>
<td style="text-align:left"><code>/api/UserReport/getUserReportInfo</code></td>
<td style="text-align:left">查某天报告；<strong>无报告返回 null</strong></td>
</tr>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/UserReport/addUserReport</code></td>
<td style="text-align:left"><strong>新增和修改都走这个</strong>，靠 ​<code>report_id</code> 区分</td>
</tr>
</tbody>
</table>
<ul>
<li>鉴权头 ​<code>Authorization: Bearer &lt;token&gt;</code>​，token 在登录响应的 ​<code>data.token</code></li>
<li><strong>空板块的约定表示是</strong> ​ <strong>​<code>&lt;p&gt;&lt;/p&gt;</code>​</strong> ，不是空字符串</li>
</ul>
<h3>3.2 思源笔记（note.nbook.icu）</h3>
<p>鉴权头 ​<code>Authorization: Token &lt;token&gt;</code>。</p>
<table>
<thead>
<tr>
<th style="text-align:left">方法</th>
<th style="text-align:left">路径</th>
<th style="text-align:left">用途</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/notebook/lsNotebooks</code></td>
<td style="text-align:left">笔记本列表</td>
</tr>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/query/sql</code></td>
<td style="text-align:left">SQL 查询块</td>
</tr>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/filetree/createDocWithMd</code></td>
<td style="text-align:left">建文档，​<code>path</code>​ 是<strong>完整 hpath</strong></td>
</tr>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/filetree/removeDoc</code></td>
<td style="text-align:left">删文档，​<code>path</code>​ 是<strong>存储路径</strong></td>
</tr>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/block/appendBlock</code></td>
<td style="text-align:left">往文档追加正文块</td>
</tr>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/block/insertBlock</code></td>
<td style="text-align:left">在某块之后插入</td>
</tr>
<tr>
<td style="text-align:left">POST</td>
<td style="text-align:left"><code>/api/block/deleteBlock</code></td>
<td style="text-align:left">删除单个块</td>
</tr>
</tbody>
</table>
<p><strong>hpath 和 path 是两个不同的东西</strong>：</p>
<table>
<thead>
<tr>
<th style="text-align:left">字段</th>
<th style="text-align:left">例子</th>
<th style="text-align:left">用在哪</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left"><code>hpath</code></td>
<td style="text-align:left"><code>/工作日志/2026/10/第3周/2026-10-16</code></td>
<td style="text-align:left">建文档、人类阅读</td>
</tr>
<tr>
<td style="text-align:left"><code>path</code></td>
<td style="text-align:left"><code>/20261019112037-kcekmkz/20261019113333-xxx.sy</code></td>
<td style="text-align:left">删文档</td>
</tr>
</tbody>
</table>
<h3>3.3 时间与周编号</h3>
<p>报告日期取本机当天。<strong>周编号按「月内第几周」</strong> ：含 1 号的那一周算第 1 周，公式是：</p>
<pre><code class="language-js">week = Math.floor((day - 1 + (1号是周几 as 周一=0)) / 7) + 1
</code></pre>
<p>例：2026-10-01 是周四（偏移 3），则 10-19 属 ​<code>floor((19-1+3)/7)+1 = 4</code> → 第 4 周。</p>
<p>和思源「日记」笔记本的 ​<code>第N周</code> 口径一致。</p>
<hr/>
<h2>4. 关键设计决策</h2>
<h3>4.1 默认只预演，绝不自动提交</h3>
<p><code>submit.mjs</code>​ 默认预演，只有显式加 ​<code>--submit</code> 才写入。日报是交给公司系统的东西，写错比写晚更麻烦。</p>
<h3>4.2 幂等靠「先查后写」</h3>
<p>两个平台都先查当天有没有，再决定新增还是修改。重复运行不会产生重复数据。</p>
<h3>4.3 两个目标互不阻塞</h3>
<p>火云台和思源是独立两步，一个失败另一个照写：</p>
<pre><code class="language-text">结果：火云台 ✔    思源 ✔
</code></pre>
<h3>4.4 脚本和状态分离</h3>
<p>代码装在技能目录（只读资源），配置 / 草稿 / 归档放工作区。工作区四层解析：<br/>
​<code>DAILY_REPORT_HOME</code>​ → ​<code>--home</code>​ → 从脚本位置向上找 → ​<code>~/日报自动化</code>。</p>
<h3>4.5 扩写是启发式，不是黑盒</h3>
<p><code>expand.mjs</code>​ 的词表显式、可读、可改。命中不了退回通用兜底，<strong>绝不丢内容</strong>。</p>
<h3>4.6 层级即总结：年 / 月 / 周 / 日期</h3>
<p>思源里的每一层容器文档本身就是那个粒度的总结，形态统一：</p>
<table>
<thead>
<tr>
<th style="text-align:left">层级</th>
<th style="text-align:left">例子</th>
<th style="text-align:left">内容</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">年</td>
<td style="text-align:left"><code>/2026</code></td>
<td style="text-align:left">年度总结</td>
</tr>
<tr>
<td style="text-align:left">月</td>
<td style="text-align:left"><code>/2026/09</code></td>
<td style="text-align:left">固定产出 / 项目专项 / 观察</td>
</tr>
<tr>
<td style="text-align:left">周</td>
<td style="text-align:left"><code>/2026/09/第3周</code></td>
<td style="text-align:left">做了什么 / 观察 / 下周</td>
</tr>
<tr>
<td style="text-align:left">日期</td>
<td style="text-align:left"><code>/2026/09/第3周/2026-09-17</code></td>
<td style="text-align:left">当天五段日报</td>
</tr>
</tbody>
</table>
<h3>4.7 碎片周换模板</h3>
<p>月内周序的必然结果：跨月的那一周被切开，会出现只有 1 天的「周」。1 天谈不了节奏，所以：</p>
<ul>
<li><strong>≥3 天</strong> → 正常周报（做了什么 / 观察 / 下周）</li>
<li><strong>2 天</strong> → 同上，但「观察」只写事实</li>
<li><strong>1 天</strong> → 碎片周模板（<strong>这天做了什么 / 承接 / 说明</strong>）</li>
</ul>
<p>碎片周的价值不是总结，是<strong>接上前后两段</strong>，让人知道断点在哪、有没有断掉。</p>
<hr/>
<h2>5. 踩过的坑（最有价值的部分）</h2>
<h3>5.1 受限环境里浏览器起不来（放弃飞书自动读取的原因）</h3>
<table>
<thead>
<tr>
<th style="text-align:left">方式</th>
<th style="text-align:left">结果</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">Playwright ​<code>launchPersistentContext</code></td>
<td style="text-align:left"><code>spawn EPERM</code>（走命名管道调试）</td>
</tr>
<tr>
<td style="text-align:left">自启 Chrome + ​<code>connectOverCDP</code></td>
<td style="text-align:left">crashpad 子进程被拒，Chrome 自杀</td>
</tr>
<tr>
<td style="text-align:left">加 ​<code>--disable-breakpad</code></td>
<td style="text-align:left"><code>FATAL: platform_channel.cc: 拒绝访问 (0x5)</code></td>
</tr>
<tr>
<td style="text-align:left">加 ​<code>--single-process --in-process-gpu</code></td>
<td style="text-align:left">同上，Mojo 命名管道仍被拒</td>
</tr>
</tbody>
</table>
<p><strong>根因</strong>：限制环境禁止创建命名管道，Chrome 多进程 IPC 强依赖它。<br/>
<strong>结论</strong>：这条路在受限环境走不通，最终改成「人工提供内容 + 纯 HTTP 接口」。</p>
<h3>5.2 ​<code>0x80073D54 进程没有包标识</code></h3>
<p>沙箱内调 WinRT 发系统通知时报这个错，看着像「应用没打包」，实际是<strong>限制环境拦了 WinRT 激活</strong>。<br/>
同样代码在计划任务里（沙箱外）完全正常。<strong>报错信息会误导人。</strong></p>
<h3>5.3 思源的 SQL 索引有延迟</h3>
<p><code>createDocWithMd</code>​ 返回成功、文件也落盘了，但紧接着 ​<code>SELECT ... FROM blocks</code> 查不到。</p>
<ul>
<li>回填 33 篇时，28 篇报了「写完回查不到」的假错</li>
<li>更要命：<strong>删除时读的是索引，索引没更新就漏删</strong>，曾因此把文档搞成重复内容叠加</li>
</ul>
<p><strong>对策</strong>：</p>
<ul>
<li>回查重试几次，拿不到只当警告</li>
<li>批量删除时循环多轮，别指望一轮删干净</li>
<li>删到空之后思源会自动补一个空段落， <strong>「删到 0」永远达不到</strong>，不能当终止条件</li>
</ul>
<h3>5.4 思源的嵌入块不适合做目录</h3>
<p><code>{{SELECT ...}}</code>​ 查询块会把<strong>命中的块本身</strong>嵌进来。查文档块（​<code>type=&#39;d&#39;</code>​）等于把整篇日报全文嵌进页面。<br/>
<strong>结论</strong>：做目录用块引用 ​<code>((id &#34;文本&#34;))</code>，别用嵌入块。</p>
<h3>5.5 思源文档块改不了正文</h3>
<p><code>updateBlock</code>​ 对文档块操作时改的是<strong>标题</strong>（文档块的 content 就是标题），正文在子块里。<br/>
<strong>结论</strong>：整篇替换只能「删旧建新」，或 ​<code>appendBlock</code> 追加。</p>
<h3>5.6 ​<code>root_id</code> 不包含子文档</h3>
<p>清空一个容器文档的正文时用 ​<code>WHERE root_id=&#39;&lt;docId&gt;&#39;</code>​ 是安全的 —— 子文档有自己独立的 root_id，不会被连带删除。<br/>
（但 ​<code>removeDoc</code>​ 删文档会连带删子文档，所以对「工作日志」这类有子文档的容器<strong>只能清正文，不能删文档</strong>。）</p>
<h3>5.7 其他小坑</h3>
<table>
<thead>
<tr>
<th style="text-align:left">坑</th>
<th style="text-align:left">说明</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">PowerShell 5.1 按 GBK 读无 BOM 的 .ps1</td>
<td style="text-align:left">中文全乱、语法报错。<strong>所有 .ps1 必须带 UTF-8 BOM</strong></td>
</tr>
<tr>
<td style="text-align:left"><code>$home</code> 是只读自动变量</td>
<td style="text-align:left">变量名大小写不敏感，​<code>$home</code>​ == ​<code>$HOME</code>，赋值报错</td>
</tr>
<tr>
<td style="text-align:left">向上找项目根撞到用户主目录</td>
<td style="text-align:left">主目录下有 ​<code>.dsh</code>，会被误认成项目。必须加「不越过 %USERPROFILE%」护栏</td>
</tr>
<tr>
<td style="text-align:left">记事本存 UTF-8 带 BOM 破坏 JSON</td>
<td style="text-align:left">读取统一 ​<code>replace(/^\uFEFF/, &#39;&#39;)</code></td>
</tr>
<tr>
<td style="text-align:left">火云台登录字段名</td>
<td style="text-align:left">必须 ​<code>user_phone</code>​/​<code>user_pwd</code></td>
</tr>
<tr>
<td style="text-align:left">PowerShell 双引号里反引号是转义符</td>
<td style="text-align:left">替换含反引号的字符串时会静默失效，改用 Node 或单引号</td>
</tr>
<tr>
<td style="text-align:left">思源中文容器的排序</td>
<td style="text-align:left">「第4周」排在日期后面（中文在数字之后），树里顺序可能不直观</td>
</tr>
</tbody>
</table>
<hr/>
<h2>6. 目录结构</h2>
<pre><code class="language-text">daily-report-huoyuntai/            技能本体（只读）
├─ SKILL.md / README.md
├─ install.ps1 / install.cmd / uninstall.ps1
├─ scripts/
│  ├─ src/
│  │  ├─ config.mjs                工作区解析 + 配置校验
│  │  ├─ calendar.mjs              单双休排班
│  │  ├─ submit.mjs                主流程 CLI
│  │  ├─ report/                   火云台一侧
│  │  │  ├─ client.mjs
│  │  │  ├─ parse-text.mjs
│  │  │  ├─ expand.mjs
│  │  │  └─ render.mjs
│  │  └─ siyuan/                   思源一侧
│  │     ├─ client.mjs
│  │     └─ publish.mjs
│  └─ tools/
│     ├─ is-workday.mjs / check-status.mjs
│     ├─ backfill-siyuan.mjs
│     ├─ remind.ps1 / install-reminder.ps1
│     └─ fetch-history.mjs
├─ templates/                      配置与草稿模板
└─ references/                     风格指南 + 接口参考
</code></pre>
<p>工作区（状态，与技能分离）：​<code>config.json</code>​ / ​<code>drafts/</code>​ / ​<code>reports/</code>​ / ​<code>.cache/</code>。</p>
<hr/>
<h2>7. 配置</h2>
<pre><code class="language-json">{
  &#34;huoyuntai&#34;: { &#34;user_phone&#34;: &#34;&#34;, &#34;user_pwd&#34;: &#34;&#34; },
  &#34;defaults&#34;: { &#34;type&#34;: 1 },
  &#34;schedule&#34;: {
    &#34;anchorWeek&#34;: &#34;2026-10-12&#34;,
    &#34;anchorIsDouble&#34;: true,
    &#34;workdays&#34;: [],
    &#34;holidays&#34;: []
  },
  &#34;siyuan&#34;: {
    &#34;enabled&#34;: true,
    &#34;url&#34;: &#34;https://note.nbook.icu&#34;,
    &#34;token&#34;: &#34;&#34;,
    &#34;notebook&#34;: &#34;20261015151147-ivwb5le&#34;,
    &#34;parentDoc&#34;: &#34;工作日志&#34;,
    &#34;pathPattern&#34;: &#34;{year}/{month}/第{week}周/{date}&#34;
  }
}
</code></pre>
<h3>单双休排班</h3>
<p>用「锚点周 + 奇偶交替」，固定规则表达不了交替休：</p>
<ul>
<li><code>anchorWeek</code>​：双休那一周的<strong>周一</strong></li>
<li><code>anchorIsDouble</code>：锚点周是不是双休</li>
<li>之后每隔一周切换；​<code>workdays</code>​/​<code>holidays</code> 处理法定节假日调休</li>
</ul>
<h3>思源目录结构</h3>
<p><code>pathPattern</code>​ 占位符 ​<code>{year}</code>​ ​<code>{month}</code>​ ​<code>{week}</code>​ ​<code>{date}</code>​ ​<code>{day}</code>：</p>
<table>
<thead>
<tr>
<th style="text-align:left">pattern</th>
<th style="text-align:left">落点</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left"><code>{year}/{month}/第{week}周/{date}</code>（默认）</td>
<td style="text-align:left"><code>/工作日志/2026/10/第4周/2026-10-19</code></td>
</tr>
<tr>
<td style="text-align:left"><code>{year}/{month}/{date}</code></td>
<td style="text-align:left"><code>/工作日志/2026/10/2026-10-19</code></td>
</tr>
<tr>
<td style="text-align:left"><code>{date}</code></td>
<td style="text-align:left"><code>/工作日志/2026-10-19</code>（平铺）</td>
</tr>
</tbody>
</table>
<p>年 / 月 / 周容器由思源按 hpath 自动创建。</p>
<hr/>
<h2>8. 使用方式</h2>
<pre><code class="language-bash">node scripts/src/submit.mjs                    # 预演
node scripts/src/submit.mjs --submit           # 提交（两个平台）
node scripts/src/submit.mjs --submit --no-siyuan
node scripts/src/submit.mjs --check            # 只验登录 + 查当天
node scripts/src/submit.mjs --json             # 只打印报文
node scripts/src/submit.mjs --raw              # 关闭扩写
node scripts/src/submit.mjs --date 2026-10-13 --submit
</code></pre>
<p>草稿格式：</p>
<pre><code class="language-text">已完成
沙利文_10.14 头条更新文章
沙利文_10.14 AI更新文章 2篇
新世界_舆情提交反馈并跟进反馈情况

未完成
Elo_10.14 关键词排名查询
</code></pre>
<hr/>
<h2>9. 完整代码</h2>
<h3>9.1 核心逻辑</h3>
<h4><code>scripts/src/config.mjs</code></h4>
<p>配置与工作区解析：决定 config.json / drafts / reports 落在哪个目录</p>
<pre><code class="language-js">import fs from &#39;node:fs&#39;;
import os from &#39;node:os&#39;;
import path from &#39;node:path&#39;;
import { fileURLToPath } from &#39;node:url&#39;;

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT_ROOT = path.resolve(HERE, &#39;..&#39;);

/** 工作区默认位置（User 范围）：用户主目录下的「日报自动化」 */
const DEFAULT_HOME_NAME = &#39;日报自动化&#39;;

/** 一个目录要同时有 config.json 和 reports/ 或 drafts/，才认作工作区 */
function looksLikeWorkspace(dir) {
  return (
    fs.existsSync(path.join(dir, &#39;config.json&#39;)) &amp;&amp;
    (fs.existsSync(path.join(dir, &#39;reports&#39;)) || fs.existsSync(path.join(dir, &#39;drafts&#39;)))
  );
}

/**
 * 从脚本位置向上找工作区。
 * Project 范围安装时，工作区就是项目根，在脚本的好几层上级
 * （&lt;项目&gt;/.dsh/skills/&lt;skill&gt;/scripts/src/），所以要往上走。
 */
function findWorkspaceUpwards(start, maxDepth = 8) {
  let cur = start;
  for (let i = 0; i &lt; maxDepth; i++) {
    if (looksLikeWorkspace(cur)) return cur;
    const parent = path.dirname(cur);
    if (parent === cur) break;
    cur = parent;
  }
  return null;
}

/**
 * 解析工作区目录（存放 config.json / drafts / reports / .cache）。
 *
 * 优先级：
 *   1. 环境变量 DAILY_REPORT_HOME
 *   2. 命令行参数 --home &lt;dir&gt;
 *   3. 从脚本位置向上找到的工作区（Project 范围安装时就是项目根）
 *   4. ~/日报自动化（User 范围安装）
 */
function resolveHome() {
  const fromEnv = process.env.DAILY_REPORT_HOME?.trim();
  if (fromEnv) return path.resolve(fromEnv);

  const i = process.argv.indexOf(&#39;--home&#39;);
  if (i !== -1 &amp;&amp; process.argv[i + 1]) return path.resolve(process.argv[i + 1]);

  const found = findWorkspaceUpwards(SCRIPT_ROOT);
  if (found) return found;

  return path.join(os.homedir(), DEFAULT_HOME_NAME);
}

export const ROOT = resolveHome();

const CONFIG_PATH = path.join(ROOT, &#39;config.json&#39;);

export function configPath() {
  return CONFIG_PATH;
}

export function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    throw new Error(
      `找不到配置文件：${CONFIG_PATH}\n` +
        `请把 config.example.json 复制成 config.json，并填入日报站的手机号和密码。\n` +
        `（也可以设置环境变量 DAILY_REPORT_HOME 指向别的工作区）`,
    );
  }

  let cfg;
  try {
    // 去掉记事本可能写入的 BOM
    cfg = JSON.parse(fs.readFileSync(CONFIG_PATH, &#39;utf8&#39;).replace(/^\uFEFF/, &#39;&#39;));
  } catch (e) {
    throw new Error(`config.json 不是合法 JSON：${e.message}`);
  }

  const phone = String(cfg?.huoyuntai?.user_phone ?? &#39;&#39;).trim();
  const pwd = String(cfg?.huoyuntai?.user_pwd ?? &#39;&#39;);

  if (!phone || phone.includes(&#39;填&#39;)) throw new Error(&#39;config.json 里 huoyuntai.user_phone 还没填。&#39;);
  if (!pwd || pwd.includes(&#39;填&#39;)) throw new Error(&#39;config.json 里 huoyuntai.user_pwd 还没填。&#39;);

  return {
    user_phone: phone,
    user_pwd: pwd,
    type: Number(cfg?.defaults?.type ?? 1),
  };
}

/** 脱敏后的手机号，用于日志 */
export function maskPhone(phone) {
  const s = String(phone);
  if (s.length &lt; 7) return &#39;***&#39;;
  return `${s.slice(0, 3)}****${s.slice(-4)}`;
}

/**
 * 读思源笔记的配置（可选目标）。
 * 没配就是 null —— 表示只发火云台。
 */
export function loadSiYuanConfig() {
  if (!fs.existsSync(CONFIG_PATH)) return null;

  let cfg;
  try {
    cfg = JSON.parse(fs.readFileSync(CONFIG_PATH, &#39;utf8&#39;).replace(/^\uFEFF/, &#39;&#39;));
  } catch {
    return null;
  }

  const s = cfg?.siyuan;
  if (!s) return null;
  if (s.enabled === false) return null;

  const url = String(s.url ?? &#39;&#39;).trim();
  const notebook = String(s.notebook ?? &#39;&#39;).trim();
  const token = String(s.token ?? &#39;&#39;);
  // 没填地址或笔记本，就当没配
  if (!url || url.includes(&#39;填&#39;) || !notebook || notebook.includes(&#39;填&#39;)) return null;

  return {
    url,
    token,
    notebook,
    parentDoc: String(s.parentDoc ?? &#39;工作日志&#39;).trim(),
    // 父文档下的子目录结构，占位符：{year} {month} {week} {date}
    pathPattern:
      String(s.pathPattern ?? &#39;{year}/{month}/第{week}周/{date}&#39;).trim() ||
      &#39;{year}/{month}/第{week}周/{date}&#39;,
    tokenMissing: !token || token.includes(&#39;填&#39;),
  };
}
</code></pre>
<h4><code>scripts/src/calendar.mjs</code></h4>
<p>单双休轮换排班：判断某天该不该上班</p>
<pre><code class="language-js">/**
 * 排班日历：判断某天是不是工作日。
 *
 * 公司的休息制度是「单双休轮换」—— 一周双休（周六周日都休），
 * 下一周单休（只休周日，周六要上班），交替进行。
 *
 * 固定的「周一到周五」规则表达不了这个，所以用「锚点周 + 奇偶交替」来算：
 * 锚点周（默认 2026-10-12 那一周）是双休，之后每隔一周切换一次。
 *
 * 遇到法定节假日调休，可以在 config.json 的 schedule 里手工加例外：
 *   &#34;workdays&#34;: [&#34;2026-10-24&#34;],   // 强制算工作日
 *   &#34;holidays&#34;: [&#34;2026-10-01&#34;]    // 强制算休息日
 */
import fs from &#39;node:fs&#39;;
import path from &#39;node:path&#39;;
import { ROOT } from &#39;./config.mjs&#39;;

export const DEFAULT_SCHEDULE = {
  /** 锚点周的周一。这一周的休息制度由 anchorIsDouble 决定 */
  anchorWeek: &#39;2026-10-12&#39;,
  /** 锚点周是不是双休 */
  anchorIsDouble: true,
  /** 强制算工作日的日期（调休上班） */
  workdays: [],
  /** 强制算休息日的日期（法定假日） */
  holidays: [],
};

const CONFIG_PATH = path.join(ROOT, &#39;config.json&#39;);

/** 读 config.json 里的 schedule 块，缺项用默认值补齐 */
export function loadSchedule() {
  let raw = {};
  try {
    raw = JSON.parse(fs.readFileSync(CONFIG_PATH, &#39;utf8&#39;).replace(/^\uFEFF/, &#39;&#39;));
  } catch {
    // 没有配置文件或读不动，就用默认排班
  }
  const s = raw?.schedule ?? {};
  return {
    anchorWeek: typeof s.anchorWeek === &#39;string&#39; ? s.anchorWeek : DEFAULT_SCHEDULE.anchorWeek,
    anchorIsDouble: typeof s.anchorIsDouble === &#39;boolean&#39; ? s.anchorIsDouble : DEFAULT_SCHEDULE.anchorIsDouble,
    workdays: Array.isArray(s.workdays) ? s.workdays.map(String) : [],
    holidays: Array.isArray(s.holidays) ? s.holidays.map(String) : [],
  };
}

/** 取某天所在周的周一（本地时间） */
function mondayOf(dateStr) {
  const d = new Date(`${dateStr}T00:00:00`);
  const dow = (d.getDay() + 6) % 7; // 0=周一 … 6=周日
  d.setDate(d.getDate() - dow);
  d.setHours(0, 0, 0, 0);
  return d;
}

/** 相对锚点周相差几周（锚点周为 0，可以为负） */
export function weekIndex(dateStr, anchorWeek) {
  const a = mondayOf(anchorWeek);
  const b = mondayOf(dateStr);
  return Math.round((b - a) / (7 * 24 * 60 * 60 * 1000));
}

const WEEKDAY_NAME = [&#39;周日&#39;, &#39;周一&#39;, &#39;周二&#39;, &#39;周三&#39;, &#39;周四&#39;, &#39;周五&#39;, &#39;周六&#39;];

/**
 * @returns {{ workday: boolean, reason: string, weekType?: &#39;双休&#39;|&#39;单休&#39;, weekIndex?: number }}
 */
export function isWorkday(dateStr, schedule = loadSchedule()) {
  if (schedule.workdays.includes(dateStr)) {
    return { workday: true, reason: &#39;手工指定为工作日&#39; };
  }
  if (schedule.holidays.includes(dateStr)) {
    return { workday: false, reason: &#39;手工指定为休息日&#39; };
  }

  const d = new Date(`${dateStr}T00:00:00`);
  if (Number.isNaN(d.getTime())) return { workday: false, reason: `日期无法解析：${dateStr}` };

  const dow = d.getDay();
  if (dow &gt;= 1 &amp;&amp; dow &lt;= 5) {
    return { workday: true, reason: WEEKDAY_NAME[dow] };
  }
  if (dow === 0) {
    return { workday: false, reason: &#39;周日（永远休）&#39; };
  }

  // 周六：看这一周是单休还是双休
  const idx = weekIndex(dateStr, schedule.anchorWeek);
  const isDouble = Math.abs(idx) % 2 === 0 ? schedule.anchorIsDouble : !schedule.anchorIsDouble;
  return {
    workday: !isDouble,
    reason: isDouble ? &#39;双休周的周六（休）&#39; : &#39;单休周的周六（要上班）&#39;,
    weekType: isDouble ? &#39;双休&#39; : &#39;单休&#39;,
    weekIndex: idx,
  };
}
</code></pre>
<h4><code>scripts/src/submit.mjs</code></h4>
<p>主流程 CLI：预演 / 提交 / 回查 / 归档</p>
<pre><code class="language-js">#!/usr/bin/env node
import fs from &#39;node:fs&#39;;
import path from &#39;node:path&#39;;
import { ROOT, loadConfig, loadSiYuanConfig, maskPhone } from &#39;./config.mjs&#39;;
import { createReportClient } from &#39;./report/client.mjs&#39;;
import { SECTIONS, buildPayload, htmlToText, validateDraft } from &#39;./report/render.mjs&#39;;
import { parsePlainText, describeSections } from &#39;./report/parse-text.mjs&#39;;
import { expandToProse } from &#39;./report/expand.mjs&#39;;
import { publishToSiYuan, buildMarkdown, renderPathPattern } from &#39;./siyuan/publish.mjs&#39;;

// ---------- 参数 ----------
function parseArgs(argv) {
  const out = { submit: false, check: false, json: false, raw: false, noSiYuan: false, draft: null, date: null, help: false };
  for (let i = 0; i &lt; argv.length; i++) {
    const a = argv[i];
    if (a === &#39;--submit&#39;) out.submit = true;
    else if (a === &#39;--dry-run&#39;) out.submit = false;
    else if (a === &#39;--check&#39;) out.check = true;
    else if (a === &#39;--json&#39;) out.json = true;
    else if (a === &#39;--raw&#39;) out.raw = true;
    else if (a === &#39;--prose&#39;) out.raw = false;
    else if (a === &#39;--no-siyuan&#39;) out.noSiYuan = true;
    else if (a === &#39;--draft&#39;) out.draft = argv[++i];
    else if (a === &#39;--date&#39;) out.date = argv[++i];
    else if (a === &#39;--help&#39; || a === &#39;-h&#39;) out.help = true;
    else if (!a.startsWith(&#39;-&#39;) &amp;&amp; !out.draft) out.draft = a;
    else throw new Error(`未知参数：${a}`);
  }
  return out;
}

function todayLocal() {
  const d = new Date();
  const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

const line = (c = &#39;─&#39;) =&gt; console.log(c.repeat(64));

/** 找草稿：显式指定优先；否则按 .txt → .md → .json 找当天的 */
function resolveDraftPath(explicit, date) {
  if (explicit) {
    const p = path.resolve(ROOT, explicit);
    return fs.existsSync(p) ? p : null;
  }
  for (const ext of [&#39;.txt&#39;, &#39;.md&#39;, &#39;.json&#39;]) {
    const p = path.join(ROOT, &#39;drafts&#39;, `${date}${ext}`);
    if (fs.existsSync(p)) return p;
  }
  return null;
}

const HELP = `
用法：
  node src/submit.mjs [草稿文件] [--date YYYY-MM-DD] [--submit]
  node src/submit.mjs --check

草稿可以是纯文本（.txt，推荐）或 JSON（.json）。
默认找 drafts/&lt;今天&gt;.txt → .md → .json。

纯文本格式：小标题下面每行一条，空行随便加。
  已完成
  沙利文_10.13头条更新文章
  新世界_10.13舆情周报

  未完成
  库存同步联调

小标题认这些写法：
  已完成 / 未完成 / 需协调 / 明日计划 / 备注
  也认：今日已完成、进行中、协调事项、明天计划、计划、卡点、说明 …
  带冒号、方括号、井号、数字编号都能识别。

默认会把「今日已完成工作」扩写成公司惯用的项目制成句风格
（见 docs/风格指南.md）；加 --raw 则照抄原文。
默认是「预演」模式：只打印将要提交的内容，不写入任何系统。
加 --submit 才会真正提交。
--check      只验证登录态并查当天是否已填过。
--json       只打印将要发出去的完整报文（不联网、不需要配置）。
--no-siyuan  只发火云台，跳过思源笔记。

配了思源笔记（config.json 的 siyuan 块）时，--submit 会同时写火云台和思源；
哪边失败会明确报出来，不会静默只成功一边。
`.trim();

function preview(payload, draftPath) {
  line();
  console.log(`草稿：${draftPath ? path.relative(ROOT, draftPath) : &#39;(内存)&#39;}`);
  console.log(`日期：${payload.report_date}    类型：${payload.type}（日报）`);
  line();
  for (const s of SECTIONS) {
    const text = htmlToText(payload[s.key]);
    console.log(`\n【${s.label}】${text ? &#39;&#39; : &#39;（空）&#39;}`);
    if (text) console.log(text.split(&#39;\n&#39;).map((l) =&gt; `  · ${l}`).join(&#39;\n&#39;));
  }
  line();
}

// ---------- 主流程 ----------
async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(HELP);
    return 0;
  }

  const date = args.date || todayLocal();

  // --check：只验证登录 + 查当天状态
  if (args.check) {
    const cfg = loadConfig();
    const client = createReportClient({ ...cfg, log: (m) =&gt; console.log(`  · ${m}`) });
    console.log(`账号：${maskPhone(cfg.user_phone)}    日期：${date}    类型：日报`);
    line();
    const info = await client.verify();
    console.log(`登录成功，当前用户：${info?.name ?? info?.user_name ?? &#39;(接口未返回姓名)&#39;}`);
    const existing = await client.getReportInfo({ report_date: date, type: cfg.type });
    if (existing) {
      console.log(`当天已有日报（id=${existing.report_id ?? existing.id}）：`);
      for (const s of SECTIONS) {
        const t = htmlToText(existing[s.key] ?? &#39;&#39;);
        console.log(`\n【${s.label}】`);
        console.log(t ? t.split(&#39;\n&#39;).map((l) =&gt; `  · ${l}`).join(&#39;\n&#39;) : &#39;  （空）&#39;);
      }
    } else {
      console.log(&#39;当天还没有填过日报。&#39;);
    }
    return 0;
  }

  // ---------- 读草稿 ----------
  const draftPath = resolveDraftPath(args.draft, date);

  if (!draftPath) {
    const want = args.draft
      ? path.resolve(ROOT, args.draft)
      : path.join(ROOT, &#39;drafts&#39;, `${date}.txt`);
    console.error(`找不到草稿文件：${want}`);
    console.error(`新建一个文本文件，把今天做的事按「已完成 / 未完成」写进去即可。`);
    console.error(`格式参考 drafts/example.txt，也支持 drafts/example.json。`);
    return 2;
  }

  const raw = fs.readFileSync(draftPath, &#39;utf8&#39;).replace(/^\uFEFF/, &#39;&#39;);
  const isPlainText = !draftPath.toLowerCase().endsWith(&#39;.json&#39;);

  let draft;
  if (isPlainText) {
    const { draft: d, warnings, sectionsSeen } = parsePlainText(raw, { report_date: date });
    draft = d;
    for (const w of warnings) console.log(`  ⚠ ${w}`);
    if (sectionsSeen.length) console.log(`  识别到板块：${describeSections(sectionsSeen)}`);
  } else {
    try {
      draft = JSON.parse(raw);
    } catch (e) {
      console.error(`草稿不是合法 JSON：${e.message}`);
      return 2;
    }
  }

  const problems = validateDraft(draft, date);
  if (problems.length) {
    console.error(&#39;草稿有问题，先修一下：&#39;);
    for (const p of problems) console.error(`  ✗ ${p}`);
    return 2;
  }

  // ---------- 成句扩写（默认开启；--raw 可关闭，照抄原文） ----------
  // 条目里没写日期的，用报告日期兜底（2026-10-14 → 10.14）
  const defaultDate = String(draft.report_date || date).slice(5).replace(&#39;-&#39;, &#39;.&#39;);

  if (!args.raw &amp;&amp; Array.isArray(draft.complete_work) &amp;&amp; draft.complete_work.length) {
    const { html, sentences } = expandToProse(draft.complete_work, { defaultDate });
    if (html) {
      draft.complete_work = html;
      console.log(&#39;  成句扩写：&#39;);
      for (const s of sentences) console.log(`    → ${s}`);
    }
  }

  // --json：只打印将要提交的报文，不联网、不需要配置
  if (args.json) {
    console.log(JSON.stringify(buildPayload(draft, { type: 1, report_date: date }), null, 2));
    return 0;
  }

  let cfg;
  try {
    cfg = loadConfig();
  } catch (e) {
    if (args.submit) {
      console.error(e.message);
      return 3;
    }
    // 预演模式下没配置也要能看到内容
    preview(buildPayload(draft, { type: 1, report_date: date }), draftPath);
    console.log(`\n⚠  ${e.message}`);
    console.log(&#39;[预演模式] 内容如上，但没有连接日报系统。&#39;);
    return 0;
  }

  const client = createReportClient({ ...cfg, log: (m) =&gt; console.log(`  · ${m}`) });
  const payload = buildPayload(draft, { type: cfg.type, report_date: date });
  const siyuan = args.noSiYuan ? null : loadSiYuanConfig();

  console.log(`账号：${maskPhone(cfg.user_phone)}`);
  if (siyuan) console.log(`思源：${siyuan.url}   笔记本 ${siyuan.notebook}`);

  // 提交模式下先确认登录能通，免得打完一屏预览才发现密码不对
  if (args.submit) await client.verify();

  preview(payload, draftPath);

  // ---------- 思源笔记：目标与正文预览 ----------
  if (siyuan) {
    line();
    console.log(&#39;【思源笔记】将写入&#39;);
    const subPath = renderPathPattern(siyuan.pathPattern, payload.report_date);
    console.log(
      `  位置：${siyuan.url}  →  ${siyuan.parentDoc ? `${siyuan.parentDoc}/` : &#39;&#39;}${subPath}`,
    );
    if (siyuan.tokenMissing) {
      console.log(&#39;  ⚠  API token 还没填（config.json 的 siyuan.token），正式提交时会跳过思源&#39;);
    }
    console.log(&#39;&#39;);
    console.log(
      buildMarkdown(payload)
        .split(&#39;\n&#39;)
        .map((l) =&gt; `  ${l}`)
        .join(&#39;\n&#39;),
    );
    line();
  }

  // ---------- 查重 ----------
  let existing = null;
  try {
    existing = await client.getReportInfo({ report_date: payload.report_date, type: payload.type });
  } catch (e) {
    if (args.submit) throw e;
    console.log(`\n⚠  连不上日报系统：${e.message}`);
    console.log(&#39;[预演模式] 内容如上，但没能查重。&#39;);
    return 0;
  }

  const mode = existing ? &#39;edit&#39; : &#39;add&#39;;
  const existingId = existing?.report_id ?? existing?.id ?? &#39;&#39;;
  console.log(
    existing
      ? `当天已存在日报（id=${existingId}）→ 将执行「修改」`
      : &#39;当天还没有日报 → 将执行「新增」&#39;,
  );

  if (!args.submit) {
    console.log(&#39;\n[预演模式] 没有提交任何内容。确认无误后加 --submit 正式提交。&#39;);
    return 0;
  }

  // ---------- 提交到火云台 ----------
  // 跟网站前端保持一致：统一走 addUserReport，用 report_id 决定新增还是覆盖
  payload.report_id = existingId || &#39;&#39;;

  line(&#39;═&#39;);
  console.log(&#39;正在提交…&#39;);
  let huoyuntaiOk = false;
  let huoyuntaiMsg = &#39;&#39;;
  try {
    const res = await client.addReport(payload);
    huoyuntaiMsg = `code=${res.code} msg=${res.msg ?? &#39;&#39;}`;
    huoyuntaiOk = res.code === 0;
  } catch (e) {
    huoyuntaiMsg = e.message;
  }
  console.log(`火云台：${huoyuntaiOk ? &#39;✔&#39; : &#39;✘&#39;}  ${huoyuntaiMsg}`);

  // ---------- 回查确认 ----------
  if (huoyuntaiOk) {
    const verify = await client.getReportInfo({ report_date: payload.report_date, type: payload.type });
    if (verify) {
      const firstLine = htmlToText(verify.complete_work || &#39;&#39;).split(&#39;\n&#39;)[0] || &#39;(空)&#39;;
      console.log(`        回查：report_id=${verify.report_id}  已完成工作首行：${firstLine}`);
    } else {
      console.log(&#39;        ⚠ 回查没读到这条报告，请到网站上确认一下。&#39;);
    }
  }

  // ---------- 归档 ----------
  const outDir = path.join(ROOT, &#39;reports&#39;);
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(
    path.join(outDir, `${payload.report_date}.json`),
    JSON.stringify({ ...payload, _submitted_at: new Date().toISOString(), _mode: mode }, null, 2),
    &#39;utf8&#39;,
  );
  fs.writeFileSync(
    path.join(outDir, `${payload.report_date}.md`),
    [
      `# 日报 ${payload.report_date}`,
      &#39;&#39;,
      ...SECTIONS.flatMap((s) =&gt; {
        const t = htmlToText(payload[s.key]);
        return [`## ${s.label}`, &#39;&#39;, t || &#39;（空）&#39;, &#39;&#39;];
      }),
    ].join(&#39;\n&#39;),
    &#39;utf8&#39;,
  );

  // ---------- 发布到思源笔记 ----------
  let siyuanOk = null;
  if (siyuan) {
    if (siyuan.tokenMissing) {
      console.log(&#39;思源：  ⚠ 跳过（API token 没填）&#39;);
    } else {
      try {
        const r = await publishToSiYuan(siyuan, payload, { log: (m) =&gt; console.log(`  · ${m}`) });
        siyuanOk = true;
        console.log(`思源：  ✔ ${r.action === &#39;create&#39; ? &#39;已新建&#39; : &#39;已覆盖&#39;} ${r.hpath}（id=${r.docId}）`);
        for (const w of r.warnings) console.log(`        ⚠ ${w}`);
      } catch (e) {
        siyuanOk = false;
        console.log(`思源：  ✘ ${e.message}`);
      }
    }
  }

  // ---------- 汇总 ----------
  line(&#39;═&#39;);
  const parts = [`火云台 ${huoyuntaiOk ? &#39;✔&#39; : &#39;✘&#39;}`];
  if (siyuan) parts.push(`思源 ${siyuanOk === true ? &#39;✔&#39; : siyuanOk === false ? &#39;✘&#39; : &#39;跳过&#39;}`);
  console.log(`结果：${parts.join(&#39;    &#39;)}`);

  if (!huoyuntaiOk) {
    console.error(&#39;火云台提交失败。&#39;);
    return 1;
  }
  if (siyuanOk === false) {
    console.error(&#39;火云台已成功，但思源写入失败 —— 内容已归档到 reports/，可稍后重跑。&#39;);
    return 1;
  }
  console.log(`完成 ✔  已归档到 reports/${payload.report_date}.{json,md}`);
  return 0;
}

main()
  .then((code) =&gt; process.exit(code))
  .catch((e) =&gt; {
    console.error(`\n出错了：${e.message}`);
    process.exit(1);
  });
</code></pre>
<h4><code>scripts/src/report/parse-text.mjs</code></h4>
<p>便签文本 → 五个板块</p>
<pre><code class="language-js">/**
 * 解析「便签式」日报文本。
 *
 * 格式：用「已完成 / 未完成 / 需协调 / 明日计划 / 备注」当小标题，
 * 标题下面每行一条。大小标题可带冒号、方括号、井号、数字编号、短横线。
 * 空行忽略；某标题下没有内容就是该板块为空。
 */

/** 小标题 → 字段名。键必须完全一致（归一化之后） */
const HEADER_MAP = new Map([
  // 今日已完成工作
  [&#39;已完成&#39;, &#39;complete_work&#39;],
  [&#39;今日已完成&#39;, &#39;complete_work&#39;],
  [&#39;已完成工作&#39;, &#39;complete_work&#39;],
  [&#39;今日已完成工作&#39;, &#39;complete_work&#39;],
  [&#39;完成&#39;, &#39;complete_work&#39;],
  [&#39;完成工作&#39;, &#39;complete_work&#39;],
  [&#39;做了&#39;, &#39;complete_work&#39;],
  [&#39;今天做了&#39;, &#39;complete_work&#39;],
  // 今日未完成工作
  [&#39;未完成&#39;, &#39;unfinished_work&#39;],
  [&#39;今日未完成&#39;, &#39;unfinished_work&#39;],
  [&#39;未完成工作&#39;, &#39;unfinished_work&#39;],
  [&#39;今日未完成工作&#39;, &#39;unfinished_work&#39;],
  [&#39;进行中&#39;, &#39;unfinished_work&#39;],
  [&#39;在做&#39;, &#39;unfinished_work&#39;],
  [&#39;待完成&#39;, &#39;unfinished_work&#39;],
  // 明日需协调事项
  [&#39;需协调&#39;, &#39;coordinate_work&#39;],
  [&#39;需协调事项&#39;, &#39;coordinate_work&#39;],
  [&#39;明日需协调&#39;, &#39;coordinate_work&#39;],
  [&#39;明日需协调事项&#39;, &#39;coordinate_work&#39;],
  [&#39;协调事项&#39;, &#39;coordinate_work&#39;],
  [&#39;协调&#39;, &#39;coordinate_work&#39;],
  [&#39;卡点&#39;, &#39;coordinate_work&#39;],
  [&#39;阻塞&#39;, &#39;coordinate_work&#39;],
  // 明日计划
  [&#39;明日计划&#39;, &#39;tomorrow_plan&#39;],
  [&#39;明天计划&#39;, &#39;tomorrow_plan&#39;],
  [&#39;计划&#39;, &#39;tomorrow_plan&#39;],
  [&#39;下一步&#39;, &#39;tomorrow_plan&#39;],
  [&#39;待办&#39;, &#39;tomorrow_plan&#39;],
  // 备注
  [&#39;备注&#39;, &#39;remark&#39;],
  [&#39;说明&#39;, &#39;remark&#39;],
  [&#39;其他&#39;, &#39;remark&#39;],
]);

/** 标题常见的后缀，允许「未完成事项」这种写法 */
const SUFFIXES = [&#39;事项&#39;, &#39;工作&#39;, &#39;内容&#39;, &#39;情况&#39;, &#39;部分&#39;];

/** 标题都很短；太长的行一律当内容，避免把任务名误判成标题 */
const MAX_HEADER_LEN = 10;

function lookupHeader(norm) {
  if (norm.length &gt; MAX_HEADER_LEN) return undefined;
  if (HEADER_MAP.has(norm)) return HEADER_MAP.get(norm);
  for (const s of SUFFIXES) {
    if (norm.length &gt; s.length + 1 &amp;&amp; norm.endsWith(s)) {
      const base = norm.slice(0, -s.length);
      if (HEADER_MAP.has(base)) return HEADER_MAP.get(base);
    }
  }
  return undefined;
}

/** 去掉常见的排版装饰，便于识别标题 */
function normalize(line) {
  return line
    .trim()
    .replace(/^[#&gt;*\-\s]+/, &#39;&#39;) // 井号、引用、星号、短横线
    .replace(/^\d+[.、)）]\s*/, &#39;&#39;) // &#34;1. &#34; / &#34;1、&#34;
    .replace(/[【\[（(]/g, &#39;&#39;)
    .replace(/[】\]）)]/g, &#39;&#39;)
    .replace(/[：:]\s*$/, &#39;&#39;)
    .replace(/\s+/g, &#39;&#39;)
    .trim();
}

/** 去掉条目行前面的项目符号 */
function stripBullet(line) {
  return line
    .trim()
    .replace(/^[-*·•+]\s*/, &#39;&#39;)
    .replace(/^\d+[.、)）]\s*/, &#39;&#39;)
    .trim();
}

const HEADER_LOOKS_LIKE = /^(已完成|未完成|需协调|明日计划|明天计划|备注|计划|进行中)/;

/**
 * @param {string} text
 * @returns {{ draft: object, warnings: string[], sectionsSeen: string[] }}
 */
export function parsePlainText(text, { report_date } = {}) {
  const warnings = [];
  const draft = {
    report_date,
    complete_work: [],
    unfinished_work: [],
    coordinate_work: [],
    tomorrow_plan: [],
    remark: [],
  };

  const sectionsSeen = [];
  let current = null;
  const orphans = [];

  const rawLines = String(text).replace(/\r\n?/g, &#39;\n&#39;).split(&#39;\n&#39;);

  for (const raw of rawLines) {
    const t = raw.trim();
    if (!t) continue;

    // 单独一行「日期 2026-10-14」之类，识别为日期
    const dateMatch = t.match(/^(?:日期|date)\s*[：:]?\s*(\d{4}-\d{2}-\d{2})\s*$/i);
    if (dateMatch) {
      draft.report_date = dateMatch[1];
      continue;
    }
    // 也接受 10.14 / 10/14 这种简写（当年）
    const shortDate = t.match(/^(?:日期|date)\s*[：:]?\s*(\d{1,2})[.\-/](\d{1,2})\s*$/i);
    if (shortDate) {
      const y = new Date().getFullYear();
      draft.report_date = `${y}-${shortDate[1].padStart(2, &#39;0&#39;)}-${shortDate[2].padStart(2, &#39;0&#39;)}`;
      continue;
    }

    const norm = normalize(t);
    const key = lookupHeader(norm);
    if (key) {
      current = key;
      if (!sectionsSeen.includes(key)) sectionsSeen.push(key);
      continue;
    }

    const item = stripBullet(t);
    if (!item) continue;

    if (current) {
      if (!draft[current].includes(item)) draft[current].push(item);
    } else if (HEADER_LOOKS_LIKE.test(norm)) {
      // 看起来像标题但没认出来（比如「未完成事项」），提醒一下
      warnings.push(`这行看着像小标题但没认出来，已当作内容处理：${t}`);
      orphans.push(item);
    } else {
      orphans.push(item);
    }
  }

  // 没有任何小标题 → 全部算「已完成」，并提醒
  if (sectionsSeen.length === 0 &amp;&amp; orphans.length) {
    draft.complete_work = orphans;
    warnings.push(&#39;没找到「已完成 / 未完成」这类小标题，已把全部内容放进「今日已完成工作」。&#39;);
  } else if (orphans.length) {
    draft.complete_work.push(...orphans);
    warnings.push(`有 ${orphans.length} 行在小标题之前，已并入「今日已完成工作」。`);
  }

  return { draft, warnings, sectionsSeen };
}

/** 输入里出现了哪些小标题（给个反馈） */
export function describeSections(keys) {
  const names = {
    complete_work: &#39;今日已完成工作&#39;,
    unfinished_work: &#39;今日未完成工作&#39;,
    coordinate_work: &#39;明日需协调事项&#39;,
    tomorrow_plan: &#39;明日计划&#39;,
    remark: &#39;备注&#39;,
  };
  return keys.map((k) =&gt; names[k] ?? k).join(&#39;、&#39;);
}
</code></pre>
<h4><code>scripts/src/report/expand.mjs</code></h4>
<p>简写 → 项目制成句（扩写引擎）</p>
<pre><code class="language-js">/**
 * 把「简写条目」扩写成公司日报的成句风格。
 *
 * 输入（简写）：  沙利文_10.14AI更新文章 2篇
 * 输出（成句）：  沙利文项目：完成 10.14 AI 主题更新文章 2 篇。
 *
 * 规则来自对历史日报的归纳，见 docs/风格指南.md。
 * 词条表可以随时扩充；没命中的条目会走通用兜底，不会被丢掉。
 */

/** 条目词条表：把简写归一到「动作 + 短语」 */
const ITEM_GLOSSARY = [
  { match: /^头条/, verb: &#39;完成&#39;, phrase: (c) =&gt; `${c.date} 头条更新文章发布` },

  {
    match: /^AI\s*(更新)?文章|^AI\s*主题/,
    verb: &#39;完成&#39;,
    phrase: (c) =&gt; `${c.date} AI 主题更新文章${c.countText ? ` ${c.countText}` : &#39;&#39;}`,
  },

  // 舆情反馈：可能是「反馈」「舆情反馈5条」「舆情提交反馈并跟进反馈情况」
  {
    match: /舆情.*反馈|^反馈|反馈情况/,
    verb: (core) =&gt; (/提交/.test(core) ? &#39;整理并提交&#39; : &#39;整理&#39;),
    phrase: (c) =&gt; `${c.date ? `${c.date} ` : &#39;&#39;}舆情反馈`,
    tail: (c, core) =&gt; {
      const bits = [];
      if (c.countText) bits.push(`共计 ${c.countText}`);
      if (/跟进|跟踪/.test(core)) bits.push(&#39;同时跟进反馈情况&#39;);
      return bits.join(&#39;，&#39;);
    },
  },

  { match: /舆情周报/, verb: &#39;编制并输出&#39;, phrase: (c) =&gt; `${c.date} 舆情周报` },

  // 通用周报：沙利文GEO周报、沙利文周报、某某周报…（历史习惯是「编制并输出…」+ 归档收尾）
  { match: /周报/, verb: &#39;编制并输出&#39;, phrase: (c) =&gt; `${c.date} ${c.item}` },

  { match: /关键词排名|排名查询|^排名$/, verb: &#39;完成&#39;, phrase: (c) =&gt; `${c.date} 关键词排名查询` },
  { match: /^月报/, verb: &#39;更新&#39;, phrase: (c) =&gt; `${c.date} 月报` },
  { match: /^官网更新文章/, verb: &#39;完成&#39;, phrase: () =&gt; &#39;官网文章更新&#39; },
  { match: /^官网\s*AI\s*文章/, verb: &#39;完成&#39;, phrase: () =&gt; &#39;官网 AI 文章发布&#39; },
  { match: /^达人资源|^博主资源|房产博主/, verb: &#39;拓展&#39;, phrase: (c) =&gt; `${c.item}` },
  { match: /季度报告|^周报$/, verb: &#39;编制并输出&#39;, phrase: (c) =&gt; `${c.date} ${c.item}` },
];

/** 括号里的补充说明 → 成句里的从句 */
const NOTE_GLOSSARY = [
  { match: /公众|公众号/, clause: &#39;同时将公众号稿件同步至头条平台&#39; },
  { match: /同步/, clause: &#39;相关稿件已同步归档&#39; },
];

/** 报告类事项的收尾语 */
const TAIL_CLAUSE = &#39;相关文档整理归档&#39;;

/** 拆出「项目_日期」前缀；没写日期的带项目条目会用报告日期兜底 */
function splitPrefix(line, defaultDate) {
  const withDate = line.match(/^([^_（）()]{1,12})_(\d{1,2}[.\-/]\d{1,2})\s*(.*)$/);
  if (withDate) {
    return {
      project: withDate[1].trim(),
      date: withDate[2].replace(/[/-]/g, &#39;.&#39;),
      item: withDate[3].trim(),
    };
  }
  const withProject = line.match(/^([^_（）()]{1,12})_(.+)$/);
  if (withProject) {
    return { project: withProject[1].trim(), date: defaultDate ?? &#39;&#39;, item: withProject[2].trim() };
  }
  return { project: &#39;&#39;, date: &#39;&#39;, item: line };
}

/** 从条目里剥出数量和括号备注 */
function splitDecorations(item) {
  let note = &#39;&#39;;
  const noteMatch = item.match(/[（(]([^）)]+)[）)]/);
  if (noteMatch) {
    note = noteMatch[1].trim();
    item = item.replace(noteMatch[0], &#39;&#39;).trim();
  }

  let countText = &#39;&#39;;
  const countMatch = item.match(/\s*(\d+)\s*([篇条份个项])$/);
  if (countMatch) {
    // 历史习惯是「2 篇」「10 条」，数字和单位之间留空格
    countText = `${countMatch[1]} ${countMatch[2]}`;
    item = item.slice(0, countMatch.index).trim();
  }

  return { item, countText, note };
}

/** 单条 → { project, verb, phrase, noteClause, tailClause } */
function toClause(raw, defaultDate) {
  const { project, date, item } = splitPrefix(raw, defaultDate);
  const { item: core, countText, note } = splitDecorations(item);

  const ctx = { date, item: core, countText };
  let verb = &#39;完成&#39;;
  let phrase = `${date ? `${date} ` : &#39;&#39;}${core}${countText ? ` ${countText}` : &#39;&#39;}`;
  let tailClause = &#39;&#39;;

  for (const g of ITEM_GLOSSARY) {
    if (g.match.test(core)) {
      verb = typeof g.verb === &#39;function&#39; ? g.verb(core, ctx) : g.verb;
      phrase = g.phrase(ctx);
      if (g.tail) tailClause = g.tail(ctx, core);
      break;
    }
  }

  let noteClause = &#39;&#39;;
  if (note) {
    for (const n of NOTE_GLOSSARY) {
      if (n.match.test(note)) {
        noteClause = n.clause;
        break;
      }
    }
    if (!noteClause) noteClause = note;
  }

  return { project, verb, phrase, noteClause, tailClause };
}

/** 动词和短语之间的空格：只在短语以数字开头时留（「完成 10.14 …」），中文直接相连 */
function joinVerb(verb, phrase) {
  if (!phrase) return verb;
  return /^\d/.test(phrase) ? `${verb} ${phrase}` : `${verb}${phrase}`;
}

/**
 * @param {string[]} lines 简写条目
 * @param {{ defaultDate?: string }} opts defaultDate 形如 &#34;10.14&#34;
 * @returns {{ html: string, sentences: string[] }}
 */
export function expandToProse(lines, { defaultDate = &#39;&#39; } = {}) {
  const clauses = lines.map((l) =&gt; toClause(l, defaultDate)).filter((c) =&gt; c.phrase);

  const groups = [];
  for (const c of clauses) {
    const last = groups[groups.length - 1];
    if (c.project &amp;&amp; last &amp;&amp; last.project === c.project) last.items.push(c);
    else groups.push({ project: c.project, items: [c] });
  }

  const sentences = groups.map((g) =&gt; {
    const parts = g.items.map((it) =&gt; joinVerb(it.verb, it.phrase));
    for (const it of g.items) {
      if (it.tailClause) parts.push(it.tailClause);
      if (it.noteClause) parts.push(it.noteClause);
    }

    // 报告类（周报/月报/季度报告）历史习惯补一句归档收尾
    const isReport = g.items.some((it) =&gt; it.verb === &#39;编制并输出&#39;);
    const hasExtra = g.items.some((it) =&gt; it.noteClause || it.tailClause);
    if (isReport &amp;&amp; !hasExtra) parts.push(TAIL_CLAUSE);

    const body = parts.join(&#39;，&#39;);
    // 有项目的加「X项目：」前缀
    const text = g.project ? `${g.project}项目：${body}` : body;
    return text.replace(/[。；;]+$/, &#39;&#39;) + &#39;。&#39;;
  });

  const html = sentences.length === 0 ? &#39;&#39; : `&lt;ol&gt;${sentences.map((s) =&gt; `&lt;li&gt;${s}&lt;/li&gt;`).join(&#39;&#39;)}&lt;/ol&gt;`;

  return { html, sentences };
}

export { TAIL_CLAUSE };
</code></pre>
<h4><code>scripts/src/report/render.mjs</code></h4>
<p>草稿 → 富文本 HTML</p>
<pre><code class="language-js">/** 日报五个板块的字段定义（界面标签 → 接口字段名） */
export const SECTIONS = [
  { key: &#39;complete_work&#39;, label: &#39;今日已完成工作&#39; },
  { key: &#39;unfinished_work&#39;, label: &#39;今日未完成工作&#39; },
  { key: &#39;coordinate_work&#39;, label: &#39;明日需协调事项&#39; },
  { key: &#39;tomorrow_plan&#39;, label: &#39;明日计划&#39; },
  { key: &#39;remark&#39;, label: &#39;备注&#39; },
];

const ESC = { &#39;&amp;&#39;: &#39;&amp;amp;&#39;, &#39;&lt;&#39;: &#39;&amp;lt;&#39;, &#39;&gt;&#39;: &#39;&amp;gt;&#39; };

function escapeHtml(s) {
  return String(s).replace(/[&amp;&lt;&gt;]/g, (c) =&gt; ESC[c]);
}

/**
 * 把草稿里的一段内容渲染成编辑器能吃的 HTML。
 * - 已经是 HTML 片段（以 &lt; 开头）→ 原样返回
 * - 字符串数组 → &lt;ul&gt;&lt;li&gt;…
 * - 单个字符串 → &lt;p&gt;…
 * - 空 → &#39;&#39;
 */
export function toHtml(value) {
  if (value === null || value === undefined) return &#39;&#39;;

  if (Array.isArray(value)) {
    const items = value
      .map((v) =&gt; String(v ?? &#39;&#39;).trim())
      .filter(Boolean)
      .flatMap((v) =&gt; v.split(&#39;\n&#39;).map((x) =&gt; x.trim()).filter(Boolean));

    if (items.length === 0) return &#39;&#39;;
    if (items.length === 1) return `&lt;p&gt;${escapeHtml(items[0])}&lt;/p&gt;`;
    return `&lt;ul&gt;${items.map((i) =&gt; `&lt;li&gt;${escapeHtml(i)}&lt;/li&gt;`).join(&#39;&#39;)}&lt;/ul&gt;`;
  }

  const text = String(value).trim();
  if (!text) return &#39;&#39;;
  if (text.startsWith(&#39;&lt;&#39;)) return text; // 已经是 HTML

  const lines = text.split(&#39;\n&#39;).map((l) =&gt; l.trim()).filter(Boolean);
  if (lines.length === 1) return `&lt;p&gt;${escapeHtml(lines[0])}&lt;/p&gt;`;
  return `&lt;ul&gt;${lines.map((l) =&gt; `&lt;li&gt;${escapeHtml(l)}&lt;/li&gt;`).join(&#39;&#39;)}&lt;/ul&gt;`;
}

/** 站点约定的「空内容」表示（不是空字符串） */
export const EMPTY_HTML = &#39;&lt;p&gt;&lt;br&gt;&lt;/p&gt;&#39;;

/** 草稿对象 → 提交载荷 */
export function buildPayload(draft, { type, report_date }) {
  const payload = {
    report_id: draft.report_id || &#39;&#39;,
    type: Number(draft.type ?? type),
    report_date: draft.report_date || report_date,
  };
  for (const s of SECTIONS) {
    payload[s.key] = toHtml(draft[s.key]) || EMPTY_HTML;
  }
  return payload;
}

/** HTML → 给人看的纯文本预览 */
export function htmlToText(html) {
  if (!html) return &#39;&#39;;
  return html
    .replace(/&lt;\/(p|li|ul|ol|div|h[1-6])&gt;/gi, &#39;\n&#39;)
    .replace(/&lt;br\s*\/?&gt;/gi, &#39;\n&#39;)
    .replace(/&lt;[^&gt;]+&gt;/g, &#39;&#39;)
    .replace(/&amp;amp;/g, &#39;&amp;&#39;)
    .replace(/&amp;lt;/g, &#39;&lt;&#39;)
    .replace(/&amp;gt;/g, &#39;&gt;&#39;)
    .replace(/&amp;nbsp;/g, &#39; &#39;)
    .split(&#39;\n&#39;)
    .map((l) =&gt; l.trim())
    .filter(Boolean)
    .join(&#39;\n&#39;);
}

/** 校验草稿，返回问题列表 */
export function validateDraft(draft, date) {
  const problems = [];
  if (!draft || typeof draft !== &#39;object&#39;) {
    problems.push(&#39;草稿不是对象&#39;);
    return problems;
  }
  const d = draft.report_date || date;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(d))) problems.push(`report_date 格式不对：${d}`);

  const filled = SECTIONS.filter((s) =&gt; toHtml(draft[s.key]) !== &#39;&#39;);
  if (filled.length === 0) problems.push(&#39;五个板块全是空的，没有内容可提交&#39;);

  return problems;
}
</code></pre>
<h4><code>scripts/src/report/client.mjs</code></h4>
<p>火云台 API 客户端</p>
<pre><code class="language-js">import fs from &#39;node:fs&#39;;
import path from &#39;node:path&#39;;
import crypto from &#39;node:crypto&#39;;
import { ROOT } from &#39;../config.mjs&#39;;

const API_BASE = &#39;https://app-api.suwork.com&#39;;
const CACHE_FILE = path.join(ROOT, &#39;.cache&#39;, &#39;token.json&#39;);

const UA =
  &#39;Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36&#39;;

function fp(phone) {
  return crypto.createHash(&#39;sha256&#39;).update(String(phone)).digest(&#39;hex&#39;).slice(0, 16);
}

function readCache(phone) {
  try {
    const j = JSON.parse(fs.readFileSync(CACHE_FILE, &#39;utf8&#39;));
    if (j.fp === fp(phone) &amp;&amp; j.token) return j.token;
  } catch {}
  return null;
}

function writeCache(phone, token) {
  fs.mkdirSync(path.dirname(CACHE_FILE), { recursive: true });
  fs.writeFileSync(CACHE_FILE, JSON.stringify({ fp: fp(phone), token }, null, 2), &#39;utf8&#39;);
}

function clearCache() {
  try {
    fs.rmSync(CACHE_FILE, { force: true });
  } catch {}
}

async function request(method, apiPath, { token, query, body } = {}) {
  let url = API_BASE + apiPath;
  if (query) {
    const qs = new URLSearchParams();
    for (const [k, v] of Object.entries(query)) qs.set(k, String(v ?? &#39;&#39;));
    url += `?${qs}`;
  }

  const headers = {
    accept: &#39;application/json, text/plain, */*&#39;,
    &#39;content-type&#39;: &#39;application/json&#39;,
    origin: &#39;https://www.huoyuntai.com&#39;,
    referer: &#39;https://www.huoyuntai.com/&#39;,
    &#39;user-agent&#39;: UA,
  };
  if (token) headers.authorization = `Bearer ${token}`;

  const res = await fetch(url, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error(`接口 ${apiPath} 返回了非 JSON 内容（HTTP ${res.status}）：${text.slice(0, 300)}`);
  }
  return json;
}

/**
 * 登录并返回 token。登录响应结构：{ code: 0, data: { token, version } }
 */
async function login(user_phone, user_pwd, log) {
  log?.(`登录中（${user_phone.slice(0, 3)}****${user_phone.slice(-4)}）…`);
  const r = await request(&#39;POST&#39;, &#39;/api/Login/login&#39;, { body: { user_phone, user_pwd } });

  if (r.code !== 0 || !r.data?.token) {
    throw new Error(`登录失败：${r.msg || JSON.stringify(r).slice(0, 200)}`);
  }
  return r.data.token;
}

export function createReportClient({ user_phone, user_pwd, log = () =&gt; {} }) {
  let token = readCache(user_phone);

  async function withToken(method, apiPath, opts = {}, retried = false) {
    if (!token) token = await login(user_phone, user_pwd, log);

    const r = await request(method, apiPath, { ...opts, token });

    // 会话失效：清缓存重登一次
    if (r.code === 403 &amp;&amp; !retried) {
      log(`会话已失效（${r.msg || &#39;403&#39;}），重新登录…`);
      clearCache();
      token = await login(user_phone, user_pwd, log);
      return withToken(method, apiPath, opts, true);
    }

    if (r.code !== 0) {
      throw new Error(`接口 ${apiPath} 失败：${r.msg || JSON.stringify(r).slice(0, 200)}`);
    }
    return r;
  }

  return {
    /** 判断登录态是否可用 */
    async verify() {
      const r = await withToken(&#39;GET&#39;, &#39;/api/user/getUserInfo&#39;, {});
      return r.data;
    },

    /** 查询某天是否已有报告（原始返回，调试用） */
    async rawReportInfo({ report_date, type }) {
      return withToken(&#39;GET&#39;, &#39;/api/UserReport/getUserReportInfo&#39;, {
        query: { report_id: &#39;&#39;, type, report_date },
      });
    },

    /** 查询某天是否已有报告 */
    async getReportInfo({ report_date, type }) {
      const r = await withToken(&#39;GET&#39;, &#39;/api/UserReport/getUserReportInfo&#39;, {
        query: { report_id: &#39;&#39;, type, report_date },
      });
      const d = r.data;
      // 接口可能返回 {} 或 [] 或 null 表示没有
      if (!d || (Array.isArray(d) &amp;&amp; d.length === 0)) return null;
      if (typeof d === &#39;object&#39; &amp;&amp; !d.report_id &amp;&amp; !d.id) return null;
      return d;
    },

    async addReport(payload) {
      return withToken(&#39;POST&#39;, &#39;/api/UserReport/addUserReport&#39;, { body: payload });
    },

    async editReport(payload) {
      return withToken(&#39;POST&#39;, &#39;/api/UserReport/editUserReport&#39;, { body: payload });
    },
  };
}
</code></pre>
<h4><code>scripts/src/siyuan/client.mjs</code></h4>
<p>思源笔记 API 客户端</p>
<pre><code class="language-js">/**
 * 思源笔记（SiYuan）API 客户端。
 *
 * 鉴权：请求头 `Authorization: Token &lt;API token&gt;`
 * token 在思源里「设置 → 关于 → API token」。
 *
 * 用到的接口：
 *   POST /api/system/version              版本（免鉴权，用来探连通性）
 *   POST /api/notebook/lsNotebooks        笔记本列表
 *   POST /api/query/sql                   SQL 查询（找文档）
 *   POST /api/filetree/createDocWithMd    新建文档（path = hpath，markdown 正文）
 *   POST /api/block/updateBlock          覆盖已有文档内容
 *   POST /api/filetree/removeDoc         删除文档（回滚/清理用）
 */

export function normalizeUrl(url) {
  return String(url ?? &#39;&#39;).trim().replace(/\/+$/, &#39;&#39;);
}

export function createSiYuanClient({ url, token, log = () =&gt; {} }) {
  const base = normalizeUrl(url);
  if (!base) throw new Error(&#39;思源地址没填（config.json 的 siyuan.url）&#39;);
  if (!token || String(token).includes(&#39;填&#39;)) {
    throw new Error(&#39;思源 API token 没填（config.json 的 siyuan.token）&#39;);
  }

  async function call(apiPath, body = {}, { timeoutMs = 20000 } = {}) {
    const ctrl = new AbortController();
    const timer = setTimeout(() =&gt; ctrl.abort(), timeoutMs);
    let res;
    try {
      res = await fetch(base + apiPath, {
        method: &#39;POST&#39;,
        signal: ctrl.signal,
        headers: {
          &#39;content-type&#39;: &#39;application/json&#39;,
          authorization: `Token ${token}`,
        },
        body: JSON.stringify(body),
      });
    } catch (e) {
      throw new Error(`连不上思源 ${base}（${e.message}）`);
    } finally {
      clearTimeout(timer);
    }

    const text = await res.text();
    let json;
    try {
      json = JSON.parse(text);
    } catch {
      throw new Error(`思源 ${apiPath} 返回非 JSON（HTTP ${res.status}）：${text.slice(0, 200)}`);
    }

    if (json.code !== 0) {
      const hint =
        json.code === -1 &amp;&amp; /auth/i.test(json.msg ?? &#39;&#39;)
          ? &#39;（API token 不对，或思源没开 API）&#39;
          : &#39;&#39;;
      throw new Error(`思源 ${apiPath} 失败：${json.msg || JSON.stringify(json)}${hint}`);
    }
    return json.data;
  }

  return {
    /** 探连通性 + 版本（不需要 token） */
    async version() {
      const r = await fetch(`${base}/api/system/version`, {
        method: &#39;POST&#39;,
        headers: { &#39;content-type&#39;: &#39;application/json&#39; },
        body: &#39;{}&#39;,
      });
      const j = await r.json();
      return j.data ?? null;
    },

    /** 笔记本列表 */
    async listNotebooks() {
      const d = await call(&#39;/api/notebook/lsNotebooks&#39;);
      return d?.notebooks ?? [];
    },

    /** 执行 SQL，返回行数组 */
    async sql(stmt) {
      return (await call(&#39;/api/query/sql&#39;, { stmt })) ?? [];
    },

    /** 新建文档，path 是 hpath（如 /工作日志/2026-10-19），返回 docId */
    async createDocWithMd({ notebook, path: docPath, markdown }) {
      return await call(&#39;/api/filetree/createDocWithMd&#39;, {
        notebook,
        path: docPath,
        markdown,
      });
    },

    /** 覆盖某个块（文档根块 id 就是 docId）的内容 */
    async updateBlock({ id, markdown }) {
      return await call(&#39;/api/block/updateBlock&#39;, {
        id,
        dataType: &#39;markdown&#39;,
        data: markdown,
      });
    },

    /** 往某个块（通常是文档根块）末尾追加 Markdown 内容 */
    async appendBlock({ parentID, markdown }) {
      return await call(&#39;/api/block/appendBlock&#39;, {
        parentID,
        dataType: &#39;markdown&#39;,
        data: markdown,
      });
    },

    /** 在某个块之后插入 Markdown 内容 */
    async insertBlock({ previousID, markdown }) {
      return await call(&#39;/api/block/insertBlock&#39;, {
        previousID,
        dataType: &#39;markdown&#39;,
        data: markdown,
      });
    },

    /** 删除一个块 */
    async deleteBlock({ id }) {
      return await call(&#39;/api/block/deleteBlock&#39;, { id });
    },

    /** 删除文档 */
    async removeDoc({ notebook, path: docPath }) {
      return await call(&#39;/api/filetree/removeDoc&#39;, { notebook, path: docPath });
    },
  };
}
</code></pre>
<h4><code>scripts/src/siyuan/publish.mjs</code></h4>
<p>日报 → 思源文档（目录结构、幂等、回查、周编号）</p>
<pre><code class="language-js">/**
 * 把日报发布到思源笔记。
 *
 * 目标形态：在指定笔记本里，名为「工作日志」的文档下面，
 * 每天建一篇标题是日期的文档，内容是五段日报的 Markdown。
 *
 * 幂等：当天已有同名文档就覆盖内容，不会重复创建。
 */
import { createSiYuanClient } from &#39;./client.mjs&#39;;

/** 日报五段 → 思源里的二级标题 */
const SECTION_TITLES = [
  [&#39;complete_work&#39;, &#39;今日已完成工作&#39;],
  [&#39;unfinished_work&#39;, &#39;今日未完成工作&#39;],
  [&#39;coordinate_work&#39;, &#39;明日需协调事项&#39;],
  [&#39;tomorrow_plan&#39;, &#39;明日计划&#39;],
  [&#39;remark&#39;, &#39;备注&#39;],
];

/** 把日报的富文本 HTML 转成 Markdown（只处理我们自己生成的这几种结构） */
export function htmlToMarkdown(html) {
  if (!html || !String(html).trim()) return &#39;&#39;;

  let s = String(html);
  const isOrdered = /&lt;ol[\s&gt;]/i.test(s);

  // 列表项
  let n = 0;
  s = s.replace(/&lt;li[^&gt;]*&gt;([\s\S]*?)&lt;\/li&gt;/gi, (_m, inner) =&gt; {
    const text = stripInline(inner);
    if (!text) return &#39;&#39;;
    return isOrdered ? `${++n}. ${text}\n` : `- ${text}\n`;
  });

  // 段落
  s = s.replace(/&lt;p[^&gt;]*&gt;([\s\S]*?)&lt;\/p&gt;/gi, (_m, inner) =&gt; {
    const text = stripInline(inner);
    return text ? `${text}\n\n` : &#39;&#39;;
  });

  // 剩下的容器标签
  s = s.replace(/&lt;\/?(ol|ul)[^&gt;]*&gt;/gi, &#39;&#39;);
  s = s.replace(/&lt;br\s*\/?&gt;/gi, &#39;\n&#39;);
  s = stripInline(s);

  return s
    .split(&#39;\n&#39;)
    .map((l) =&gt; l.replace(/\s+$/, &#39;&#39;))
    .join(&#39;\n&#39;)
    .replace(/\n{3,}/g, &#39;\n\n&#39;)
    .trim();
}

function stripInline(s) {
  return String(s)
    .replace(/&lt;[^&gt;]+&gt;/g, &#39;&#39;)
    .replace(/&amp;nbsp;/g, &#39; &#39;)
    .replace(/&amp;lt;/g, &#39;&lt;&#39;)
    .replace(/&amp;gt;/g, &#39;&gt;&#39;)
    .replace(/&amp;amp;/g, &#39;&amp;&#39;)
    .trim();
}

/** 日报载荷 → 思源文档正文 */
export function buildMarkdown(payload) {
  const blocks = [];
  for (const [key, title] of SECTION_TITLES) {
    const md = htmlToMarkdown(payload[key]);
    if (!md) continue;
    blocks.push(`## ${title}\n\n${md}`);
  }
  return blocks.length ? `${blocks.join(&#39;\n\n&#39;)}\n` : &#39;&#39;;
}

/** SQL 字符串转义 */
function q(s) {
  return String(s).replace(/&#39;/g, &#34;&#39;&#39;&#34;);
}

/**
 * 某天是该月的第几周（1 起），含 1 号的那一周算第 1 周。
 * 和思源「日记」笔记本的 `第N周` 编号口径一致。
 */
export function weekOfMonth(date) {
  const dt = new Date(`${date}T00:00:00`);
  if (Number.isNaN(dt.getTime())) return 1;
  const first = new Date(dt.getFullYear(), dt.getMonth(), 1);
  const offset = (first.getDay() + 6) % 7; // 1 号是周几，周一 = 0
  return Math.floor((dt.getDate() - 1 + offset) / 7) + 1;
}

/**
 * 按模板生成父文档下的子路径。
 * 占位符：{year} {month} {week} {date} {day}
 *   &#39;{year}/{month}/{date}&#39;            → 2026/10/2026-10-19
 *   &#39;{year}/{month}/第{week}周/{date}&#39;  → 2026/10/第4周/2026-10-19
 *   &#39;{date}&#39;                           → 2026-10-19（平铺）
 */
export function renderPathPattern(pattern, date) {
  const [y = &#39;&#39;, m = &#39;&#39;, d = &#39;&#39;] = String(date).split(&#39;-&#39;);
  return String(pattern)
    .replace(/\{year\}/g, y)
    .replace(/\{month\}/g, m)
    .replace(/\{week\}/g, String(weekOfMonth(date)))
    .replace(/\{date\}/g, date)
    .replace(/\{day\}/g, d)
    .split(&#39;/&#39;)
    .map((seg) =&gt; seg.trim())
    .filter(Boolean)
    .join(&#39;/&#39;);
}

/** 找到「工作日志」这个父文档的 hpath；找不到就返回空串（建在笔记本根） */
async function resolveParentHPath(client, notebook, parentDoc) {
  if (!parentDoc) return &#39;&#39;;

  const byTitle = await client.sql(
    `SELECT id, hpath, content FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39; AND content=&#39;${q(parentDoc)}&#39; LIMIT 5`,
  );
  if (byTitle?.length) return byTitle[0].hpath;

  const byPath = await client.sql(
    `SELECT id, hpath FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39; AND hpath LIKE &#39;%/${q(parentDoc)}&#39; LIMIT 5`,
  );
  if (byPath?.length) return byPath[0].hpath;

  return null; // 明确表示「没找到父文档」
}

/** 按 hpath 找现有文档（同时取到存储 path，removeDoc 需要它） */
async function findDocByHPath(client, notebook, hpath) {
  const rows = await client.sql(
    `SELECT id, hpath, path FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39; AND hpath=&#39;${q(hpath)}&#39; LIMIT 1`,
  );
  return rows?.[0] ?? null;
}

/**
 * 发布当天日报到思源。
 *
 * @returns {{ action:&#39;create&#39;|&#39;update&#39;, docId:string, hpath:string, markdown:string, warnings:string[] }}
 */
export async function publishToSiYuan(siyuanConfig, payload, { log = () =&gt; {}, dryRun = false } = {}) {
  const { url, token, notebook, parentDoc = &#39;工作日志&#39; } = siyuanConfig ?? {};

  if (!notebook || String(notebook).includes(&#39;填&#39;)) {
    throw new Error(&#39;思源笔记本 ID 没填（config.json 的 siyuan.notebook）&#39;);
  }

  const markdown = buildMarkdown(payload);
  if (!markdown.trim()) throw new Error(&#39;日报内容为空，没什么可发的&#39;);

  const client = createSiYuanClient({ url, token, log });
  const warnings = [];

  // 1. 确认笔记本存在
  const notebooks = await client.listNotebooks();
  const nb = notebooks.find((x) =&gt; x.id === notebook);
  if (!nb) {
    const names = notebooks.map((x) =&gt; `${x.name}(${x.id})`).join(&#39;、&#39;) || &#39;(无)&#39;;
    throw new Error(`思源里找不到笔记本 ${notebook}。现有的：${names}`);
  }
  if (nb.closed) warnings.push(`笔记本「${nb.name}」当前是关闭状态，写完可能看不到内容`);
  log(`笔记本：${nb.name}`);

  // 2. 定位父文档，算出目标 hpath
  // 目录结构由 pathPattern 决定，默认 年份/月份/日期 → /工作日志/2026/10/2026-10-19
  const parentHPath = await resolveParentHPath(client, notebook, parentDoc);
  const pattern = siyuanConfig?.pathPattern || &#39;{year}/{month}/{date}&#39;;
  const subPath = renderPathPattern(pattern, payload.report_date);
  const base = parentHPath ?? &#39;&#39;;
  if (parentHPath === null &amp;&amp; parentDoc) {
    warnings.push(`没找到名为「${parentDoc}」的文档，将建在笔记本根目录`);
  }
  const hpath = `${base}/${subPath}`;
  log(`目标文档：${nb.name}${hpath}`);

  // 3. 已存在就重建，否则新建
  // 注意：文档块的 content 是「标题」，正文在子块里，所以 updateBlock 换不掉正文。
  // 这里用「删掉重建」来保证内容整体替换（日报是整篇重写，不需要保留块 id）。
  const existing = await findDocByHPath(client, notebook, hpath);
  const action = existing ? &#39;update&#39; : &#39;create&#39;;

  if (dryRun) {
    return { action, docId: existing?.id ?? &#39;(将新建)&#39;, hpath, markdown, warnings };
  }

  if (existing) {
    // removeDoc 要的是存储路径（/笔记本ID/文档ID.sy），不是 hpath
    await client.removeDoc({ notebook, path: existing.path });
    log(`已删除旧文档 ${existing.id}（稍后重建）`);
  }

  const created = await client.createDocWithMd({ notebook, path: hpath, markdown });

  // 返回值可能是字符串（旧版）或对象 {id, hPath, ...}（新版）
  const createdId = typeof created === &#39;string&#39; ? created : created?.id;
  const createdHPath = typeof created === &#39;object&#39; &amp;&amp; created ? created.hPath : null;

  if (!createdId) throw new Error(&#39;思源没有返回新文档 id，创建可能失败&#39;);

  if (createdHPath &amp;&amp; createdHPath !== hpath) {
    // 落地位置和预期不一致 —— 清掉误建的，明确报错，不要留下脏数据
    warnings.push(`文档实际建在 ${createdHPath}，与预期的 ${hpath} 不一致`);
    try {
      await client.removeDoc({ notebook, path: createdHPath });
      warnings.push(&#39;已删除建错位置的文档&#39;);
    } catch {
      warnings.push(&#39;清理建错的文档失败，请手动检查&#39;);
    }
    throw new Error(`思源文档落点不对：期望 ${hpath}，实际 ${createdHPath}`);
  }

  log(`${action === &#39;create&#39; ? &#39;已新建&#39; : &#39;已重建&#39;}文档 ${createdId}`);

  // 4. 回查确认
  // 注意：思源建完文档后 SQL 索引有延迟，立刻查常常查不到（文档其实已经写好了）。
  // 所以这里重试几次，仍查不到只当作警告，不当失败。
  let check = null;
  for (let i = 0; i &lt; 6 &amp;&amp; !check; i++) {
    await new Promise((r) =&gt; setTimeout(r, 250 * (i + 1)));
    try {
      check = await findDocByHPath(client, notebook, hpath);
    } catch {
      // 单次查询失败忽略，继续重试
    }
  }

  if (!check) {
    warnings.push(&#39;思源的 SQL 索引尚未更新，暂时回查不到这篇（文档通常已建好，稍后刷新即可）&#39;);
    return { action, docId: createdId, hpath, markdown, warnings };
  }

  return { action, docId: check.id, hpath, markdown, warnings };
}

/**
 * 重建父文档里的「最近日志」链接列表。
 *
 * 为什么不用思源的嵌入块：嵌入块会把命中的**块本身**原样嵌进来，
 * 查文档块（type=&#39;d&#39;）等于把整篇日报全文嵌进页面，不是目录该有的样子。
 * 所以这里改成「手写链接列表 + 自动化维护」：
 *   - 只重写 indexHeading 那一节（到下一个同级或更高级标题为止）
 *   - 其余内容（说明、项目表、每月复盘）一律不动
 *
 * @returns {{ count:number, heading:string, created:boolean }}
 */
export async function rebuildIndex(siyuanConfig, { log = () =&gt; {}, limit = 30, dryRun = false } = {}) {
  const {
    url,
    token,
    notebook,
    parentDoc = &#39;工作日志&#39;,
    indexHeading = &#39;最近日志&#39;,
  } = siyuanConfig ?? {};

  const client = createSiYuanClient({ url, token, log });

  // 1. 父文档
  const parents = await client.sql(
    `SELECT id, hpath, path FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39; AND content=&#39;${q(parentDoc)}&#39; LIMIT 1`,
  );
  const parent = parents?.[0];
  if (!parent) throw new Error(`找不到「${parentDoc}」文档，无法维护索引`);

  // 2. 现有日期文档（新到旧）
  const rows = await client.sql(
    `SELECT content FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39;` +
      ` AND hpath LIKE &#39;${q(parent.hpath)}/%&#39; AND content LIKE &#39;____-__-__&#39;` +
      ` ORDER BY content DESC LIMIT ${Number(limit) || 30}`,
  );
  const dates = rows.map((r) =&gt; r.content);
  const listMd = dates.length ? dates.map((d) =&gt; `- [[${d}]]`).join(&#39;\n&#39;) : &#39;- （还没有日志）&#39;;

  // 3. 找到 indexHeading 那一节
  const blocks = await client.sql(
    `SELECT id, type, content, sort FROM blocks WHERE root_id=&#39;${q(parent.id)}&#39; AND type!=&#39;d&#39; ORDER BY sort`,
  );
  const headIdx = blocks.findIndex(
    (b) =&gt; b.type === &#39;h&#39; &amp;&amp; String(b.content ?? &#39;&#39;).trim() === indexHeading,
  );

  if (headIdx === -1) {
    // 没有这一节 → 在文档末尾补一个标题 + 列表
    if (dryRun) return { count: dates.length, heading: indexHeading, created: true };
    await client.appendBlock({
      parentID: parent.id,
      markdown: `## ${indexHeading}\n\n${listMd}\n`,
    });
    log(`已补建「${indexHeading}」小节（${dates.length} 条）`);
    return { count: dates.length, heading: indexHeading, created: true };
  }

  const head = blocks[headIdx];
  const headLevel = String(head.subtype ?? &#39;h2&#39;).replace(&#39;h&#39;, &#39;&#39;) || &#39;2&#39;;

  // 这一节的范围：标题之后，到下一个「同级或更高级」标题为止
  const tail = [];
  for (let i = headIdx + 1; i &lt; blocks.length; i++) {
    const b = blocks[i];
    if (b.type === &#39;h&#39;) {
      const lvl = String(b.subtype ?? &#39;h2&#39;).replace(&#39;h&#39;, &#39;&#39;) || &#39;2&#39;;
      if (Number(lvl) &lt;= Number(headLevel)) break; // 遇到同级/上级标题，本节结束
    }
    tail.push(b);
  }

  if (dryRun) return { count: dates.length, heading: indexHeading, created: false };

  // 4. 删掉旧列表块，再把新列表插到标题后面
  for (const b of tail) {
    await client.deleteBlock({ id: b.id });
  }

  await client.insertBlock({ previousID: head.id, markdown: listMd });

  log(`「${indexHeading}」已重建：${dates.length} 条`);
  return { count: dates.length, heading: indexHeading, created: false };
}
</code></pre>
<h3>9.2 外围脚本</h3>
<h4><code>scripts/tools/is-workday.mjs</code></h4>
<p>命令行查某天算不算工作日，可列出未来排班</p>
<pre><code class="language-js">/**
 * 判断某天是不是工作日（单双休轮换）。
 *
 * 用法：
 *   node is-workday.mjs                  # 今天
 *   node is-workday.mjs --date 2026-10-24
 *   node is-workday.mjs --days 14        # 列出今天起 14 天的排班（人看）
 *
 * 单日输出一行 JSON：{&#34;date&#34;:&#34;2026-10-24&#34;,&#34;workday&#34;:true,&#34;reason&#34;:&#34;单休周的周六（要上班）&#34;}
 * 永远退出码 0，判断结果放在 JSON 里。
 */
import { isWorkday, loadSchedule, weekIndex } from &#39;../src/calendar.mjs&#39;;

function arg(name) {
  const i = process.argv.indexOf(name);
  return i !== -1 &amp;&amp; process.argv[i + 1] ? process.argv[i + 1] : null;
}

function fmt(d) {
  const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

const schedule = loadSchedule();
const days = Number(arg(&#39;--days&#39;) || 0);

if (days &gt; 0) {
  console.log(`排班表（锚点周 ${schedule.anchorWeek}，${schedule.anchorIsDouble ? &#39;双休&#39; : &#39;单休&#39;}）\n`);
  const base = new Date(`${arg(&#39;--date&#39;) || fmt(new Date())}T00:00:00`);
  const NAME = [&#39;日&#39;, &#39;一&#39;, &#39;二&#39;, &#39;三&#39;, &#39;四&#39;, &#39;五&#39;, &#39;六&#39;];
  for (let i = 0; i &lt; days; i++) {
    const d = new Date(base);
    d.setDate(d.getDate() + i);
    const ds = fmt(d);
    const r = isWorkday(ds, schedule);
    const idx = weekIndex(ds, schedule.anchorWeek);
    console.log(
      `  ${ds}  周${NAME[d.getDay()]}  第${String(idx).padStart(3)}周  ${r.workday ? &#39;上班&#39; : &#39;休息&#39;}   ${r.reason}`,
    );
  }
  process.exit(0);
}

const date = arg(&#39;--date&#39;) || fmt(new Date());
const r = isWorkday(date, schedule);
process.stdout.write(JSON.stringify({ date, workday: r.workday, reason: r.reason, weekType: r.weekType ?? null }) + &#39;\n&#39;);
process.exit(0);
</code></pre>
<h4><code>scripts/tools/check-status.mjs</code></h4>
<p>查某天日报写没写，输出 JSON，供通知脚本判断</p>
<pre><code class="language-js">/**
 * 检查某天的日报写没写，输出机器可读的 JSON，供 remind.ps1 判断要不要弹通知。
 *
 * 用法：node check-status.mjs [--home &lt;工作区&gt;] [--date YYYY-MM-DD]
 *
 * 输出（stdout 一行 JSON）：
 *   {&#34;ok&#34;:true, &#34;date&#34;:&#34;2026-10-14&#34;, &#34;filed&#34;:false, &#34;reportId&#34;:113793, &#34;error&#34;:null}
 *   {&#34;ok&#34;:false,&#34;date&#34;:&#34;2026-10-14&#34;, &#34;filed&#34;:null,  &#34;reportId&#34;:null,   &#34;error&#34;:&#34;…&#34;}
 *
 * 永远以退出码 0 结束 —— 判断结果放在 JSON 里，避免调用方去解析报错文本。
 */
import { loadConfig } from &#39;../src/config.mjs&#39;;
import { createReportClient } from &#39;../src/report/client.mjs&#39;;
import { SECTIONS, htmlToText } from &#39;../src/report/render.mjs&#39;;

function arg(name) {
  const i = process.argv.indexOf(name);
  return i !== -1 &amp;&amp; process.argv[i + 1] ? process.argv[i + 1] : null;
}

function todayLocal() {
  const d = new Date();
  const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

const date = arg(&#39;--date&#39;) || todayLocal();

function emit(obj) {
  process.stdout.write(JSON.stringify(obj) + &#39;\n&#39;);
}

try {
  const cfg = loadConfig();
  const client = createReportClient({ ...cfg, log: () =&gt; {} });
  const report = await client.getReportInfo({ report_date: date, type: cfg.type });

  if (!report) {
    emit({ ok: true, date, filed: false, reportId: null, error: null });
  } else {
    const filled = SECTIONS.filter((s) =&gt; htmlToText(report[s.key] ?? &#39;&#39;).trim() !== &#39;&#39;);
    emit({
      ok: true,
      date,
      filed: filled.length &gt; 0,
      filledSections: filled.map((s) =&gt; s.label),
      reportId: report.report_id ?? report.id ?? null,
      error: null,
    });
  }
} catch (e) {
  emit({ ok: false, date, filed: null, reportId: null, error: String(e?.message ?? e) });
}
process.exit(0);
</code></pre>
<h4><code>scripts/tools/backfill-siyuan.mjs</code></h4>
<p>历史回填 + 目录结构迁移</p>
<pre><code class="language-js">/**
 * 把历史日报回填到思源笔记。
 *
 * 数据来源：火云台（按日期查），不是本地归档 —— 以服务器上的内容为准。
 *
 * 用法：
 *   node backfill-siyuan.mjs --days 30 --dry-run     # 先看会推哪些
 *   node backfill-siyuan.mjs --only 2026-10-16       # 只推一天
 *   node backfill-siyuan.mjs --days 30               # 真推
 *   node backfill-siyuan.mjs --from 2026-10-01 --to 2026-10-16
 *
 * 幂等：某天已存在同名文档就删了重建，不会重复累积。
 * 空的（五段全空）日报会跳过，不会建空文档。
 */
import { loadConfig, loadSiYuanConfig } from &#39;../src/config.mjs&#39;;
import { createReportClient } from &#39;../src/report/client.mjs&#39;;
import { SECTIONS, htmlToText } from &#39;../src/report/render.mjs&#39;;
import { publishToSiYuan, renderPathPattern } from &#39;../src/siyuan/publish.mjs&#39;;
import { createSiYuanClient } from &#39;../src/siyuan/client.mjs&#39;;

function arg(name) {
  const i = process.argv.indexOf(name);
  return i !== -1 &amp;&amp; process.argv[i + 1] ? process.argv[i + 1] : null;
}
function flag(name) {
  return process.argv.includes(name);
}

function ymd(d) {
  const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

const only = arg(&#39;--only&#39;);
const from = arg(&#39;--from&#39;);
const to = arg(&#39;--to&#39;);
const days = Number(arg(&#39;--days&#39;) || 60);
const dryRun = flag(&#39;--dry-run&#39;);

// 待处理的日期列表（新到旧）
const dates = [];
if (only) {
  dates.push(only);
} else {
  const end = to ? new Date(`${to}T00:00:00`) : new Date();
  const start = from ? new Date(`${from}T00:00:00`) : new Date(end.getTime() - (days - 1) * 86400000);
  for (let d = new Date(end); d &gt;= start; d.setDate(d.getDate() - 1)) dates.push(ymd(d));
}

const cfg = loadConfig();
const siyuan = loadSiYuanConfig();
if (!siyuan) {
  console.error(&#39;没配思源（config.json 的 siyuan 块）&#39;);
  process.exit(2);
}
if (siyuan.tokenMissing) {
  console.error(&#39;思源 API token 没填&#39;);
  process.exit(2);
}

const client = createReportClient({ ...cfg, log: () =&gt; {} });

console.log(`扫描 ${dates.length} 天${dryRun ? &#39;（预演）&#39; : &#39;&#39;}：${dates[dates.length - 1]} ~ ${dates[0]}\n`);

// ---------- 可选：迁移目录结构 ----------
// 把所有「日期文档」跟当前 pathPattern 算出的目标位置比一遍，
// 位置不对的删掉，后面正常的推送会按新结构重建。
// 比固定规则（只删单层）更通用：改了模板就能自动跟进。
if (flag(&#39;--migrate&#39;)) {
  const q = (v) =&gt; String(v).replace(/&#39;/g, &#34;&#39;&#39;&#34;);
  const sx = createSiYuanClient({ url: siyuan.url, token: siyuan.token });

  const parent = await sx.sql(
    `SELECT id, hpath FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(siyuan.notebook)}&#39; AND content=&#39;${q(siyuan.parentDoc)}&#39; LIMIT 1`,
  );
  const parentHPath = parent?.[0]?.hpath ?? &#39;&#39;;

  const rows = await sx.sql(
    `SELECT id, hpath, path, content FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(siyuan.notebook)}&#39; AND hpath LIKE &#39;${q(parentHPath)}/%&#39;`,
  );

  let removed = 0;
  for (const r of rows) {
    // 只处理日期文档；年/月/周这些容器文档一律不动
    if (!/^\d{4}-\d{2}-\d{2}$/.test(r.content ?? &#39;&#39;)) continue;

    const expected = `${parentHPath}/${renderPathPattern(siyuan.pathPattern, r.content)}`;
    if (r.hpath === expected) continue; // 位置已经对了

    if (dryRun) {
      console.log(`  [预演] 待迁移  ${r.hpath}  →  ${expected}`);
    } else {
      // removeDoc 要的是存储路径（/笔记本ID/文档ID.sy），不是 hpath
      await sx.removeDoc({ notebook: siyuan.notebook, path: r.path });
      console.log(`  迁移：删除旧位置  ${r.hpath}`);
    }
    removed++;
  }
  console.log(`结构迁移：${dryRun ? &#39;将删除&#39; : &#39;已删除&#39;} ${removed} 篇旧位置文档\n`);
}

const pushed = [];
const skipped = [];
const failed = [];

for (const date of dates) {
  let report;
  try {
    report = await client.getReportInfo({ report_date: date, type: cfg.type });
  } catch (e) {
    failed.push({ date, error: `查日报失败：${e.message}` });
    console.log(`  ${date}  ✘ 查日报失败：${e.message}`);
    continue;
  }

  if (!report) {
    skipped.push({ date, reason: &#39;没有报告&#39; });
    continue;
  }

  const filled = SECTIONS.filter((s) =&gt; htmlToText(report[s.key] ?? &#39;&#39;).trim() !== &#39;&#39;);
  if (filled.length === 0) {
    skipped.push({ date, reason: &#39;内容为空&#39; });
    continue;
  }

  const payload = { report_date: date, type: cfg.type };
  for (const s of SECTIONS) payload[s.key] = report[s.key] ?? &#39;&#39;;

  try {
    const r = await publishToSiYuan(siyuan, payload, { dryRun });
    pushed.push({ date, action: r.action, hpath: r.hpath, sections: filled.map((s) =&gt; s.label) });
    console.log(`  ${date}  ✔ ${r.action === &#39;create&#39; ? &#39;新建&#39; : &#39;重建&#39;}  ${r.hpath}`);
  } catch (e) {
    failed.push({ date, error: e.message });
    console.log(`  ${date}  ✘ ${e.message}`);
  }

  // 火云台接口有节流，稍微间隔一下
  await new Promise((r) =&gt; setTimeout(r, 120));
}

console.log(&#39;\n&#39; + &#39;─&#39;.repeat(60));
console.log(`成功 ${pushed.length}    跳过 ${skipped.length}    失败 ${failed.length}`);

if (skipped.length) {
  const byReason = {};
  for (const s of skipped) byReason[s.reason] = (byReason[s.reason] ?? 0) + 1;
  console.log(&#39;\n跳过原因：&#39;);
  for (const [k, v] of Object.entries(byReason)) console.log(`  ${k}：${v} 天`);
}

if (failed.length) {
  console.log(&#39;\n失败：&#39;);
  for (const f of failed) console.log(`  ${f.date}  ${f.error}`);
}

if (dryRun) console.log(&#39;\n[预演] 什么都没写入。去掉 --dry-run 才会真写。&#39;);
process.exit(failed.length ? 1 : 0);
</code></pre>
<h4><code>scripts/tools/remind.ps1</code></h4>
<p>Windows 通知：先判断排班，再查状态，没写才弹</p>
<pre><code class="language-powershell">﻿&lt;#
.SYNOPSIS
  日报提醒：检查今天是否已提交日报，没提交就弹一条 Windows 通知。

.DESCRIPTION
  由「任务计划程序」在工作日下午 17:30 调用。逻辑：

    1. 调 check-status.mjs 问服务器今天写没写
    2. 已写     → 静默退出，不打扰
    3. 未写     → 弹 Windows 通知
    4. 查不通   → 弹一条「无法确认」的通知（宁可多提醒，不要漏）

  通知点击后打开日报网站。整个过程不写日报、不提交任何东西。

.PARAMETER Workspace
  工作区目录（含 config.json）。不传则按 DAILY_REPORT_HOME → 向上查找 → 默认值 解析。

.PARAMETER Date
  要检查的日期，默认今天。

.PARAMETER Force
  不管写没写都弹通知（测试用）。

.PARAMETER Test
  只弹一条固定的测试通知，不联网、不读配置。

.EXAMPLE
  .\remind.ps1 -Test
  .\remind.ps1 -Force
  .\remind.ps1 -Workspace &#34;D:\工作区\日报&#34;
#&gt;
[CmdletBinding()]
param(
  [string]$Workspace,
  [string]$Date,
  [switch]$Force,
  [switch]$Test
)

$ErrorActionPreference = &#39;Stop&#39;

$ScriptDir   = $PSScriptRoot
$SkillRoot   = Split-Path (Split-Path $ScriptDir -Parent) -Parent   # &lt;skill&gt;/
$CheckScript = Join-Path $ScriptDir &#39;check-status.mjs&#39;
$AppId       = &#39;DeepSeek.DSH.DailyReport&#39;
$ReportUrl   = &#39;https://www.huoyuntai.com/#/home/reportList?limit=10&amp;page=1&#39;

# ---------- 工作区解析（与 config.mjs 保持一致）----------
function Resolve-Workspace {
  param([string]$Explicit)
  if ($Explicit) { return [System.IO.Path]::GetFullPath($Explicit) }
  if ($env:DAILY_REPORT_HOME) { return [System.IO.Path]::GetFullPath($env:DAILY_REPORT_HOME) }

  # 从 skill 位置向上找同时有 config.json 和 reports/ 的目录
  $cur = [System.IO.Path]::GetFullPath($SkillRoot)
  for ($i = 0; $i -lt 8 -and $cur; $i++) {
    if ((Test-Path (Join-Path $cur &#39;config.json&#39;)) -and
        ((Test-Path (Join-Path $cur &#39;reports&#39;)) -or (Test-Path (Join-Path $cur &#39;drafts&#39;)))) {
      return $cur
    }
    $parent = Split-Path $cur -Parent
    if (-not $parent -or $parent -eq $cur) { break }
    $cur = $parent
  }
  return (Join-Path $env:USERPROFILE &#39;日报自动化&#39;)
}

function Find-Node {
  $cmd = Get-Command node -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($p in @(
    (Join-Path $env:ProgramFiles &#39;nodejs\node.exe&#39;),
    (Join-Path ${env:ProgramFiles(x86)} &#39;nodejs\node.exe&#39;),
    (Join-Path $env:LOCALAPPDATA &#39;Programs\nodejs\node.exe&#39;)
  )) { if ($p -and (Test-Path $p)) { return $p } }
  return $null
}

function Write-Log {
  param([string]$Message, [string]$LogDir)
  if (-not $LogDir) { return }
  try {
    $dir = Join-Path $LogDir &#39;.cache&#39;
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $line = &#39;{0}  {1}&#39; -f (Get-Date -Format &#39;yyyy-MM-dd HH:mm:ss&#39;), $Message
    Add-Content -LiteralPath (Join-Path $dir &#39;reminder.log&#39;) -Value $line -Encoding UTF8
  } catch { }
}

# ---------- 弹通知 ----------
function Show-Toast {
  param([string]$Title, [string]$Body, [string]$AppIdToUse)

  try {
    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
  } catch {
    return $false
  }

  $esc = { param($s) [System.Security.SecurityElement]::Escape([string]$s) }
  $xmlText = @&#34;
&lt;toast activationType=&#34;protocol&#34; launch=&#34;$(&amp; $esc $ReportUrl)&#34;&gt;
  &lt;visual&gt;
    &lt;binding template=&#34;ToastGeneric&#34;&gt;
      &lt;text&gt;$(&amp; $esc $Title)&lt;/text&gt;
      &lt;text&gt;$(&amp; $esc $Body)&lt;/text&gt;
    &lt;/binding&gt;
  &lt;/visual&gt;
&lt;/toast&gt;
&#34;@

  try {
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($xmlText)
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppIdToUse).Show($toast)
    return $true
  } catch {
    return $false
  }
}

function Notify {
  param([string]$Title, [string]$Body, [string]$LogDir)

  # 优先用注册过的自定义 AppID（通知里显示「日报提醒」），失败退到 PowerShell 的 AppID
  if (Show-Toast -Title $Title -Body $Body -AppIdToUse $AppId) {
    Write-Log &#34;toast sent (custom appid): $Body&#34; $LogDir
    return &#39;toast-custom&#39;
  }
  $psAppId = &#39;{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe&#39;
  if (Show-Toast -Title $Title -Body $Body -AppIdToUse $psAppId) {
    Write-Log &#34;toast sent (powershell appid): $Body&#34; $LogDir
    return &#39;toast-powershell&#39;
  }

  # 最后兜底：消息框（不美观但一定能看见）
  try {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Body, $Title) | Out-Null
    Write-Log &#34;messagebox shown: $Body&#34; $LogDir
    return &#39;messagebox&#39;
  } catch {
    Write-Log &#34;ALL notification paths failed&#34; $LogDir
    return &#39;none&#39;
  }
}

# ---------- 主流程 ----------
$ws = Resolve-Workspace -Explicit $Workspace

if ($Test) {
  $r = Notify -Title &#39;日报提醒（测试）&#39; -Body &#39;如果你看到这条，说明通知链路是通的。&#39; -LogDir $ws
  Write-Host &#34;测试通知发送结果：$r&#34;
  exit 0
}

$node = Find-Node
if (-not $node) {
  Notify -Title &#39;日报提醒&#39; -Body &#39;找不到 Node.js，无法检查今天的日报状态。&#39; -LogDir $ws | Out-Null
  exit 1
}

$logDir = $ws

# ---------- 先看今天该不该上班（单双休轮换）----------
# 周六是否上班由 calendar.mjs 按锚点周奇偶算，见 config.json 的 schedule 块
if (-not $Force) {
  $wd = $null
  try {
    $wdArgs = @((Join-Path $ScriptDir &#39;is-workday.mjs&#39;))
    if ($Date) { $wdArgs += @(&#39;--date&#39;, $Date) }
    $wd = (&amp; $node @wdArgs 2&gt;&amp;1 | Out-String).Trim() | ConvertFrom-Json
  } catch {
    Write-Log &#34;workday check failed: $($_.Exception.Message)&#34; $logDir
  }
  if ($wd -and -not $wd.workday) {
    Write-Log &#34;not a workday ($($wd.reason)) -&gt; stay silent&#34; $logDir
    exit 0
  }
}

$json = $null
try {
  $args = @($CheckScript)
  if ($Date) { $args += @(&#39;--date&#39;, $Date) }
  $raw = &amp; $node @args 2&gt;&amp;1 | Out-String
  $json = $raw.Trim() | ConvertFrom-Json
} catch {
  Write-Log &#34;check failed: $($_.Exception.Message)&#34; $logDir
}

if (-not $json -or -not $json.ok) {
  $reason = if ($json -and $json.error) { $json.error } else { &#39;检查脚本没有返回结果&#39; }
  Write-Log &#34;check error: $reason&#34; $logDir
  Notify -Title &#39;日报提醒&#39; -Body &#34;无法确认今天的日报状态，记得看一下。（$reason）&#34; -LogDir $logDir | Out-Null
  exit 0
}

if ($json.filed -and -not $Force) {
  Write-Log &#34;already filed ($($json.date)) -&gt; stay silent&#34; $logDir
  exit 0
}

$body = if ($json.filed -and $Force) {
  &#34;今天（$($json.date)）的日报已提交。这条是 -Force 测试。&#34;
} else {
  &#34;今天（$($json.date)）的日报还没写，记得提交。&#34;
}
Notify -Title &#39;日报提醒&#39; -Body $body -LogDir $logDir | Out-Null
exit 0
</code></pre>
<h4><code>scripts/tools/install-reminder.ps1</code></h4>
<p>注册 / 移除计划任务与通知身份</p>
<pre><code class="language-powershell">﻿&lt;#
.SYNOPSIS
  注册 / 移除「日报提醒」的 Windows 定时任务（右下角系统通知）。

.DESCRIPTION
  做两件事：

    1. 在 HKCU 注册一个 AppUserModelID，让通知显示成「日报提醒」
    2. 用任务计划程序注册定时任务，到点调用 remind.ps1

  remind.ps1 会先查服务器今天写没写日报：写了就静默退出，没写才弹通知。
  任务以「仅交互式登录时运行」注册 —— 通知必须投递到你的桌面会话，
  所以任务只在你自己登录着的时候跑。

.PARAMETER Workspace
  工作区目录（含 config.json）。默认按 DAILY_REPORT_HOME → 向上查找 → 默认值 解析。

.PARAMETER Time
  触发时间，24 小时制 HH:mm，默认 17:30。

.PARAMETER Days
  触发星期，默认周一到周五。

.PARAMETER TaskName
  任务计划里的任务名，默认「日报提醒」。

.PARAMETER Remove
  移除已注册的任务和注册表项。

.PARAMETER Test
  注册完成后立刻弹一条测试通知。

.EXAMPLE
  .\install-reminder.ps1 -Test
  .\install-reminder.ps1 -Time 18:00 -Days Monday,Wednesday,Friday
  .\install-reminder.ps1 -Remove
#&gt;
[CmdletBinding()]
param(
  [string]$Workspace,
  [string]$Time = &#39;17:30&#39;,
  [string[]]$Days = @(&#39;Monday&#39;, &#39;Tuesday&#39;, &#39;Wednesday&#39;, &#39;Thursday&#39;, &#39;Friday&#39;),
  [string]$TaskName = &#39;日报提醒&#39;,
  [switch]$Remove,
  [switch]$Test
)

$ErrorActionPreference = &#39;Stop&#39;

$AppId     = &#39;DeepSeek.DSH.DailyReport&#39;
$RemindPs1 = Join-Path $PSScriptRoot &#39;remind.ps1&#39;
$SkillRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$RegPath   = &#34;HKCU:\SOFTWARE\Classes\AppUserModelId\$AppId&#34;

function W($t)  { Write-Host $t }
function Ok($t) { Write-Host &#34;    OK  $t&#34; -ForegroundColor Green }

function Resolve-Workspace {
  param([string]$Explicit)
  if ($Explicit) { return [System.IO.Path]::GetFullPath($Explicit) }
  if ($env:DAILY_REPORT_HOME) { return [System.IO.Path]::GetFullPath($env:DAILY_REPORT_HOME) }
  $cur = [System.IO.Path]::GetFullPath($SkillRoot)
  for ($i = 0; $i -lt 8 -and $cur; $i++) {
    if ((Test-Path (Join-Path $cur &#39;config.json&#39;)) -and
        ((Test-Path (Join-Path $cur &#39;reports&#39;)) -or (Test-Path (Join-Path $cur &#39;drafts&#39;)))) {
      return $cur
    }
    $parent = Split-Path $cur -Parent
    if (-not $parent -or $parent -eq $cur) { break }
    $cur = $parent
  }
  return (Join-Path $env:USERPROFILE &#39;日报自动化&#39;)
}

# ================= 移除 =================
if ($Remove) {
  W &#39;&#39;
  W &#39;  日报提醒 · 移除&#39;
  W &#39;  ================================&#39;

  $t = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  if ($t) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Ok &#34;已删除计划任务「$TaskName」&#34;
  } else {
    W &#34;    计划任务「$TaskName」不存在&#34;
  }
  if (Test-Path -LiteralPath $RegPath) {
    Remove-Item -LiteralPath $RegPath -Recurse -Force
    Ok &#39;已删除注册表项&#39;
  }
  W &#39;&#39;
  exit 0
}

# ================= 注册 =================
W &#39;&#39;
W &#39;  日报提醒 · 安装（Windows 系统通知）&#39;
W &#39;  ================================&#39;

$ws = Resolve-Workspace -Explicit $Workspace
W &#39;&#39;
W &#34;    工作区   $ws&#34;
W &#34;    脚本     $RemindPs1&#34;
W &#34;    时间     每周 $($Days -join &#39;, &#39;) $Time&#34;
W &#39;&#39;

if (-not (Test-Path -LiteralPath $RemindPs1)) { throw &#34;找不到 remind.ps1：$RemindPs1&#34; }
if (-not (Test-Path -LiteralPath (Join-Path $ws &#39;config.json&#39;))) {
  W &#39;    !! 工作区里没有 config.json —— 通知能弹，但查不出今天写没写。&#39; -ForegroundColor Yellow
}

# ---------- 1. 通知身份 ----------
W &#39;[1] 注册通知身份&#39;
if (-not (Test-Path -LiteralPath $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
New-ItemProperty -LiteralPath $RegPath -Name &#39;DisplayName&#39; -Value &#39;日报提醒&#39; -PropertyType String -Force | Out-Null
Ok &#34;AppUserModelID = $AppId&#34;

# ---------- 2. 计划任务 ----------
W &#39;&#39;
W &#39;[2] 注册计划任务&#39;

$psExe  = Join-Path $env:SystemRoot &#39;System32\WindowsPowerShell\v1.0\powershell.exe&#39;
$action = New-ScheduledTaskAction -Execute $psExe `
  -Argument &#34;-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `&#34;$RemindPs1`&#34; -Workspace `&#34;$ws`&#34;&#34; `
  -WorkingDirectory $ws

$at      = [datetime]::Today.Add([timespan]::Parse($Time))
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek ([System.DayOfWeek[]]$Days) -At $at

$settings = New-ScheduledTaskSettingsSet `
  -StartWhenAvailable `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -MultipleInstances IgnoreNew `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

# 仅交互式登录时运行：通知要投递到你的桌面会话
$principal = New-ScheduledTaskPrincipal -UserId &#34;$env:USERDOMAIN\$env:USERNAME&#34; -LogonType Interactive -RunLevel Limited

try {
  Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Settings $settings -Principal $principal -Force | Out-Null
  Ok &#34;计划任务「$TaskName」已注册&#34;
} catch {
  W &#39;&#39;
  W &#39;    注册计划任务失败。&#39; -ForegroundColor Red
  W &#34;    $($_.Exception.Message)&#34; -ForegroundColor Red
  W &#39;&#39;
  W &#39;    请改用「以管理员身份运行」的 PowerShell 重跑本脚本。&#39; -ForegroundColor Yellow
  exit 1
}

# ---------- 3. 可选：立刻测一条 ----------
if ($Test) {
  W &#39;&#39;
  W &#39;[3] 发送测试通知&#39;
  &amp; powershell.exe -NoProfile -ExecutionPolicy Bypass -File $RemindPs1 -Workspace $ws -Test | Out-Null
  Ok &#39;已触发 —— 看右下角&#39;
  W &#39;        （没弹出的话检查「专注助手 / 勿扰模式」是否开着）&#39; -ForegroundColor DarkGray
}

W &#39;&#39;
W &#39;  安装完成&#39; -ForegroundColor Green
W &#39;  ================================&#39;
W &#39;&#39;
W &#34;  触发时间：每周 $($Days -join &#39;, &#39;) $Time&#34;
W &#39;  行为：先查服务器今天写没写 —— 写了静默退出，没写才弹通知&#39;
W &#39;  日志：&lt;工作区&gt;\.cache\reminder.log&#39;
W &#39;&#39;
W &#34;  手动测：  &amp; `&#34;$RemindPs1`&#34; -Workspace `&#34;$ws`&#34; -Test&#34;
W &#34;  立刻跑：  Start-ScheduledTask -TaskName &#39;$TaskName&#39;&#34;
W &#34;  移除：    &amp; `&#34;$PSCommandPath`&#34; -Remove&#34;
W &#39;&#39;
</code></pre>
<h4><code>scripts/tools/fetch-history.mjs</code></h4>
<p>拉取历史日报</p>
<pre><code class="language-js">/**
 * 拉取历史日报，用于分析写作风格。
 * 用法：node tools/fetch-history.mjs [天数=30]
 */
import { loadConfig } from &#39;../src/config.mjs&#39;;
import { createReportClient } from &#39;../src/report/client.mjs&#39;;
import { SECTIONS } from &#39;../src/report/render.mjs&#39;;

const days = Number(process.argv[2] || 30);
const cfg = loadConfig();
const client = createReportClient({ ...cfg, log: () =&gt; {} });

function d(offset) {
  const t = new Date();
  t.setDate(t.getDate() - offset);
  const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;);
  return `${t.getFullYear()}-${p(t.getMonth() + 1)}-${p(t.getDate())}`;
}

const found = [];
for (let i = 0; i &lt; days; i++) {
  const date = d(i);
  try {
    const r = await client.getReportInfo({ report_date: date, type: cfg.type });
    if (r) found.push({ date, r });
  } catch (e) {
    console.error(`# ${date} 失败：${e.message}`);
  }
}

console.log(`共找到 ${found.length} 天的日报\n`);
console.log(&#39;=&#39;.repeat(70));

for (const { date, r } of found.reverse()) {
  console.log(`\n### ${date}  (id=${r.report_id})`);
  for (const s of SECTIONS) {
    const html = r[s.key] || &#39;&#39;;
    const text = html
      .replace(/&lt;\/(p|li|ul|ol|div|h[1-6])&gt;/gi, &#39;\n&#39;)
      .replace(/&lt;br\s*\/?&gt;/gi, &#39;&#39;)
      .replace(/&lt;[^&gt;]+&gt;/g, &#39;&#39;)
      .replace(/&amp;amp;/g, &#39;&amp;&#39;)
      .replace(/&amp;lt;/g, &#39;&lt;&#39;)
      .replace(/&amp;gt;/g, &#39;&gt;&#39;)
      .replace(/&amp;nbsp;/g, &#39; &#39;)
      .split(&#39;\n&#39;)
      .map((l) =&gt; l.trim())
      .filter(Boolean)
      .join(&#39;\n&#39;);
    if (text) console.log(`  [${s.label}]\n${text.split(&#39;\n&#39;).map((l) =&gt; `    ${l}`).join(&#39;\n&#39;)}`);
  }
}
</code></pre>
<h3>9.3 安装与卸载</h3>
<h4><code>install.ps1</code></h4>
<p>安装脚本：Project / User 两种范围</p>
<pre><code class="language-powershell">﻿&lt;#
.SYNOPSIS
  安装 daily-report-huoyuntai skill。

.DESCRIPTION
  两种安装范围，默认最小权限：

    Project（默认）  装到 &lt;项目根&gt;\.dsh\skills —— 只在这个项目里可见
    User             装到 &lt;DSH_HOME&gt;\skills   —— 所有项目都可见

  技能目录只放只读的脚本与文档；账号密码、草稿、归档放在「工作区」。
  Project 范围的工作区默认就是项目根目录，凭证不出项目。
  已存在的 config.json 永远不会被覆盖。

.PARAMETER Scope
  Project（默认）或 User。

.PARAMETER ProjectRoot
  Project 范围的项目根目录。默认从脚本位置向上找 .git / .dsh / .agents / package.json。

.PARAMETER SkillRoot
  直接指定技能根目录，覆盖 Scope 的推导结果。

.PARAMETER Workspace
  工作区目录。Project 默认 &lt;项目根&gt;，User 默认 &lt;用户目录&gt;\日报自动化。

.PARAMETER Force
  保留参数，当前仅用于显式声明意图。

.EXAMPLE
  .\install.ps1                          # 装到当前项目（最小权限）
  .\install.ps1 -Scope User              # 装到全局，所有项目可用
  .\install.ps1 -Scope Project -ProjectRoot &#34;D:\work\日报&#34;
#&gt;
[CmdletBinding()]
param(
  [ValidateSet(&#39;Project&#39;, &#39;User&#39;)]
  [string]$Scope = &#39;Project&#39;,
  [string]$ProjectRoot,
  [string]$SkillRoot,
  [string]$Workspace,
  [switch]$Force
)

$ErrorActionPreference = &#39;Stop&#39;
$SkillName = &#39;daily-report-huoyuntai&#39;
$Source = $PSScriptRoot

function Write-Step($n, $text) { Write-Host &#34;`n[$n] $text&#34; -ForegroundColor Cyan }
function Write-Ok($text)       { Write-Host &#34;    OK  $text&#34; -ForegroundColor Green }
function Write-Warn2($text)    { Write-Host &#34;    !!  $text&#34; -ForegroundColor Yellow }

Write-Host &#39;&#39;
Write-Host &#39;  日报自动化 skill · 安装程序&#39; -ForegroundColor White
Write-Host &#39;  ================================&#39; -ForegroundColor DarkGray

# ---------- 选择安装范围 ----------
# 只有交互式运行（双击）且没显式传 -Scope 时才问；管道/自动化调用直接走默认 Project
$interactive = $true
try { $interactive = -not [Console]::IsInputRedirected } catch { $interactive = $false }

if (-not $PSBoundParameters.ContainsKey(&#39;Scope&#39;) -and $interactive) {
  Write-Host &#39;&#39;
  Write-Host &#39;  装到哪里？&#39; -ForegroundColor White
  Write-Host &#39;    [1] 当前项目  —— 最小权限，只在这个项目里可见（推荐）&#39;
  Write-Host &#39;                     账号密码也只放在这个项目里&#39;
  Write-Host &#39;    [2] 全局      —— 所有项目都能用&#39;
  Write-Host &#39;                     技能装到用户目录，工作区在 用户目录\日报自动化&#39;
  Write-Host &#39;&#39;
  $ans = Read-Host &#39;  请输入 1 或 2 [默认 1]&#39;
  if ($ans -eq &#39;2&#39;) { $Scope = &#39;User&#39; }
}

# ---------- 0. 前置检查 ----------
Write-Step 0 &#39;检查运行环境&#39;

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
  throw &#34;找不到 node。请先安装 Node.js 18 或更高版本，并确认 `node -v` 能跑。&#34;
}
$nodeVersion = (&amp; node -v) 2&gt;$null
Write-Ok &#34;Node $nodeVersion  ($($nodeCmd.Source))&#34;

if (-not (Test-Path (Join-Path $Source &#39;SKILL.md&#39;))) {
  throw &#34;在 $Source 里找不到 SKILL.md —— 请从 skill 目录内部运行本脚本。&#34;
}
Write-Ok &#34;源目录 $Source&#34;

# ---------- 1. 推导项目根 ----------
# 规则与 DSH 自身的本地发现保持一致，再补两条兜底：
#   1) 向上找 .git（DSH 就是这么定义项目根的）
#   2) 其次 .dsh / .agents / package.json，但不越过用户主目录
#      （主目录下有 %USERPROFILE%\.dsh，否则会把整个主目录误当成项目）
#   3) 发布布局 &lt;项目&gt;\skill\&lt;skill名&gt;\ —— 取上两级
function Find-ProjectRoot($start) {
  $userHome = [System.IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd(&#39;\&#39;)
  $cur = [System.IO.Path]::GetFullPath($start)
  $markers = @(&#39;.git&#39;, &#39;.dsh&#39;, &#39;.agents&#39;, &#39;package.json&#39;)

  $walk = $cur
  while ($walk) {
    if ($walk.TrimEnd(&#39;\&#39;) -ieq $userHome) { break }
    foreach ($m in $markers) {
      if (Test-Path (Join-Path $walk $m)) { return $walk }
    }
    $parent = Split-Path $walk -Parent
    if (-not $parent -or $parent -eq $walk) { break }
    $walk = $parent
  }

  # 发布布局兜底：&lt;项目&gt;\skill\&lt;skill名&gt;\
  $parent = Split-Path $cur -Parent
  if ($parent) {
    $leaf = Split-Path $parent -Leaf
    if ($leaf -eq &#39;skill&#39; -or $leaf -eq &#39;skills&#39;) {
      $grand = Split-Path $parent -Parent
      if ($grand) { return $grand }
    }
  }

  return $null
}

if (-not $ProjectRoot) {
  $found = Find-ProjectRoot $Source
  if ($found) { $ProjectRoot = $found }
  else { $ProjectRoot = (Get-Location).Path }
}
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

# ---------- 2. 确定安装位置 ----------
$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE &#39;.dsh&#39; }

if (-not $SkillRoot) {
  if ($Scope -eq &#39;Project&#39;) { $SkillRoot = Join-Path $ProjectRoot &#39;.dsh\skills&#39; }
  else                      { $SkillRoot = Join-Path $dshHome &#39;skills&#39; }
}
if (-not $Workspace) {
  if ($Scope -eq &#39;Project&#39;) { $Workspace = $ProjectRoot }
  else                      { $Workspace = Join-Path $env:USERPROFILE &#39;日报自动化&#39; }
}

$SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot)
$Workspace = [System.IO.Path]::GetFullPath($Workspace)
$Target    = Join-Path $SkillRoot $SkillName

Write-Step 1 &#39;确定安装位置&#39;
Write-Host &#34;    范围     $Scope&#34; -ForegroundColor White
if ($Scope -eq &#39;Project&#39;) {
  Write-Ok &#34;项目根   $ProjectRoot&#34;
  Write-Host &#39;             （只有工作目录在这个项目里时，这个技能才可见）&#39; -ForegroundColor DarkGray
} else {
  Write-Host &#39;             （全局安装：所有项目都能看到这个技能）&#39; -ForegroundColor DarkGray
}
Write-Ok &#34;技能目录 $Target&#34;
Write-Ok &#34;工作区   $Workspace&#34;

# 安全阀：不要装进自己的源目录里
$srcFull = [System.IO.Path]::GetFullPath($Source).TrimEnd(&#39;\&#39;)
if ($Target.TrimEnd(&#39;\&#39;) -eq $srcFull) {
  throw &#34;目标目录和源目录相同（$Target）。请不要把 skill 装在它自己的源目录里。&#34;
}
if ($Target.TrimEnd(&#39;\&#39;).StartsWith($srcFull + &#39;\&#39;)) {
  throw &#34;目标目录在源目录内部（$Target）。请换一个 SkillRoot。&#34;
}

# ---------- 3. 安装 skill ----------
Write-Step 2 &#39;安装 skill&#39;

if (Test-Path -LiteralPath $Target) {
  Write-Warn2 &#39;目标已存在，将覆盖更新（对已安装副本的本地改动会丢失）&#39;
  Remove-Item -LiteralPath $Target -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $Target | Out-Null

Get-ChildItem -LiteralPath $Source -Force | Where-Object { $_.Name -ne &#39;.git&#39; } | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $Target -Recurse -Force
}
Write-Ok &#34;已复制 $((Get-ChildItem -LiteralPath $Target -Recurse -File).Count) 个文件&#34;

# ---------- 4. 准备工作区 ----------
Write-Step 3 &#39;准备工作区&#39;

foreach ($sub in @(&#39;drafts&#39;, &#39;reports&#39;, &#39;.cache&#39;)) {
  $p = Join-Path $Workspace $sub
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
Write-Ok &#34;目录就绪 $Workspace&#34;

$cfgPath = Join-Path $Workspace &#39;config.json&#39;
if (Test-Path -LiteralPath $cfgPath) {
  Write-Warn2 &#39;config.json 已存在，保持不变（不会覆盖你的账号密码）&#39;
} else {
  Copy-Item -LiteralPath (Join-Path $Target &#39;templates\config.example.json&#39;) -Destination $cfgPath -Force
  Write-Ok &#39;已生成 config.json（待填账号密码）&#39;
}

$exampleDraft = Join-Path $Workspace &#39;drafts\example.txt&#39;
if (-not (Test-Path -LiteralPath $exampleDraft)) {
  Copy-Item -LiteralPath (Join-Path $Target &#39;templates\drafts\example.txt&#39;) -Destination $exampleDraft -Force
  Write-Ok &#39;已放入草稿示例 drafts\example.txt&#39;
}

# 凭证落在 git 仓库里要提醒
if (Test-Path -LiteralPath (Join-Path $Workspace &#39;.git&#39;)) {
  Write-Warn2 &#39;工作区是个 git 仓库：config.json 含账号密码，记得把它写进 .gitignore&#39;
}

# ---------- 5. 冒烟测试 ----------
Write-Step 4 &#39;冒烟测试&#39;

$submit = Join-Path $Target &#39;scripts\src\submit.mjs&#39;
$prevHome = $env:DAILY_REPORT_HOME
try {
  $env:DAILY_REPORT_HOME = $Workspace
  $out = &amp; node $submit --help 2&gt;&amp;1 | Out-String
  if ($LASTEXITCODE -ne 0 -or $out -notmatch &#39;用法&#39;) {
    throw &#34;脚本没能正常运行：`n$out&#34;
  }
  Write-Ok &#39;--help 正常&#39;
} finally {
  if ($null -eq $prevHome) { Remove-Item Env:\DAILY_REPORT_HOME -ErrorAction SilentlyContinue }
  else { $env:DAILY_REPORT_HOME = $prevHome }
}

# ---------- 完成 ----------
Write-Host &#39;&#39;
Write-Host &#39;  安装完成&#39; -ForegroundColor Green
Write-Host &#39;  ================================&#39; -ForegroundColor DarkGray
Write-Host &#39;&#39;
if ($Scope -eq &#39;Project&#39;) {
  Write-Host &#39;  注意：这是项目级安装，只在工作目录属于&#39; -ForegroundColor Yellow
  Write-Host &#34;        $ProjectRoot&#34; -ForegroundColor Yellow
  Write-Host &#39;        时会生效。想在所有项目里可用，重装时加 -Scope User。&#39; -ForegroundColor Yellow
  Write-Host &#39;&#39;
}
Write-Host &#39;  下一步：&#39; -ForegroundColor White
Write-Host &#39;&#39;
Write-Host &#34;    1. 填账号密码：  $cfgPath&#34;
Write-Host &#39;       （用记事本打开，填 user_phone 和 user_pwd 两个值）&#39;
Write-Host &#39;&#39;
Write-Host &#39;    2. 验证登录：&#39;
Write-Host &#34;       `$env:DAILY_REPORT_HOME=&#39;$Workspace&#39;&#34;
Write-Host &#34;       node `&#34;$submit`&#34; --check&#34;
Write-Host &#39;&#39;
Write-Host &#39;    3. 之后直接跟 AI 说「写日报」并贴出今天做的事就行。&#39; -ForegroundColor White
Write-Host &#39;&#39;
Write-Host &#34;  卸载：  &amp; `&#34;$Target\uninstall.ps1`&#34; -Scope $Scope&#34; -ForegroundColor DarkGray
Write-Host &#39;&#39;
</code></pre>
<h4><code>uninstall.ps1</code></h4>
<p>卸载脚本：默认保留工作区</p>
<pre><code class="language-powershell">﻿&lt;#
.SYNOPSIS
  卸载 daily-report-huoyuntai skill。

.DESCRIPTION
  默认只删技能目录，保留工作区（你的 config.json 和日报归档都还在）。
  加 -RemoveWorkspace 才会连工作区一起删。

.PARAMETER Scope
  Project（默认）或 User —— 与安装时用的范围一致。

.PARAMETER ProjectRoot
  Project 范围的项目根目录。默认从脚本位置向上找 .git / .dsh / .agents / package.json。

.PARAMETER SkillRoot
  直接指定技能根目录，覆盖 Scope 的推导结果。

.PARAMETER Workspace
  工作区目录，仅 -RemoveWorkspace 时需要。

.PARAMETER RemoveWorkspace
  连同工作区一起删除（含 config.json、草稿、归档）。会二次确认。

.PARAMETER Force
  跳过确认。

.EXAMPLE
  .\uninstall.ps1
  .\uninstall.ps1 -Scope User
  .\uninstall.ps1 -RemoveWorkspace
#&gt;
[CmdletBinding()]
param(
  [ValidateSet(&#39;Project&#39;, &#39;User&#39;)]
  [string]$Scope = &#39;Project&#39;,
  [string]$ProjectRoot,
  [string]$SkillRoot,
  [string]$Workspace,
  [switch]$RemoveWorkspace,
  [switch]$Force
)

$ErrorActionPreference = &#39;Stop&#39;
$SkillName = &#39;daily-report-huoyuntai&#39;
$Source = $PSScriptRoot

function Find-ProjectRoot($start) {
  $userHome = [System.IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd(&#39;\&#39;)
  $cur = [System.IO.Path]::GetFullPath($start)
  $markers = @(&#39;.git&#39;, &#39;.dsh&#39;, &#39;.agents&#39;, &#39;package.json&#39;)

  $walk = $cur
  while ($walk) {
    if ($walk.TrimEnd(&#39;\&#39;) -ieq $userHome) { break }
    foreach ($m in $markers) {
      if (Test-Path (Join-Path $walk $m)) { return $walk }
    }
    $parent = Split-Path $walk -Parent
    if (-not $parent -or $parent -eq $walk) { break }
    $walk = $parent
  }

  # 发布布局兜底：&lt;项目&gt;\skill\&lt;skill名&gt;\
  $parent = Split-Path $cur -Parent
  if ($parent) {
    $leaf = Split-Path $parent -Leaf
    if ($leaf -eq &#39;skill&#39; -or $leaf -eq &#39;skills&#39;) {
      $grand = Split-Path $parent -Parent
      if ($grand) { return $grand }
    }
  }

  return $null
}

if (-not $ProjectRoot) {
  $found = Find-ProjectRoot $Source
  if ($found) { $ProjectRoot = $found } else { $ProjectRoot = (Get-Location).Path }
}
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE &#39;.dsh&#39; }

if (-not $SkillRoot) {
  if ($Scope -eq &#39;Project&#39;) { $SkillRoot = Join-Path $ProjectRoot &#39;.dsh\skills&#39; }
  else                      { $SkillRoot = Join-Path $dshHome &#39;skills&#39; }
}
if (-not $Workspace) {
  if ($Scope -eq &#39;Project&#39;) { $Workspace = $ProjectRoot }
  else                      { $Workspace = Join-Path $env:USERPROFILE &#39;日报自动化&#39; }
}

$Target = [System.IO.Path]::GetFullPath((Join-Path $SkillRoot $SkillName))
$WorkspaceFull = [System.IO.Path]::GetFullPath($Workspace)

Write-Host &#39;&#39;
Write-Host &#39;  日报自动化 skill · 卸载程序&#39; -ForegroundColor White
Write-Host &#39;  ================================&#39; -ForegroundColor DarkGray
Write-Host &#34;  范围 $Scope&#34; -ForegroundColor DarkGray

# 安全阀：只允许删除明确以 skill 名结尾的目录
if (-not (Split-Path $Target -Leaf).Equals($SkillName, &#39;OrdinalIgnoreCase&#39;)) {
  throw &#34;拒绝执行：目标目录名不是 $SkillName（$Target）&#34;
}

if (-not (Test-Path -LiteralPath $Target)) {
  Write-Host &#34;`n  技能目录不存在，无需删除：$Target&#34; -ForegroundColor Yellow
} else {
  if (-not $Force) {
    $ans = Read-Host &#34;`n  确认删除技能目录？`n    $Target`n  [y/N]&#34;
    if ($ans -notmatch &#39;^[yY]&#39;) { Write-Host &#39;  已取消。&#39; -ForegroundColor Yellow; exit 0 }
  }
  Remove-Item -LiteralPath $Target -Recurse -Force
  Write-Host &#34;  已删除 $Target&#34; -ForegroundColor Green
}

if ($RemoveWorkspace) {
  if (-not (Test-Path -LiteralPath $WorkspaceFull)) {
    Write-Host &#34;  工作区不存在：$WorkspaceFull&#34; -ForegroundColor Yellow
  } else {
    Write-Host &#34;`n  警告：以下目录将连同账号密码和全部归档一起删除&#34; -ForegroundColor Yellow
    Write-Host &#34;    $WorkspaceFull&#34; -ForegroundColor Yellow
    if (-not $Force) {
      $ans2 = Read-Host &#39;  确认？输入 DELETE 继续&#39;
      if ($ans2 -ne &#39;DELETE&#39;) { Write-Host &#39;  已跳过工作区。&#39; -ForegroundColor Yellow; exit 0 }
    }
    Remove-Item -LiteralPath $WorkspaceFull -Recurse -Force
    Write-Host &#34;  已删除 $WorkspaceFull&#34; -ForegroundColor Green
  }
} else {
  Write-Host &#34;`n  工作区保留：$WorkspaceFull&#34; -ForegroundColor DarkGray
  Write-Host &#39;  （如需一并删除，加 -RemoveWorkspace）&#39; -ForegroundColor DarkGray
}

Write-Host &#39;&#39;
</code></pre>
<hr/>
<h2>10. 维护手册</h2>
<h3>加一个新项目 / 新说法</h3>
<p>改 ​<code>scripts/src/report/expand.mjs</code>​ 的 ​<code>ITEM_GLOSSARY</code>​。数组<strong>从上往下匹配，先命中先用</strong>，具体规则要放在宽泛规则前面，例如 ​<code>舆情周报</code>​ 必须在通用的 ​<code>周报</code> 之前。</p>
<h3>改排班</h3>
<p>改 ​<code>config.json</code>​ 的 ​<code>schedule</code>。两个提醒（Windows 计划任务 + 会话定时任务）都会跟着变。</p>
<h3>改思源目录结构</h3>
<p>改 ​<code>siyuan.pathPattern</code>，然后迁移：</p>
<pre><code class="language-bash">node scripts/tools/backfill-siyuan.mjs --days 60 --dry-run --migrate   # 先看
node scripts/tools/backfill-siyuan.mjs --days 60 --migrate             # 再跑
</code></pre>
<p><code>--migrate</code> 会把每个日期文档跟新模板算出的位置比对，位置不对的删掉再重建；只处理日期文档，年/月/周容器不动。</p>
<h3>生成周 / 月小结</h3>
<p>小结是<strong>语言工作</strong>，不是脚本能自动写的。流程：读该周期内的日期文档 → 统计固定项频次 → 按项目归类 → 写进容器文档（​<code>appendBlock</code>，不要删文档）。</p>
<h3>网站改版导致接口失效</h3>
<p>先 ​<code>--check</code>​ 区分登录问题还是接口问题，再按 ​<code>references/接口参考.md</code>​ 最后一节重新定位：抓首页 → 找 ​<code>runtime.js</code>​ 的 chunk hash 规则 → 在 ​<code>app.js</code>​ 搜路由 → 下载对应 chunk → 搜 ​<code>/api/</code> 字符串。bundle 是单行压缩的，要按字节位置截取。</p>
<h3>备份什么</h3>
<p>真正需要备份的只有 ​<strong>​<code>config.json</code>​</strong>​（含凭证）和 ​<strong>​<code>reports/</code>​</strong> （归档）。代码可从技能目录重装，日报原文在火云台服务器上也有。</p>
<hr/>
<h2>11. 已知限制</h2>
<ul>
<li><strong>接口是逆向还原的</strong>，网站改版会失效 —— 最大风险</li>
<li><strong>编辑窗口 ±3 天</strong> —— 只能补交最近三天</li>
<li><strong>不覆盖火云台「工作日报」</strong> —— ​<code>#/home/dayReport</code>​ 是另一套结构化表单（​<code>/api/WorkReport/*</code>）</li>
<li><strong>成句扩写是启发式的</strong> —— 词表外的新说法走兜底，需要偶尔人工润色</li>
<li><strong>思源删除进回收站</strong> —— 覆盖当天日志用「删旧建新」，旧文档留在回收站</li>
<li><strong>周小结/月小结核对靠人</strong> —— 生成后需要过目，尤其「观察」部分容易过度解读</li>
<li><strong>提醒依赖环境</strong> —— Windows 通知需计划任务已注册且用户登录；会话内提醒需 DSH 在运行</li>
</ul>
<hr/>
<p><em>本文档由工作区脚本生成，代码部分与</em> ​<em>​<code>skill/daily-report-huoyuntai/</code>​</em> ​ <em>保持同步。</em></p>
', 'private', NULL, '日报自动化 · 全流程与代码 一套把「口头简写」变成公司日报的自动化： 解析简写 → 成句扩写 → 预演确认 → 双平台发布（火云台 + 思源笔记）→ 回查归档 。 附带 Windows 系统通知提醒、单双休排班判断、历史回填与三级小结。 更新：2026-10-19（新增「周」层级、碎片周模板） 代码量：约 2400 行 依赖：零 1. 它解决什么问题 每天要写日报，但真实的记录是零散的： 沙利文_10.14 头条更新文章 沙利文_10.14 AI更新文章 2篇 新世界_舆情提交反馈并跟进反馈情况 公司要的是成句的项目制写法： 沙利文项目：完成 10.14 头条更新文章发布，完成 10.14 AI 主题更新文章 2 篇。 新世界项目：整理并提交 10.14 舆情反馈，同时跟进反馈情况。 中间这段翻译以前靠人脑，现在靠规则 + 一次人工确认。同一份内容写进两个地方（公司系统 + 个人思源），并按周/月/年归档。 2. 整体架构 口头简写 / 便签 ↓ parse-text.mjs 解析成五个板块 ↓ expand.mjs 成句扩写（项目制句式） ↓ render.mjs 渲成富文本 / Markdown ↓ 预演（给人看） ↓ 人工确认 ┌────┴────┐ ↓ ↓ 火云台 思源笔记 部门人员报告 工作日志/年/月/第N周/日期 ↓ ↓ └────┬────┘ ↓ 回查确认 → 归档 reports/ 四个独立的部分围绕同一份内容： 组件 作用 触发 日报流水线 写日报到两个平台 人工说「提交」 Windows 通知 到点提醒，写过了不吵 计划任务，工作日 17:40 排班判断 单双休轮换，决定哪天算工作日 被通知和人工查询共用 回填 / 小结 历史数据搬家、周月年总结 手动或定时 3. 三个平台的接口 3.1 火云台（huoyuntai.com） 前端是 Vue SPA，真实接口在 ​ https://app-api.suwork.com ，接口逆向还原。 方法 路径 用途 POST /api/Login/login 登录，​ {user_phone, user_pwd} ，无验证码 GET /api/user/getUserInfo 校验登录态 GET /api/UserReport/getUserReportInfo 查某天报告； 无报告返回 null POST /api/UserReport/addUserReport 新增和修改都走这个 ，靠 ​ report_id 区分 鉴权头 ​ Authorization: Bearer &lt;token&gt; ​，token 在登录响应的 ​ data.token 空板块的约定表示是 ​ ​ &lt;p&gt;&lt;/p&gt; ​ ，不是空字符串 3.2 思源笔记（note.nbook.icu） 鉴权头 ​ Authorization: Token &lt;token&gt; 。 方法 路径 用途 POST /api/notebook/lsNotebooks 笔记本列表 POST /api/query/sql SQL 查询块 POST /api/filetree/createDocWithMd 建文档，​ path ​ 是 完整 hpath POST /api/filetree/removeDoc 删文档，​ path ​ 是 存储路径 POST /api/block/appendBlock 往文档追加正文块 POST /api/block/insertBlock 在某块之后插入 POST /api/block/deleteBlock 删除单个块 hpath 和 path 是两个不同的东西 ： 字段 例子 用在哪 hpath /工作日志/2026/10/第3周/2026-10-16 建文档、人类阅读 path /20261019112037-kcekmkz/20261019113333-xxx.sy 删文档 3.3 时间与周编号 报告日期取本机当天。 周编号按「月内第几周」 ：含 1 号的那一周算第 1 周，公式是： week = Math.floor((day - 1 + (1号是周几 as 周一=0)) / 7) + 1 例：2026-10-01 是周四（偏移 3），则 10-19 属 ​ floor((19-1+3)/7)+1 = 4 → 第 4 周。 和思源「日记」笔记本的 ​ 第N周 口径一致。 4. 关键设计决策 4.1 默认只预演，绝不自动提交 submit.mjs ​ 默认预演，只有显式加 ​ --submit 才写入。日报是交给公司系统的东西，写错比写晚更麻烦。 4.2 幂等靠「先查后写」 两个平台都先查当天有没有，再决定新增还是修改。重复运行不会产生重复数据。 4.3 两个目标互不阻塞 火云台和思源是独立两步，一个失败另一个照写： 结果：火云台 ✔ 思源 ✔ 4.4 脚本和状态分离 代码装在技能目录（只读资源），配置 / 草稿 / 归档放工作区。工作区四层解析： ​ DAILY_REPORT_HOME ​ → ​ --home ​ → 从脚本位置向上找 → ​ ~/日报自动化 。 4.5 扩写是启发式，不是黑盒 expand.mjs ​ 的词表显式、可读、可改。命中不了退回通用兜底， 绝不丢内容 。 4.6 层级即总结：年 / 月 / 周 / 日期 思源里的每一层容器文档本身就是那个粒度的总结，形态统一： 层级 例子 内容 年 /2026 年度总结 月 /2026/09 固定产出 / 项目专项 / 观察 周 /2026/09/第3周 做了什么 / 观察 / 下周 日期 /2026/09/第3周/2026-09-17 当天五段日报 4.7 碎片周换模板 月内周序的必然结果：跨月的那一周被切开，会出现只有 1 天的「周」。1 天谈不了节奏，所以： ≥3 天 → 正常周报（做了什么 / 观察 / 下周） 2 天 → 同上，但「观察」只写事实 1 天 → 碎片周模板（ 这天做了什么 / 承接 / 说明 ） 碎片周的价值不是总结，是 接上前后两段 ，让人知道断点在哪、有没有断掉。 5. 踩过的坑（最有价值的部分） 5.1 受限环境里浏览器起不来（放弃飞书自动读取的原因） 方式 结果 Playwright ​ launchPersistentContext spawn EPERM （走命名管道调试） 自启 Chrome + ​ connectOverCDP crashpad 子进程被拒，Chrome 自杀 加 ​ --disable-breakpad FATAL: platform_channel.cc: 拒绝访问 (0x5) 加 ​ --single-process --in-process-gpu 同上，Mojo 命名管道仍被拒 根因 ：限制环境禁止创建命名管道，Chrome 多进程 IPC 强依赖它。 结论 ：这条路在受限环境走不通，最终改成「人工提供内容 + 纯 HTTP 接口」。 5.2 ​ 0x80073D54 进程没有包标识 沙箱内调 WinRT 发系统通知时报这个错，看着像「应用没打包」，实际是 限制环境拦了 WinRT 激活 。 同样代码在计划任务里（沙箱外）完全正常。 报错信息会误导人。 5.3 思源的 SQL 索引有延迟 createDocWithMd ​ 返回成功、文件也落盘了，但紧接着 ​ SELECT ... FROM blocks 查不到。 回填 33 篇时，28 篇报了「写完回查不到」的假错 更要命： 删除时读的是索引，索引没更新就漏删 ，曾因此把文档搞成重复内容叠加 对策 ： 回查重试几次，拿不到只当警告 批量删除时循环多轮，别指望一轮删干净 删到空之后思源会自动补一个空段落， 「删到 0」永远达不到 ，不能当终止条件 5.4 思源的嵌入块不适合做目录 {{SELECT ...}} ​ 查询块会把 命中的块本身 嵌进来。查文档块（​ type=&#39;d&#39; ​）等于把整篇日报全文嵌进页面。 结论 ：做目录用块引用 ​ ((id &#34;文本&#34;)) ，别用嵌入块。 5.5 思源文档块改不了正文 updateBlock ​ 对文档块操作时改的是 标题 （文档块的 content 就是标题），正文在子块里。 结论 ：整篇替换只能「删旧建新」，或 ​ appendBlock 追加。 5.6 ​ root_id 不包含子文档 清空一个容器文档的正文时用 ​ WHERE root_id=&#39;&lt;docId&gt;&#39; ​ 是安全的 —— 子文档有自己独立的 root_id，不会被连带删除。 （但 ​ removeDoc ​ 删文档会连带删子文档，所以对「工作日志」这类有子文档的容器 只能清正文，不能删文档 。） 5.7 其他小坑 坑 说明 PowerShell 5.1 按 GBK 读无 BOM 的 .ps1 中文全乱、语法报错。 所有 .ps1 必须带 UTF-8 BOM $home 是只读自动变量 变量名大小写不敏感，​ $home ​ == ​ $HOME ，赋值报错 向上找项目根撞到用户主目录 主目录下有 ​ .dsh ，会被误认成项目。必须加「不越过 %USERPROFILE%」护栏 记事本存 UTF-8 带 BOM 破坏 JSON 读取统一 ​ replace(/^\uFEFF/, &#39;&#39;) 火云台登录字段名 必须 ​ user_phone ​/​ user_pwd PowerShell 双引号里反引号是转义符 替换含反引号的字符串时会静默失效，改用 Node 或单引号 思源中文容器的排序 「第4周」排在日期后面（中文在数字之后），树里顺序可能不直观 6. 目录结构 daily-report-huoyuntai/ 技能本体（只读） ├─ SKILL.md / README.md ├─ install.ps1 / install.cmd / uninstall.ps1 ├─ scripts/ │ ├─ src/ │ │ ├─ config.mjs 工作区解析 + 配置校验 │ │ ├─ calendar.mjs 单双休排班 │ │ ├─ submit.mjs 主流程 CLI │ │ ├─ report/ 火云台一侧 │ │ │ ├─ client.mjs │ │ │ ├─ parse-text.mjs │ │ │ ├─ expand.mjs │ │ │ └─ render.mjs │ │ └─ siyuan/ 思源一侧 │ │ ├─ client.mjs │ │ └─ publish.mjs │ └─ tools/ │ ├─ is-workday.mjs / check-status.mjs │ ├─ backfill-siyuan.mjs │ ├─ remind.ps1 / install-reminder.ps1 │ └─ fetch-history.mjs ├─ templates/ 配置与草稿模板 └─ references/ 风格指南 + 接口参考 工作区（状态，与技能分离）：​ config.json ​ / ​ drafts/ ​ / ​ reports/ ​ / ​ .cache/ 。 7. 配置 { &#34;huoyuntai&#34;: { &#34;user_phone&#34;: &#34;&#34;, &#34;user_pwd&#34;: &#34;&#34; }, &#34;defaults&#34;: { &#34;type&#34;: 1 }, &#34;schedule&#34;: { &#34;anchorWeek&#34;: &#34;2026-10-12&#34;, &#34;anchorIsDouble&#34;: true, &#34;workdays&#34;: [], &#34;holidays&#34;: [] }, &#34;siyuan&#34;: { &#34;enabled&#34;: true, &#34;url&#34;: &#34;https://note.nbook.icu&#34;, &#34;token&#34;: &#34;&#34;, &#34;notebook&#34;: &#34;20261015151147-ivwb5le&#34;, &#34;parentDoc&#34;: &#34;工作日志&#34;, &#34;pathPattern&#34;: &#34;{year}/{month}/第{week}周/{date}&#34; } } 单双休排班 用「锚点周 + 奇偶交替」，固定规则表达不了交替休： anchorWeek ​：双休那一周的 周一 anchorIsDouble ：锚点周是不是双休 之后每隔一周切换；​ workdays ​/​ holidays 处理法定节假日调休 思源目录结构 pathPattern ​ 占位符 ​ {year} ​ ​ {month} ​ ​ {week} ​ ​ {date} ​ ​ {day} ： pattern 落点 {year}/{month}/第{week}周/{date} （默认） /工作日志/2026/10/第4周/2026-10-19 {year}/{month}/{date} /工作日志/2026/10/2026-10-19 {date} /工作日志/2026-10-19 （平铺） 年 / 月 / 周容器由思源按 hpath 自动创建。 8. 使用方式 node scripts/src/submit.mjs # 预演 node scripts/src/submit.mjs --submit # 提交（两个平台） node scripts/src/submit.mjs --submit --no-siyuan node scripts/src/submit.mjs --check # 只验登录 + 查当天 node scripts/src/submit.mjs --json # 只打印报文 node scripts/src/submit.mjs --raw # 关闭扩写 node scripts/src/submit.mjs --date 2026-10-13 --submit 草稿格式： 已完成 沙利文_10.14 头条更新文章 沙利文_10.14 AI更新文章 2篇 新世界_舆情提交反馈并跟进反馈情况 未完成 Elo_10.14 关键词排名查询 9. 完整代码 9.1 核心逻辑 scripts/src/config.mjs 配置与工作区解析：决定 config.json / drafts / reports 落在哪个目录 import fs from &#39;node:fs&#39;; import os from &#39;node:os&#39;; import path from &#39;node:path&#39;; import { fileURLToPath } from &#39;node:url&#39;; const HERE = path.dirname(fileURLToPath(import.meta.url)); const SCRIPT_ROOT = path.resolve(HERE, &#39;..&#39;); /** 工作区默认位置（User 范围）：用户主目录下的「日报自动化」 */ const DEFAULT_HOME_NAME = &#39;日报自动化&#39;; /** 一个目录要同时有 config.json 和 reports/ 或 drafts/，才认作工作区 */ function looksLikeWorkspace(dir) { return ( fs.existsSync(path.join(dir, &#39;config.json&#39;)) &amp;&amp; (fs.existsSync(path.join(dir, &#39;reports&#39;)) || fs.existsSync(path.join(dir, &#39;drafts&#39;))) ); } /** * 从脚本位置向上找工作区。 * Project 范围安装时，工作区就是项目根，在脚本的好几层上级 * （&lt;项目&gt;/.dsh/skills/&lt;skill&gt;/scripts/src/），所以要往上走。 */ function findWorkspaceUpwards(start, maxDepth = 8) { let cur = start; for (let i = 0; i &lt; maxDepth; i++) { if (looksLikeWorkspace(cur)) return cur; const parent = path.dirname(cur); if (parent === cur) break; cur = parent; } return null; } /** * 解析工作区目录（存放 config.json / drafts / reports / .cache）。 * * 优先级： * 1. 环境变量 DAILY_REPORT_HOME * 2. 命令行参数 --home &lt;dir&gt; * 3. 从脚本位置向上找到的工作区（Project 范围安装时就是项目根） * 4. ~/日报自动化（User 范围安装） */ function resolveHome() { const fromEnv = process.env.DAILY_REPORT_HOME?.trim(); if (fromEnv) return path.resolve(fromEnv); const i = process.argv.indexOf(&#39;--home&#39;); if (i !== -1 &amp;&amp; process.argv[i + 1]) return path.resolve(process.argv[i + 1]); const found = findWorkspaceUpwards(SCRIPT_ROOT); if (found) return found; return path.join(os.homedir(), DEFAULT_HOME_NAME); } export const ROOT = resolveHome(); const CONFIG_PATH = path.join(ROOT, &#39;config.json&#39;); export function configPath() { return CONFIG_PATH; } export function loadConfig() { if (!fs.existsSync(CONFIG_PATH)) { throw new Error( `找不到配置文件：${CONFIG_PATH}\n` + `请把 config.example.json 复制成 config.json，并填入日报站的手机号和密码。\n` + `（也可以设置环境变量 DAILY_REPORT_HOME 指向别的工作区）`, ); } let cfg; try { // 去掉记事本可能写入的 BOM cfg = JSON.parse(fs.readFileSync(CONFIG_PATH, &#39;utf8&#39;).replace(/^\uFEFF/, &#39;&#39;)); } catch (e) { throw new Error(`config.json 不是合法 JSON：${e.message}`); } const phone = String(cfg?.huoyuntai?.user_phone ?? &#39;&#39;).trim(); const pwd = String(cfg?.huoyuntai?.user_pwd ?? &#39;&#39;); if (!phone || phone.includes(&#39;填&#39;)) throw new Error(&#39;config.json 里 huoyuntai.user_phone 还没填。&#39;); if (!pwd || pwd.includes(&#39;填&#39;)) throw new Error(&#39;config.json 里 huoyuntai.user_pwd 还没填。&#39;); return { user_phone: phone, user_pwd: pwd, type: Number(cfg?.defaults?.type ?? 1), }; } /** 脱敏后的手机号，用于日志 */ export function maskPhone(phone) { const s = String(phone); if (s.length &lt; 7) return &#39;***&#39;; return `${s.slice(0, 3)}****${s.slice(-4)}`; } /** * 读思源笔记的配置（可选目标）。 * 没配就是 null —— 表示只发火云台。 */ export function loadSiYuanConfig() { if (!fs.existsSync(CONFIG_PATH)) return null; let cfg; try { cfg = JSON.parse(fs.readFileSync(CONFIG_PATH, &#39;utf8&#39;).replace(/^\uFEFF/, &#39;&#39;)); } catch { return null; } const s = cfg?.siyuan; if (!s) return null; if (s.enabled === false) return null; const url = String(s.url ?? &#39;&#39;).trim(); const notebook = String(s.notebook ?? &#39;&#39;).trim(); const token = String(s.token ?? &#39;&#39;); // 没填地址或笔记本，就当没配 if (!url || url.includes(&#39;填&#39;) || !notebook || notebook.includes(&#39;填&#39;)) return null; return { url, token, notebook, parentDoc: String(s.parentDoc ?? &#39;工作日志&#39;).trim(), // 父文档下的子目录结构，占位符：{year} {month} {week} {date} pathPattern: String(s.pathPattern ?? &#39;{year}/{month}/第{week}周/{date}&#39;).trim() || &#39;{year}/{month}/第{week}周/{date}&#39;, tokenMissing: !token || token.includes(&#39;填&#39;), }; } scripts/src/calendar.mjs 单双休轮换排班：判断某天该不该上班 /** * 排班日历：判断某天是不是工作日。 * * 公司的休息制度是「单双休轮换」—— 一周双休（周六周日都休）， * 下一周单休（只休周日，周六要上班），交替进行。 * * 固定的「周一到周五」规则表达不了这个，所以用「锚点周 + 奇偶交替」来算： * 锚点周（默认 2026-10-12 那一周）是双休，之后每隔一周切换一次。 * * 遇到法定节假日调休，可以在 config.json 的 schedule 里手工加例外： * &#34;workdays&#34;: [&#34;2026-10-24&#34;], // 强制算工作日 * &#34;holidays&#34;: [&#34;2026-10-01&#34;] // 强制算休息日 */ import fs from &#39;node:fs&#39;; import path from &#39;node:path&#39;; import { ROOT } from &#39;./config.mjs&#39;; export const DEFAULT_SCHEDULE = { /** 锚点周的周一。这一周的休息制度由 anchorIsDouble 决定 */ anchorWeek: &#39;2026-10-12&#39;, /** 锚点周是不是双休 */ anchorIsDouble: true, /** 强制算工作日的日期（调休上班） */ workdays: [], /** 强制算休息日的日期（法定假日） */ holidays: [], }; const CONFIG_PATH = path.join(ROOT, &#39;config.json&#39;); /** 读 config.json 里的 schedule 块，缺项用默认值补齐 */ export function loadSchedule() { let raw = {}; try { raw = JSON.parse(fs.readFileSync(CONFIG_PATH, &#39;utf8&#39;).replace(/^\uFEFF/, &#39;&#39;)); } catch { // 没有配置文件或读不动，就用默认排班 } const s = raw?.schedule ?? {}; return { anchorWeek: typeof s.anchorWeek === &#39;string&#39; ? s.anchorWeek : DEFAULT_SCHEDULE.anchorWeek, anchorIsDouble: typeof s.anchorIsDouble === &#39;boolean&#39; ? s.anchorIsDouble : DEFAULT_SCHEDULE.anchorIsDouble, workdays: Array.isArray(s.workdays) ? s.workdays.map(String) : [], holidays: Array.isArray(s.holidays) ? s.holidays.map(String) : [], }; } /** 取某天所在周的周一（本地时间） */ function mondayOf(dateStr) { const d = new Date(`${dateStr}T00:00:00`); const dow = (d.getDay() + 6) % 7; // 0=周一 … 6=周日 d.setDate(d.getDate() - dow); d.setHours(0, 0, 0, 0); return d; } /** 相对锚点周相差几周（锚点周为 0，可以为负） */ export function weekIndex(dateStr, anchorWeek) { const a = mondayOf(anchorWeek); const b = mondayOf(dateStr); return Math.round((b - a) / (7 * 24 * 60 * 60 * 1000)); } const WEEKDAY_NAME = [&#39;周日&#39;, &#39;周一&#39;, &#39;周二&#39;, &#39;周三&#39;, &#39;周四&#39;, &#39;周五&#39;, &#39;周六&#39;]; /** * @returns {{ workday: boolean, reason: string, weekType?: &#39;双休&#39;|&#39;单休&#39;, weekIndex?: number }} */ export function isWorkday(dateStr, schedule = loadSchedule()) { if (schedule.workdays.includes(dateStr)) { return { workday: true, reason: &#39;手工指定为工作日&#39; }; } if (schedule.holidays.includes(dateStr)) { return { workday: false, reason: &#39;手工指定为休息日&#39; }; } const d = new Date(`${dateStr}T00:00:00`); if (Number.isNaN(d.getTime())) return { workday: false, reason: `日期无法解析：${dateStr}` }; const dow = d.getDay(); if (dow &gt;= 1 &amp;&amp; dow &lt;= 5) { return { workday: true, reason: WEEKDAY_NAME[dow] }; } if (dow === 0) { return { workday: false, reason: &#39;周日（永远休）&#39; }; } // 周六：看这一周是单休还是双休 const idx = weekIndex(dateStr, schedule.anchorWeek); const isDouble = Math.abs(idx) % 2 === 0 ? schedule.anchorIsDouble : !schedule.anchorIsDouble; return { workday: !isDouble, reason: isDouble ? &#39;双休周的周六（休）&#39; : &#39;单休周的周六（要上班）&#39;, weekType: isDouble ? &#39;双休&#39; : &#39;单休&#39;, weekIndex: idx, }; } scripts/src/submit.mjs 主流程 CLI：预演 / 提交 / 回查 / 归档 #!/usr/bin/env node import fs from &#39;node:fs&#39;; import path from &#39;node:path&#39;; import { ROOT, loadConfig, loadSiYuanConfig, maskPhone } from &#39;./config.mjs&#39;; import { createReportClient } from &#39;./report/client.mjs&#39;; import { SECTIONS, buildPayload, htmlToText, validateDraft } from &#39;./report/render.mjs&#39;; import { parsePlainText, describeSections } from &#39;./report/parse-text.mjs&#39;; import { expandToProse } from &#39;./report/expand.mjs&#39;; import { publishToSiYuan, buildMarkdown, renderPathPattern } from &#39;./siyuan/publish.mjs&#39;; // ---------- 参数 ---------- function parseArgs(argv) { const out = { submit: false, check: false, json: false, raw: false, noSiYuan: false, draft: null, date: null, help: false }; for (let i = 0; i &lt; argv.length; i++) { const a = argv[i]; if (a === &#39;--submit&#39;) out.submit = true; else if (a === &#39;--dry-run&#39;) out.submit = false; else if (a === &#39;--check&#39;) out.check = true; else if (a === &#39;--json&#39;) out.json = true; else if (a === &#39;--raw&#39;) out.raw = true; else if (a === &#39;--prose&#39;) out.raw = false; else if (a === &#39;--no-siyuan&#39;) out.noSiYuan = true; else if (a === &#39;--draft&#39;) out.draft = argv[++i]; else if (a === &#39;--date&#39;) out.date = argv[++i]; else if (a === &#39;--help&#39; || a === &#39;-h&#39;) out.help = true; else if (!a.startsWith(&#39;-&#39;) &amp;&amp; !out.draft) out.draft = a; else throw new Error(`未知参数：${a}`); } return out; } function todayLocal() { const d = new Date(); const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;); return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`; } const line = (c = &#39;─&#39;) =&gt; console.log(c.repeat(64)); /** 找草稿：显式指定优先；否则按 .txt → .md → .json 找当天的 */ function resolveDraftPath(explicit, date) { if (explicit) { const p = path.resolve(ROOT, explicit); return fs.existsSync(p) ? p : null; } for (const ext of [&#39;.txt&#39;, &#39;.md&#39;, &#39;.json&#39;]) { const p = path.join(ROOT, &#39;drafts&#39;, `${date}${ext}`); if (fs.existsSync(p)) return p; } return null; } const HELP = ` 用法： node src/submit.mjs [草稿文件] [--date YYYY-MM-DD] [--submit] node src/submit.mjs --check 草稿可以是纯文本（.txt，推荐）或 JSON（.json）。 默认找 drafts/&lt;今天&gt;.txt → .md → .json。 纯文本格式：小标题下面每行一条，空行随便加。 已完成 沙利文_10.13头条更新文章 新世界_10.13舆情周报 未完成 库存同步联调 小标题认这些写法： 已完成 / 未完成 / 需协调 / 明日计划 / 备注 也认：今日已完成、进行中、协调事项、明天计划、计划、卡点、说明 … 带冒号、方括号、井号、数字编号都能识别。 默认会把「今日已完成工作」扩写成公司惯用的项目制成句风格 （见 docs/风格指南.md）；加 --raw 则照抄原文。 默认是「预演」模式：只打印将要提交的内容，不写入任何系统。 加 --submit 才会真正提交。 --check 只验证登录态并查当天是否已填过。 --json 只打印将要发出去的完整报文（不联网、不需要配置）。 --no-siyuan 只发火云台，跳过思源笔记。 配了思源笔记（config.json 的 siyuan 块）时，--submit 会同时写火云台和思源； 哪边失败会明确报出来，不会静默只成功一边。 `.trim(); function preview(payload, draftPath) { line(); console.log(`草稿：${draftPath ? path.relative(ROOT, draftPath) : &#39;(内存)&#39;}`); console.log(`日期：${payload.report_date} 类型：${payload.type}（日报）`); line(); for (const s of SECTIONS) { const text = htmlToText(payload[s.key]); console.log(`\n【${s.label}】${text ? &#39;&#39; : &#39;（空）&#39;}`); if (text) console.log(text.split(&#39;\n&#39;).map((l) =&gt; ` · ${l}`).join(&#39;\n&#39;)); } line(); } // ---------- 主流程 ---------- async function main() { const args = parseArgs(process.argv.slice(2)); if (args.help) { console.log(HELP); return 0; } const date = args.date || todayLocal(); // --check：只验证登录 + 查当天状态 if (args.check) { const cfg = loadConfig(); const client = createReportClient({ ...cfg, log: (m) =&gt; console.log(` · ${m}`) }); console.log(`账号：${maskPhone(cfg.user_phone)} 日期：${date} 类型：日报`); line(); const info = await client.verify(); console.log(`登录成功，当前用户：${info?.name ?? info?.user_name ?? &#39;(接口未返回姓名)&#39;}`); const existing = await client.getReportInfo({ report_date: date, type: cfg.type }); if (existing) { console.log(`当天已有日报（id=${existing.report_id ?? existing.id}）：`); for (const s of SECTIONS) { const t = htmlToText(existing[s.key] ?? &#39;&#39;); console.log(`\n【${s.label}】`); console.log(t ? t.split(&#39;\n&#39;).map((l) =&gt; ` · ${l}`).join(&#39;\n&#39;) : &#39; （空）&#39;); } } else { console.log(&#39;当天还没有填过日报。&#39;); } return 0; } // ---------- 读草稿 ---------- const draftPath = resolveDraftPath(args.draft, date); if (!draftPath) { const want = args.draft ? path.resolve(ROOT, args.draft) : path.join(ROOT, &#39;drafts&#39;, `${date}.txt`); console.error(`找不到草稿文件：${want}`); console.error(`新建一个文本文件，把今天做的事按「已完成 / 未完成」写进去即可。`); console.error(`格式参考 drafts/example.txt，也支持 drafts/example.json。`); return 2; } const raw = fs.readFileSync(draftPath, &#39;utf8&#39;).replace(/^\uFEFF/, &#39;&#39;); const isPlainText = !draftPath.toLowerCase().endsWith(&#39;.json&#39;); let draft; if (isPlainText) { const { draft: d, warnings, sectionsSeen } = parsePlainText(raw, { report_date: date }); draft = d; for (const w of warnings) console.log(` ⚠ ${w}`); if (sectionsSeen.length) console.log(` 识别到板块：${describeSections(sectionsSeen)}`); } else { try { draft = JSON.parse(raw); } catch (e) { console.error(`草稿不是合法 JSON：${e.message}`); return 2; } } const problems = validateDraft(draft, date); if (problems.length) { console.error(&#39;草稿有问题，先修一下：&#39;); for (const p of problems) console.error(` ✗ ${p}`); return 2; } // ---------- 成句扩写（默认开启；--raw 可关闭，照抄原文） ---------- // 条目里没写日期的，用报告日期兜底（2026-10-14 → 10.14） const defaultDate = String(draft.report_date || date).slice(5).replace(&#39;-&#39;, &#39;.&#39;); if (!args.raw &amp;&amp; Array.isArray(draft.complete_work) &amp;&amp; draft.complete_work.length) { const { html, sentences } = expandToProse(draft.complete_work, { defaultDate }); if (html) { draft.complete_work = html; console.log(&#39; 成句扩写：&#39;); for (const s of sentences) console.log(` → ${s}`); } } // --json：只打印将要提交的报文，不联网、不需要配置 if (args.json) { console.log(JSON.stringify(buildPayload(draft, { type: 1, report_date: date }), null, 2)); return 0; } let cfg; try { cfg = loadConfig(); } catch (e) { if (args.submit) { console.error(e.message); return 3; } // 预演模式下没配置也要能看到内容 preview(buildPayload(draft, { type: 1, report_date: date }), draftPath); console.log(`\n⚠ ${e.message}`); console.log(&#39;[预演模式] 内容如上，但没有连接日报系统。&#39;); return 0; } const client = createReportClient({ ...cfg, log: (m) =&gt; console.log(` · ${m}`) }); const payload = buildPayload(draft, { type: cfg.type, report_date: date }); const siyuan = args.noSiYuan ? null : loadSiYuanConfig(); console.log(`账号：${maskPhone(cfg.user_phone)}`); if (siyuan) console.log(`思源：${siyuan.url} 笔记本 ${siyuan.notebook}`); // 提交模式下先确认登录能通，免得打完一屏预览才发现密码不对 if (args.submit) await client.verify(); preview(payload, draftPath); // ---------- 思源笔记：目标与正文预览 ---------- if (siyuan) { line(); console.log(&#39;【思源笔记】将写入&#39;); const subPath = renderPathPattern(siyuan.pathPattern, payload.report_date); console.log( ` 位置：${siyuan.url} → ${siyuan.parentDoc ? `${siyuan.parentDoc}/` : &#39;&#39;}${subPath}`, ); if (siyuan.tokenMissing) { console.log(&#39; ⚠ API token 还没填（config.json 的 siyuan.token），正式提交时会跳过思源&#39;); } console.log(&#39;&#39;); console.log( buildMarkdown(payload) .split(&#39;\n&#39;) .map((l) =&gt; ` ${l}`) .join(&#39;\n&#39;), ); line(); } // ---------- 查重 ---------- let existing = null; try { existing = await client.getReportInfo({ report_date: payload.report_date, type: payload.type }); } catch (e) { if (args.submit) throw e; console.log(`\n⚠ 连不上日报系统：${e.message}`); console.log(&#39;[预演模式] 内容如上，但没能查重。&#39;); return 0; } const mode = existing ? &#39;edit&#39; : &#39;add&#39;; const existingId = existing?.report_id ?? existing?.id ?? &#39;&#39;; console.log( existing ? `当天已存在日报（id=${existingId}）→ 将执行「修改」` : &#39;当天还没有日报 → 将执行「新增」&#39;, ); if (!args.submit) { console.log(&#39;\n[预演模式] 没有提交任何内容。确认无误后加 --submit 正式提交。&#39;); return 0; } // ---------- 提交到火云台 ---------- // 跟网站前端保持一致：统一走 addUserReport，用 report_id 决定新增还是覆盖 payload.report_id = existingId || &#39;&#39;; line(&#39;═&#39;); console.log(&#39;正在提交…&#39;); let huoyuntaiOk = false; let huoyuntaiMsg = &#39;&#39;; try { const res = await client.addReport(payload); huoyuntaiMsg = `code=${res.code} msg=${res.msg ?? &#39;&#39;}`; huoyuntaiOk = res.code === 0; } catch (e) { huoyuntaiMsg = e.message; } console.log(`火云台：${huoyuntaiOk ? &#39;✔&#39; : &#39;✘&#39;} ${huoyuntaiMsg}`); // ---------- 回查确认 ---------- if (huoyuntaiOk) { const verify = await client.getReportInfo({ report_date: payload.report_date, type: payload.type }); if (verify) { const firstLine = htmlToText(verify.complete_work || &#39;&#39;).split(&#39;\n&#39;)[0] || &#39;(空)&#39;; console.log(` 回查：report_id=${verify.report_id} 已完成工作首行：${firstLine}`); } else { console.log(&#39; ⚠ 回查没读到这条报告，请到网站上确认一下。&#39;); } } // ---------- 归档 ---------- const outDir = path.join(ROOT, &#39;reports&#39;); fs.mkdirSync(outDir, { recursive: true }); fs.writeFileSync( path.join(outDir, `${payload.report_date}.json`), JSON.stringify({ ...payload, _submitted_at: new Date().toISOString(), _mode: mode }, null, 2), &#39;utf8&#39;, ); fs.writeFileSync( path.join(outDir, `${payload.report_date}.md`), [ `# 日报 ${payload.report_date}`, &#39;&#39;, ...SECTIONS.flatMap((s) =&gt; { const t = htmlToText(payload[s.key]); return [`## ${s.label}`, &#39;&#39;, t || &#39;（空）&#39;, &#39;&#39;]; }), ].join(&#39;\n&#39;), &#39;utf8&#39;, ); // ---------- 发布到思源笔记 ---------- let siyuanOk = null; if (siyuan) { if (siyuan.tokenMissing) { console.log(&#39;思源： ⚠ 跳过（API token 没填）&#39;); } else { try { const r = await publishToSiYuan(siyuan, payload, { log: (m) =&gt; console.log(` · ${m}`) }); siyuanOk = true; console.log(`思源： ✔ ${r.action === &#39;create&#39; ? &#39;已新建&#39; : &#39;已覆盖&#39;} ${r.hpath}（id=${r.docId}）`); for (const w of r.warnings) console.log(` ⚠ ${w}`); } catch (e) { siyuanOk = false; console.log(`思源： ✘ ${e.message}`); } } } // ---------- 汇总 ---------- line(&#39;═&#39;); const parts = [`火云台 ${huoyuntaiOk ? &#39;✔&#39; : &#39;✘&#39;}`]; if (siyuan) parts.push(`思源 ${siyuanOk === true ? &#39;✔&#39; : siyuanOk === false ? &#39;✘&#39; : &#39;跳过&#39;}`); console.log(`结果：${parts.join(&#39; &#39;)}`); if (!huoyuntaiOk) { console.error(&#39;火云台提交失败。&#39;); return 1; } if (siyuanOk === false) { console.error(&#39;火云台已成功，但思源写入失败 —— 内容已归档到 reports/，可稍后重跑。&#39;); return 1; } console.log(`完成 ✔ 已归档到 reports/${payload.report_date}.{json,md}`); return 0; } main() .then((code) =&gt; process.exit(code)) .catch((e) =&gt; { console.error(`\n出错了：${e.message}`); process.exit(1); }); scripts/src/report/parse-text.mjs 便签文本 → 五个板块 /** * 解析「便签式」日报文本。 * * 格式：用「已完成 / 未完成 / 需协调 / 明日计划 / 备注」当小标题， * 标题下面每行一条。大小标题可带冒号、方括号、井号、数字编号、短横线。 * 空行忽略；某标题下没有内容就是该板块为空。 */ /** 小标题 → 字段名。键必须完全一致（归一化之后） */ const HEADER_MAP = new Map([ // 今日已完成工作 [&#39;已完成&#39;, &#39;complete_work&#39;], [&#39;今日已完成&#39;, &#39;complete_work&#39;], [&#39;已完成工作&#39;, &#39;complete_work&#39;], [&#39;今日已完成工作&#39;, &#39;complete_work&#39;], [&#39;完成&#39;, &#39;complete_work&#39;], [&#39;完成工作&#39;, &#39;complete_work&#39;], [&#39;做了&#39;, &#39;complete_work&#39;], [&#39;今天做了&#39;, &#39;complete_work&#39;], // 今日未完成工作 [&#39;未完成&#39;, &#39;unfinished_work&#39;], [&#39;今日未完成&#39;, &#39;unfinished_work&#39;], [&#39;未完成工作&#39;, &#39;unfinished_work&#39;], [&#39;今日未完成工作&#39;, &#39;unfinished_work&#39;], [&#39;进行中&#39;, &#39;unfinished_work&#39;], [&#39;在做&#39;, &#39;unfinished_work&#39;], [&#39;待完成&#39;, &#39;unfinished_work&#39;], // 明日需协调事项 [&#39;需协调&#39;, &#39;coordinate_work&#39;], [&#39;需协调事项&#39;, &#39;coordinate_work&#39;], [&#39;明日需协调&#39;, &#39;coordinate_work&#39;], [&#39;明日需协调事项&#39;, &#39;coordinate_work&#39;], [&#39;协调事项&#39;, &#39;coordinate_work&#39;], [&#39;协调&#39;, &#39;coordinate_work&#39;], [&#39;卡点&#39;, &#39;coordinate_work&#39;], [&#39;阻塞&#39;, &#39;coordinate_work&#39;], // 明日计划 [&#39;明日计划&#39;, &#39;tomorrow_plan&#39;], [&#39;明天计划&#39;, &#39;tomorrow_plan&#39;], [&#39;计划&#39;, &#39;tomorrow_plan&#39;], [&#39;下一步&#39;, &#39;tomorrow_plan&#39;], [&#39;待办&#39;, &#39;tomorrow_plan&#39;], // 备注 [&#39;备注&#39;, &#39;remark&#39;], [&#39;说明&#39;, &#39;remark&#39;], [&#39;其他&#39;, &#39;remark&#39;], ]); /** 标题常见的后缀，允许「未完成事项」这种写法 */ const SUFFIXES = [&#39;事项&#39;, &#39;工作&#39;, &#39;内容&#39;, &#39;情况&#39;, &#39;部分&#39;]; /** 标题都很短；太长的行一律当内容，避免把任务名误判成标题 */ const MAX_HEADER_LEN = 10; function lookupHeader(norm) { if (norm.length &gt; MAX_HEADER_LEN) return undefined; if (HEADER_MAP.has(norm)) return HEADER_MAP.get(norm); for (const s of SUFFIXES) { if (norm.length &gt; s.length + 1 &amp;&amp; norm.endsWith(s)) { const base = norm.slice(0, -s.length); if (HEADER_MAP.has(base)) return HEADER_MAP.get(base); } } return undefined; } /** 去掉常见的排版装饰，便于识别标题 */ function normalize(line) { return line .trim() .replace(/^[#&gt;*\-\s]+/, &#39;&#39;) // 井号、引用、星号、短横线 .replace(/^\d+[.、)）]\s*/, &#39;&#39;) // &#34;1. &#34; / &#34;1、&#34; .replace(/[【\[（(]/g, &#39;&#39;) .replace(/[】\]）)]/g, &#39;&#39;) .replace(/[：:]\s*$/, &#39;&#39;) .replace(/\s+/g, &#39;&#39;) .trim(); } /** 去掉条目行前面的项目符号 */ function stripBullet(line) { return line .trim() .replace(/^[-*·•+]\s*/, &#39;&#39;) .replace(/^\d+[.、)）]\s*/, &#39;&#39;) .trim(); } const HEADER_LOOKS_LIKE = /^(已完成|未完成|需协调|明日计划|明天计划|备注|计划|进行中)/; /** * @param {string} text * @returns {{ draft: object, warnings: string[], sectionsSeen: string[] }} */ export function parsePlainText(text, { report_date } = {}) { const warnings = []; const draft = { report_date, complete_work: [], unfinished_work: [], coordinate_work: [], tomorrow_plan: [], remark: [], }; const sectionsSeen = []; let current = null; const orphans = []; const rawLines = String(text).replace(/\r\n?/g, &#39;\n&#39;).split(&#39;\n&#39;); for (const raw of rawLines) { const t = raw.trim(); if (!t) continue; // 单独一行「日期 2026-10-14」之类，识别为日期 const dateMatch = t.match(/^(?:日期|date)\s*[：:]?\s*(\d{4}-\d{2}-\d{2})\s*$/i); if (dateMatch) { draft.report_date = dateMatch[1]; continue; } // 也接受 10.14 / 10/14 这种简写（当年） const shortDate = t.match(/^(?:日期|date)\s*[：:]?\s*(\d{1,2})[.\-/](\d{1,2})\s*$/i); if (shortDate) { const y = new Date().getFullYear(); draft.report_date = `${y}-${shortDate[1].padStart(2, &#39;0&#39;)}-${shortDate[2].padStart(2, &#39;0&#39;)}`; continue; } const norm = normalize(t); const key = lookupHeader(norm); if (key) { current = key; if (!sectionsSeen.includes(key)) sectionsSeen.push(key); continue; } const item = stripBullet(t); if (!item) continue; if (current) { if (!draft[current].includes(item)) draft[current].push(item); } else if (HEADER_LOOKS_LIKE.test(norm)) { // 看起来像标题但没认出来（比如「未完成事项」），提醒一下 warnings.push(`这行看着像小标题但没认出来，已当作内容处理：${t}`); orphans.push(item); } else { orphans.push(item); } } // 没有任何小标题 → 全部算「已完成」，并提醒 if (sectionsSeen.length === 0 &amp;&amp; orphans.length) { draft.complete_work = orphans; warnings.push(&#39;没找到「已完成 / 未完成」这类小标题，已把全部内容放进「今日已完成工作」。&#39;); } else if (orphans.length) { draft.complete_work.push(...orphans); warnings.push(`有 ${orphans.length} 行在小标题之前，已并入「今日已完成工作」。`); } return { draft, warnings, sectionsSeen }; } /** 输入里出现了哪些小标题（给个反馈） */ export function describeSections(keys) { const names = { complete_work: &#39;今日已完成工作&#39;, unfinished_work: &#39;今日未完成工作&#39;, coordinate_work: &#39;明日需协调事项&#39;, tomorrow_plan: &#39;明日计划&#39;, remark: &#39;备注&#39;, }; return keys.map((k) =&gt; names[k] ?? k).join(&#39;、&#39;); } scripts/src/report/expand.mjs 简写 → 项目制成句（扩写引擎） /** * 把「简写条目」扩写成公司日报的成句风格。 * * 输入（简写）： 沙利文_10.14AI更新文章 2篇 * 输出（成句）： 沙利文项目：完成 10.14 AI 主题更新文章 2 篇。 * * 规则来自对历史日报的归纳，见 docs/风格指南.md。 * 词条表可以随时扩充；没命中的条目会走通用兜底，不会被丢掉。 */ /** 条目词条表：把简写归一到「动作 + 短语」 */ const ITEM_GLOSSARY = [ { match: /^头条/, verb: &#39;完成&#39;, phrase: (c) =&gt; `${c.date} 头条更新文章发布` }, { match: /^AI\s*(更新)?文章|^AI\s*主题/, verb: &#39;完成&#39;, phrase: (c) =&gt; `${c.date} AI 主题更新文章${c.countText ? ` ${c.countText}` : &#39;&#39;}`, }, // 舆情反馈：可能是「反馈」「舆情反馈5条」「舆情提交反馈并跟进反馈情况」 { match: /舆情.*反馈|^反馈|反馈情况/, verb: (core) =&gt; (/提交/.test(core) ? &#39;整理并提交&#39; : &#39;整理&#39;), phrase: (c) =&gt; `${c.date ? `${c.date} ` : &#39;&#39;}舆情反馈`, tail: (c, core) =&gt; { const bits = []; if (c.countText) bits.push(`共计 ${c.countText}`); if (/跟进|跟踪/.test(core)) bits.push(&#39;同时跟进反馈情况&#39;); return bits.join(&#39;，&#39;); }, }, { match: /舆情周报/, verb: &#39;编制并输出&#39;, phrase: (c) =&gt; `${c.date} 舆情周报` }, // 通用周报：沙利文GEO周报、沙利文周报、某某周报…（历史习惯是「编制并输出…」+ 归档收尾） { match: /周报/, verb: &#39;编制并输出&#39;, phrase: (c) =&gt; `${c.date} ${c.item}` }, { match: /关键词排名|排名查询|^排名$/, verb: &#39;完成&#39;, phrase: (c) =&gt; `${c.date} 关键词排名查询` }, { match: /^月报/, verb: &#39;更新&#39;, phrase: (c) =&gt; `${c.date} 月报` }, { match: /^官网更新文章/, verb: &#39;完成&#39;, phrase: () =&gt; &#39;官网文章更新&#39; }, { match: /^官网\s*AI\s*文章/, verb: &#39;完成&#39;, phrase: () =&gt; &#39;官网 AI 文章发布&#39; }, { match: /^达人资源|^博主资源|房产博主/, verb: &#39;拓展&#39;, phrase: (c) =&gt; `${c.item}` }, { match: /季度报告|^周报$/, verb: &#39;编制并输出&#39;, phrase: (c) =&gt; `${c.date} ${c.item}` }, ]; /** 括号里的补充说明 → 成句里的从句 */ const NOTE_GLOSSARY = [ { match: /公众|公众号/, clause: &#39;同时将公众号稿件同步至头条平台&#39; }, { match: /同步/, clause: &#39;相关稿件已同步归档&#39; }, ]; /** 报告类事项的收尾语 */ const TAIL_CLAUSE = &#39;相关文档整理归档&#39;; /** 拆出「项目_日期」前缀；没写日期的带项目条目会用报告日期兜底 */ function splitPrefix(line, defaultDate) { const withDate = line.match(/^([^_（）()]{1,12})_(\d{1,2}[.\-/]\d{1,2})\s*(.*)$/); if (withDate) { return { project: withDate[1].trim(), date: withDate[2].replace(/[/-]/g, &#39;.&#39;), item: withDate[3].trim(), }; } const withProject = line.match(/^([^_（）()]{1,12})_(.+)$/); if (withProject) { return { project: withProject[1].trim(), date: defaultDate ?? &#39;&#39;, item: withProject[2].trim() }; } return { project: &#39;&#39;, date: &#39;&#39;, item: line }; } /** 从条目里剥出数量和括号备注 */ function splitDecorations(item) { let note = &#39;&#39;; const noteMatch = item.match(/[（(]([^）)]+)[）)]/); if (noteMatch) { note = noteMatch[1].trim(); item = item.replace(noteMatch[0], &#39;&#39;).trim(); } let countText = &#39;&#39;; const countMatch = item.match(/\s*(\d+)\s*([篇条份个项])$/); if (countMatch) { // 历史习惯是「2 篇」「10 条」，数字和单位之间留空格 countText = `${countMatch[1]} ${countMatch[2]}`; item = item.slice(0, countMatch.index).trim(); } return { item, countText, note }; } /** 单条 → { project, verb, phrase, noteClause, tailClause } */ function toClause(raw, defaultDate) { const { project, date, item } = splitPrefix(raw, defaultDate); const { item: core, countText, note } = splitDecorations(item); const ctx = { date, item: core, countText }; let verb = &#39;完成&#39;; let phrase = `${date ? `${date} ` : &#39;&#39;}${core}${countText ? ` ${countText}` : &#39;&#39;}`; let tailClause = &#39;&#39;; for (const g of ITEM_GLOSSARY) { if (g.match.test(core)) { verb = typeof g.verb === &#39;function&#39; ? g.verb(core, ctx) : g.verb; phrase = g.phrase(ctx); if (g.tail) tailClause = g.tail(ctx, core); break; } } let noteClause = &#39;&#39;; if (note) { for (const n of NOTE_GLOSSARY) { if (n.match.test(note)) { noteClause = n.clause; break; } } if (!noteClause) noteClause = note; } return { project, verb, phrase, noteClause, tailClause }; } /** 动词和短语之间的空格：只在短语以数字开头时留（「完成 10.14 …」），中文直接相连 */ function joinVerb(verb, phrase) { if (!phrase) return verb; return /^\d/.test(phrase) ? `${verb} ${phrase}` : `${verb}${phrase}`; } /** * @param {string[]} lines 简写条目 * @param {{ defaultDate?: string }} opts defaultDate 形如 &#34;10.14&#34; * @returns {{ html: string, sentences: string[] }} */ export function expandToProse(lines, { defaultDate = &#39;&#39; } = {}) { const clauses = lines.map((l) =&gt; toClause(l, defaultDate)).filter((c) =&gt; c.phrase); const groups = []; for (const c of clauses) { const last = groups[groups.length - 1]; if (c.project &amp;&amp; last &amp;&amp; last.project === c.project) last.items.push(c); else groups.push({ project: c.project, items: [c] }); } const sentences = groups.map((g) =&gt; { const parts = g.items.map((it) =&gt; joinVerb(it.verb, it.phrase)); for (const it of g.items) { if (it.tailClause) parts.push(it.tailClause); if (it.noteClause) parts.push(it.noteClause); } // 报告类（周报/月报/季度报告）历史习惯补一句归档收尾 const isReport = g.items.some((it) =&gt; it.verb === &#39;编制并输出&#39;); const hasExtra = g.items.some((it) =&gt; it.noteClause || it.tailClause); if (isReport &amp;&amp; !hasExtra) parts.push(TAIL_CLAUSE); const body = parts.join(&#39;，&#39;); // 有项目的加「X项目：」前缀 const text = g.project ? `${g.project}项目：${body}` : body; return text.replace(/[。；;]+$/, &#39;&#39;) + &#39;。&#39;; }); const html = sentences.length === 0 ? &#39;&#39; : `&lt;ol&gt;${sentences.map((s) =&gt; `&lt;li&gt;${s}&lt;/li&gt;`).join(&#39;&#39;)}&lt;/ol&gt;`; return { html, sentences }; } export { TAIL_CLAUSE }; scripts/src/report/render.mjs 草稿 → 富文本 HTML /** 日报五个板块的字段定义（界面标签 → 接口字段名） */ export const SECTIONS = [ { key: &#39;complete_work&#39;, label: &#39;今日已完成工作&#39; }, { key: &#39;unfinished_work&#39;, label: &#39;今日未完成工作&#39; }, { key: &#39;coordinate_work&#39;, label: &#39;明日需协调事项&#39; }, { key: &#39;tomorrow_plan&#39;, label: &#39;明日计划&#39; }, { key: &#39;remark&#39;, label: &#39;备注&#39; }, ]; const ESC = { &#39;&amp;&#39;: &#39;&amp;amp;&#39;, &#39;&lt;&#39;: &#39;&amp;lt;&#39;, &#39;&gt;&#39;: &#39;&amp;gt;&#39; }; function escapeHtml(s) { return String(s).replace(/[&amp;&lt;&gt;]/g, (c) =&gt; ESC[c]); } /** * 把草稿里的一段内容渲染成编辑器能吃的 HTML。 * - 已经是 HTML 片段（以 &lt; 开头）→ 原样返回 * - 字符串数组 → &lt;ul&gt;&lt;li&gt;… * - 单个字符串 → &lt;p&gt;… * - 空 → &#39;&#39; */ export function toHtml(value) { if (value === null || value === undefined) return &#39;&#39;; if (Array.isArray(value)) { const items = value .map((v) =&gt; String(v ?? &#39;&#39;).trim()) .filter(Boolean) .flatMap((v) =&gt; v.split(&#39;\n&#39;).map((x) =&gt; x.trim()).filter(Boolean)); if (items.length === 0) return &#39;&#39;; if (items.length === 1) return `&lt;p&gt;${escapeHtml(items[0])}&lt;/p&gt;`; return `&lt;ul&gt;${items.map((i) =&gt; `&lt;li&gt;${escapeHtml(i)}&lt;/li&gt;`).join(&#39;&#39;)}&lt;/ul&gt;`; } const text = String(value).trim(); if (!text) return &#39;&#39;; if (text.startsWith(&#39;&lt;&#39;)) return text; // 已经是 HTML const lines = text.split(&#39;\n&#39;).map((l) =&gt; l.trim()).filter(Boolean); if (lines.length === 1) return `&lt;p&gt;${escapeHtml(lines[0])}&lt;/p&gt;`; return `&lt;ul&gt;${lines.map((l) =&gt; `&lt;li&gt;${escapeHtml(l)}&lt;/li&gt;`).join(&#39;&#39;)}&lt;/ul&gt;`; } /** 站点约定的「空内容」表示（不是空字符串） */ export const EMPTY_HTML = &#39;&lt;p&gt;&lt;br&gt;&lt;/p&gt;&#39;; /** 草稿对象 → 提交载荷 */ export function buildPayload(draft, { type, report_date }) { const payload = { report_id: draft.report_id || &#39;&#39;, type: Number(draft.type ?? type), report_date: draft.report_date || report_date, }; for (const s of SECTIONS) { payload[s.key] = toHtml(draft[s.key]) || EMPTY_HTML; } return payload; } /** HTML → 给人看的纯文本预览 */ export function htmlToText(html) { if (!html) return &#39;&#39;; return html .replace(/&lt;\/(p|li|ul|ol|div|h[1-6])&gt;/gi, &#39;\n&#39;) .replace(/&lt;br\s*\/?&gt;/gi, &#39;\n&#39;) .replace(/&lt;[^&gt;]+&gt;/g, &#39;&#39;) .replace(/&amp;amp;/g, &#39;&amp;&#39;) .replace(/&amp;lt;/g, &#39;&lt;&#39;) .replace(/&amp;gt;/g, &#39;&gt;&#39;) .replace(/&amp;nbsp;/g, &#39; &#39;) .split(&#39;\n&#39;) .map((l) =&gt; l.trim()) .filter(Boolean) .join(&#39;\n&#39;); } /** 校验草稿，返回问题列表 */ export function validateDraft(draft, date) { const problems = []; if (!draft || typeof draft !== &#39;object&#39;) { problems.push(&#39;草稿不是对象&#39;); return problems; } const d = draft.report_date || date; if (!/^\d{4}-\d{2}-\d{2}$/.test(String(d))) problems.push(`report_date 格式不对：${d}`); const filled = SECTIONS.filter((s) =&gt; toHtml(draft[s.key]) !== &#39;&#39;); if (filled.length === 0) problems.push(&#39;五个板块全是空的，没有内容可提交&#39;); return problems; } scripts/src/report/client.mjs 火云台 API 客户端 import fs from &#39;node:fs&#39;; import path from &#39;node:path&#39;; import crypto from &#39;node:crypto&#39;; import { ROOT } from &#39;../config.mjs&#39;; const API_BASE = &#39;https://app-api.suwork.com&#39;; const CACHE_FILE = path.join(ROOT, &#39;.cache&#39;, &#39;token.json&#39;); const UA = &#39;Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36&#39;; function fp(phone) { return crypto.createHash(&#39;sha256&#39;).update(String(phone)).digest(&#39;hex&#39;).slice(0, 16); } function readCache(phone) { try { const j = JSON.parse(fs.readFileSync(CACHE_FILE, &#39;utf8&#39;)); if (j.fp === fp(phone) &amp;&amp; j.token) return j.token; } catch {} return null; } function writeCache(phone, token) { fs.mkdirSync(path.dirname(CACHE_FILE), { recursive: true }); fs.writeFileSync(CACHE_FILE, JSON.stringify({ fp: fp(phone), token }, null, 2), &#39;utf8&#39;); } function clearCache() { try { fs.rmSync(CACHE_FILE, { force: true }); } catch {} } async function request(method, apiPath, { token, query, body } = {}) { let url = API_BASE + apiPath; if (query) { const qs = new URLSearchParams(); for (const [k, v] of Object.entries(query)) qs.set(k, String(v ?? &#39;&#39;)); url += `?${qs}`; } const headers = { accept: &#39;application/json, text/plain, */*&#39;, &#39;content-type&#39;: &#39;application/json&#39;, origin: &#39;https://www.huoyuntai.com&#39;, referer: &#39;https://www.huoyuntai.com/&#39;, &#39;user-agent&#39;: UA, }; if (token) headers.authorization = `Bearer ${token}`; const res = await fetch(url, { method, headers, body: body === undefined ? undefined : JSON.stringify(body), }); const text = await res.text(); let json; try { json = JSON.parse(text); } catch { throw new Error(`接口 ${apiPath} 返回了非 JSON 内容（HTTP ${res.status}）：${text.slice(0, 300)}`); } return json; } /** * 登录并返回 token。登录响应结构：{ code: 0, data: { token, version } } */ async function login(user_phone, user_pwd, log) { log?.(`登录中（${user_phone.slice(0, 3)}****${user_phone.slice(-4)}）…`); const r = await request(&#39;POST&#39;, &#39;/api/Login/login&#39;, { body: { user_phone, user_pwd } }); if (r.code !== 0 || !r.data?.token) { throw new Error(`登录失败：${r.msg || JSON.stringify(r).slice(0, 200)}`); } return r.data.token; } export function createReportClient({ user_phone, user_pwd, log = () =&gt; {} }) { let token = readCache(user_phone); async function withToken(method, apiPath, opts = {}, retried = false) { if (!token) token = await login(user_phone, user_pwd, log); const r = await request(method, apiPath, { ...opts, token }); // 会话失效：清缓存重登一次 if (r.code === 403 &amp;&amp; !retried) { log(`会话已失效（${r.msg || &#39;403&#39;}），重新登录…`); clearCache(); token = await login(user_phone, user_pwd, log); return withToken(method, apiPath, opts, true); } if (r.code !== 0) { throw new Error(`接口 ${apiPath} 失败：${r.msg || JSON.stringify(r).slice(0, 200)}`); } return r; } return { /** 判断登录态是否可用 */ async verify() { const r = await withToken(&#39;GET&#39;, &#39;/api/user/getUserInfo&#39;, {}); return r.data; }, /** 查询某天是否已有报告（原始返回，调试用） */ async rawReportInfo({ report_date, type }) { return withToken(&#39;GET&#39;, &#39;/api/UserReport/getUserReportInfo&#39;, { query: { report_id: &#39;&#39;, type, report_date }, }); }, /** 查询某天是否已有报告 */ async getReportInfo({ report_date, type }) { const r = await withToken(&#39;GET&#39;, &#39;/api/UserReport/getUserReportInfo&#39;, { query: { report_id: &#39;&#39;, type, report_date }, }); const d = r.data; // 接口可能返回 {} 或 [] 或 null 表示没有 if (!d || (Array.isArray(d) &amp;&amp; d.length === 0)) return null; if (typeof d === &#39;object&#39; &amp;&amp; !d.report_id &amp;&amp; !d.id) return null; return d; }, async addReport(payload) { return withToken(&#39;POST&#39;, &#39;/api/UserReport/addUserReport&#39;, { body: payload }); }, async editReport(payload) { return withToken(&#39;POST&#39;, &#39;/api/UserReport/editUserReport&#39;, { body: payload }); }, }; } scripts/src/siyuan/client.mjs 思源笔记 API 客户端 /** * 思源笔记（SiYuan）API 客户端。 * * 鉴权：请求头 `Authorization: Token &lt;API token&gt;` * token 在思源里「设置 → 关于 → API token」。 * * 用到的接口： * POST /api/system/version 版本（免鉴权，用来探连通性） * POST /api/notebook/lsNotebooks 笔记本列表 * POST /api/query/sql SQL 查询（找文档） * POST /api/filetree/createDocWithMd 新建文档（path = hpath，markdown 正文） * POST /api/block/updateBlock 覆盖已有文档内容 * POST /api/filetree/removeDoc 删除文档（回滚/清理用） */ export function normalizeUrl(url) { return String(url ?? &#39;&#39;).trim().replace(/\/+$/, &#39;&#39;); } export function createSiYuanClient({ url, token, log = () =&gt; {} }) { const base = normalizeUrl(url); if (!base) throw new Error(&#39;思源地址没填（config.json 的 siyuan.url）&#39;); if (!token || String(token).includes(&#39;填&#39;)) { throw new Error(&#39;思源 API token 没填（config.json 的 siyuan.token）&#39;); } async function call(apiPath, body = {}, { timeoutMs = 20000 } = {}) { const ctrl = new AbortController(); const timer = setTimeout(() =&gt; ctrl.abort(), timeoutMs); let res; try { res = await fetch(base + apiPath, { method: &#39;POST&#39;, signal: ctrl.signal, headers: { &#39;content-type&#39;: &#39;application/json&#39;, authorization: `Token ${token}`, }, body: JSON.stringify(body), }); } catch (e) { throw new Error(`连不上思源 ${base}（${e.message}）`); } finally { clearTimeout(timer); } const text = await res.text(); let json; try { json = JSON.parse(text); } catch { throw new Error(`思源 ${apiPath} 返回非 JSON（HTTP ${res.status}）：${text.slice(0, 200)}`); } if (json.code !== 0) { const hint = json.code === -1 &amp;&amp; /auth/i.test(json.msg ?? &#39;&#39;) ? &#39;（API token 不对，或思源没开 API）&#39; : &#39;&#39;; throw new Error(`思源 ${apiPath} 失败：${json.msg || JSON.stringify(json)}${hint}`); } return json.data; } return { /** 探连通性 + 版本（不需要 token） */ async version() { const r = await fetch(`${base}/api/system/version`, { method: &#39;POST&#39;, headers: { &#39;content-type&#39;: &#39;application/json&#39; }, body: &#39;{}&#39;, }); const j = await r.json(); return j.data ?? null; }, /** 笔记本列表 */ async listNotebooks() { const d = await call(&#39;/api/notebook/lsNotebooks&#39;); return d?.notebooks ?? []; }, /** 执行 SQL，返回行数组 */ async sql(stmt) { return (await call(&#39;/api/query/sql&#39;, { stmt })) ?? []; }, /** 新建文档，path 是 hpath（如 /工作日志/2026-10-19），返回 docId */ async createDocWithMd({ notebook, path: docPath, markdown }) { return await call(&#39;/api/filetree/createDocWithMd&#39;, { notebook, path: docPath, markdown, }); }, /** 覆盖某个块（文档根块 id 就是 docId）的内容 */ async updateBlock({ id, markdown }) { return await call(&#39;/api/block/updateBlock&#39;, { id, dataType: &#39;markdown&#39;, data: markdown, }); }, /** 往某个块（通常是文档根块）末尾追加 Markdown 内容 */ async appendBlock({ parentID, markdown }) { return await call(&#39;/api/block/appendBlock&#39;, { parentID, dataType: &#39;markdown&#39;, data: markdown, }); }, /** 在某个块之后插入 Markdown 内容 */ async insertBlock({ previousID, markdown }) { return await call(&#39;/api/block/insertBlock&#39;, { previousID, dataType: &#39;markdown&#39;, data: markdown, }); }, /** 删除一个块 */ async deleteBlock({ id }) { return await call(&#39;/api/block/deleteBlock&#39;, { id }); }, /** 删除文档 */ async removeDoc({ notebook, path: docPath }) { return await call(&#39;/api/filetree/removeDoc&#39;, { notebook, path: docPath }); }, }; } scripts/src/siyuan/publish.mjs 日报 → 思源文档（目录结构、幂等、回查、周编号） /** * 把日报发布到思源笔记。 * * 目标形态：在指定笔记本里，名为「工作日志」的文档下面， * 每天建一篇标题是日期的文档，内容是五段日报的 Markdown。 * * 幂等：当天已有同名文档就覆盖内容，不会重复创建。 */ import { createSiYuanClient } from &#39;./client.mjs&#39;; /** 日报五段 → 思源里的二级标题 */ const SECTION_TITLES = [ [&#39;complete_work&#39;, &#39;今日已完成工作&#39;], [&#39;unfinished_work&#39;, &#39;今日未完成工作&#39;], [&#39;coordinate_work&#39;, &#39;明日需协调事项&#39;], [&#39;tomorrow_plan&#39;, &#39;明日计划&#39;], [&#39;remark&#39;, &#39;备注&#39;], ]; /** 把日报的富文本 HTML 转成 Markdown（只处理我们自己生成的这几种结构） */ export function htmlToMarkdown(html) { if (!html || !String(html).trim()) return &#39;&#39;; let s = String(html); const isOrdered = /&lt;ol[\s&gt;]/i.test(s); // 列表项 let n = 0; s = s.replace(/&lt;li[^&gt;]*&gt;([\s\S]*?)&lt;\/li&gt;/gi, (_m, inner) =&gt; { const text = stripInline(inner); if (!text) return &#39;&#39;; return isOrdered ? `${++n}. ${text}\n` : `- ${text}\n`; }); // 段落 s = s.replace(/&lt;p[^&gt;]*&gt;([\s\S]*?)&lt;\/p&gt;/gi, (_m, inner) =&gt; { const text = stripInline(inner); return text ? `${text}\n\n` : &#39;&#39;; }); // 剩下的容器标签 s = s.replace(/&lt;\/?(ol|ul)[^&gt;]*&gt;/gi, &#39;&#39;); s = s.replace(/&lt;br\s*\/?&gt;/gi, &#39;\n&#39;); s = stripInline(s); return s .split(&#39;\n&#39;) .map((l) =&gt; l.replace(/\s+$/, &#39;&#39;)) .join(&#39;\n&#39;) .replace(/\n{3,}/g, &#39;\n\n&#39;) .trim(); } function stripInline(s) { return String(s) .replace(/&lt;[^&gt;]+&gt;/g, &#39;&#39;) .replace(/&amp;nbsp;/g, &#39; &#39;) .replace(/&amp;lt;/g, &#39;&lt;&#39;) .replace(/&amp;gt;/g, &#39;&gt;&#39;) .replace(/&amp;amp;/g, &#39;&amp;&#39;) .trim(); } /** 日报载荷 → 思源文档正文 */ export function buildMarkdown(payload) { const blocks = []; for (const [key, title] of SECTION_TITLES) { const md = htmlToMarkdown(payload[key]); if (!md) continue; blocks.push(`## ${title}\n\n${md}`); } return blocks.length ? `${blocks.join(&#39;\n\n&#39;)}\n` : &#39;&#39;; } /** SQL 字符串转义 */ function q(s) { return String(s).replace(/&#39;/g, &#34;&#39;&#39;&#34;); } /** * 某天是该月的第几周（1 起），含 1 号的那一周算第 1 周。 * 和思源「日记」笔记本的 `第N周` 编号口径一致。 */ export function weekOfMonth(date) { const dt = new Date(`${date}T00:00:00`); if (Number.isNaN(dt.getTime())) return 1; const first = new Date(dt.getFullYear(), dt.getMonth(), 1); const offset = (first.getDay() + 6) % 7; // 1 号是周几，周一 = 0 return Math.floor((dt.getDate() - 1 + offset) / 7) + 1; } /** * 按模板生成父文档下的子路径。 * 占位符：{year} {month} {week} {date} {day} * &#39;{year}/{month}/{date}&#39; → 2026/10/2026-10-19 * &#39;{year}/{month}/第{week}周/{date}&#39; → 2026/10/第4周/2026-10-19 * &#39;{date}&#39; → 2026-10-19（平铺） */ export function renderPathPattern(pattern, date) { const [y = &#39;&#39;, m = &#39;&#39;, d = &#39;&#39;] = String(date).split(&#39;-&#39;); return String(pattern) .replace(/\{year\}/g, y) .replace(/\{month\}/g, m) .replace(/\{week\}/g, String(weekOfMonth(date))) .replace(/\{date\}/g, date) .replace(/\{day\}/g, d) .split(&#39;/&#39;) .map((seg) =&gt; seg.trim()) .filter(Boolean) .join(&#39;/&#39;); } /** 找到「工作日志」这个父文档的 hpath；找不到就返回空串（建在笔记本根） */ async function resolveParentHPath(client, notebook, parentDoc) { if (!parentDoc) return &#39;&#39;; const byTitle = await client.sql( `SELECT id, hpath, content FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39; AND content=&#39;${q(parentDoc)}&#39; LIMIT 5`, ); if (byTitle?.length) return byTitle[0].hpath; const byPath = await client.sql( `SELECT id, hpath FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39; AND hpath LIKE &#39;%/${q(parentDoc)}&#39; LIMIT 5`, ); if (byPath?.length) return byPath[0].hpath; return null; // 明确表示「没找到父文档」 } /** 按 hpath 找现有文档（同时取到存储 path，removeDoc 需要它） */ async function findDocByHPath(client, notebook, hpath) { const rows = await client.sql( `SELECT id, hpath, path FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39; AND hpath=&#39;${q(hpath)}&#39; LIMIT 1`, ); return rows?.[0] ?? null; } /** * 发布当天日报到思源。 * * @returns {{ action:&#39;create&#39;|&#39;update&#39;, docId:string, hpath:string, markdown:string, warnings:string[] }} */ export async function publishToSiYuan(siyuanConfig, payload, { log = () =&gt; {}, dryRun = false } = {}) { const { url, token, notebook, parentDoc = &#39;工作日志&#39; } = siyuanConfig ?? {}; if (!notebook || String(notebook).includes(&#39;填&#39;)) { throw new Error(&#39;思源笔记本 ID 没填（config.json 的 siyuan.notebook）&#39;); } const markdown = buildMarkdown(payload); if (!markdown.trim()) throw new Error(&#39;日报内容为空，没什么可发的&#39;); const client = createSiYuanClient({ url, token, log }); const warnings = []; // 1. 确认笔记本存在 const notebooks = await client.listNotebooks(); const nb = notebooks.find((x) =&gt; x.id === notebook); if (!nb) { const names = notebooks.map((x) =&gt; `${x.name}(${x.id})`).join(&#39;、&#39;) || &#39;(无)&#39;; throw new Error(`思源里找不到笔记本 ${notebook}。现有的：${names}`); } if (nb.closed) warnings.push(`笔记本「${nb.name}」当前是关闭状态，写完可能看不到内容`); log(`笔记本：${nb.name}`); // 2. 定位父文档，算出目标 hpath // 目录结构由 pathPattern 决定，默认 年份/月份/日期 → /工作日志/2026/10/2026-10-19 const parentHPath = await resolveParentHPath(client, notebook, parentDoc); const pattern = siyuanConfig?.pathPattern || &#39;{year}/{month}/{date}&#39;; const subPath = renderPathPattern(pattern, payload.report_date); const base = parentHPath ?? &#39;&#39;; if (parentHPath === null &amp;&amp; parentDoc) { warnings.push(`没找到名为「${parentDoc}」的文档，将建在笔记本根目录`); } const hpath = `${base}/${subPath}`; log(`目标文档：${nb.name}${hpath}`); // 3. 已存在就重建，否则新建 // 注意：文档块的 content 是「标题」，正文在子块里，所以 updateBlock 换不掉正文。 // 这里用「删掉重建」来保证内容整体替换（日报是整篇重写，不需要保留块 id）。 const existing = await findDocByHPath(client, notebook, hpath); const action = existing ? &#39;update&#39; : &#39;create&#39;; if (dryRun) { return { action, docId: existing?.id ?? &#39;(将新建)&#39;, hpath, markdown, warnings }; } if (existing) { // removeDoc 要的是存储路径（/笔记本ID/文档ID.sy），不是 hpath await client.removeDoc({ notebook, path: existing.path }); log(`已删除旧文档 ${existing.id}（稍后重建）`); } const created = await client.createDocWithMd({ notebook, path: hpath, markdown }); // 返回值可能是字符串（旧版）或对象 {id, hPath, ...}（新版） const createdId = typeof created === &#39;string&#39; ? created : created?.id; const createdHPath = typeof created === &#39;object&#39; &amp;&amp; created ? created.hPath : null; if (!createdId) throw new Error(&#39;思源没有返回新文档 id，创建可能失败&#39;); if (createdHPath &amp;&amp; createdHPath !== hpath) { // 落地位置和预期不一致 —— 清掉误建的，明确报错，不要留下脏数据 warnings.push(`文档实际建在 ${createdHPath}，与预期的 ${hpath} 不一致`); try { await client.removeDoc({ notebook, path: createdHPath }); warnings.push(&#39;已删除建错位置的文档&#39;); } catch { warnings.push(&#39;清理建错的文档失败，请手动检查&#39;); } throw new Error(`思源文档落点不对：期望 ${hpath}，实际 ${createdHPath}`); } log(`${action === &#39;create&#39; ? &#39;已新建&#39; : &#39;已重建&#39;}文档 ${createdId}`); // 4. 回查确认 // 注意：思源建完文档后 SQL 索引有延迟，立刻查常常查不到（文档其实已经写好了）。 // 所以这里重试几次，仍查不到只当作警告，不当失败。 let check = null; for (let i = 0; i &lt; 6 &amp;&amp; !check; i++) { await new Promise((r) =&gt; setTimeout(r, 250 * (i + 1))); try { check = await findDocByHPath(client, notebook, hpath); } catch { // 单次查询失败忽略，继续重试 } } if (!check) { warnings.push(&#39;思源的 SQL 索引尚未更新，暂时回查不到这篇（文档通常已建好，稍后刷新即可）&#39;); return { action, docId: createdId, hpath, markdown, warnings }; } return { action, docId: check.id, hpath, markdown, warnings }; } /** * 重建父文档里的「最近日志」链接列表。 * * 为什么不用思源的嵌入块：嵌入块会把命中的**块本身**原样嵌进来， * 查文档块（type=&#39;d&#39;）等于把整篇日报全文嵌进页面，不是目录该有的样子。 * 所以这里改成「手写链接列表 + 自动化维护」： * - 只重写 indexHeading 那一节（到下一个同级或更高级标题为止） * - 其余内容（说明、项目表、每月复盘）一律不动 * * @returns {{ count:number, heading:string, created:boolean }} */ export async function rebuildIndex(siyuanConfig, { log = () =&gt; {}, limit = 30, dryRun = false } = {}) { const { url, token, notebook, parentDoc = &#39;工作日志&#39;, indexHeading = &#39;最近日志&#39;, } = siyuanConfig ?? {}; const client = createSiYuanClient({ url, token, log }); // 1. 父文档 const parents = await client.sql( `SELECT id, hpath, path FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39; AND content=&#39;${q(parentDoc)}&#39; LIMIT 1`, ); const parent = parents?.[0]; if (!parent) throw new Error(`找不到「${parentDoc}」文档，无法维护索引`); // 2. 现有日期文档（新到旧） const rows = await client.sql( `SELECT content FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(notebook)}&#39;` + ` AND hpath LIKE &#39;${q(parent.hpath)}/%&#39; AND content LIKE &#39;____-__-__&#39;` + ` ORDER BY content DESC LIMIT ${Number(limit) || 30}`, ); const dates = rows.map((r) =&gt; r.content); const listMd = dates.length ? dates.map((d) =&gt; `- [[${d}]]`).join(&#39;\n&#39;) : &#39;- （还没有日志）&#39;; // 3. 找到 indexHeading 那一节 const blocks = await client.sql( `SELECT id, type, content, sort FROM blocks WHERE root_id=&#39;${q(parent.id)}&#39; AND type!=&#39;d&#39; ORDER BY sort`, ); const headIdx = blocks.findIndex( (b) =&gt; b.type === &#39;h&#39; &amp;&amp; String(b.content ?? &#39;&#39;).trim() === indexHeading, ); if (headIdx === -1) { // 没有这一节 → 在文档末尾补一个标题 + 列表 if (dryRun) return { count: dates.length, heading: indexHeading, created: true }; await client.appendBlock({ parentID: parent.id, markdown: `## ${indexHeading}\n\n${listMd}\n`, }); log(`已补建「${indexHeading}」小节（${dates.length} 条）`); return { count: dates.length, heading: indexHeading, created: true }; } const head = blocks[headIdx]; const headLevel = String(head.subtype ?? &#39;h2&#39;).replace(&#39;h&#39;, &#39;&#39;) || &#39;2&#39;; // 这一节的范围：标题之后，到下一个「同级或更高级」标题为止 const tail = []; for (let i = headIdx + 1; i &lt; blocks.length; i++) { const b = blocks[i]; if (b.type === &#39;h&#39;) { const lvl = String(b.subtype ?? &#39;h2&#39;).replace(&#39;h&#39;, &#39;&#39;) || &#39;2&#39;; if (Number(lvl) &lt;= Number(headLevel)) break; // 遇到同级/上级标题，本节结束 } tail.push(b); } if (dryRun) return { count: dates.length, heading: indexHeading, created: false }; // 4. 删掉旧列表块，再把新列表插到标题后面 for (const b of tail) { await client.deleteBlock({ id: b.id }); } await client.insertBlock({ previousID: head.id, markdown: listMd }); log(`「${indexHeading}」已重建：${dates.length} 条`); return { count: dates.length, heading: indexHeading, created: false }; } 9.2 外围脚本 scripts/tools/is-workday.mjs 命令行查某天算不算工作日，可列出未来排班 /** * 判断某天是不是工作日（单双休轮换）。 * * 用法： * node is-workday.mjs # 今天 * node is-workday.mjs --date 2026-10-24 * node is-workday.mjs --days 14 # 列出今天起 14 天的排班（人看） * * 单日输出一行 JSON：{&#34;date&#34;:&#34;2026-10-24&#34;,&#34;workday&#34;:true,&#34;reason&#34;:&#34;单休周的周六（要上班）&#34;} * 永远退出码 0，判断结果放在 JSON 里。 */ import { isWorkday, loadSchedule, weekIndex } from &#39;../src/calendar.mjs&#39;; function arg(name) { const i = process.argv.indexOf(name); return i !== -1 &amp;&amp; process.argv[i + 1] ? process.argv[i + 1] : null; } function fmt(d) { const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;); return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`; } const schedule = loadSchedule(); const days = Number(arg(&#39;--days&#39;) || 0); if (days &gt; 0) { console.log(`排班表（锚点周 ${schedule.anchorWeek}，${schedule.anchorIsDouble ? &#39;双休&#39; : &#39;单休&#39;}）\n`); const base = new Date(`${arg(&#39;--date&#39;) || fmt(new Date())}T00:00:00`); const NAME = [&#39;日&#39;, &#39;一&#39;, &#39;二&#39;, &#39;三&#39;, &#39;四&#39;, &#39;五&#39;, &#39;六&#39;]; for (let i = 0; i &lt; days; i++) { const d = new Date(base); d.setDate(d.getDate() + i); const ds = fmt(d); const r = isWorkday(ds, schedule); const idx = weekIndex(ds, schedule.anchorWeek); console.log( ` ${ds} 周${NAME[d.getDay()]} 第${String(idx).padStart(3)}周 ${r.workday ? &#39;上班&#39; : &#39;休息&#39;} ${r.reason}`, ); } process.exit(0); } const date = arg(&#39;--date&#39;) || fmt(new Date()); const r = isWorkday(date, schedule); process.stdout.write(JSON.stringify({ date, workday: r.workday, reason: r.reason, weekType: r.weekType ?? null }) + &#39;\n&#39;); process.exit(0); scripts/tools/check-status.mjs 查某天日报写没写，输出 JSON，供通知脚本判断 /** * 检查某天的日报写没写，输出机器可读的 JSON，供 remind.ps1 判断要不要弹通知。 * * 用法：node check-status.mjs [--home &lt;工作区&gt;] [--date YYYY-MM-DD] * * 输出（stdout 一行 JSON）： * {&#34;ok&#34;:true, &#34;date&#34;:&#34;2026-10-14&#34;, &#34;filed&#34;:false, &#34;reportId&#34;:113793, &#34;error&#34;:null} * {&#34;ok&#34;:false,&#34;date&#34;:&#34;2026-10-14&#34;, &#34;filed&#34;:null, &#34;reportId&#34;:null, &#34;error&#34;:&#34;…&#34;} * * 永远以退出码 0 结束 —— 判断结果放在 JSON 里，避免调用方去解析报错文本。 */ import { loadConfig } from &#39;../src/config.mjs&#39;; import { createReportClient } from &#39;../src/report/client.mjs&#39;; import { SECTIONS, htmlToText } from &#39;../src/report/render.mjs&#39;; function arg(name) { const i = process.argv.indexOf(name); return i !== -1 &amp;&amp; process.argv[i + 1] ? process.argv[i + 1] : null; } function todayLocal() { const d = new Date(); const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;); return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`; } const date = arg(&#39;--date&#39;) || todayLocal(); function emit(obj) { process.stdout.write(JSON.stringify(obj) + &#39;\n&#39;); } try { const cfg = loadConfig(); const client = createReportClient({ ...cfg, log: () =&gt; {} }); const report = await client.getReportInfo({ report_date: date, type: cfg.type }); if (!report) { emit({ ok: true, date, filed: false, reportId: null, error: null }); } else { const filled = SECTIONS.filter((s) =&gt; htmlToText(report[s.key] ?? &#39;&#39;).trim() !== &#39;&#39;); emit({ ok: true, date, filed: filled.length &gt; 0, filledSections: filled.map((s) =&gt; s.label), reportId: report.report_id ?? report.id ?? null, error: null, }); } } catch (e) { emit({ ok: false, date, filed: null, reportId: null, error: String(e?.message ?? e) }); } process.exit(0); scripts/tools/backfill-siyuan.mjs 历史回填 + 目录结构迁移 /** * 把历史日报回填到思源笔记。 * * 数据来源：火云台（按日期查），不是本地归档 —— 以服务器上的内容为准。 * * 用法： * node backfill-siyuan.mjs --days 30 --dry-run # 先看会推哪些 * node backfill-siyuan.mjs --only 2026-10-16 # 只推一天 * node backfill-siyuan.mjs --days 30 # 真推 * node backfill-siyuan.mjs --from 2026-10-01 --to 2026-10-16 * * 幂等：某天已存在同名文档就删了重建，不会重复累积。 * 空的（五段全空）日报会跳过，不会建空文档。 */ import { loadConfig, loadSiYuanConfig } from &#39;../src/config.mjs&#39;; import { createReportClient } from &#39;../src/report/client.mjs&#39;; import { SECTIONS, htmlToText } from &#39;../src/report/render.mjs&#39;; import { publishToSiYuan, renderPathPattern } from &#39;../src/siyuan/publish.mjs&#39;; import { createSiYuanClient } from &#39;../src/siyuan/client.mjs&#39;; function arg(name) { const i = process.argv.indexOf(name); return i !== -1 &amp;&amp; process.argv[i + 1] ? process.argv[i + 1] : null; } function flag(name) { return process.argv.includes(name); } function ymd(d) { const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;); return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`; } const only = arg(&#39;--only&#39;); const from = arg(&#39;--from&#39;); const to = arg(&#39;--to&#39;); const days = Number(arg(&#39;--days&#39;) || 60); const dryRun = flag(&#39;--dry-run&#39;); // 待处理的日期列表（新到旧） const dates = []; if (only) { dates.push(only); } else { const end = to ? new Date(`${to}T00:00:00`) : new Date(); const start = from ? new Date(`${from}T00:00:00`) : new Date(end.getTime() - (days - 1) * 86400000); for (let d = new Date(end); d &gt;= start; d.setDate(d.getDate() - 1)) dates.push(ymd(d)); } const cfg = loadConfig(); const siyuan = loadSiYuanConfig(); if (!siyuan) { console.error(&#39;没配思源（config.json 的 siyuan 块）&#39;); process.exit(2); } if (siyuan.tokenMissing) { console.error(&#39;思源 API token 没填&#39;); process.exit(2); } const client = createReportClient({ ...cfg, log: () =&gt; {} }); console.log(`扫描 ${dates.length} 天${dryRun ? &#39;（预演）&#39; : &#39;&#39;}：${dates[dates.length - 1]} ~ ${dates[0]}\n`); // ---------- 可选：迁移目录结构 ---------- // 把所有「日期文档」跟当前 pathPattern 算出的目标位置比一遍， // 位置不对的删掉，后面正常的推送会按新结构重建。 // 比固定规则（只删单层）更通用：改了模板就能自动跟进。 if (flag(&#39;--migrate&#39;)) { const q = (v) =&gt; String(v).replace(/&#39;/g, &#34;&#39;&#39;&#34;); const sx = createSiYuanClient({ url: siyuan.url, token: siyuan.token }); const parent = await sx.sql( `SELECT id, hpath FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(siyuan.notebook)}&#39; AND content=&#39;${q(siyuan.parentDoc)}&#39; LIMIT 1`, ); const parentHPath = parent?.[0]?.hpath ?? &#39;&#39;; const rows = await sx.sql( `SELECT id, hpath, path, content FROM blocks WHERE type=&#39;d&#39; AND box=&#39;${q(siyuan.notebook)}&#39; AND hpath LIKE &#39;${q(parentHPath)}/%&#39;`, ); let removed = 0; for (const r of rows) { // 只处理日期文档；年/月/周这些容器文档一律不动 if (!/^\d{4}-\d{2}-\d{2}$/.test(r.content ?? &#39;&#39;)) continue; const expected = `${parentHPath}/${renderPathPattern(siyuan.pathPattern, r.content)}`; if (r.hpath === expected) continue; // 位置已经对了 if (dryRun) { console.log(` [预演] 待迁移 ${r.hpath} → ${expected}`); } else { // removeDoc 要的是存储路径（/笔记本ID/文档ID.sy），不是 hpath await sx.removeDoc({ notebook: siyuan.notebook, path: r.path }); console.log(` 迁移：删除旧位置 ${r.hpath}`); } removed++; } console.log(`结构迁移：${dryRun ? &#39;将删除&#39; : &#39;已删除&#39;} ${removed} 篇旧位置文档\n`); } const pushed = []; const skipped = []; const failed = []; for (const date of dates) { let report; try { report = await client.getReportInfo({ report_date: date, type: cfg.type }); } catch (e) { failed.push({ date, error: `查日报失败：${e.message}` }); console.log(` ${date} ✘ 查日报失败：${e.message}`); continue; } if (!report) { skipped.push({ date, reason: &#39;没有报告&#39; }); continue; } const filled = SECTIONS.filter((s) =&gt; htmlToText(report[s.key] ?? &#39;&#39;).trim() !== &#39;&#39;); if (filled.length === 0) { skipped.push({ date, reason: &#39;内容为空&#39; }); continue; } const payload = { report_date: date, type: cfg.type }; for (const s of SECTIONS) payload[s.key] = report[s.key] ?? &#39;&#39;; try { const r = await publishToSiYuan(siyuan, payload, { dryRun }); pushed.push({ date, action: r.action, hpath: r.hpath, sections: filled.map((s) =&gt; s.label) }); console.log(` ${date} ✔ ${r.action === &#39;create&#39; ? &#39;新建&#39; : &#39;重建&#39;} ${r.hpath}`); } catch (e) { failed.push({ date, error: e.message }); console.log(` ${date} ✘ ${e.message}`); } // 火云台接口有节流，稍微间隔一下 await new Promise((r) =&gt; setTimeout(r, 120)); } console.log(&#39;\n&#39; + &#39;─&#39;.repeat(60)); console.log(`成功 ${pushed.length} 跳过 ${skipped.length} 失败 ${failed.length}`); if (skipped.length) { const byReason = {}; for (const s of skipped) byReason[s.reason] = (byReason[s.reason] ?? 0) + 1; console.log(&#39;\n跳过原因：&#39;); for (const [k, v] of Object.entries(byReason)) console.log(` ${k}：${v} 天`); } if (failed.length) { console.log(&#39;\n失败：&#39;); for (const f of failed) console.log(` ${f.date} ${f.error}`); } if (dryRun) console.log(&#39;\n[预演] 什么都没写入。去掉 --dry-run 才会真写。&#39;); process.exit(failed.length ? 1 : 0); scripts/tools/remind.ps1 Windows 通知：先判断排班，再查状态，没写才弹 ﻿&lt;# .SYNOPSIS 日报提醒：检查今天是否已提交日报，没提交就弹一条 Windows 通知。 .DESCRIPTION 由「任务计划程序」在工作日下午 17:30 调用。逻辑： 1. 调 check-status.mjs 问服务器今天写没写 2. 已写 → 静默退出，不打扰 3. 未写 → 弹 Windows 通知 4. 查不通 → 弹一条「无法确认」的通知（宁可多提醒，不要漏） 通知点击后打开日报网站。整个过程不写日报、不提交任何东西。 .PARAMETER Workspace 工作区目录（含 config.json）。不传则按 DAILY_REPORT_HOME → 向上查找 → 默认值 解析。 .PARAMETER Date 要检查的日期，默认今天。 .PARAMETER Force 不管写没写都弹通知（测试用）。 .PARAMETER Test 只弹一条固定的测试通知，不联网、不读配置。 .EXAMPLE .\remind.ps1 -Test .\remind.ps1 -Force .\remind.ps1 -Workspace &#34;D:\工作区\日报&#34; #&gt; [CmdletBinding()] param( [string]$Workspace, [string]$Date, [switch]$Force, [switch]$Test ) $ErrorActionPreference = &#39;Stop&#39; $ScriptDir = $PSScriptRoot $SkillRoot = Split-Path (Split-Path $ScriptDir -Parent) -Parent # &lt;skill&gt;/ $CheckScript = Join-Path $ScriptDir &#39;check-status.mjs&#39; $AppId = &#39;DeepSeek.DSH.DailyReport&#39; $ReportUrl = &#39;https://www.huoyuntai.com/#/home/reportList?limit=10&amp;page=1&#39; # ---------- 工作区解析（与 config.mjs 保持一致）---------- function Resolve-Workspace { param([string]$Explicit) if ($Explicit) { return [System.IO.Path]::GetFullPath($Explicit) } if ($env:DAILY_REPORT_HOME) { return [System.IO.Path]::GetFullPath($env:DAILY_REPORT_HOME) } # 从 skill 位置向上找同时有 config.json 和 reports/ 的目录 $cur = [System.IO.Path]::GetFullPath($SkillRoot) for ($i = 0; $i -lt 8 -and $cur; $i++) { if ((Test-Path (Join-Path $cur &#39;config.json&#39;)) -and ((Test-Path (Join-Path $cur &#39;reports&#39;)) -or (Test-Path (Join-Path $cur &#39;drafts&#39;)))) { return $cur } $parent = Split-Path $cur -Parent if (-not $parent -or $parent -eq $cur) { break } $cur = $parent } return (Join-Path $env:USERPROFILE &#39;日报自动化&#39;) } function Find-Node { $cmd = Get-Command node -ErrorAction SilentlyContinue if ($cmd) { return $cmd.Source } foreach ($p in @( (Join-Path $env:ProgramFiles &#39;nodejs\node.exe&#39;), (Join-Path ${env:ProgramFiles(x86)} &#39;nodejs\node.exe&#39;), (Join-Path $env:LOCALAPPDATA &#39;Programs\nodejs\node.exe&#39;) )) { if ($p -and (Test-Path $p)) { return $p } } return $null } function Write-Log { param([string]$Message, [string]$LogDir) if (-not $LogDir) { return } try { $dir = Join-Path $LogDir &#39;.cache&#39; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null } $line = &#39;{0} {1}&#39; -f (Get-Date -Format &#39;yyyy-MM-dd HH:mm:ss&#39;), $Message Add-Content -LiteralPath (Join-Path $dir &#39;reminder.log&#39;) -Value $line -Encoding UTF8 } catch { } } # ---------- 弹通知 ---------- function Show-Toast { param([string]$Title, [string]$Body, [string]$AppIdToUse) try { [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] } catch { return $false } $esc = { param($s) [System.Security.SecurityElement]::Escape([string]$s) } $xmlText = @&#34; &lt;toast activationType=&#34;protocol&#34; launch=&#34;$(&amp; $esc $ReportUrl)&#34;&gt; &lt;visual&gt; &lt;binding template=&#34;ToastGeneric&#34;&gt; &lt;text&gt;$(&amp; $esc $Title)&lt;/text&gt; &lt;text&gt;$(&amp; $esc $Body)&lt;/text&gt; &lt;/binding&gt; &lt;/visual&gt; &lt;/toast&gt; &#34;@ try { $xml = New-Object Windows.Data.Xml.Dom.XmlDocument $xml.LoadXml($xmlText) $toast = New-Object Windows.UI.Notifications.ToastNotification $xml [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppIdToUse).Show($toast) return $true } catch { return $false } } function Notify { param([string]$Title, [string]$Body, [string]$LogDir) # 优先用注册过的自定义 AppID（通知里显示「日报提醒」），失败退到 PowerShell 的 AppID if (Show-Toast -Title $Title -Body $Body -AppIdToUse $AppId) { Write-Log &#34;toast sent (custom appid): $Body&#34; $LogDir return &#39;toast-custom&#39; } $psAppId = &#39;{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe&#39; if (Show-Toast -Title $Title -Body $Body -AppIdToUse $psAppId) { Write-Log &#34;toast sent (powershell appid): $Body&#34; $LogDir return &#39;toast-powershell&#39; } # 最后兜底：消息框（不美观但一定能看见） try { Add-Type -AssemblyName System.Windows.Forms [System.Windows.Forms.MessageBox]::Show($Body, $Title) | Out-Null Write-Log &#34;messagebox shown: $Body&#34; $LogDir return &#39;messagebox&#39; } catch { Write-Log &#34;ALL notification paths failed&#34; $LogDir return &#39;none&#39; } } # ---------- 主流程 ---------- $ws = Resolve-Workspace -Explicit $Workspace if ($Test) { $r = Notify -Title &#39;日报提醒（测试）&#39; -Body &#39;如果你看到这条，说明通知链路是通的。&#39; -LogDir $ws Write-Host &#34;测试通知发送结果：$r&#34; exit 0 } $node = Find-Node if (-not $node) { Notify -Title &#39;日报提醒&#39; -Body &#39;找不到 Node.js，无法检查今天的日报状态。&#39; -LogDir $ws | Out-Null exit 1 } $logDir = $ws # ---------- 先看今天该不该上班（单双休轮换）---------- # 周六是否上班由 calendar.mjs 按锚点周奇偶算，见 config.json 的 schedule 块 if (-not $Force) { $wd = $null try { $wdArgs = @((Join-Path $ScriptDir &#39;is-workday.mjs&#39;)) if ($Date) { $wdArgs += @(&#39;--date&#39;, $Date) } $wd = (&amp; $node @wdArgs 2&gt;&amp;1 | Out-String).Trim() | ConvertFrom-Json } catch { Write-Log &#34;workday check failed: $($_.Exception.Message)&#34; $logDir } if ($wd -and -not $wd.workday) { Write-Log &#34;not a workday ($($wd.reason)) -&gt; stay silent&#34; $logDir exit 0 } } $json = $null try { $args = @($CheckScript) if ($Date) { $args += @(&#39;--date&#39;, $Date) } $raw = &amp; $node @args 2&gt;&amp;1 | Out-String $json = $raw.Trim() | ConvertFrom-Json } catch { Write-Log &#34;check failed: $($_.Exception.Message)&#34; $logDir } if (-not $json -or -not $json.ok) { $reason = if ($json -and $json.error) { $json.error } else { &#39;检查脚本没有返回结果&#39; } Write-Log &#34;check error: $reason&#34; $logDir Notify -Title &#39;日报提醒&#39; -Body &#34;无法确认今天的日报状态，记得看一下。（$reason）&#34; -LogDir $logDir | Out-Null exit 0 } if ($json.filed -and -not $Force) { Write-Log &#34;already filed ($($json.date)) -&gt; stay silent&#34; $logDir exit 0 } $body = if ($json.filed -and $Force) { &#34;今天（$($json.date)）的日报已提交。这条是 -Force 测试。&#34; } else { &#34;今天（$($json.date)）的日报还没写，记得提交。&#34; } Notify -Title &#39;日报提醒&#39; -Body $body -LogDir $logDir | Out-Null exit 0 scripts/tools/install-reminder.ps1 注册 / 移除计划任务与通知身份 ﻿&lt;# .SYNOPSIS 注册 / 移除「日报提醒」的 Windows 定时任务（右下角系统通知）。 .DESCRIPTION 做两件事： 1. 在 HKCU 注册一个 AppUserModelID，让通知显示成「日报提醒」 2. 用任务计划程序注册定时任务，到点调用 remind.ps1 remind.ps1 会先查服务器今天写没写日报：写了就静默退出，没写才弹通知。 任务以「仅交互式登录时运行」注册 —— 通知必须投递到你的桌面会话， 所以任务只在你自己登录着的时候跑。 .PARAMETER Workspace 工作区目录（含 config.json）。默认按 DAILY_REPORT_HOME → 向上查找 → 默认值 解析。 .PARAMETER Time 触发时间，24 小时制 HH:mm，默认 17:30。 .PARAMETER Days 触发星期，默认周一到周五。 .PARAMETER TaskName 任务计划里的任务名，默认「日报提醒」。 .PARAMETER Remove 移除已注册的任务和注册表项。 .PARAMETER Test 注册完成后立刻弹一条测试通知。 .EXAMPLE .\install-reminder.ps1 -Test .\install-reminder.ps1 -Time 18:00 -Days Monday,Wednesday,Friday .\install-reminder.ps1 -Remove #&gt; [CmdletBinding()] param( [string]$Workspace, [string]$Time = &#39;17:30&#39;, [string[]]$Days = @(&#39;Monday&#39;, &#39;Tuesday&#39;, &#39;Wednesday&#39;, &#39;Thursday&#39;, &#39;Friday&#39;), [string]$TaskName = &#39;日报提醒&#39;, [switch]$Remove, [switch]$Test ) $ErrorActionPreference = &#39;Stop&#39; $AppId = &#39;DeepSeek.DSH.DailyReport&#39; $RemindPs1 = Join-Path $PSScriptRoot &#39;remind.ps1&#39; $SkillRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent $RegPath = &#34;HKCU:\SOFTWARE\Classes\AppUserModelId\$AppId&#34; function W($t) { Write-Host $t } function Ok($t) { Write-Host &#34; OK $t&#34; -ForegroundColor Green } function Resolve-Workspace { param([string]$Explicit) if ($Explicit) { return [System.IO.Path]::GetFullPath($Explicit) } if ($env:DAILY_REPORT_HOME) { return [System.IO.Path]::GetFullPath($env:DAILY_REPORT_HOME) } $cur = [System.IO.Path]::GetFullPath($SkillRoot) for ($i = 0; $i -lt 8 -and $cur; $i++) { if ((Test-Path (Join-Path $cur &#39;config.json&#39;)) -and ((Test-Path (Join-Path $cur &#39;reports&#39;)) -or (Test-Path (Join-Path $cur &#39;drafts&#39;)))) { return $cur } $parent = Split-Path $cur -Parent if (-not $parent -or $parent -eq $cur) { break } $cur = $parent } return (Join-Path $env:USERPROFILE &#39;日报自动化&#39;) } # ================= 移除 ================= if ($Remove) { W &#39;&#39; W &#39; 日报提醒 · 移除&#39; W &#39; ================================&#39; $t = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue if ($t) { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false Ok &#34;已删除计划任务「$TaskName」&#34; } else { W &#34; 计划任务「$TaskName」不存在&#34; } if (Test-Path -LiteralPath $RegPath) { Remove-Item -LiteralPath $RegPath -Recurse -Force Ok &#39;已删除注册表项&#39; } W &#39;&#39; exit 0 } # ================= 注册 ================= W &#39;&#39; W &#39; 日报提醒 · 安装（Windows 系统通知）&#39; W &#39; ================================&#39; $ws = Resolve-Workspace -Explicit $Workspace W &#39;&#39; W &#34; 工作区 $ws&#34; W &#34; 脚本 $RemindPs1&#34; W &#34; 时间 每周 $($Days -join &#39;, &#39;) $Time&#34; W &#39;&#39; if (-not (Test-Path -LiteralPath $RemindPs1)) { throw &#34;找不到 remind.ps1：$RemindPs1&#34; } if (-not (Test-Path -LiteralPath (Join-Path $ws &#39;config.json&#39;))) { W &#39; !! 工作区里没有 config.json —— 通知能弹，但查不出今天写没写。&#39; -ForegroundColor Yellow } # ---------- 1. 通知身份 ---------- W &#39;[1] 注册通知身份&#39; if (-not (Test-Path -LiteralPath $RegPath)) { New-Item -Path $RegPath -Force | Out-Null } New-ItemProperty -LiteralPath $RegPath -Name &#39;DisplayName&#39; -Value &#39;日报提醒&#39; -PropertyType String -Force | Out-Null Ok &#34;AppUserModelID = $AppId&#34; # ---------- 2. 计划任务 ---------- W &#39;&#39; W &#39;[2] 注册计划任务&#39; $psExe = Join-Path $env:SystemRoot &#39;System32\WindowsPowerShell\v1.0\powershell.exe&#39; $action = New-ScheduledTaskAction -Execute $psExe ` -Argument &#34;-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `&#34;$RemindPs1`&#34; -Workspace `&#34;$ws`&#34;&#34; ` -WorkingDirectory $ws $at = [datetime]::Today.Add([timespan]::Parse($Time)) $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek ([System.DayOfWeek[]]$Days) -At $at $settings = New-ScheduledTaskSettingsSet ` -StartWhenAvailable ` -AllowStartIfOnBatteries ` -DontStopIfGoingOnBatteries ` -MultipleInstances IgnoreNew ` -ExecutionTimeLimit (New-TimeSpan -Minutes 10) # 仅交互式登录时运行：通知要投递到你的桌面会话 $principal = New-ScheduledTaskPrincipal -UserId &#34;$env:USERDOMAIN\$env:USERNAME&#34; -LogonType Interactive -RunLevel Limited try { Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger ` -Settings $settings -Principal $principal -Force | Out-Null Ok &#34;计划任务「$TaskName」已注册&#34; } catch { W &#39;&#39; W &#39; 注册计划任务失败。&#39; -ForegroundColor Red W &#34; $($_.Exception.Message)&#34; -ForegroundColor Red W &#39;&#39; W &#39; 请改用「以管理员身份运行」的 PowerShell 重跑本脚本。&#39; -ForegroundColor Yellow exit 1 } # ---------- 3. 可选：立刻测一条 ---------- if ($Test) { W &#39;&#39; W &#39;[3] 发送测试通知&#39; &amp; powershell.exe -NoProfile -ExecutionPolicy Bypass -File $RemindPs1 -Workspace $ws -Test | Out-Null Ok &#39;已触发 —— 看右下角&#39; W &#39; （没弹出的话检查「专注助手 / 勿扰模式」是否开着）&#39; -ForegroundColor DarkGray } W &#39;&#39; W &#39; 安装完成&#39; -ForegroundColor Green W &#39; ================================&#39; W &#39;&#39; W &#34; 触发时间：每周 $($Days -join &#39;, &#39;) $Time&#34; W &#39; 行为：先查服务器今天写没写 —— 写了静默退出，没写才弹通知&#39; W &#39; 日志：&lt;工作区&gt;\.cache\reminder.log&#39; W &#39;&#39; W &#34; 手动测： &amp; `&#34;$RemindPs1`&#34; -Workspace `&#34;$ws`&#34; -Test&#34; W &#34; 立刻跑： Start-ScheduledTask -TaskName &#39;$TaskName&#39;&#34; W &#34; 移除： &amp; `&#34;$PSCommandPath`&#34; -Remove&#34; W &#39;&#39; scripts/tools/fetch-history.mjs 拉取历史日报 /** * 拉取历史日报，用于分析写作风格。 * 用法：node tools/fetch-history.mjs [天数=30] */ import { loadConfig } from &#39;../src/config.mjs&#39;; import { createReportClient } from &#39;../src/report/client.mjs&#39;; import { SECTIONS } from &#39;../src/report/render.mjs&#39;; const days = Number(process.argv[2] || 30); const cfg = loadConfig(); const client = createReportClient({ ...cfg, log: () =&gt; {} }); function d(offset) { const t = new Date(); t.setDate(t.getDate() - offset); const p = (n) =&gt; String(n).padStart(2, &#39;0&#39;); return `${t.getFullYear()}-${p(t.getMonth() + 1)}-${p(t.getDate())}`; } const found = []; for (let i = 0; i &lt; days; i++) { const date = d(i); try { const r = await client.getReportInfo({ report_date: date, type: cfg.type }); if (r) found.push({ date, r }); } catch (e) { console.error(`# ${date} 失败：${e.message}`); } } console.log(`共找到 ${found.length} 天的日报\n`); console.log(&#39;=&#39;.repeat(70)); for (const { date, r } of found.reverse()) { console.log(`\n### ${date} (id=${r.report_id})`); for (const s of SECTIONS) { const html = r[s.key] || &#39;&#39;; const text = html .replace(/&lt;\/(p|li|ul|ol|div|h[1-6])&gt;/gi, &#39;\n&#39;) .replace(/&lt;br\s*\/?&gt;/gi, &#39;&#39;) .replace(/&lt;[^&gt;]+&gt;/g, &#39;&#39;) .replace(/&amp;amp;/g, &#39;&amp;&#39;) .replace(/&amp;lt;/g, &#39;&lt;&#39;) .replace(/&amp;gt;/g, &#39;&gt;&#39;) .replace(/&amp;nbsp;/g, &#39; &#39;) .split(&#39;\n&#39;) .map((l) =&gt; l.trim()) .filter(Boolean) .join(&#39;\n&#39;); if (text) console.log(` [${s.label}]\n${text.split(&#39;\n&#39;).map((l) =&gt; ` ${l}`).join(&#39;\n&#39;)}`); } } 9.3 安装与卸载 install.ps1 安装脚本：Project / User 两种范围 ﻿&lt;# .SYNOPSIS 安装 daily-report-huoyuntai skill。 .DESCRIPTION 两种安装范围，默认最小权限： Project（默认） 装到 &lt;项目根&gt;\.dsh\skills —— 只在这个项目里可见 User 装到 &lt;DSH_HOME&gt;\skills —— 所有项目都可见 技能目录只放只读的脚本与文档；账号密码、草稿、归档放在「工作区」。 Project 范围的工作区默认就是项目根目录，凭证不出项目。 已存在的 config.json 永远不会被覆盖。 .PARAMETER Scope Project（默认）或 User。 .PARAMETER ProjectRoot Project 范围的项目根目录。默认从脚本位置向上找 .git / .dsh / .agents / package.json。 .PARAMETER SkillRoot 直接指定技能根目录，覆盖 Scope 的推导结果。 .PARAMETER Workspace 工作区目录。Project 默认 &lt;项目根&gt;，User 默认 &lt;用户目录&gt;\日报自动化。 .PARAMETER Force 保留参数，当前仅用于显式声明意图。 .EXAMPLE .\install.ps1 # 装到当前项目（最小权限） .\install.ps1 -Scope User # 装到全局，所有项目可用 .\install.ps1 -Scope Project -ProjectRoot &#34;D:\work\日报&#34; #&gt; [CmdletBinding()] param( [ValidateSet(&#39;Project&#39;, &#39;User&#39;)] [string]$Scope = &#39;Project&#39;, [string]$ProjectRoot, [string]$SkillRoot, [string]$Workspace, [switch]$Force ) $ErrorActionPreference = &#39;Stop&#39; $SkillName = &#39;daily-report-huoyuntai&#39; $Source = $PSScriptRoot function Write-Step($n, $text) { Write-Host &#34;`n[$n] $text&#34; -ForegroundColor Cyan } function Write-Ok($text) { Write-Host &#34; OK $text&#34; -ForegroundColor Green } function Write-Warn2($text) { Write-Host &#34; !! $text&#34; -ForegroundColor Yellow } Write-Host &#39;&#39; Write-Host &#39; 日报自动化 skill · 安装程序&#39; -ForegroundColor White Write-Host &#39; ================================&#39; -ForegroundColor DarkGray # ---------- 选择安装范围 ---------- # 只有交互式运行（双击）且没显式传 -Scope 时才问；管道/自动化调用直接走默认 Project $interactive = $true try { $interactive = -not [Console]::IsInputRedirected } catch { $interactive = $false } if (-not $PSBoundParameters.ContainsKey(&#39;Scope&#39;) -and $interactive) { Write-Host &#39;&#39; Write-Host &#39; 装到哪里？&#39; -ForegroundColor White Write-Host &#39; [1] 当前项目 —— 最小权限，只在这个项目里可见（推荐）&#39; Write-Host &#39; 账号密码也只放在这个项目里&#39; Write-Host &#39; [2] 全局 —— 所有项目都能用&#39; Write-Host &#39; 技能装到用户目录，工作区在 用户目录\日报自动化&#39; Write-Host &#39;&#39; $ans = Read-Host &#39; 请输入 1 或 2 [默认 1]&#39; if ($ans -eq &#39;2&#39;) { $Scope = &#39;User&#39; } } # ---------- 0. 前置检查 ---------- Write-Step 0 &#39;检查运行环境&#39; $nodeCmd = Get-Command node -ErrorAction SilentlyContinue if (-not $nodeCmd) { throw &#34;找不到 node。请先安装 Node.js 18 或更高版本，并确认 `node -v` 能跑。&#34; } $nodeVersion = (&amp; node -v) 2&gt;$null Write-Ok &#34;Node $nodeVersion ($($nodeCmd.Source))&#34; if (-not (Test-Path (Join-Path $Source &#39;SKILL.md&#39;))) { throw &#34;在 $Source 里找不到 SKILL.md —— 请从 skill 目录内部运行本脚本。&#34; } Write-Ok &#34;源目录 $Source&#34; # ---------- 1. 推导项目根 ---------- # 规则与 DSH 自身的本地发现保持一致，再补两条兜底： # 1) 向上找 .git（DSH 就是这么定义项目根的） # 2) 其次 .dsh / .agents / package.json，但不越过用户主目录 # （主目录下有 %USERPROFILE%\.dsh，否则会把整个主目录误当成项目） # 3) 发布布局 &lt;项目&gt;\skill\&lt;skill名&gt;\ —— 取上两级 function Find-ProjectRoot($start) { $userHome = [System.IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd(&#39;\&#39;) $cur = [System.IO.Path]::GetFullPath($start) $markers = @(&#39;.git&#39;, &#39;.dsh&#39;, &#39;.agents&#39;, &#39;package.json&#39;) $walk = $cur while ($walk) { if ($walk.TrimEnd(&#39;\&#39;) -ieq $userHome) { break } foreach ($m in $markers) { if (Test-Path (Join-Path $walk $m)) { return $walk } } $parent = Split-Path $walk -Parent if (-not $parent -or $parent -eq $walk) { break } $walk = $parent } # 发布布局兜底：&lt;项目&gt;\skill\&lt;skill名&gt;\ $parent = Split-Path $cur -Parent if ($parent) { $leaf = Split-Path $parent -Leaf if ($leaf -eq &#39;skill&#39; -or $leaf -eq &#39;skills&#39;) { $grand = Split-Path $parent -Parent if ($grand) { return $grand } } } return $null } if (-not $ProjectRoot) { $found = Find-ProjectRoot $Source if ($found) { $ProjectRoot = $found } else { $ProjectRoot = (Get-Location).Path } } $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot) # ---------- 2. 确定安装位置 ---------- $dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE &#39;.dsh&#39; } if (-not $SkillRoot) { if ($Scope -eq &#39;Project&#39;) { $SkillRoot = Join-Path $ProjectRoot &#39;.dsh\skills&#39; } else { $SkillRoot = Join-Path $dshHome &#39;skills&#39; } } if (-not $Workspace) { if ($Scope -eq &#39;Project&#39;) { $Workspace = $ProjectRoot } else { $Workspace = Join-Path $env:USERPROFILE &#39;日报自动化&#39; } } $SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot) $Workspace = [System.IO.Path]::GetFullPath($Workspace) $Target = Join-Path $SkillRoot $SkillName Write-Step 1 &#39;确定安装位置&#39; Write-Host &#34; 范围 $Scope&#34; -ForegroundColor White if ($Scope -eq &#39;Project&#39;) { Write-Ok &#34;项目根 $ProjectRoot&#34; Write-Host &#39; （只有工作目录在这个项目里时，这个技能才可见）&#39; -ForegroundColor DarkGray } else { Write-Host &#39; （全局安装：所有项目都能看到这个技能）&#39; -ForegroundColor DarkGray } Write-Ok &#34;技能目录 $Target&#34; Write-Ok &#34;工作区 $Workspace&#34; # 安全阀：不要装进自己的源目录里 $srcFull = [System.IO.Path]::GetFullPath($Source).TrimEnd(&#39;\&#39;) if ($Target.TrimEnd(&#39;\&#39;) -eq $srcFull) { throw &#34;目标目录和源目录相同（$Target）。请不要把 skill 装在它自己的源目录里。&#34; } if ($Target.TrimEnd(&#39;\&#39;).StartsWith($srcFull + &#39;\&#39;)) { throw &#34;目标目录在源目录内部（$Target）。请换一个 SkillRoot。&#34; } # ---------- 3. 安装 skill ---------- Write-Step 2 &#39;安装 skill&#39; if (Test-Path -LiteralPath $Target) { Write-Warn2 &#39;目标已存在，将覆盖更新（对已安装副本的本地改动会丢失）&#39; Remove-Item -LiteralPath $Target -Recurse -Force } New-Item -ItemType Directory -Force -Path $Target | Out-Null Get-ChildItem -LiteralPath $Source -Force | Where-Object { $_.Name -ne &#39;.git&#39; } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $Target -Recurse -Force } Write-Ok &#34;已复制 $((Get-ChildItem -LiteralPath $Target -Recurse -File).Count) 个文件&#34; # ---------- 4. 准备工作区 ---------- Write-Step 3 &#39;准备工作区&#39; foreach ($sub in @(&#39;drafts&#39;, &#39;reports&#39;, &#39;.cache&#39;)) { $p = Join-Path $Workspace $sub if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } } Write-Ok &#34;目录就绪 $Workspace&#34; $cfgPath = Join-Path $Workspace &#39;config.json&#39; if (Test-Path -LiteralPath $cfgPath) { Write-Warn2 &#39;config.json 已存在，保持不变（不会覆盖你的账号密码）&#39; } else { Copy-Item -LiteralPath (Join-Path $Target &#39;templates\config.example.json&#39;) -Destination $cfgPath -Force Write-Ok &#39;已生成 config.json（待填账号密码）&#39; } $exampleDraft = Join-Path $Workspace &#39;drafts\example.txt&#39; if (-not (Test-Path -LiteralPath $exampleDraft)) { Copy-Item -LiteralPath (Join-Path $Target &#39;templates\drafts\example.txt&#39;) -Destination $exampleDraft -Force Write-Ok &#39;已放入草稿示例 drafts\example.txt&#39; } # 凭证落在 git 仓库里要提醒 if (Test-Path -LiteralPath (Join-Path $Workspace &#39;.git&#39;)) { Write-Warn2 &#39;工作区是个 git 仓库：config.json 含账号密码，记得把它写进 .gitignore&#39; } # ---------- 5. 冒烟测试 ---------- Write-Step 4 &#39;冒烟测试&#39; $submit = Join-Path $Target &#39;scripts\src\submit.mjs&#39; $prevHome = $env:DAILY_REPORT_HOME try { $env:DAILY_REPORT_HOME = $Workspace $out = &amp; node $submit --help 2&gt;&amp;1 | Out-String if ($LASTEXITCODE -ne 0 -or $out -notmatch &#39;用法&#39;) { throw &#34;脚本没能正常运行：`n$out&#34; } Write-Ok &#39;--help 正常&#39; } finally { if ($null -eq $prevHome) { Remove-Item Env:\DAILY_REPORT_HOME -ErrorAction SilentlyContinue } else { $env:DAILY_REPORT_HOME = $prevHome } } # ---------- 完成 ---------- Write-Host &#39;&#39; Write-Host &#39; 安装完成&#39; -ForegroundColor Green Write-Host &#39; ================================&#39; -ForegroundColor DarkGray Write-Host &#39;&#39; if ($Scope -eq &#39;Project&#39;) { Write-Host &#39; 注意：这是项目级安装，只在工作目录属于&#39; -ForegroundColor Yellow Write-Host &#34; $ProjectRoot&#34; -ForegroundColor Yellow Write-Host &#39; 时会生效。想在所有项目里可用，重装时加 -Scope User。&#39; -ForegroundColor Yellow Write-Host &#39;&#39; } Write-Host &#39; 下一步：&#39; -ForegroundColor White Write-Host &#39;&#39; Write-Host &#34; 1. 填账号密码： $cfgPath&#34; Write-Host &#39; （用记事本打开，填 user_phone 和 user_pwd 两个值）&#39; Write-Host &#39;&#39; Write-Host &#39; 2. 验证登录：&#39; Write-Host &#34; `$env:DAILY_REPORT_HOME=&#39;$Workspace&#39;&#34; Write-Host &#34; node `&#34;$submit`&#34; --check&#34; Write-Host &#39;&#39; Write-Host &#39; 3. 之后直接跟 AI 说「写日报」并贴出今天做的事就行。&#39; -ForegroundColor White Write-Host &#39;&#39; Write-Host &#34; 卸载： &amp; `&#34;$Target\uninstall.ps1`&#34; -Scope $Scope&#34; -ForegroundColor DarkGray Write-Host &#39;&#39; uninstall.ps1 卸载脚本：默认保留工作区 ﻿&lt;# .SYNOPSIS 卸载 daily-report-huoyuntai skill。 .DESCRIPTION 默认只删技能目录，保留工作区（你的 config.json 和日报归档都还在）。 加 -RemoveWorkspace 才会连工作区一起删。 .PARAMETER Scope Project（默认）或 User —— 与安装时用的范围一致。 .PARAMETER ProjectRoot Project 范围的项目根目录。默认从脚本位置向上找 .git / .dsh / .agents / package.json。 .PARAMETER SkillRoot 直接指定技能根目录，覆盖 Scope 的推导结果。 .PARAMETER Workspace 工作区目录，仅 -RemoveWorkspace 时需要。 .PARAMETER RemoveWorkspace 连同工作区一起删除（含 config.json、草稿、归档）。会二次确认。 .PARAMETER Force 跳过确认。 .EXAMPLE .\uninstall.ps1 .\uninstall.ps1 -Scope User .\uninstall.ps1 -RemoveWorkspace #&gt; [CmdletBinding()] param( [ValidateSet(&#39;Project&#39;, &#39;User&#39;)] [string]$Scope = &#39;Project&#39;, [string]$ProjectRoot, [string]$SkillRoot, [string]$Workspace, [switch]$RemoveWorkspace, [switch]$Force ) $ErrorActionPreference = &#39;Stop&#39; $SkillName = &#39;daily-report-huoyuntai&#39; $Source = $PSScriptRoot function Find-ProjectRoot($start) { $userHome = [System.IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd(&#39;\&#39;) $cur = [System.IO.Path]::GetFullPath($start) $markers = @(&#39;.git&#39;, &#39;.dsh&#39;, &#39;.agents&#39;, &#39;package.json&#39;) $walk = $cur while ($walk) { if ($walk.TrimEnd(&#39;\&#39;) -ieq $userHome) { break } foreach ($m in $markers) { if (Test-Path (Join-Path $walk $m)) { return $walk } } $parent = Split-Path $walk -Parent if (-not $parent -or $parent -eq $walk) { break } $walk = $parent } # 发布布局兜底：&lt;项目&gt;\skill\&lt;skill名&gt;\ $parent = Split-Path $cur -Parent if ($parent) { $leaf = Split-Path $parent -Leaf if ($leaf -eq &#39;skill&#39; -or $leaf -eq &#39;skills&#39;) { $grand = Split-Path $parent -Parent if ($grand) { return $grand } } } return $null } if (-not $ProjectRoot) { $found = Find-ProjectRoot $Source if ($found) { $ProjectRoot = $found } else { $ProjectRoot = (Get-Location).Path } } $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot) $dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE &#39;.dsh&#39; } if (-not $SkillRoot) { if ($Scope -eq &#39;Project&#39;) { $SkillRoot = Join-Path $ProjectRoot &#39;.dsh\skills&#39; } else { $SkillRoot = Join-Path $dshHome &#39;skills&#39; } } if (-not $Workspace) { if ($Scope -eq &#39;Project&#39;) { $Workspace = $ProjectRoot } else { $Workspace = Join-Path $env:USERPROFILE &#39;日报自动化&#39; } } $Target = [System.IO.Path]::GetFullPath((Join-Path $SkillRoot $SkillName)) $WorkspaceFull = [System.IO.Path]::GetFullPath($Workspace) Write-Host &#39;&#39; Write-Host &#39; 日报自动化 skill · 卸载程序&#39; -ForegroundColor White Write-Host &#39; ================================&#39; -ForegroundColor DarkGray Write-Host &#34; 范围 $Scope&#34; -ForegroundColor DarkGray # 安全阀：只允许删除明确以 skill 名结尾的目录 if (-not (Split-Path $Target -Leaf).Equals($SkillName, &#39;OrdinalIgnoreCase&#39;)) { throw &#34;拒绝执行：目标目录名不是 $SkillName（$Target）&#34; } if (-not (Test-Path -LiteralPath $Target)) { Write-Host &#34;`n 技能目录不存在，无需删除：$Target&#34; -ForegroundColor Yellow } else { if (-not $Force) { $ans = Read-Host &#34;`n 确认删除技能目录？`n $Target`n [y/N]&#34; if ($ans -notmatch &#39;^[yY]&#39;) { Write-Host &#39; 已取消。&#39; -ForegroundColor Yellow; exit 0 } } Remove-Item -LiteralPath $Target -Recurse -Force Write-Host &#34; 已删除 $Target&#34; -ForegroundColor Green } if ($RemoveWorkspace) { if (-not (Test-Path -LiteralPath $WorkspaceFull)) { Write-Host &#34; 工作区不存在：$WorkspaceFull&#34; -ForegroundColor Yellow } else { Write-Host &#34;`n 警告：以下目录将连同账号密码和全部归档一起删除&#34; -ForegroundColor Yellow Write-Host &#34; $WorkspaceFull&#34; -ForegroundColor Yellow if (-not $Force) { $ans2 = Read-Host &#39; 确认？输入 DELETE 继续&#39; if ($ans2 -ne &#39;DELETE&#39;) { Write-Host &#39; 已跳过工作区。&#39; -ForegroundColor Yellow; exit 0 } } Remove-Item -LiteralPath $WorkspaceFull -Recurse -Force Write-Host &#34; 已删除 $WorkspaceFull&#34; -ForegroundColor Green } } else { Write-Host &#34;`n 工作区保留：$WorkspaceFull&#34; -ForegroundColor DarkGray Write-Host &#39; （如需一并删除，加 -RemoveWorkspace）&#39; -ForegroundColor DarkGray } Write-Host &#39;&#39; 10. 维护手册 加一个新项目 / 新说法 改 ​ scripts/src/report/expand.mjs ​ 的 ​ ITEM_GLOSSARY ​。数组 从上往下匹配，先命中先用 ，具体规则要放在宽泛规则前面，例如 ​ 舆情周报 ​ 必须在通用的 ​ 周报 之前。 改排班 改 ​ config.json ​ 的 ​ schedule 。两个提醒（Windows 计划任务 + 会话定时任务）都会跟着变。 改思源目录结构 改 ​ siyuan.pathPattern ，然后迁移： node scripts/tools/backfill-siyuan.mjs --days 60 --dry-run --migrate # 先看 node scripts/tools/backfill-siyuan.mjs --days 60 --migrate # 再跑 --migrate 会把每个日期文档跟新模板算出的位置比对，位置不对的删掉再重建；只处理日期文档，年/月/周容器不动。 生成周 / 月小结 小结是 语言工作 ，不是脚本能自动写的。流程：读该周期内的日期文档 → 统计固定项频次 → 按项目归类 → 写进容器文档（​ appendBlock ，不要删文档）。 网站改版导致接口失效 先 ​ --check ​ 区分登录问题还是接口问题，再按 ​ references/接口参考.md ​ 最后一节重新定位：抓首页 → 找 ​ runtime.js ​ 的 chunk hash 规则 → 在 ​ app.js ​ 搜路由 → 下载对应 chunk → 搜 ​ /api/ 字符串。bundle 是单行压缩的，要按字节位置截取。 备份什么 真正需要备份的只有 ​ ​ config.json ​ ​（含凭证）和 ​ ​ reports/ ​ （归档）。代码可从技能目录重装，日报原文在火云台服务器上也有。 11. 已知限制 接口是逆向还原的 ，网站改版会失效 —— 最大风险 编辑窗口 ±3 天 —— 只能补交最近三天 不覆盖火云台「工作日报」 —— ​ #/home/dayReport ​ 是另一套结构化表单（​ /api/WorkReport/* ） 成句扩写是启发式的 —— 词表外的新说法走兜底，需要偶尔人工润色 思源删除进回收站 —— 覆盖当天日志用「删旧建新」，旧文档留在回收站 周小结/月小结核对靠人 —— 生成后需要过目，尤其「观察」部分容易过度解读 提醒依赖环境 —— Windows 通知需计划任务已注册且用户登录；会话内提醒需 DSH 在运行 本文档由工作区脚本生成，代码部分与 ​ ​ skill/daily-report-huoyuntai/ ​ ​ 保持同步。', '2026-10-31 11:02:15.296402+08'::timestamptz, '2026-10-31 11:03:40.228297+08'::timestamptz, '6f9b36f3-b5ee-4cd6-aeb0-1c011a524893'::uuid, 0, NULL),
  ('8e88609d-abab-4108-a0d6-070714bb60cc'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '官网检索器 · 核心技术方案', '<blockquote>
<p>本文是整个项目的技术核心，记录官网标识判定、状态机、并行隔离、断点续跑与脱敏的全部细节。</p>
</blockquote>
<h2>1. 官网标识命中判定</h2>
<h3>1.1 百度 vs 必应的判定依据不同</h3>
<table>
<thead>
<tr>
<th>平台</th>
<th>判定来源</th>
</tr>
</thead>
<tbody>
<tr>
<td>百度系</td>
<td>结果条目<strong>来源行</strong>出现的官方字样（​<code>BAIDU_OFFICIAL_MARKS</code> 列表，子串匹配，命中任意一个即官网）</td>
</tr>
<tr>
<td>必应系</td>
<td>cite 显示的<strong>域名</strong>是否含 ​<code>TARGET_DOMAIN</code></td>
</tr>
</tbody>
</table>
<h3>1.2 命中即停，平台间互不影响</h3>
<p>一个平台命中后，该词在该平台立即停止（记录全局排名/页码），但<strong>其他三个平台照跑</strong>——四平台结果各自独立、互不污染。</p>
<h2>2. 翻页三态：区分&#34;真到底&#34;和&#34;翻页失效&#34;（易踩坑）</h2>
<p>百度翻页用一个返回值表达三种情况，避免把&#34;真只有 1 页&#34;和&#34;选择器/风控失效&#34;合并成一个错误：</p>
<pre><code class="language-python"># 返回值语义
有下一页        → 继续抓
False          → 结果真到底了 → 一直未命中判 none
&#34;stuck&#34;        → 有下一页链接但点击后 URL 未前进 → 判 error，需人工复核
</code></pre>
<h2>3. 熔断：连续 0 条 ≠ 未命中（防反向误报）</h2>
<ul>
<li><code>ZERO_RESULT_BREAK = 3</code>​：<strong>连续 3 页解析出 0 条自然结果</strong> → 判「解析异常 ​<code>malfunction</code>」。</li>
<li>目的：页面结构变化 / 被反爬拦截时，空结果 ≠ 官网没收录，不能误判成「未命中 ​<code>none</code>」。</li>
</ul>
<h2>4. 五态状态机（每「词 × 引擎」独立）</h2>
<pre><code>pending     待跑（断点续跑的起点）
hit         命中（记录 rank / page / evidence / shot）
none        前 10 页未命中（不参与重试）
error       明确错误（如翻页卡住）→ 需人工复核
restricted  搜索引擎合规过滤/受限页，无法判定
malfunction 连续多页 0 条，解析异常
</code></pre>
<h3>结论聚合的坑</h3>
<p>聚合 ​<code>conclusion()</code>​ 时，只要存在 ​<code>error / restricted / malfunction</code>​，<strong>就不下「未命中」结论</strong>——这三个状态是&#34;判不出来&#34;，写成&#34;10 页未见&#34;会让报告结论反向。</p>
<h2>5. 多任务并行隔离 + 断点续跑</h2>
<h3>5.1 每任务完全隔离</h3>
<p>每个任务 = 一个 ​<code>TabState</code>​：独立 ​<code>data/t&lt;id&gt;.db</code>、独立截图目录、独立浏览器 profile 子目录。并行跑多个任务互不污染、互不抢 profile。</p>
<h3>5.2 断点续跑：pending 驱动</h3>
<ul>
<li>每「词 × 引擎」有独立状态列（​<code>baidu_status</code> 等）。</li>
<li><code>load_pending()</code> 只取「仍 pending 且该词需要跑该引擎」的组合。</li>
<li>重新「开始」只喂这个集合 → <strong>已跑完的不重跑</strong>。</li>
</ul>
<h3>5.3 导入 upsert 不重置已跑结果（易踩坑）</h3>
<pre><code class="language-sql">INSERT INTO tasks (keyword, engines, updated_at) VALUES (?, ?, ?)
ON CONFLICT(keyword) DO UPDATE SET engines=excluded.engines, updated_at=excluded.updated_at
</code></pre>
<ul>
<li>新词插入；已存在的词<strong>只更新</strong> ​<strong>​<code>engines</code>​</strong>​ <strong>字段</strong>（同步最新平台勾选），<strong>不重置已跑状态</strong>。</li>
</ul>
<h3>5.4 并发一致性坑（已修复）</h3>
<table>
<thead>
<tr>
<th>坑</th>
<th>修复</th>
</tr>
</thead>
<tbody>
<tr>
<td>「已在运行」检查与 worker 赋值不在同一临界区 → 双标签重复跑抢 profile</td>
<td>收敛到同一临界区</td>
</tr>
<tr>
<td><code>_next_id</code> 无锁 → 并发建任务 tid 重复、数据互相覆盖</td>
<td>加 ​<code>REG_LOCK</code></td>
</tr>
<tr>
<td><code>load_pending</code> 连接从不 close → 泄漏 SQLite 句柄</td>
<td><code>finally: conn.close()</code></td>
</tr>
</tbody>
</table>
<h2>6. 风控规避节奏</h2>
<pre><code class="language-python">DELAY_MIN_MS = 2500   # 翻页随机延迟下限
DELAY_MAX_MS = 5000   # 上限（防被识别为高频机器人）
PAGE_WAIT_MS = 3000   # 页面加载后额外等待（等动态渲染）
</code></pre>
<ul>
<li>移动端独立 UA/视口（iPhone 14 Pro Max 参数，dsf=3），与桌面端隔离。</li>
<li>验证码兜底：遇验证码记错误 → 走「重试失败项」重跑（已删除&#34;跳过&#34;功能）。</li>
</ul>
<h2>7. 品牌配置分离 + 脱敏发布</h2>
<h3>7.1 config.py 占位 + config_local.py 覆盖</h3>
<pre><code class="language-python"># core/config.py
TARGET_DOMAIN = &#34;example.com&#34;          # 占位值
with contextlib.suppress(ImportError):
    from .config_local import *        # 覆盖为真实值
</code></pre>
<ul>
<li><code>core/config_local.py</code>​ 放真实目标域名/官网标识，<strong>被</strong> ​ <strong>​<code>.gitignore</code>​</strong>​ <strong>忽略，永不误提交</strong>。</li>
<li>fork 到其他品牌只需改 ​<code>config_local.py</code>，采集代码零改动。</li>
</ul>
<h3>7.2 启动自检（防&#34;配置没生效全判未命中&#34;）</h3>
<p>服务启动时检测配置是否仍是占位值，是则打印醒目警告——避免 ​<code>config_local.py</code>​ 没生效时去匹配 ​<code>example.com</code>、全部静默判未命中。</p>
<h3>7.3 脱敏发布红线</h3>
<p>真实域名/标识比 cookie 更能暴露商业意图，公开仓库必须 0 命中：</p>
<pre><code class="language-bash">git grep -E &#34;真实品牌关键词&#34; .      # 仓库内应 0 命中
git check-ignore core/config_local.py  # 真实配置必须被忽略
</code></pre>
<ul>
<li>代码注释、docstring、函数名（如 ​<code>_is_official</code>）均不得含品牌子串。</li>
<li>运行时数据（​<code>data/</code>​、​<code>shots/</code>​、​<code>profile_sessions/</code>​、​<code>logs/</code>）一律 gitignore。</li>
</ul>
<h2>8. SQLite「每词一行 × 四引擎列」模型</h2>
<ul>
<li>每词一行，四个引擎各占 5 列（​<code>status/rank/page/evidence/shot</code>​），共 20 引擎列 + ​<code>keyword/updated_at/engines</code>。</li>
<li>引擎列映射：​<code>_ENGINE_COLS[engine]</code>​ → 对应列名（​<code>baidu_status</code>​、​<code>baidu_rank</code>…）。</li>
<li><strong>迁移补列</strong>：​<code>init_db</code>​ 每次读 ​<code>PRAGMA table_info</code>​，缺列自动 ​<code>ALTER TABLE ADD COLUMN</code> → 老库平滑升级。</li>
</ul>
<h2>9. 可复用清单</h2>
<ul data-type="taskList">
<li data-type="taskItem" data-checked="false">官网标识命中判定：百度来源行 vs 必应 cite 域名，命中即停、平台独立</li>
<li data-type="taskItem" data-checked="false">翻页三态：​<code>False</code>​（真到底）与 ​<code>&#34;stuck&#34;</code>（翻页失效需复核）分离</li>
<li data-type="taskItem" data-checked="false">熔断：连续 N 页 0 条 → ​<code>malfunction</code>，避免空结果误判未命中</li>
<li data-type="taskItem" data-checked="false">五态状态机 + 结论聚合不把&#34;判不出来&#34;写成&#34;未命中&#34;</li>
<li data-type="taskItem" data-checked="false">pending 驱动断点续跑 + upsert 只更新 ​<code>engines</code> 不重置已跑结果</li>
<li data-type="taskItem" data-checked="false">每任务独立 db/profile/截图目录实现并行隔离</li>
<li data-type="taskItem" data-checked="false">并发一致性：worker 赋值临界区、​<code>_next_id</code> 加锁、连接 finally close</li>
<li data-type="taskItem" data-checked="false">风控规避：随机延迟 + 页面等待 + 移动端独立 UA/视口</li>
<li data-type="taskItem" data-checked="false">品牌配置分离：config.py 占位 + config_local.py（gitignore）覆盖 + 启动自检</li>
<li data-type="taskItem" data-checked="false">脱敏发布红线：​<code>git grep</code>​ 0 命中 + ​<code>git check-ignore</code> 校验</li>
<li data-type="taskItem" data-checked="false">SQLite 迁移补列：​<code>PRAGMA table_info</code>​ + ​<code>ALTER TABLE ADD COLUMN</code></li>
<li data-type="taskItem" data-checked="false">前端 hash 路由免后端 history 回退</li>
<li data-type="taskItem" data-checked="false">单端口生产模式：后端同时托管 API + 静态 ​<code>dist</code></li>
</ul>
', 'private', NULL, '官网检索器 · 核心技术方案 本文是整个项目的技术核心，记录官网标识判定、状态机、并行隔离、断点续跑与脱敏的全部细节。 1. 官网标识命中判定 1.1 百度 vs 必应的判定依据不同 平台 判定来源 百度系 结果条目 来源行 出现的官方字样（​ BAIDU_OFFICIAL_MARKS 列表，子串匹配，命中任意一个即官网） 必应系 cite 显示的 域名 是否含 ​ TARGET_DOMAIN 1.2 命中即停，平台间互不影响 一个平台命中后，该词在该平台立即停止（记录全局排名/页码），但 其他三个平台照跑 ——四平台结果各自独立、互不污染。 2. 翻页三态：区分&#34;真到底&#34;和&#34;翻页失效&#34;（易踩坑） 百度翻页用一个返回值表达三种情况，避免把&#34;真只有 1 页&#34;和&#34;选择器/风控失效&#34;合并成一个错误： # 返回值语义 有下一页 → 继续抓 False → 结果真到底了 → 一直未命中判 none &#34;stuck&#34; → 有下一页链接但点击后 URL 未前进 → 判 error，需人工复核 3. 熔断：连续 0 条 ≠ 未命中（防反向误报） ZERO_RESULT_BREAK = 3 ​： 连续 3 页解析出 0 条自然结果 → 判「解析异常 ​ malfunction 」。 目的：页面结构变化 / 被反爬拦截时，空结果 ≠ 官网没收录，不能误判成「未命中 ​ none 」。 4. 五态状态机（每「词 × 引擎」独立） pending 待跑（断点续跑的起点） hit 命中（记录 rank / page / evidence / shot） none 前 10 页未命中（不参与重试） error 明确错误（如翻页卡住）→ 需人工复核 restricted 搜索引擎合规过滤/受限页，无法判定 malfunction 连续多页 0 条，解析异常 结论聚合的坑 聚合 ​ conclusion() ​ 时，只要存在 ​ error / restricted / malfunction ​， 就不下「未命中」结论 ——这三个状态是&#34;判不出来&#34;，写成&#34;10 页未见&#34;会让报告结论反向。 5. 多任务并行隔离 + 断点续跑 5.1 每任务完全隔离 每个任务 = 一个 ​ TabState ​：独立 ​ data/t&lt;id&gt;.db 、独立截图目录、独立浏览器 profile 子目录。并行跑多个任务互不污染、互不抢 profile。 5.2 断点续跑：pending 驱动 每「词 × 引擎」有独立状态列（​ baidu_status 等）。 load_pending() 只取「仍 pending 且该词需要跑该引擎」的组合。 重新「开始」只喂这个集合 → 已跑完的不重跑 。 5.3 导入 upsert 不重置已跑结果（易踩坑） INSERT INTO tasks (keyword, engines, updated_at) VALUES (?, ?, ?) ON CONFLICT(keyword) DO UPDATE SET engines=excluded.engines, updated_at=excluded.updated_at 新词插入；已存在的词 只更新 ​ ​ engines ​ ​ 字段 （同步最新平台勾选）， 不重置已跑状态 。 5.4 并发一致性坑（已修复） 坑 修复 「已在运行」检查与 worker 赋值不在同一临界区 → 双标签重复跑抢 profile 收敛到同一临界区 _next_id 无锁 → 并发建任务 tid 重复、数据互相覆盖 加 ​ REG_LOCK load_pending 连接从不 close → 泄漏 SQLite 句柄 finally: conn.close() 6. 风控规避节奏 DELAY_MIN_MS = 2500 # 翻页随机延迟下限 DELAY_MAX_MS = 5000 # 上限（防被识别为高频机器人） PAGE_WAIT_MS = 3000 # 页面加载后额外等待（等动态渲染） 移动端独立 UA/视口（iPhone 14 Pro Max 参数，dsf=3），与桌面端隔离。 验证码兜底：遇验证码记错误 → 走「重试失败项」重跑（已删除&#34;跳过&#34;功能）。 7. 品牌配置分离 + 脱敏发布 7.1 config.py 占位 + config_local.py 覆盖 # core/config.py TARGET_DOMAIN = &#34;example.com&#34; # 占位值 with contextlib.suppress(ImportError): from .config_local import * # 覆盖为真实值 core/config_local.py ​ 放真实目标域名/官网标识， 被 ​ ​ .gitignore ​ ​ 忽略，永不误提交 。 fork 到其他品牌只需改 ​ config_local.py ，采集代码零改动。 7.2 启动自检（防&#34;配置没生效全判未命中&#34;） 服务启动时检测配置是否仍是占位值，是则打印醒目警告——避免 ​ config_local.py ​ 没生效时去匹配 ​ example.com 、全部静默判未命中。 7.3 脱敏发布红线 真实域名/标识比 cookie 更能暴露商业意图，公开仓库必须 0 命中： git grep -E &#34;真实品牌关键词&#34; . # 仓库内应 0 命中 git check-ignore core/config_local.py # 真实配置必须被忽略 代码注释、docstring、函数名（如 ​ _is_official ）均不得含品牌子串。 运行时数据（​ data/ ​、​ shots/ ​、​ profile_sessions/ ​、​ logs/ ）一律 gitignore。 8. SQLite「每词一行 × 四引擎列」模型 每词一行，四个引擎各占 5 列（​ status/rank/page/evidence/shot ​），共 20 引擎列 + ​ keyword/updated_at/engines 。 引擎列映射：​ _ENGINE_COLS[engine] ​ → 对应列名（​ baidu_status ​、​ baidu_rank …）。 迁移补列 ：​ init_db ​ 每次读 ​ PRAGMA table_info ​，缺列自动 ​ ALTER TABLE ADD COLUMN → 老库平滑升级。 9. 可复用清单 官网标识命中判定：百度来源行 vs 必应 cite 域名，命中即停、平台独立 翻页三态：​ False ​（真到底）与 ​ &#34;stuck&#34; （翻页失效需复核）分离 熔断：连续 N 页 0 条 → ​ malfunction ，避免空结果误判未命中 五态状态机 + 结论聚合不把&#34;判不出来&#34;写成&#34;未命中&#34; pending 驱动断点续跑 + upsert 只更新 ​ engines 不重置已跑结果 每任务独立 db/profile/截图目录实现并行隔离 并发一致性：worker 赋值临界区、​ _next_id 加锁、连接 finally close 风控规避：随机延迟 + 页面等待 + 移动端独立 UA/视口 品牌配置分离：config.py 占位 + config_local.py（gitignore）覆盖 + 启动自检 脱敏发布红线：​ git grep ​ 0 命中 + ​ git check-ignore 校验 SQLite 迁移补列：​ PRAGMA table_info ​ + ​ ALTER TABLE ADD COLUMN 前端 hash 路由免后端 history 回退 单端口生产模式：后端同时托管 API + 静态 ​ dist', '2026-10-31 17:43:11.589297+08'::timestamptz, '2026-10-31 17:43:11.589297+08'::timestamptz, '57475bc4-ef3c-4e7e-a8b7-17b5526dc5a2'::uuid, 0, NULL),
  ('c839c163-7732-4c7b-bd46-2902a657f07b'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '官网检索器 · 接口文档', '<p>基础地址：​<code>http://127.0.0.1:27532</code></p>
<ul>
<li>平台枚举：​<code>baidu</code>​ / ​<code>bing</code>​ / ​<code>baidu_m</code>​ / ​<code>bing_m</code></li>
<li>状态枚举：​<code>pending</code>​ / ​<code>hit</code>​ / ​<code>none</code>​ / ​<code>error</code>​ / ​<code>restricted</code>​ / ​<code>malfunction</code></li>
<li>任务 ID：​<code>tid</code>​（如 ​<code>t1</code>​），对应独立库 ​<code>data/t&lt;id&gt;.db</code></li>
</ul>
<h2>GET /api/tabs</h2>
<p>获取全部任务摘要。</p>
<h3>响应</h3>
<pre><code class="language-json">{
  &#34;tabs&#34;: [
    {
      &#34;id&#34;: &#34;t1&#34;, &#34;name&#34;: &#34;7月官网监测&#34;,
      &#34;platforms&#34;: [&#34;baidu&#34;, &#34;bing&#34;, &#34;baidu_m&#34;, &#34;bing_m&#34;],
      &#34;status&#34;: &#34;finished&#34;,
      &#34;progress&#34;: { &#34;done&#34;: 40, &#34;total&#34;: 40 }
    }
  ]
}
</code></pre>
<h2>GET /api/tabs/<tid>/state</tid></h2>
<p>获取单任务完整状态（含每词×引擎结果 + 日志）。</p>
<h3>响应</h3>
<pre><code class="language-json">{
  &#34;tab&#34;: { &#34;id&#34;: &#34;t1&#34;, &#34;name&#34;: &#34;...&#34;, &#34;status&#34;: &#34;running&#34;, &#34;progress&#34;: { &#34;done&#34;: 12, &#34;total&#34;: 40 } },
  &#34;tasks&#34;: [
    {
      &#34;kw&#34;: &#34;关键词A&#34;,
      &#34;baidu&#34;:  { &#34;status&#34;: &#34;hit&#34;, &#34;rank&#34;: 1, &#34;page&#34;: 1, &#34;evidence&#34;: &#34;...&#34;, &#34;shot&#34;: &#34;shots/...png&#34; },
      &#34;bing&#34;:   { &#34;status&#34;: &#34;pending&#34; },
      &#34;baidu_m&#34;:{ &#34;status&#34;: &#34;none&#34; },
      &#34;bing_m&#34;: { &#34;status&#34;: &#34;error&#34; }
    }
  ],
  &#34;logs&#34;: [ { &#34;t&#34;: &#34;HH:MM:SS&#34;, &#34;s&#34;: &#34;...&#34; } ]
}
</code></pre>
<h3>字段说明</h3>
<table>
<thead>
<tr>
<th>字段</th>
<th>说明</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>status</code></td>
<td>任务状态：​<code>pending/running/paused/stopped/finished</code></td>
</tr>
<tr>
<td><code>tasks[].&lt;engine&gt;.status</code></td>
<td>该词该引擎状态（五态）</td>
</tr>
<tr>
<td><code>rank / page</code></td>
<td>命中时的全局排名与页码</td>
</tr>
<tr>
<td><code>evidence / shot</code></td>
<td>命中依据 / 截图路径</td>
</tr>
</tbody>
</table>
<h2>GET /api/tabs/<tid>/export?cols=...</tid></h2>
<p>导出该任务 Excel。</p>
<ul>
<li><code>cols</code>：可选，逗号分隔的列 id；不传则全部。</li>
<li>响应：​<code>application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</code>（xlsx 文件）</li>
</ul>
<h2>GET /api/tabs/<tid>/export_shots</tid></h2>
<p>导出该任务全部截图 zip。</p>
<ul>
<li>响应：​<code>application/zip</code></li>
<li>zip 结构：​<code>平台/PC|MOB/*.png</code></li>
</ul>
<h2>GET /api/export_all?cols=...</h2>
<p>导出汇总 Excel（每任务一个 sheet + 合计）。</p>
<h2>GET /api/export_zip?cols=...</h2>
<p>导出全部任务截图 zip。</p>
<h2>GET /api/export_date</h2>
<p>按日期打包导出。</p>
<ul>
<li>Query 参数：日期（如 ​<code>?date=2026-10-16</code>）</li>
<li>响应：zip，含当日所有任务截图（按 ​<code>第一页/其他页 × 平台</code> 分层）+ 汇总工作簿（每任务一 sheet）</li>
</ul>
<h2>GET /shots/<name></name></h2>
<p>获取单张截图。</p>
<h2>POST /api/tabs</h2>
<p>创建任务。</p>
<h3>请求</h3>
<pre><code class="language-json">{ &#34;name&#34;: &#34;7月官网监测&#34;, &#34;platforms&#34;: [&#34;baidu&#34;, &#34;bing&#34;] }
</code></pre>
<blockquote>
<p><code>platforms</code> 不传则默认全选；前端默认全不勾选，由用户选择。</p>
</blockquote>
<h3>响应</h3>
<pre><code class="language-json">{ &#34;ok&#34;: true, &#34;tab&#34;: { &#34;id&#34;: &#34;t1&#34;, &#34;name&#34;: &#34;...&#34;, &#34;platforms&#34;: [...] } }
</code></pre>
<h2>POST /api/tabs/<tid>/close | /delete | /rename | /clear</tid></h2>
<ul>
<li><code>close</code>​：​<code>{}</code> — 关闭任务（停线程，保留数据）</li>
<li><code>delete</code>​：​<code>{}</code> — 删除任务（删 db + 截图目录 + profile）</li>
<li><code>rename</code>​：​<code>{ &#34;name&#34;: &#34;新名&#34; }</code> — 重命名</li>
<li><code>clear</code>​：​<code>{}</code> — 清空该任务全部数据</li>
</ul>
<h2>POST /api/tabs/<tid>/import</tid></h2>
<p>导入关键词。</p>
<h3>请求</h3>
<pre><code class="language-json">{ &#34;keywords&#34;: [&#34;关键词A&#34;, &#34;关键词B&#34;] }
</code></pre>
<ul>
<li>平台沿用建任务时勾选；已有词只更新 ​<code>engines</code>，不重置已跑结果。</li>
</ul>
<h3>响应</h3>
<pre><code class="language-json">{ &#34;ok&#34;: true, &#34;count&#34;: 2 }
</code></pre>
<h2>POST /api/tabs/<tid>/start</tid></h2>
<p>开始跑批（只跑 pending）。</p>
<ul>
<li>响应：​<code>{ &#34;ok&#34;: true }</code></li>
</ul>
<h2>POST /api/tabs/<tid>/pause | /stop</tid></h2>
<ul>
<li><code>pause</code>​：​<code>{}</code> — 暂停/继续（当前词完成后停止）</li>
<li><code>stop</code>​：​<code>{}</code> — 停止</li>
</ul>
<h2>POST /api/tabs/<tid>/retry</tid></h2>
<p>重试失败项。</p>
<h3>请求</h3>
<pre><code class="language-json">{ &#34;keywords&#34;: [&#34;关键词A&#34;], &#34;engines&#34;: [&#34;baidu&#34;, &#34;bing&#34;] }
</code></pre>
<ul>
<li>把指定词/引擎重置为 pending 再跑；<strong>未命中</strong> ​<strong>​<code>none</code>​</strong>​ <strong>不参与重试</strong>（​<code>FAILED=[&#39;error&#39;,&#39;restricted&#39;,&#39;malfunction&#39;]</code>）。</li>
</ul>
<h3>响应</h3>
<pre><code class="language-json">{ &#34;ok&#34;: true, &#34;retried&#34;: [...] }
</code></pre>
<h2>错误约定</h2>
<table>
<thead>
<tr>
<th>场景</th>
<th>响应</th>
</tr>
</thead>
<tbody>
<tr>
<td>任务不存在</td>
<td><code>404 { &#34;error&#34;: &#34;任务不存在&#34; }</code></td>
</tr>
<tr>
<td>路径不存在</td>
<td><code>404 { &#34;error&#34;: &#34;not found&#34; }</code></td>
</tr>
<tr>
<td>导入无有效关键词</td>
<td><code>{ &#34;error&#34;: &#34;没有有效关键词&#34; }</code></td>
</tr>
</tbody>
</table>
<h2>前端路由映射</h2>
<table>
<thead>
<tr>
<th>前端路由</th>
<th>组件</th>
<th>对应后端接口</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>/</code></td>
<td>Overview</td>
<td><code>/api/tabs</code></td>
</tr>
<tr>
<td><code>/task/:id</code></td>
<td>TaskDetail</td>
<td><code>/api/tabs/&lt;tid&gt;/state</code></td>
</tr>
<tr>
<td><code>/all</code></td>
<td>AllTasks</td>
<td><code>/api/tabs</code></td>
</tr>
<tr>
<td><code>/download</code></td>
<td>Download</td>
<td><code>/api/export_*</code></td>
</tr>
</tbody>
</table>
', 'private', NULL, '官网检索器 · 接口文档 基础地址：​ http://127.0.0.1:27532 平台枚举：​ baidu ​ / ​ bing ​ / ​ baidu_m ​ / ​ bing_m 状态枚举：​ pending ​ / ​ hit ​ / ​ none ​ / ​ error ​ / ​ restricted ​ / ​ malfunction 任务 ID：​ tid ​（如 ​ t1 ​），对应独立库 ​ data/t&lt;id&gt;.db GET /api/tabs 获取全部任务摘要。 响应 { &#34;tabs&#34;: [ { &#34;id&#34;: &#34;t1&#34;, &#34;name&#34;: &#34;7月官网监测&#34;, &#34;platforms&#34;: [&#34;baidu&#34;, &#34;bing&#34;, &#34;baidu_m&#34;, &#34;bing_m&#34;], &#34;status&#34;: &#34;finished&#34;, &#34;progress&#34;: { &#34;done&#34;: 40, &#34;total&#34;: 40 } } ] } GET /api/tabs/ /state 获取单任务完整状态（含每词×引擎结果 + 日志）。 响应 { &#34;tab&#34;: { &#34;id&#34;: &#34;t1&#34;, &#34;name&#34;: &#34;...&#34;, &#34;status&#34;: &#34;running&#34;, &#34;progress&#34;: { &#34;done&#34;: 12, &#34;total&#34;: 40 } }, &#34;tasks&#34;: [ { &#34;kw&#34;: &#34;关键词A&#34;, &#34;baidu&#34;: { &#34;status&#34;: &#34;hit&#34;, &#34;rank&#34;: 1, &#34;page&#34;: 1, &#34;evidence&#34;: &#34;...&#34;, &#34;shot&#34;: &#34;shots/...png&#34; }, &#34;bing&#34;: { &#34;status&#34;: &#34;pending&#34; }, &#34;baidu_m&#34;:{ &#34;status&#34;: &#34;none&#34; }, &#34;bing_m&#34;: { &#34;status&#34;: &#34;error&#34; } } ], &#34;logs&#34;: [ { &#34;t&#34;: &#34;HH:MM:SS&#34;, &#34;s&#34;: &#34;...&#34; } ] } 字段说明 字段 说明 status 任务状态：​ pending/running/paused/stopped/finished tasks[].&lt;engine&gt;.status 该词该引擎状态（五态） rank / page 命中时的全局排名与页码 evidence / shot 命中依据 / 截图路径 GET /api/tabs/ /export?cols=... 导出该任务 Excel。 cols ：可选，逗号分隔的列 id；不传则全部。 响应：​ application/vnd.openxmlformats-officedocument.spreadsheetml.sheet （xlsx 文件） GET /api/tabs/ /export_shots 导出该任务全部截图 zip。 响应：​ application/zip zip 结构：​ 平台/PC|MOB/*.png GET /api/export_all?cols=... 导出汇总 Excel（每任务一个 sheet + 合计）。 GET /api/export_zip?cols=... 导出全部任务截图 zip。 GET /api/export_date 按日期打包导出。 Query 参数：日期（如 ​ ?date=2026-10-16 ） 响应：zip，含当日所有任务截图（按 ​ 第一页/其他页 × 平台 分层）+ 汇总工作簿（每任务一 sheet） GET /shots/ 获取单张截图。 POST /api/tabs 创建任务。 请求 { &#34;name&#34;: &#34;7月官网监测&#34;, &#34;platforms&#34;: [&#34;baidu&#34;, &#34;bing&#34;] } platforms 不传则默认全选；前端默认全不勾选，由用户选择。 响应 { &#34;ok&#34;: true, &#34;tab&#34;: { &#34;id&#34;: &#34;t1&#34;, &#34;name&#34;: &#34;...&#34;, &#34;platforms&#34;: [...] } } POST /api/tabs/ /close | /delete | /rename | /clear close ​：​ {} — 关闭任务（停线程，保留数据） delete ​：​ {} — 删除任务（删 db + 截图目录 + profile） rename ​：​ { &#34;name&#34;: &#34;新名&#34; } — 重命名 clear ​：​ {} — 清空该任务全部数据 POST /api/tabs/ /import 导入关键词。 请求 { &#34;keywords&#34;: [&#34;关键词A&#34;, &#34;关键词B&#34;] } 平台沿用建任务时勾选；已有词只更新 ​ engines ，不重置已跑结果。 响应 { &#34;ok&#34;: true, &#34;count&#34;: 2 } POST /api/tabs/ /start 开始跑批（只跑 pending）。 响应：​ { &#34;ok&#34;: true } POST /api/tabs/ /pause | /stop pause ​：​ {} — 暂停/继续（当前词完成后停止） stop ​：​ {} — 停止 POST /api/tabs/ /retry 重试失败项。 请求 { &#34;keywords&#34;: [&#34;关键词A&#34;], &#34;engines&#34;: [&#34;baidu&#34;, &#34;bing&#34;] } 把指定词/引擎重置为 pending 再跑； 未命中 ​ ​ none ​ ​ 不参与重试 （​ FAILED=[&#39;error&#39;,&#39;restricted&#39;,&#39;malfunction&#39;] ）。 响应 { &#34;ok&#34;: true, &#34;retried&#34;: [...] } 错误约定 场景 响应 任务不存在 404 { &#34;error&#34;: &#34;任务不存在&#34; } 路径不存在 404 { &#34;error&#34;: &#34;not found&#34; } 导入无有效关键词 { &#34;error&#34;: &#34;没有有效关键词&#34; } 前端路由映射 前端路由 组件 对应后端接口 / Overview /api/tabs /task/:id TaskDetail /api/tabs/&lt;tid&gt;/state /all AllTasks /api/tabs /download Download /api/export_*', '2026-10-31 17:43:10.778047+08'::timestamptz, '2026-10-31 17:43:10.778047+08'::timestamptz, '57475bc4-ef3c-4e7e-a8b7-17b5526dc5a2'::uuid, 0, NULL),
  ('f1ce4cae-ff94-438e-8a23-b8d7b5524299'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'seo-inspector 项目知识沉淀', '<blockquote>
<p>批量关键词官网可见性检索工具（百度 / 必应 × PC / 移动）。本文只记录可复用的技术知识，不写功能介绍。</p>
</blockquote>
<h2>项目架构速览</h2>
<table>
<thead>
<tr>
<th style="text-align:left">层</th>
<th style="text-align:left">技术</th>
<th style="text-align:left">说明</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">前端</td>
<td style="text-align:left">Vue 3 + Vite + vue-router（hash）</td>
<td style="text-align:left">纯静态产物 ​<code>web/dist</code>，由后端直接托管</td>
</tr>
<tr>
<td style="text-align:left">后端</td>
<td style="text-align:left">Python 3.10+ 标准库 ​<code>http.server</code>​ + ​<code>ThreadingHTTPServer</code></td>
<td style="text-align:left">单进程多线程，无 Web 框架</td>
</tr>
<tr>
<td style="text-align:left">浏览器自动化</td>
<td style="text-align:left">Playwright（Chromium ​<code>==1.62.0</code>）</td>
<td style="text-align:left">四平台采集 + 截图</td>
</tr>
<tr>
<td style="text-align:left">存储</td>
<td style="text-align:left">SQLite（每任务独立 ​<code>.db</code>​）+ ​<code>openpyxl</code></td>
<td style="text-align:left">结果表 + Excel 导出</td>
</tr>
<tr>
<td style="text-align:left">调度</td>
<td style="text-align:left">每任务一个 ​<code>Worker</code> 线程</td>
<td style="text-align:left">多任务并行、独立隔离</td>
</tr>
<tr>
<td style="text-align:left">端口</td>
<td style="text-align:left"><code>127.0.0.1:27532</code></td>
<td style="text-align:left"><code>scripts/start_panel.bat</code> 一键启动</td>
</tr>
</tbody>
</table>
<pre><code>浏览器(Vue3) → HTTP JSON/文件 → server.py(路由+Worker调度+导出)
                                  └→ core/{baidu,bing,baidu_m,bing_m}.py → engine.py(Playwright)
</code></pre>
<p>四个采集模块对齐命名：​<code>baidu</code>​ / ​<code>bing</code>​ / ​<code>baidu_m</code>​ / ​<code>bing_m</code>，各配独立 UA/视口（移动端为 iPhone 14 Pro Max 参数，dsf=3）。</p>
<hr/>
<h2>核心知识一：搜索引擎官网标识命中判定</h2>
<h3>1. 百度 vs 必应的判定依据不同</h3>
<table>
<thead>
<tr>
<th style="text-align:left">平台</th>
<th style="text-align:left">判定来源</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">百度系</td>
<td style="text-align:left">结果条目<strong>来源行</strong>出现的官方字样（​<code>BAIDU_OFFICIAL_MARKS</code> 列表，子串匹配，命中任意一个即官网）</td>
</tr>
<tr>
<td style="text-align:left">必应系</td>
<td style="text-align:left">cite 显示的<strong>域名</strong>是否含 ​<code>TARGET_DOMAIN</code></td>
</tr>
</tbody>
</table>
<h3>2. 命中即停，平台间互不影响</h3>
<p>一个平台命中后，该词在该平台立即停止（记录全局排名/页码），但<strong>其他三个平台照跑</strong>——四平台结果各自独立、互不污染。</p>
<h3>3. 翻页三态：区分&#34;真到底&#34;和&#34;翻页失效&#34;（易踩坑）</h3>
<p>百度翻页用一个返回值表达三种情况，避免把&#34;真只有 1 页&#34;和&#34;选择器/风控失效&#34;合并成一个错误：</p>
<pre><code class="language-python"># 返回值语义
有下一页        → 继续抓
False          → 结果真到底了 → 一直未命中判 none
&#34;stuck&#34;        → 有下一页链接但点击后 URL 未前进 → 判 error，需人工复核
</code></pre>
<h3>4. 熔断：连续 0 条 ≠ 未命中（防反向误报）</h3>
<ul>
<li><code>ZERO_RESULT_BREAK = 3</code>​：<strong>连续 3 页解析出 0 条自然结果</strong> → 判「解析异常 ​<code>malfunction</code>」。</li>
<li>目的：页面结构变化 / 被反爬拦截时，空结果 ≠ 官网没收录，不能误判成「未命中 ​<code>none</code>」。</li>
</ul>
<hr/>
<h2>核心知识二：抓取状态语义与结论聚合</h2>
<h3>1. 五态定义（每「词 × 引擎」独立）</h3>
<pre><code>pending     待跑（断点续跑的起点）
hit         命中（记录 rank / page / evidence / shot）
none        前 10 页未命中（不参与重试）
error       明确错误（如翻页卡住）→ 需人工复核
restricted  搜索引擎合规过滤/受限页，无法判定
malfunction 连续多页 0 条，解析异常
</code></pre>
<h3>2. 结论聚合的坑：不要把&#34;判不出来&#34;写成&#34;未命中&#34;</h3>
<p>聚合 ​<code>conclusion()</code>​ 时，只要存在 ​<code>error / restricted / malfunction</code>​，<strong>就不下「未命中」结论</strong>——这三个状态是&#34;判不出来&#34;，写成&#34;10 页未见&#34;会让报告结论反向。</p>
<hr/>
<h2>核心知识三：多任务并行隔离 + 断点续跑</h2>
<h3>1. 每任务完全隔离</h3>
<p>每个任务 = 一个 ​<code>TabState</code>​：独立 ​<code>data/t&lt;id&gt;.db</code>、独立截图目录、独立浏览器 profile 子目录。并行跑多个任务互不污染、互不抢 profile。</p>
<h3>2. 断点续跑：pending 驱动</h3>
<ul>
<li>每「词 × 引擎」有独立状态列（​<code>baidu_status</code> 等）。</li>
<li><code>load_pending()</code> 只取「仍 pending 且该词需要跑该引擎」的组合。</li>
<li>重新「开始」只喂这个集合 → <strong>已跑完的不重跑</strong>。</li>
</ul>
<h3>3. 导入 upsert 不重置已跑结果（易踩坑）</h3>
<pre><code class="language-sql">INSERT INTO tasks (keyword, engines, updated_at) VALUES (?, ?, ?)
ON CONFLICT(keyword) DO UPDATE SET engines=excluded.engines, updated_at=excluded.updated_at
</code></pre>
<ul>
<li>新词插入；已存在的词<strong>只更新</strong> ​<strong>​<code>engines</code>​</strong>​ <strong>字段</strong>（同步最新平台勾选），<strong>不重置已跑状态</strong>——已跑过的平台不因重新导入而重跑。</li>
</ul>
<h3>4. 单进程多线程 Worker</h3>
<ul>
<li>每任务一个 ​<code>Worker(threading.Thread)</code>，线程内串行跑该任务所有 pending 词×平台；多任务各自线程并行。</li>
<li>暂停/停止用 ​<code>pause_evt</code>​ / ​<code>stop_evt</code>​（​<code>pause</code> 当前词完成后停）。</li>
</ul>
<h3>5. 并发一致性坑（已修复）</h3>
<table>
<thead>
<tr>
<th style="text-align:left">坑</th>
<th style="text-align:left">修复</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">「已在运行」检查与 worker 赋值不在同一临界区 → 双标签重复跑抢同一 profile</td>
<td style="text-align:left">收敛到同一临界区</td>
</tr>
<tr>
<td style="text-align:left"><code>_next_id</code> 无锁 → 并发建任务 tid 重复、数据互相覆盖</td>
<td style="text-align:left">加 ​<code>REG_LOCK</code></td>
</tr>
<tr>
<td style="text-align:left"><code>load_pending</code> 连接从不 close → 泄漏 SQLite 句柄</td>
<td style="text-align:left"><code>finally: conn.close()</code></td>
</tr>
</tbody>
</table>
<hr/>
<h2>核心知识四：风控规避节奏</h2>
<pre><code class="language-python">DELAY_MIN_MS = 2500   # 翻页随机延迟下限
DELAY_MAX_MS = 5000   # 上限（防被识别为高频机器人）
PAGE_WAIT_MS = 3000   # 页面加载后额外等待（等动态渲染）
</code></pre>
<ul>
<li>随机延迟用 ​<code>random</code>​（ruff ​<code>S311</code> 已豁免，属合理用法）。</li>
<li>移动端独立 UA/视口（iPhone 14 Pro Max 参数），与桌面端隔离。</li>
<li>验证码兜底：遇验证码记错误 → 走「重试失败项」重跑（已删除&#34;跳过&#34;功能）。</li>
</ul>
<hr/>
<h2>核心知识五：品牌配置分离 + 脱敏发布</h2>
<h3>1. config.py 占位 + config_local.py 覆盖</h3>
<pre><code class="language-python"># core/config.py
TARGET_DOMAIN = &#34;example.com&#34;          # 占位值
with contextlib.suppress(ImportError):
    from .config_local import *        # 覆盖为真实值
</code></pre>
<ul>
<li><code>core/config_local.py</code>​ 放真实目标域名/官网标识，<strong>被</strong> ​ <strong>​<code>.gitignore</code>​</strong>​ <strong>忽略，永不误提交</strong>，分支间不冲突。</li>
<li>fork 到其他品牌只需改 ​<code>config_local.py</code>，采集代码零改动。</li>
</ul>
<h3>2. 启动自检（防&#34;配置没生效全判未命中&#34;）</h3>
<p>服务启动时检测配置是否仍是占位值，是则打印醒目警告——避免 ​<code>config_local.py</code>​ 没生效时，程序去匹配 ​<code>example.com</code>、全部静默判未命中。</p>
<h3>3. 脱敏发布红线</h3>
<p>真实域名/标识比 cookie 更能暴露商业意图，公开仓库必须 0 命中：</p>
<pre><code class="language-bash">git grep -E &#34;真实品牌关键词&#34; .      # 仓库内应 0 命中
git check-ignore core/config_local.py  # 真实配置必须被忽略
</code></pre>
<ul>
<li>代码注释、docstring、函数名（如 ​<code>_is_official</code>）均不得含品牌子串。</li>
<li>运行时数据（​<code>data/</code>​、​<code>shots/</code>​、​<code>profile_sessions/</code>​、​<code>logs/</code>）一律 gitignore。</li>
</ul>
<hr/>
<h2>核心知识六：SQLite&#34;每词一行 × 四引擎列&#34;模型</h2>
<ul>
<li>每词一行，四个引擎各占 5 列（​<code>status/rank/page/evidence/shot</code>​），共 20 引擎列 + ​<code>keyword/updated_at/engines</code>。</li>
<li>引擎列映射：​<code>_ENGINE_COLS[engine]</code>​ → 对应列名（​<code>baidu_status</code>​、​<code>baidu_rank</code>…）。</li>
<li><strong>迁移补列</strong>：​<code>init_db</code>​ 每次读 ​<code>PRAGMA table_info</code>​，缺列自动 ​<code>ALTER TABLE ADD COLUMN</code> → 老库平滑升级，无需手工迁移。</li>
</ul>
<pre><code class="language-python">def _now():
    return datetime.datetime.now().astimezone().strftime(&#34;%Y-%m-%d %H:%M:%S&#34;)
</code></pre>
<hr/>
<h2>工程要点</h2>
<ul>
<li><strong>单文件 server.py</strong>（~1300 行）：功能集中、零框架依赖，作为单人运维工具可接受；代价是职责混合。</li>
<li><strong>前端 hash 路由</strong>（​<code>createWebHashHistory</code>​）：后端只需托管 ​<code>dist</code>，无需为深链做 history 回退。</li>
<li><strong>导出</strong>：单任务 Excel / 汇总 Excel（每任务一 sheet）/ 截图 zip / <strong>按日期打包</strong>（截图按 ​<code>第一页|其他页 × 平台</code> 分层 + 汇总工作簿）。</li>
<li><strong>截图归档</strong>：​<code>平台/PC|MOB</code> 子目录，与前端 2×2 布局一一对应。</li>
<li><strong>CI</strong>（GitHub Actions）：backend job 跑 ​<code>pytest + ruff</code>​，frontend job 跑 ​<code>npm build</code>​；smoke test 根页面断言在 <strong>dist 缺失时容错跳过</strong>（CI 后端 job 不构建前端，避免误报 500）。</li>
<li><strong>ruff 规则调优</strong>：​<code>select</code>​ 含安全规则 ​<code>S</code>​；爬虫场景豁免 ​<code>S110/S112/S311/S310/S608</code>（try-except 健壮性、random 延迟、urlopen、SQL 硬编码均为合理用法）。</li>
<li><strong>双远程发布</strong>：​<code>origin</code>​ push 配置双 url（gitee + github），​<code>git push</code> 一次双推。</li>
</ul>
<h2>可复用清单</h2>
<ul data-type="taskList">
<li data-type="taskItem" data-checked="false">官网标识命中判定：百度来源行 vs 必应 cite 域名，命中即停、平台独立</li>
<li data-type="taskItem" data-checked="false">翻页三态：​<code>False</code>​（真到底）与 ​<code>&#34;stuck&#34;</code>（翻页失效需复核）分离</li>
<li data-type="taskItem" data-checked="false">熔断：连续 N 页 0 条 → ​<code>malfunction</code>，避免空结果误判未命中</li>
<li data-type="taskItem" data-checked="false">五态状态机 + 结论聚合不把&#34;判不出来&#34;写成&#34;未命中&#34;</li>
<li data-type="taskItem" data-checked="false">pending 驱动断点续跑 + upsert 只更新 ​<code>engines</code> 不重置已跑结果</li>
<li data-type="taskItem" data-checked="false">每任务独立 db/profile/截图目录实现并行隔离</li>
<li data-type="taskItem" data-checked="false">单进程多线程 Worker + ​<code>pause_evt</code>​/​<code>stop_evt</code> 协作</li>
<li data-type="taskItem" data-checked="false">并发一致性：worker 赋值临界区、​<code>_next_id</code> 加锁、连接 finally close</li>
<li data-type="taskItem" data-checked="false">风控规避：随机延迟 + 页面等待 + 移动端独立 UA/视口</li>
<li data-type="taskItem" data-checked="false">品牌配置分离：config.py 占位 + config_local.py（gitignore）覆盖 + 启动自检</li>
<li data-type="taskItem" data-checked="false">脱敏发布红线：​<code>git grep</code>​ 0 命中 + ​<code>git check-ignore</code> 校验</li>
<li data-type="taskItem" data-checked="false">SQLite 迁移补列：​<code>PRAGMA table_info</code>​ + ​<code>ALTER TABLE ADD COLUMN</code></li>
<li data-type="taskItem" data-checked="false">前端 hash 路由免后端 history 回退</li>
<li data-type="taskItem" data-checked="false">单端口生产模式：后端同时托管 API + 静态 ​<code>dist</code></li>
</ul>
', 'private', NULL, 'seo-inspector 项目知识沉淀 批量关键词官网可见性检索工具（百度 / 必应 × PC / 移动）。本文只记录可复用的技术知识，不写功能介绍。 项目架构速览 层 技术 说明 前端 Vue 3 + Vite + vue-router（hash） 纯静态产物 ​ web/dist ，由后端直接托管 后端 Python 3.10+ 标准库 ​ http.server ​ + ​ ThreadingHTTPServer 单进程多线程，无 Web 框架 浏览器自动化 Playwright（Chromium ​ ==1.62.0 ） 四平台采集 + 截图 存储 SQLite（每任务独立 ​ .db ​）+ ​ openpyxl 结果表 + Excel 导出 调度 每任务一个 ​ Worker 线程 多任务并行、独立隔离 端口 127.0.0.1:27532 scripts/start_panel.bat 一键启动 浏览器(Vue3) → HTTP JSON/文件 → server.py(路由+Worker调度+导出) └→ core/{baidu,bing,baidu_m,bing_m}.py → engine.py(Playwright) 四个采集模块对齐命名：​ baidu ​ / ​ bing ​ / ​ baidu_m ​ / ​ bing_m ，各配独立 UA/视口（移动端为 iPhone 14 Pro Max 参数，dsf=3）。 核心知识一：搜索引擎官网标识命中判定 1. 百度 vs 必应的判定依据不同 平台 判定来源 百度系 结果条目 来源行 出现的官方字样（​ BAIDU_OFFICIAL_MARKS 列表，子串匹配，命中任意一个即官网） 必应系 cite 显示的 域名 是否含 ​ TARGET_DOMAIN 2. 命中即停，平台间互不影响 一个平台命中后，该词在该平台立即停止（记录全局排名/页码），但 其他三个平台照跑 ——四平台结果各自独立、互不污染。 3. 翻页三态：区分&#34;真到底&#34;和&#34;翻页失效&#34;（易踩坑） 百度翻页用一个返回值表达三种情况，避免把&#34;真只有 1 页&#34;和&#34;选择器/风控失效&#34;合并成一个错误： # 返回值语义 有下一页 → 继续抓 False → 结果真到底了 → 一直未命中判 none &#34;stuck&#34; → 有下一页链接但点击后 URL 未前进 → 判 error，需人工复核 4. 熔断：连续 0 条 ≠ 未命中（防反向误报） ZERO_RESULT_BREAK = 3 ​： 连续 3 页解析出 0 条自然结果 → 判「解析异常 ​ malfunction 」。 目的：页面结构变化 / 被反爬拦截时，空结果 ≠ 官网没收录，不能误判成「未命中 ​ none 」。 核心知识二：抓取状态语义与结论聚合 1. 五态定义（每「词 × 引擎」独立） pending 待跑（断点续跑的起点） hit 命中（记录 rank / page / evidence / shot） none 前 10 页未命中（不参与重试） error 明确错误（如翻页卡住）→ 需人工复核 restricted 搜索引擎合规过滤/受限页，无法判定 malfunction 连续多页 0 条，解析异常 2. 结论聚合的坑：不要把&#34;判不出来&#34;写成&#34;未命中&#34; 聚合 ​ conclusion() ​ 时，只要存在 ​ error / restricted / malfunction ​， 就不下「未命中」结论 ——这三个状态是&#34;判不出来&#34;，写成&#34;10 页未见&#34;会让报告结论反向。 核心知识三：多任务并行隔离 + 断点续跑 1. 每任务完全隔离 每个任务 = 一个 ​ TabState ​：独立 ​ data/t&lt;id&gt;.db 、独立截图目录、独立浏览器 profile 子目录。并行跑多个任务互不污染、互不抢 profile。 2. 断点续跑：pending 驱动 每「词 × 引擎」有独立状态列（​ baidu_status 等）。 load_pending() 只取「仍 pending 且该词需要跑该引擎」的组合。 重新「开始」只喂这个集合 → 已跑完的不重跑 。 3. 导入 upsert 不重置已跑结果（易踩坑） INSERT INTO tasks (keyword, engines, updated_at) VALUES (?, ?, ?) ON CONFLICT(keyword) DO UPDATE SET engines=excluded.engines, updated_at=excluded.updated_at 新词插入；已存在的词 只更新 ​ ​ engines ​ ​ 字段 （同步最新平台勾选）， 不重置已跑状态 ——已跑过的平台不因重新导入而重跑。 4. 单进程多线程 Worker 每任务一个 ​ Worker(threading.Thread) ，线程内串行跑该任务所有 pending 词×平台；多任务各自线程并行。 暂停/停止用 ​ pause_evt ​ / ​ stop_evt ​（​ pause 当前词完成后停）。 5. 并发一致性坑（已修复） 坑 修复 「已在运行」检查与 worker 赋值不在同一临界区 → 双标签重复跑抢同一 profile 收敛到同一临界区 _next_id 无锁 → 并发建任务 tid 重复、数据互相覆盖 加 ​ REG_LOCK load_pending 连接从不 close → 泄漏 SQLite 句柄 finally: conn.close() 核心知识四：风控规避节奏 DELAY_MIN_MS = 2500 # 翻页随机延迟下限 DELAY_MAX_MS = 5000 # 上限（防被识别为高频机器人） PAGE_WAIT_MS = 3000 # 页面加载后额外等待（等动态渲染） 随机延迟用 ​ random ​（ruff ​ S311 已豁免，属合理用法）。 移动端独立 UA/视口（iPhone 14 Pro Max 参数），与桌面端隔离。 验证码兜底：遇验证码记错误 → 走「重试失败项」重跑（已删除&#34;跳过&#34;功能）。 核心知识五：品牌配置分离 + 脱敏发布 1. config.py 占位 + config_local.py 覆盖 # core/config.py TARGET_DOMAIN = &#34;example.com&#34; # 占位值 with contextlib.suppress(ImportError): from .config_local import * # 覆盖为真实值 core/config_local.py ​ 放真实目标域名/官网标识， 被 ​ ​ .gitignore ​ ​ 忽略，永不误提交 ，分支间不冲突。 fork 到其他品牌只需改 ​ config_local.py ，采集代码零改动。 2. 启动自检（防&#34;配置没生效全判未命中&#34;） 服务启动时检测配置是否仍是占位值，是则打印醒目警告——避免 ​ config_local.py ​ 没生效时，程序去匹配 ​ example.com 、全部静默判未命中。 3. 脱敏发布红线 真实域名/标识比 cookie 更能暴露商业意图，公开仓库必须 0 命中： git grep -E &#34;真实品牌关键词&#34; . # 仓库内应 0 命中 git check-ignore core/config_local.py # 真实配置必须被忽略 代码注释、docstring、函数名（如 ​ _is_official ）均不得含品牌子串。 运行时数据（​ data/ ​、​ shots/ ​、​ profile_sessions/ ​、​ logs/ ）一律 gitignore。 核心知识六：SQLite&#34;每词一行 × 四引擎列&#34;模型 每词一行，四个引擎各占 5 列（​ status/rank/page/evidence/shot ​），共 20 引擎列 + ​ keyword/updated_at/engines 。 引擎列映射：​ _ENGINE_COLS[engine] ​ → 对应列名（​ baidu_status ​、​ baidu_rank …）。 迁移补列 ：​ init_db ​ 每次读 ​ PRAGMA table_info ​，缺列自动 ​ ALTER TABLE ADD COLUMN → 老库平滑升级，无需手工迁移。 def _now(): return datetime.datetime.now().astimezone().strftime(&#34;%Y-%m-%d %H:%M:%S&#34;) 工程要点 单文件 server.py （~1300 行）：功能集中、零框架依赖，作为单人运维工具可接受；代价是职责混合。 前端 hash 路由 （​ createWebHashHistory ​）：后端只需托管 ​ dist ，无需为深链做 history 回退。 导出 ：单任务 Excel / 汇总 Excel（每任务一 sheet）/ 截图 zip / 按日期打包 （截图按 ​ 第一页|其他页 × 平台 分层 + 汇总工作簿）。 截图归档 ：​ 平台/PC|MOB 子目录，与前端 2×2 布局一一对应。 CI （GitHub Actions）：backend job 跑 ​ pytest + ruff ​，frontend job 跑 ​ npm build ​；smoke test 根页面断言在 dist 缺失时容错跳过 （CI 后端 job 不构建前端，避免误报 500）。 ruff 规则调优 ：​ select ​ 含安全规则 ​ S ​；爬虫场景豁免 ​ S110/S112/S311/S310/S608 （try-except 健壮性、random 延迟、urlopen、SQL 硬编码均为合理用法）。 双远程发布 ：​ origin ​ push 配置双 url（gitee + github），​ git push 一次双推。 可复用清单 官网标识命中判定：百度来源行 vs 必应 cite 域名，命中即停、平台独立 翻页三态：​ False ​（真到底）与 ​ &#34;stuck&#34; （翻页失效需复核）分离 熔断：连续 N 页 0 条 → ​ malfunction ，避免空结果误判未命中 五态状态机 + 结论聚合不把&#34;判不出来&#34;写成&#34;未命中&#34; pending 驱动断点续跑 + upsert 只更新 ​ engines 不重置已跑结果 每任务独立 db/profile/截图目录实现并行隔离 单进程多线程 Worker + ​ pause_evt ​/​ stop_evt 协作 并发一致性：worker 赋值临界区、​ _next_id 加锁、连接 finally close 风控规避：随机延迟 + 页面等待 + 移动端独立 UA/视口 品牌配置分离：config.py 占位 + config_local.py（gitignore）覆盖 + 启动自检 脱敏发布红线：​ git grep ​ 0 命中 + ​ git check-ignore 校验 SQLite 迁移补列：​ PRAGMA table_info ​ + ​ ALTER TABLE ADD COLUMN 前端 hash 路由免后端 history 回退 单端口生产模式：后端同时托管 API + 静态 ​ dist', '2026-10-31 11:04:23.63629+08'::timestamptz, '2026-10-31 11:05:02.06937+08'::timestamptz, '9e43d5aa-00e9-4619-a51d-1195d25ea739'::uuid, 0, NULL),
  ('f84dbe36-4332-4c04-953a-cb68bf45d2e4'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'gogs-diary · 开发记录', '<h2>1. v0.1 — 基础日记</h2>
<ul>
<li>读 Gogs SQLite action 表</li>
<li>调 DeepSeek 生成日记</li>
<li>写入思源 daily note/&lt;年&gt;/&lt;月&gt;/&lt;日期&gt;</li>
</ul>
<h2>2. v0.2 — 四级总结</h2>
<ul>
<li>加 weekly/monthly/yearly 三种模式</li>
<li>文档树加&#34;第X周&#34;层级（月和日之间）</li>
<li>cron 定时触发</li>
</ul>
<h2>3. v0.3 — 改动文件 + prompt 外置</h2>
<ul>
<li>接 Gogs API 查 commit 改动文件，日记更具体</li>
<li>prompt 抽到 prompts.toml，改文案不动代码</li>
<li>加 --date 参数补历史数据</li>
</ul>
<h2>4. v0.4 — 手写内容识别</h2>
<ul>
<li>周/月/年报读取思源手写内容</li>
<li>截取&#34;自动生成&#34;标记之前的部分</li>
<li>避免 AI 生成内容循环喂给下一级</li>
</ul>
<h2>5. v0.5 — 层级修正</h2>
<ul>
<li>月报读周报、年报读月报，不直接读日记</li>
<li>标题层级统一：周/月/年报用 H1+H2，日记用 H2+H3</li>
<li>分割线移到标题后面</li>
</ul>
<h2>踩坑记录</h2>
<h3>Gogs action 表没有 commit_sha</h3>
<p>Gogs 的 action 表只有 id/user_id/op_type/repo_id/content/created_unix 等列，没有 commit_sha。改动文件不是从数据库拿的，是通过 Gogs API 按时间范围查 commits 获取的。</p>
<h3>思源 getDoc 参数名</h3>
<p>思源的 ​<code>/api/filetree/getDoc</code>​ 接口参数是 ​<code>id</code>​，不是 ​<code>docID</code>​。用错参数会报 ​<code>Field [id] is required</code>。</p>
<h3>标题层级重复</h3>
<p>一开始在 prompts.toml 里让 DS 自己输出标题，但代码里 append_to_siyuan 已经加了标题，结果重复了两遍。最终方案：标题由代码统一控制，DS 只输出正文。</p>
<h3>分割线位置</h3>
<p>分割线一开始放在标题前面，导致标题跑到分割线下面。调整为：标题 → 分割线 → 自动生成内容。</p>
', 'private', NULL, 'gogs-diary · 开发记录 1. v0.1 — 基础日记 读 Gogs SQLite action 表 调 DeepSeek 生成日记 写入思源 daily note/&lt;年&gt;/&lt;月&gt;/&lt;日期&gt; 2. v0.2 — 四级总结 加 weekly/monthly/yearly 三种模式 文档树加&#34;第X周&#34;层级（月和日之间） cron 定时触发 3. v0.3 — 改动文件 + prompt 外置 接 Gogs API 查 commit 改动文件，日记更具体 prompt 抽到 prompts.toml，改文案不动代码 加 --date 参数补历史数据 4. v0.4 — 手写内容识别 周/月/年报读取思源手写内容 截取&#34;自动生成&#34;标记之前的部分 避免 AI 生成内容循环喂给下一级 5. v0.5 — 层级修正 月报读周报、年报读月报，不直接读日记 标题层级统一：周/月/年报用 H1+H2，日记用 H2+H3 分割线移到标题后面 踩坑记录 Gogs action 表没有 commit_sha Gogs 的 action 表只有 id/user_id/op_type/repo_id/content/created_unix 等列，没有 commit_sha。改动文件不是从数据库拿的，是通过 Gogs API 按时间范围查 commits 获取的。 思源 getDoc 参数名 思源的 ​ /api/filetree/getDoc ​ 接口参数是 ​ id ​，不是 ​ docID ​。用错参数会报 ​ Field [id] is required 。 标题层级重复 一开始在 prompts.toml 里让 DS 自己输出标题，但代码里 append_to_siyuan 已经加了标题，结果重复了两遍。最终方案：标题由代码统一控制，DS 只输出正文。 分割线位置 分割线一开始放在标题前面，导致标题跑到分割线下面。调整为：标题 → 分割线 → 自动生成内容。', '2026-10-31 17:43:08.716732+08'::timestamptz, '2026-10-31 17:43:08.716732+08'::timestamptz, 'a1e7e98b-f958-4d11-9727-964a23a0415e'::uuid, 0, NULL),
  ('3c561697-a20b-4fc0-9b31-ea5b5f87808a'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '沙利文后台系统', '<div id="readability-page-1" class="page"><div data-v-73470880="" data-prefix="el" data-v-8201b000="" data-v-34116364="" id="app" data-v-app=""><table><colgroup><col name="el-table_1_column_1" width="404"><col name="el-table_1_column_2" width="134"><col name="el-table_1_column_3" width="134"><col name="el-table_1_column_4" width="160"><col name="el-table_1_column_5" width="442"><col name="el-table_1_column_6" width="80"><col name="el-table_1_column_7" width="321"><col name="el-table_1_column_8" width="150"></colgroup><!--v-if--><tbody tabindex="-1"><tr><td colspan="1" rowspan="1"><p>专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:23:53</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:34</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文全球研讨会预告（11/4 - 11/12）</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:41:26</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:40:33</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:54</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:04</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981889121551301feca09" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981889121551301feca09</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>校招 | 2027，与沙利文中国一起成长，迎接无限可能！</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-11-02 11:48:02</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:39</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式）</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:12</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:31:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:30:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:28:19</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖”</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-10-29 10:26:56</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr></tbody><!--v-if--></table><!--v-if--><!--v-if--></div></div>', 'private', NULL, '沙利文后台系统 专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读 传媒中心 公司动态 2026-11-04 11:23:53 https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊 最新洞察 企业研究 2026-11-04 11:22:59 https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》 最新洞察 趋势研读 2026-11-04 11:22:34 https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文全球研讨会预告（11/4 - 11/12） 传媒中心 公司动态 2026-11-03 14:41:26 https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》 最新洞察 趋势研读 2026-11-03 14:40:33 https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台 传媒中心 公司动态 2026-11-03 14:39:54 https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行 传媒中心 公司动态 2026-11-03 14:39:04 https://www.frostchina.com/content/news/detail/6ae981889121551301feca09 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 校招 | 2027，与沙利文中国一起成长，迎接无限可能！ — — 2026-11-02 11:48:02 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》 最新洞察 趋势研读 2026-10-30 11:28:39 https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》 最新洞察 趋势研读 2026-10-30 11:28:27 https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式） 最新洞察 趋势研读 2026-10-30 11:28:12 https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》 最新洞察 趋势研读 2026-10-29 10:31:27 https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势 传媒中心 公司动态 2026-10-29 10:30:59 https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖 最新洞察 企业研究 2026-10-29 10:28:19 https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖” — — 2026-10-29 10:26:56 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 —', '2026-11-05 11:35:32.027416+08'::timestamptz, '2026-11-05 11:35:32.027416+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:35:44.667562+08'::timestamptz),
  ('9f9a115f-f513-46eb-9dab-966232d47f46'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '向山巅再迈一步', '<div id="readability-page-1" class="page"><div><p>© Alex Treadway/Getty Images</p></div></div>', 'private', NULL, '向山巅再迈一步 © Alex Treadway/Getty Images', '2026-11-05 11:36:11.880181+08'::timestamptz, '2026-11-05 11:36:11.880181+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:44:00.723271+08'::timestamptz),
  ('59f4dcc0-7ee3-44ba-a4b6-9310830c5b55'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '搜索查重工具方案', '<h2>1 概述</h2><p>本工具为浏览器端 Tampermonkey（油猴）查重工具，<strong>同时支持百度、必应搜索结果实时检测</strong>，用于在搜索浏览过程中自动识别命中规则的搜索标题。 核心设计目标：<strong>脱敏、本地存储、无硬编码敏感内容、笔记可安全同步</strong>。</p><h2>2 功能清单</h2><ol><li><p>覆盖平台：百度（PC+移动端搜索页）、必应（PC搜索页）</p></li><li><p>匹配方式：正则表达式数组，<strong>不区分大小写</strong>，模糊匹配标题文本</p></li><li><p>触发时机：页面初次加载、滚动加载新结果、DOM动态更新</p></li><li><p>防抖控制：400ms 防抖，避免频繁扫描</p></li><li><p>通知方式：浏览器原生通知弹窗，控制台打印命中日志</p></li><li><p>去重机制：内存集合缓存已命中标题，同一条结果不会重复弹窗</p></li><li><p>规则存储：规则数组保存在浏览器 <code>localStorage</code>，脚本内无硬编码规则</p></li><li><p>日志输出：仅打印搜索词 + 结果总数；只有命中时输出命中详情，日志干净</p></li></ol><h2>3 架构与数据流向</h2><pre class="hljs"><code>浏览器打开百度/必应搜索页 → Tampermonkey 脚本启动
→ 读取 localStorage 内 example 规则数组
→ 编译为不区分大小写正则
→ 监听页面DOM变化、滚动事件
→ 抓取搜索结果标题+链接
→ 循环正则匹配标题
→ 命中：控制台输出记录 + 浏览器通知；做内存去重
→ 未命中：无输出

</code></pre><blockquote><p>数据边界：<strong>规则只存在当前浏览器实例，无痕窗口、其他浏览器需要重新导入</strong>；脚本本身不向任何外部服务器上传搜索词、标题、匹配规则。</p></blockquote><h2>4 平台适配说明</h2><h3>4.1 百度（PC+移动端）</h3><ul><li><p>匹配URL：<code>www.baidu.com/s</code>、<code>m.baidu.com/s</code></p></li><li><p>DOM选择器</p><ul><li><p>PC结果：<code>a.normal-sub_11u5j</code></p></li><li><p>移动端结果：<code>section.cosc-card-content</code></p></li></ul></li><li><p>标题节点：<code>h3[data-module="top_title"]</code></p></li><li><p>搜索关键词取自URL参数 <code>word</code></p></li></ul><h3>4.2 必应（PC）</h3><ul><li><p>匹配URL：<code>cn.bing.com/search</code>、<code>www.bing.com/search</code></p></li><li><p>DOM选择器：<code>li.b_algo</code></p></li><li><p>标题节点：<code>h2 a</code></p></li><li><p>搜索关键词取自URL参数 <code>q</code></p></li></ul><blockquote><p>风险：搜索引擎前端DOM结构改版会导致选择器失效，需要更新对应选择器。</p></blockquote><h2>5 脱敏与安全设计（重点）</h2><ol><li><p><strong>规则抽离</strong>：所有匹配正则不写在脚本源码，统一放在 <code>localStorage.example_check_exp</code></p></li><li><p><strong>源码脱敏</strong>：脚本内部标记统一使用 <code>example</code>，不存在业务名称、项目代号、产品词</p></li><li><p><strong>无持久化泄露</strong>：脚本本身不写任何业务内容到笔记、云端；笔记只保存通用脚本逻辑文档</p></li><li><p><strong>本地运算</strong>：全部匹配逻辑在浏览器前端完成，无后端、无API、无数据外发</p></li><li><p><strong>隔离特性</strong>：localStorage 是浏览器域隔离，不同浏览器、无痕模式相互独立</p></li></ol><h2>6 规则管理操作手册（控制台执行）</h2><p>存储键：<code>example_check_exp</code>，值为 JSON 字符串数组，正则<strong>不需要前后 </strong><code>/</code>。</p><pre class="hljs"><code>// 导入/更新规则
const expList = [
    "xxx.*aaa",
    "bbb.*ccc"
];
localStorage.setItem("example_check_exp", JSON.stringify(expList));

// 查看当前规则
JSON.parse(localStorage.getItem("example_check_exp"))

// 复制规则到剪贴板，用于备份
copy(JSON.parse(localStorage.getItem("example_check_exp")))

// 清空全部规则
localStorage.removeItem("example_check_exp")

</code></pre><ul><li><p>规则示例：<code>工业触摸.*显示器</code>、<code>医疗.*触控屏</code></p></li><li><p>语法：标准 JS 正则字符串，<code>.*</code> 代表任意字符，匹配时忽略大小写</p></li></ul><h2>7 日志输出格式</h2><pre class="hljs"><code>=====搜索词===== 页面链接总数：N
✅命中 | 标题：xxx | 链接：xxx

</code></pre><ul><li><p>无规则时提示：<code>=====搜索词===== 页面链接总数：0，未配置example规则</code></p></li><li><p>控制台仅保留必要信息，不批量打印全部搜索结果</p></li></ul><h2>8 依赖与前置条件</h2><ol><li><p>浏览器扩展：Tampermonkey（油猴）</p></li><li><p>浏览器权限：页面通知权限（否则弹窗通知不生效）</p></li><li><p>限制：</p><ul><li><p>搜索引擎前端改版 → 选择器失效，扫描失效</p></li><li><p>无痕模式默认隔离 localStorage，规则丢失</p></li><li><p>多浏览器使用需要分别导入规则</p></li></ul></li><li><p>部署方式：百度、必应分为两个独立脚本，在 Tampermonkey 分别新建脚本粘贴</p></li></ol><h2>9 维护与迭代清单</h2><table style="min-width: 50px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th style="text-align: left;"><p>事项</p></th><th style="text-align: left;"><p>操作</p></th></tr><tr><td style="text-align: left;"><p>新增/修改匹配关键词</p></td><td style="text-align: left;"><p>控制台重新导入 exp 数组</p></td></tr><tr><td style="text-align: left;"><p>百度页面改版</p></td><td style="text-align: left;"><p>更新 pcCards、mobileCards 选择器</p></td></tr><tr><td style="text-align: left;"><p>必应页面改版</p></td><td style="text-align: left;"><p>更新 <code>li.b_algo</code> 结果选择器</p></td></tr><tr><td style="text-align: left;"><p>更换浏览器</p></td><td style="text-align: left;"><p>重新导入规则</p></td></tr><tr><td style="text-align: left;"><p>停用</p></td><td style="text-align: left;"><p>Tampermonkey 内关闭脚本开关</p></td></tr></tbody></table><h2>10 风险说明</h2><ol><li><p>搜索引擎前端结构不定期升级，属于外部依赖，无法保证长期稳定；</p></li><li><p>localStorage 仅本地存储，无自动备份，建议定期 <code>copy</code> 导出规则单独备份；</p></li><li><p>仅做标题文本匹配，不做内容正文抓取，只能判断标题命中；</p></li><li><p>浏览器通知权限被拦截时，仅保留控制台日志，不会弹窗提醒。</p></li></ol><p>如果你需要，我可以再给一份精简摘要版（适合放在笔记顶部）。</p>', 'private', NULL, '搜索查重工具方案 1 概述 本工具为浏览器端 Tampermonkey（油猴）查重工具， 同时支持百度、必应搜索结果实时检测 ，用于在搜索浏览过程中自动识别命中规则的搜索标题。 核心设计目标： 脱敏、本地存储、无硬编码敏感内容、笔记可安全同步 。 2 功能清单 覆盖平台：百度（PC+移动端搜索页）、必应（PC搜索页） 匹配方式：正则表达式数组， 不区分大小写 ，模糊匹配标题文本 触发时机：页面初次加载、滚动加载新结果、DOM动态更新 防抖控制：400ms 防抖，避免频繁扫描 通知方式：浏览器原生通知弹窗，控制台打印命中日志 去重机制：内存集合缓存已命中标题，同一条结果不会重复弹窗 规则存储：规则数组保存在浏览器 localStorage ，脚本内无硬编码规则 日志输出：仅打印搜索词 + 结果总数；只有命中时输出命中详情，日志干净 3 架构与数据流向 浏览器打开百度/必应搜索页 → Tampermonkey 脚本启动 → 读取 localStorage 内 example 规则数组 → 编译为不区分大小写正则 → 监听页面DOM变化、滚动事件 → 抓取搜索结果标题+链接 → 循环正则匹配标题 → 命中：控制台输出记录 + 浏览器通知；做内存去重 → 未命中：无输出 数据边界： 规则只存在当前浏览器实例，无痕窗口、其他浏览器需要重新导入 ；脚本本身不向任何外部服务器上传搜索词、标题、匹配规则。 4 平台适配说明 4.1 百度（PC+移动端） 匹配URL： www.baidu.com/s 、 m.baidu.com/s DOM选择器 PC结果： a.normal-sub_11u5j 移动端结果： section.cosc-card-content 标题节点： h3[data-module="top_title"] 搜索关键词取自URL参数 word 4.2 必应（PC） 匹配URL： cn.bing.com/search 、 www.bing.com/search DOM选择器： li.b_algo 标题节点： h2 a 搜索关键词取自URL参数 q 风险：搜索引擎前端DOM结构改版会导致选择器失效，需要更新对应选择器。 5 脱敏与安全设计（重点） 规则抽离 ：所有匹配正则不写在脚本源码，统一放在 localStorage.example_check_exp 源码脱敏 ：脚本内部标记统一使用 example ，不存在业务名称、项目代号、产品词 无持久化泄露 ：脚本本身不写任何业务内容到笔记、云端；笔记只保存通用脚本逻辑文档 本地运算 ：全部匹配逻辑在浏览器前端完成，无后端、无API、无数据外发 隔离特性 ：localStorage 是浏览器域隔离，不同浏览器、无痕模式相互独立 6 规则管理操作手册（控制台执行） 存储键： example_check_exp ，值为 JSON 字符串数组，正则 不需要前后 / 。 // 导入/更新规则 const expList = [ "xxx.*aaa", "bbb.*ccc" ]; localStorage.setItem("example_check_exp", JSON.stringify(expList)); // 查看当前规则 JSON.parse(localStorage.getItem("example_check_exp")) // 复制规则到剪贴板，用于备份 copy(JSON.parse(localStorage.getItem("example_check_exp"))) // 清空全部规则 localStorage.removeItem("example_check_exp") 规则示例： 工业触摸.*显示器 、 医疗.*触控屏 语法：标准 JS 正则字符串， .* 代表任意字符，匹配时忽略大小写 7 日志输出格式 =====搜索词===== 页面链接总数：N ✅命中 | 标题：xxx | 链接：xxx 无规则时提示： =====搜索词===== 页面链接总数：0，未配置example规则 控制台仅保留必要信息，不批量打印全部搜索结果 8 依赖与前置条件 浏览器扩展：Tampermonkey（油猴） 浏览器权限：页面通知权限（否则弹窗通知不生效） 限制： 搜索引擎前端改版 → 选择器失效，扫描失效 无痕模式默认隔离 localStorage，规则丢失 多浏览器使用需要分别导入规则 部署方式：百度、必应分为两个独立脚本，在 Tampermonkey 分别新建脚本粘贴 9 维护与迭代清单 事项 操作 新增/修改匹配关键词 控制台重新导入 exp 数组 百度页面改版 更新 pcCards、mobileCards 选择器 必应页面改版 更新 li.b_algo 结果选择器 更换浏览器 重新导入规则 停用 Tampermonkey 内关闭脚本开关 10 风险说明 搜索引擎前端结构不定期升级，属于外部依赖，无法保证长期稳定； localStorage 仅本地存储，无自动备份，建议定期 copy 导出规则单独备份； 仅做标题文本匹配，不做内容正文抓取，只能判断标题命中； 浏览器通知权限被拦截时，仅保留控制台日志，不会弹窗提醒。 如果你需要，我可以再给一份精简摘要版（适合放在笔记顶部）。', '2026-11-02 13:42:27.954714+08'::timestamptz, '2026-11-04 17:52:38.742067+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:45:06.466952+08'::timestamptz),
  ('a6866ed7-62a8-4405-a43e-af98fa312041'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Js', '<pre class="hljs"><code class="language-javascript">// ==UserScript==
// @name         搜索查重（百度｜example脱敏版）
// @namespace    http://tampermonkey.net/
// @version      2.14
// @description  百度PC/移动端查重，匹配规则从localStorage读取，无硬编码敏感内容；仅浏览器通知，精简日志
// @author       You
// @match        https://www.baidu.com/s*
// @match        https://baidu.com/s*
// @match        https://m.baidu.com/s*
// @match        https://m.baidu.com/from=*/ssid=*/s?*
// @grant        none
// ==/UserScript==


(function() {
    ''use strict'';
    console.log("=====example 搜索查重（百度）脚本启动=====");

    const CONFIG = {
        STORAGE_KEY: "example_check_exp"
    };

    // 读取正则表达式数组
    function getExpList() {
        const raw = localStorage.getItem(CONFIG.STORAGE_KEY);
        if (!raw) return [];
        try {
            const arr = JSON.parse(raw);
            return arr.map(item =&gt; new RegExp(item, "i"));
        } catch (e) {
            return [];
        }
    }

    function normalize(str){
        return str.replace(/\s+/g,'' '').trim();
    }

    function getSearchWord() {
        const urlParams = new URLSearchParams(location.search);
        return urlParams.get(''word'') || '''';
    }

    let isRunning = false;
    let debounceTimer = null;
    const notifiedSet = new Set();

    function sendNotify(titleText, matchText){
        const msg = `标题：${titleText}\n${matchText}`;
        if("Notification" in window &amp;&amp; Notification.permission === "granted"){
            new Notification(''example 查重命中'', { body: msg });
        }
    }

    function scan(){
        if(isRunning) return;
        isRunning = true;
        try{
            const keyword = getSearchWord();
            const expList = getExpList();
            if(expList.length === 0) {
                console.log(`=====${keyword}===== 页面链接总数：0，未配置example规则`);
                return;
            }

            const pcCards = document.querySelectorAll(''a.normal-sub_11u5j'');
            const mobileCards = document.querySelectorAll(''section.cosc-card-content'');
            const allCards = [...pcCards, ...mobileCards];
            console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`);

            allCards.forEach(card=&gt;{
                let rawTitle = "";
                let linkUrl = "";
                let hitReason = null;

                if (card.tagName === "A") {
                    const titleEl = card.querySelector(''h3[data-module="top_title"]'');
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    linkUrl = card.href;
                } else {
                    const titleEl = card.querySelector(''div[data-module="title"] h3'');
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    const aTag = card.querySelector("a");
                    linkUrl = aTag?.href || "";
                }

                const titleNorm = normalize(rawTitle);
                for(const exp of expList){
                    if(exp.test(titleNorm)){
                        hitReason = `example 正则匹配：${exp.source}`;
                        break;
                    }
                }

                const titleKey = rawTitle;
                if(notifiedSet.has(titleKey)) return;

                if(hitReason){
                    notifiedSet.add(titleKey);
                    console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl}`);
                    sendNotify(rawTitle, hitReason);
                }
            })
        }finally{
            isRunning = false;
        }
    }

    function debounceScan(){
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(scan, 400);
    }

    function start(){
        if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){
            Notification.requestPermission();
        }
        const observer = new MutationObserver(()=&gt; debounceScan());
        observer.observe(document.body, {childList:true, subtree:true});

        window.addEventListener(''scroll'', debounceScan, {passive:true});
        scan();
        setTimeout(scan, 1200);
    }
    if(document.body) start();
    else document.addEventListener(''DOMContentLoaded'', start);
})();

</code></pre><pre class="hljs"><code class="language-javascript">// ==UserScript==
// @name         搜索查重（必应｜example脱敏版）
// @namespace    http://tampermonkey.net/
// @version      1.5
// @description  必应PC/移动端查重，匹配规则从localStorage读取，无硬编码敏感内容；仅浏览器通知，精简日志
// @author       You
// @match        https://cn.bing.com/search*
// @match        https://www.bing.com/search*
// @grant        none
// ==/UserScript==


(function() {
    ''use strict'';
    console.log("=====example 搜索查重（必应）脚本启动=====");

    const CONFIG = {
        STORAGE_KEY: "example_check_exp"
    };

    function getExpList() {
        const raw = localStorage.getItem(CONFIG.STORAGE_KEY);
        if (!raw) return [];
        try {
            const arr = JSON.parse(raw);
            return arr.map(item =&gt; new RegExp(item, "i"));
        } catch (e) {
            return [];
        }
    }

    function normalize(str){
        return str.replace(/\s+/g,'' '').trim();
    }

    function getSearchWord() {
        const urlParams = new URLSearchParams(location.search);
        return urlParams.get(''q'') || '''';
    }

    let isRunning = false;
    let debounceTimer = null;
    const notifiedSet = new Set();

    function sendNotify(titleText, matchText){
        const msg = `标题：${titleText}\n${matchText}`;
        if("Notification" in window &amp;&amp; Notification.permission === "granted"){
            new Notification(''example 查重命中【必应】'', { body: msg });
        }
    }

    function scan(){
        if(isRunning) return;
        isRunning = true;
        try{
            const keyword = getSearchWord();
            const expList = getExpList();
            if(expList.length === 0) {
                console.log(`=====${keyword}===== 页面链接总数：0，未配置example规则`);
                return;
            }

            const cards = document.querySelectorAll(''li.b_algo'');
            console.log(`=====${keyword}===== 页面链接总数：${cards.length}`);

            cards.forEach(card=&gt;{
                let rawTitle = "";
                let linkUrl = "";
                let hitReason = null;

                const titleEl = card.querySelector(''h2 a'');
                if(!titleEl) return;
                rawTitle = titleEl.innerText.trim();
                linkUrl = titleEl.href;

                const titleNorm = normalize(rawTitle);
                for(const exp of expList){
                    if(exp.test(titleNorm)){
                        hitReason = `example 正则匹配：${exp.source}`;
                        break;
                    }
                }

                const titleKey = rawTitle;
                if(notifiedSet.has(titleKey)) return;

                if(hitReason){
                    notifiedSet.add(titleKey);
                    console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl}`);
                    sendNotify(rawTitle, hitReason);
                }
            })
        }finally{
            isRunning = false;
        }
    }

    function debounceScan(){
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(scan, 400);
    }

    function start(){
        if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){
            Notification.requestPermission();
        }
        const observer = new MutationObserver(()=&gt; debounceScan());
        observer.observe(document.body, {childList:true, subtree:true});

        window.addEventListener(''scroll'', debounceScan, {passive:true});
        scan();
        setTimeout(scan, 1200);
    }
    if(document.body) start();
    else document.addEventListener(''DOMContentLoaded'', start);
})();

</code></pre><p></p>', 'private', NULL, 'Js // ==UserScript== // @name 搜索查重（百度｜example脱敏版） // @namespace http://tampermonkey.net/ // @version 2.14 // @description 百度PC/移动端查重，匹配规则从localStorage读取，无硬编码敏感内容；仅浏览器通知，精简日志 // @author You // @match https://www.baidu.com/s* // @match https://baidu.com/s* // @match https://m.baidu.com/s* // @match https://m.baidu.com/from=*/ssid=*/s?* // @grant none // ==/UserScript== (function() { ''use strict''; console.log("=====example 搜索查重（百度）脚本启动====="); const CONFIG = { STORAGE_KEY: "example_check_exp" }; // 读取正则表达式数组 function getExpList() { const raw = localStorage.getItem(CONFIG.STORAGE_KEY); if (!raw) return []; try { const arr = JSON.parse(raw); return arr.map(item =&gt; new RegExp(item, "i")); } catch (e) { return []; } } function normalize(str){ return str.replace(/\s+/g,'' '').trim(); } function getSearchWord() { const urlParams = new URLSearchParams(location.search); return urlParams.get(''word'') || ''''; } let isRunning = false; let debounceTimer = null; const notifiedSet = new Set(); function sendNotify(titleText, matchText){ const msg = `标题：${titleText}\n${matchText}`; if("Notification" in window &amp;&amp; Notification.permission === "granted"){ new Notification(''example 查重命中'', { body: msg }); } } function scan(){ if(isRunning) return; isRunning = true; try{ const keyword = getSearchWord(); const expList = getExpList(); if(expList.length === 0) { console.log(`=====${keyword}===== 页面链接总数：0，未配置example规则`); return; } const pcCards = document.querySelectorAll(''a.normal-sub_11u5j''); const mobileCards = document.querySelectorAll(''section.cosc-card-content''); const allCards = [...pcCards, ...mobileCards]; console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`); allCards.forEach(card=&gt;{ let rawTitle = ""; let linkUrl = ""; let hitReason = null; if (card.tagName === "A") { const titleEl = card.querySelector(''h3[data-module="top_title"]''); if(!titleEl) return; rawTitle = titleEl.innerText.trim(); linkUrl = card.href; } else { const titleEl = card.querySelector(''div[data-module="title"] h3''); if(!titleEl) return; rawTitle = titleEl.innerText.trim(); const aTag = card.querySelector("a"); linkUrl = aTag?.href || ""; } const titleNorm = normalize(rawTitle); for(const exp of expList){ if(exp.test(titleNorm)){ hitReason = `example 正则匹配：${exp.source}`; break; } } const titleKey = rawTitle; if(notifiedSet.has(titleKey)) return; if(hitReason){ notifiedSet.add(titleKey); console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl}`); sendNotify(rawTitle, hitReason); } }) }finally{ isRunning = false; } } function debounceScan(){ clearTimeout(debounceTimer); debounceTimer = setTimeout(scan, 400); } function start(){ if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){ Notification.requestPermission(); } const observer = new MutationObserver(()=&gt; debounceScan()); observer.observe(document.body, {childList:true, subtree:true}); window.addEventListener(''scroll'', debounceScan, {passive:true}); scan(); setTimeout(scan, 1200); } if(document.body) start(); else document.addEventListener(''DOMContentLoaded'', start); })(); // ==UserScript== // @name 搜索查重（必应｜example脱敏版） // @namespace http://tampermonkey.net/ // @version 1.5 // @description 必应PC/移动端查重，匹配规则从localStorage读取，无硬编码敏感内容；仅浏览器通知，精简日志 // @author You // @match https://cn.bing.com/search* // @match https://www.bing.com/search* // @grant none // ==/UserScript== (function() { ''use strict''; console.log("=====example 搜索查重（必应）脚本启动====="); const CONFIG = { STORAGE_KEY: "example_check_exp" }; function getExpList() { const raw = localStorage.getItem(CONFIG.STORAGE_KEY); if (!raw) return []; try { const arr = JSON.parse(raw); return arr.map(item =&gt; new RegExp(item, "i")); } catch (e) { return []; } } function normalize(str){ return str.replace(/\s+/g,'' '').trim(); } function getSearchWord() { const urlParams = new URLSearchParams(location.search); return urlParams.get(''q'') || ''''; } let isRunning = false; let debounceTimer = null; const notifiedSet = new Set(); function sendNotify(titleText, matchText){ const msg = `标题：${titleText}\n${matchText}`; if("Notification" in window &amp;&amp; Notification.permission === "granted"){ new Notification(''example 查重命中【必应】'', { body: msg }); } } function scan(){ if(isRunning) return; isRunning = true; try{ const keyword = getSearchWord(); const expList = getExpList(); if(expList.length === 0) { console.log(`=====${keyword}===== 页面链接总数：0，未配置example规则`); return; } const cards = document.querySelectorAll(''li.b_algo''); console.log(`=====${keyword}===== 页面链接总数：${cards.length}`); cards.forEach(card=&gt;{ let rawTitle = ""; let linkUrl = ""; let hitReason = null; const titleEl = card.querySelector(''h2 a''); if(!titleEl) return; rawTitle = titleEl.innerText.trim(); linkUrl = titleEl.href; const titleNorm = normalize(rawTitle); for(const exp of expList){ if(exp.test(titleNorm)){ hitReason = `example 正则匹配：${exp.source}`; break; } } const titleKey = rawTitle; if(notifiedSet.has(titleKey)) return; if(hitReason){ notifiedSet.add(titleKey); console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl}`); sendNotify(rawTitle, hitReason); } }) }finally{ isRunning = false; } } function debounceScan(){ clearTimeout(debounceTimer); debounceTimer = setTimeout(scan, 400); } function start(){ if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){ Notification.requestPermission(); } const observer = new MutationObserver(()=&gt; debounceScan()); observer.observe(document.body, {childList:true, subtree:true}); window.addEventListener(''scroll'', debounceScan, {passive:true}); scan(); setTimeout(scan, 1200); } if(document.body) start(); else document.addEventListener(''DOMContentLoaded'', start); })();', '2026-11-02 13:39:19.608044+08'::timestamptz, '2026-11-04 13:34:18.85082+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:45:09.427339+08'::timestamptz),
  ('3d5062df-d20e-4c43-b03c-9fe56073c7ea'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'url', '<p><a target="_blank" rel="noopener noreferrer nofollow" href="https://www.cnblogs.com/zrui-xyu/p/23544084">https://www.cnblogs.com/zrui-xyu/p/23544084</a></p>', 'private', NULL, 'url https://www.cnblogs.com/zrui-xyu/p/23544084', '2026-11-04 18:38:52.452839+08'::timestamptz, '2026-11-04 18:38:52.452839+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:45:12.554114+08'::timestamptz),
  ('6f62b534-b4b4-4d3c-8970-13d8306c2b13'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'wx-image-downloader 项目知识沉淀', '<blockquote><p>一键下载微信公众号文章封面与正文图片的工具。本文只记录可复用的技术知识，不写功能介绍。</p></blockquote><h2>项目架构速览</h2><table style="min-width: 75px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th style="text-align: left;"><p>层</p></th><th style="text-align: left;"><p>技术</p></th><th style="text-align: left;"><p>说明</p></th></tr><tr><td style="text-align: left;"><p>前端</p></td><td style="text-align: left;"><p>Vue 3.5 + naive-ui + Vite 6</p></td><td style="text-align: left;"><p>单页应用，缩略图勾选式 UI</p></td></tr><tr><td style="text-align: left;"><p>后端</p></td><td style="text-align: left;"><p>Fastify 5 + cheerio + undici + jszip</p></td><td style="text-align: left;"><p>API 服务 + 图片代理 + zip 打包</p></td></tr><tr><td style="text-align: left;"><p>包管理</p></td><td style="text-align: left;"><p>pnpm 12.11.2（corepack 启用）</p></td><td style="text-align: left;"><p><code>pnpm-workspace.yaml</code> 锁定 esbuild 构建</p></td></tr><tr><td style="text-align: left;"><p>端口</p></td><td style="text-align: left;"><p>后端 3000 / dev 前端 5173</p></td><td style="text-align: left;"><p>Vite proxy 把 ​<code>/api</code> 转发到 3000</p></td></tr><tr><td style="text-align: left;"><p>启动</p></td><td style="text-align: left;"><p><code>start.bat</code>​ → ​<code>pnpm start</code></p></td><td style="text-align: left;"><p>生产模式 Fastify 同时静态托管 ​<code>dist/</code></p></td></tr></tbody></table><pre class="hljs"><code>开发:  pnpm dev   → Vite(5173) 代理 /api → Fastify(3000)
生产:  pnpm build → pnpm start → Fastify(3000) 单端口服务 API + 静态文件
</code></pre><p>API 端点：​<code>POST /api/preview</code>​（解析文章）、​<code>POST /api/download</code>​（打包 zip）、​<code>GET /api/thumb</code>​（图片代理）、​<code>POST /api/open-folder</code>。</p><hr><h2>核心知识一：微信公众号图片爬取的五个关键坑</h2><h3>1. 懒加载：真实地址在 ​<code>data-src</code>​ 而非 ​<code>src</code></h3><p>微信文章正文 ​<code>&lt;img&gt;</code>​ 的 ​<code>src</code>​ 通常是占位图或空，真实图片 URL 在 ​<code>data-src</code>​ 属性。解析时必须优先读 ​<code>data-src</code>：</p><pre class="hljs"><code class="language-js">let url = $(child).attr(''data-src'') || $(child).attr(''src'') || ''''
</code></pre><h3>2. 清理懒加载参数才能拿原图</h3><p>微信图片 URL 会带 ​<code>wxfrom</code>​、​<code>wx_lazy</code>​、​<code>wx_co</code>​、​<code>tp</code>​、​<code>wx_header</code> 等参数。这些参数会触发微信的压缩/降级逻辑，去掉后才能拿到原图：</p><pre class="hljs"><code class="language-js">const WX_LAZY_PARAMS = new Set([''wxfrom'', ''wx_lazy'', ''wx_co'', ''tp'', ''wx_header''])
function cleanWxUrl(url) {
  const u = new URL(url)
  const keep = [...u.searchParams.entries()].filter(([k]) =&gt; !WX_LAZY_PARAMS.has(k))
  u.search = new URLSearchParams(keep).toString()
  return u.toString()
}
</code></pre><h3>3. 防盗链：必须带 Referer</h3><p>微信图片服务器校验 ​<code>Referer</code>​，直接请求返回 403。Referer 必须是文章页 URL。这也是<strong>前端不能直接加载微信图片</strong>的根本原因——浏览器会带页面 origin 作为 Referer，被微信拒绝。因此需要后端做图片代理：</p><pre class="hljs"><code class="language-js">// 后端 GET /api/thumb 代理图片，注入正确的 Referer
headers: { ''User-Agent'': USER_AGENT, Referer: articleUrl, Accept: ''image/*'' }
</code></pre><p>前端缩略图 URL 构造成：​<code>/api/thumb?url=&lt;encodeURIComponent(图片URL)&gt;&amp;referer=&lt;encodeURIComponent(文章URL)&gt;</code></p><h3>4. 封面图提取优先级</h3><pre class="hljs"><code>meta[property="og:image"] → meta[name="og:image"]
→ meta[property="twitter:image"] → meta[name="twitter:image"]
→ #js_content / .rich_media_content 内第一张 img 的 data-src
</code></pre><h3>5. 微信动画轮播图（SVG 长图滑动）</h3><p>公众号里常见的"横向滑动长图/多帧轮播"不是 ​<code>&lt;img&gt;</code>​，而是一个 ​<code>&lt;svg&gt;</code>​ 包裹 ​<code>&lt;foreignObject&gt;</code>​，配合 ​<code>animateTransform</code> 做平移动画。每一帧图片藏在：</p><ul><li><p><code>foreignObject &gt; svg[data-lazy-bgimg]</code>​ 的 ​<code>data-lazy-bgimg</code></p></li><li><p>或内部 ​<code>svg[data-src]</code></p></li><li><p>或 ​<code>style="background-image: url(...)"</code> 里</p></li></ul><p>提取方式：检测 ​<code>$svg.find(''animateTransform'').length &gt; 0</code>​，然后遍历 ​<code>foreignObject</code>​，从 ​<code>data-lazy-bgimg</code>​ / ​<code>data-src</code>​ / CSS ​<code>url()</code>​ 中正则提取每帧 URL，结合 ​<code>viewBox</code> 解析宽高比。</p><h3>6. HTML 可能被 JSON 转义包裹</h3><p>部分微信文章返回的 HTML 最外层是一个 JSON 字符串（带 BOM），需要先尝试 ​<code>JSON.parse</code> 解一层再交给 cheerio：</p><pre class="hljs"><code class="language-js">function decodePossibleEscaped(html) {
  const stripped = html.replace(/^﻿\s*/, '''')  // 去 BOM
  try { const d = JSON.parse(stripped); if (typeof d === ''string'') return d } catch {}
  return html
}
</code></pre><hr><h2>核心知识二：图片格式识别的三级策略</h2><p>微信图片 URL 不一定带扩展名，需要按优先级判定保存后缀：</p><ol><li><p><strong>URL 参数</strong> ​<strong>​</strong><code>wx_fmt</code><strong>​</strong>​：微信特有参数，值如 ​<code>jpeg</code>​、​<code>png</code>​、​<code>gif</code>​、​<code>webp</code></p></li><li><p><strong>Content-Type 响应头</strong>：MIME 映射到扩展名</p></li><li><p><strong>文件头魔数（magic bytes）</strong> ：前 16 字节判定</p></li></ol><pre class="hljs"><code class="language-js">// 魔数判定
FF D8 FF                          → jpg
89 50 4E 47 (‰PNG)               → png
47 49 46 38 (GIF8)               → gif
52 49 46 46 ... 57 45 42 50     → webp (RIFF....WEBP)
</code></pre><hr><h2>核心知识三：并发下载与重试模式</h2><ul><li><p><strong>Worker pool</strong>：固定 5 个并发消费者，共享一个队列，​<code>queue.shift()</code> 逐个取任务</p></li><li><p><strong>重试退避</strong>：HTML 请求重试 3 次，间隔 ​<code>i * 2000ms</code>​；图片请求间隔 ​<code>i * 1000ms</code></p></li><li><p><strong>超时</strong>：​<code>bodyTimeout: 20000, headersTimeout: 20000</code>（undici）</p></li><li><p><strong>下载结果</strong>：直接在内存中用 JSZip 打包成 ​<code>nodebuffer</code>​，通过 ​<code>Content-Disposition: attachment</code> 返回浏览器，不落盘</p></li></ul><hr><h2>核心知识四：目录与文件名清理</h2><pre class="hljs"><code class="language-js">// Windows 非法字符替换为下划线，截断到 80 字符
name = name.replace(/[\\/:*?"&lt;&gt;|\r\n\t]/g, ''_'').trim()
name = name.replace(/\s+/g, '' '')
name = name.slice(0, 80).trim().replace(/^[ .]+|[ .]+$/, '''')
</code></pre><p>文章标题去掉开头的"原创"前缀后作为 zip 内文件夹名。图片按出现顺序三位编号：​<code>cover</code>​（封面）、​<code>001</code>​（正文图）、​<code>001_01</code>（动画帧）。</p><hr><h2>工程要点</h2><ul><li><p><strong>​</strong><code>@fastify/static</code><strong>​</strong>​ <strong>仅在非 dev 模式注册</strong>，避免 dev 时 Vite 与静态服务冲突</p></li><li><p><strong>Vite dev proxy</strong>：​<code>''/api'': ''http://localhost:3000''</code>，前端 fetch 用相对路径</p></li><li><p><strong>pnpm onlyBuiltDependencies</strong>：​<code>pnpm-workspace.yaml</code>​ 中显式允许 esbuild 构建，配合 ​<code>.npmrc</code>​ 的 ​<code>strict-dep-builds=false</code></p></li><li><p><strong>start.bat 首跑逻辑</strong>：检测 pnpm → ​<code>corepack enable</code>​ → 无 ​<code>node_modules</code>​ 则 ​<code>pnpm install --allow-build=esbuild</code>​ → ​<code>pnpm start</code></p></li><li><p><strong>CORS</strong>：​<code>@fastify/cors</code>​ 设 ​<code>origin: true</code>，本地工具无需严格限制</p></li><li><p><strong>旧版</strong> ​<strong>​</strong><code>python-legacy/</code><strong>​</strong> ​：Python + tkinter + PyInstaller 实现，用 ​<code>requests</code>​ + ​<code>beautifulsoup4</code>​ + ​<code>ttkbootstrap</code>，GitHub Actions 推 tag 自动三平台打包；已被 Node 版取代但保留参考</p></li></ul><h2>可复用清单</h2><ul data-type="taskList"><li data-checked="false" data-type="taskItem"><label><input type="checkbox"><span></span></label><div><p>微信文章 HTML 解析：cheerio + ​<code>#js_content</code> 容器</p></div></li><li data-checked="false" data-type="taskItem"><label><input type="checkbox"><span></span></label><div><p>图片代理模式：后端注入 Referer 解决防盗链 + CORS</p></div></li><li data-checked="false" data-type="taskItem"><label><input type="checkbox"><span></span></label><div><p>三级格式识别：URL 参数 → MIME → magic bytes</p></div></li><li data-checked="false" data-type="taskItem"><label><input type="checkbox"><span></span></label><div><p>SVG foreignObject 动画帧提取</p></div></li><li data-checked="false" data-type="taskItem"><label><input type="checkbox"><span></span></label><div><p>Worker pool 并发 + 指数退避重试</p></div></li><li data-checked="false" data-type="taskItem"><label><input type="checkbox"><span></span></label><div><p>JSZip 内存打包直传浏览器</p></div></li></ul><p></p>', 'private', NULL, 'wx-image-downloader 项目知识沉淀 一键下载微信公众号文章封面与正文图片的工具。本文只记录可复用的技术知识，不写功能介绍。 项目架构速览 层 技术 说明 前端 Vue 3.5 + naive-ui + Vite 6 单页应用，缩略图勾选式 UI 后端 Fastify 5 + cheerio + undici + jszip API 服务 + 图片代理 + zip 打包 包管理 pnpm 12.11.2（corepack 启用） pnpm-workspace.yaml 锁定 esbuild 构建 端口 后端 3000 / dev 前端 5173 Vite proxy 把 ​ /api 转发到 3000 启动 start.bat ​ → ​ pnpm start 生产模式 Fastify 同时静态托管 ​ dist/ 开发: pnpm dev → Vite(5173) 代理 /api → Fastify(3000) 生产: pnpm build → pnpm start → Fastify(3000) 单端口服务 API + 静态文件 API 端点：​ POST /api/preview ​（解析文章）、​ POST /api/download ​（打包 zip）、​ GET /api/thumb ​（图片代理）、​ POST /api/open-folder 。 核心知识一：微信公众号图片爬取的五个关键坑 1. 懒加载：真实地址在 ​ data-src ​ 而非 ​ src 微信文章正文 ​ &lt;img&gt; ​ 的 ​ src ​ 通常是占位图或空，真实图片 URL 在 ​ data-src ​ 属性。解析时必须优先读 ​ data-src ： let url = $(child).attr(''data-src'') || $(child).attr(''src'') || '''' 2. 清理懒加载参数才能拿原图 微信图片 URL 会带 ​ wxfrom ​、​ wx_lazy ​、​ wx_co ​、​ tp ​、​ wx_header 等参数。这些参数会触发微信的压缩/降级逻辑，去掉后才能拿到原图： const WX_LAZY_PARAMS = new Set([''wxfrom'', ''wx_lazy'', ''wx_co'', ''tp'', ''wx_header'']) function cleanWxUrl(url) { const u = new URL(url) const keep = [...u.searchParams.entries()].filter(([k]) =&gt; !WX_LAZY_PARAMS.has(k)) u.search = new URLSearchParams(keep).toString() return u.toString() } 3. 防盗链：必须带 Referer 微信图片服务器校验 ​ Referer ​，直接请求返回 403。Referer 必须是文章页 URL。这也是 前端不能直接加载微信图片 的根本原因——浏览器会带页面 origin 作为 Referer，被微信拒绝。因此需要后端做图片代理： // 后端 GET /api/thumb 代理图片，注入正确的 Referer headers: { ''User-Agent'': USER_AGENT, Referer: articleUrl, Accept: ''image/*'' } 前端缩略图 URL 构造成：​ /api/thumb?url=&lt;encodeURIComponent(图片URL)&gt;&amp;referer=&lt;encodeURIComponent(文章URL)&gt; 4. 封面图提取优先级 meta[property="og:image"] → meta[name="og:image"] → meta[property="twitter:image"] → meta[name="twitter:image"] → #js_content / .rich_media_content 内第一张 img 的 data-src 5. 微信动画轮播图（SVG 长图滑动） 公众号里常见的"横向滑动长图/多帧轮播"不是 ​ &lt;img&gt; ​，而是一个 ​ &lt;svg&gt; ​ 包裹 ​ &lt;foreignObject&gt; ​，配合 ​ animateTransform 做平移动画。每一帧图片藏在： foreignObject &gt; svg[data-lazy-bgimg] ​ 的 ​ data-lazy-bgimg 或内部 ​ svg[data-src] 或 ​ style="background-image: url(...)" 里 提取方式：检测 ​ $svg.find(''animateTransform'').length &gt; 0 ​，然后遍历 ​ foreignObject ​，从 ​ data-lazy-bgimg ​ / ​ data-src ​ / CSS ​ url() ​ 中正则提取每帧 URL，结合 ​ viewBox 解析宽高比。 6. HTML 可能被 JSON 转义包裹 部分微信文章返回的 HTML 最外层是一个 JSON 字符串（带 BOM），需要先尝试 ​ JSON.parse 解一层再交给 cheerio： function decodePossibleEscaped(html) { const stripped = html.replace(/^﻿\s*/, '''') // 去 BOM try { const d = JSON.parse(stripped); if (typeof d === ''string'') return d } catch {} return html } 核心知识二：图片格式识别的三级策略 微信图片 URL 不一定带扩展名，需要按优先级判定保存后缀： URL 参数 ​ ​ wx_fmt ​ ​：微信特有参数，值如 ​ jpeg ​、​ png ​、​ gif ​、​ webp Content-Type 响应头 ：MIME 映射到扩展名 文件头魔数（magic bytes） ：前 16 字节判定 // 魔数判定 FF D8 FF → jpg 89 50 4E 47 (‰PNG) → png 47 49 46 38 (GIF8) → gif 52 49 46 46 ... 57 45 42 50 → webp (RIFF....WEBP) 核心知识三：并发下载与重试模式 Worker pool ：固定 5 个并发消费者，共享一个队列，​ queue.shift() 逐个取任务 重试退避 ：HTML 请求重试 3 次，间隔 ​ i * 2000ms ​；图片请求间隔 ​ i * 1000ms 超时 ：​ bodyTimeout: 20000, headersTimeout: 20000 （undici） 下载结果 ：直接在内存中用 JSZip 打包成 ​ nodebuffer ​，通过 ​ Content-Disposition: attachment 返回浏览器，不落盘 核心知识四：目录与文件名清理 // Windows 非法字符替换为下划线，截断到 80 字符 name = name.replace(/[\\/:*?"&lt;&gt;|\r\n\t]/g, ''_'').trim() name = name.replace(/\s+/g, '' '') name = name.slice(0, 80).trim().replace(/^[ .]+|[ .]+$/, '''') 文章标题去掉开头的"原创"前缀后作为 zip 内文件夹名。图片按出现顺序三位编号：​ cover ​（封面）、​ 001 ​（正文图）、​ 001_01 （动画帧）。 工程要点 ​ @fastify/static ​ ​ 仅在非 dev 模式注册 ，避免 dev 时 Vite 与静态服务冲突 Vite dev proxy ：​ ''/api'': ''http://localhost:3000'' ，前端 fetch 用相对路径 pnpm onlyBuiltDependencies ：​ pnpm-workspace.yaml ​ 中显式允许 esbuild 构建，配合 ​ .npmrc ​ 的 ​ strict-dep-builds=false start.bat 首跑逻辑 ：检测 pnpm → ​ corepack enable ​ → 无 ​ node_modules ​ 则 ​ pnpm install --allow-build=esbuild ​ → ​ pnpm start CORS ：​ @fastify/cors ​ 设 ​ origin: true ，本地工具无需严格限制 旧版 ​ ​ python-legacy/ ​ ​：Python + tkinter + PyInstaller 实现，用 ​ requests ​ + ​ beautifulsoup4 ​ + ​ ttkbootstrap ，GitHub Actions 推 tag 自动三平台打包；已被 Node 版取代但保留参考 可复用清单 微信文章 HTML 解析：cheerio + ​ #js_content 容器 图片代理模式：后端注入 Referer 解决防盗链 + CORS 三级格式识别：URL 参数 → MIME → magic bytes SVG foreignObject 动画帧提取 Worker pool 并发 + 指数退避重试 JSZip 内存打包直传浏览器', '2026-10-31 11:03:56.034059+08'::timestamptz, '2026-11-04 13:21:01.589847+08'::timestamptz, '6f9b36f3-b5ee-4cd6-aeb0-1c011a524893'::uuid, 0, NULL),
  ('091ccc31-caaf-48d0-842d-a3e1b77e1951'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'gogs-diary · 部署与运行', '<h2>1. 环境要求</h2>
<ul>
<li>Python 3.12+</li>
<li>uv</li>
<li>同服务器可访问 Gogs SQLite</li>
<li>思源笔记 HTTP API 可达</li>
</ul>
<h2>2. 安装</h2>
<pre><code class="language-bash">cd /home/deploy
git clone https://git.nbook.icu/kairo/gogs-diary.git
cd gogs-diary
uv sync
cp .env.example .env
# 编辑 .env 填入配置
</code></pre>
<h2>3. 配置项</h2>
<h3>.env</h3>
<pre><code>GOGS_DB_PATH=/home/deploy/selfhost/gogs/data/gogs/data/gogs.db
GOGS_URL=http://localhost:3000
GOGS_TOKEN=
DEEPSEEK_API_KEY=
DEEPSEEK_MODEL=deepseek-flash
SIYUAN_URL=https://note.nbook.icu
SIYUAN_TOKEN=
SIYUAN_NOTEBOOK_ID=20261015151147-ivwb5le
</code></pre>
<h3>prompts.toml</h3>
<p>四个周期的提示词模板，改完直接生效，不用动代码。注意：标题由代码统一控制，DS 只输出正文。</p>
<h2>4. 运行命令</h2>
<pre><code class="language-bash"># 日记（默认模式）
uv run python -m gogs_diary.main

# 周报/月报/年报
uv run python -m gogs_diary.main weekly
uv run python -m gogs_diary.main monthly
uv run python -m gogs_diary.main yearly

# 补历史数据
uv run python -m gogs_diary.main daily --date 2026-10-18
uv run python -m gogs_diary.main weekly --date 2026-10-15
uv run python -m gogs_diary.main monthly --date 2026-10-15
uv run python -m gogs_diary.main yearly --date 2025-06-01
</code></pre>
<h2>5. cron 配置</h2>
<pre><code class="language-cron"># 每天 19:00 日记
0 19 * * * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main

# 每周一 09:00 周报
0 9 * * 1 cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main weekly

# 每月 1 号 00:30 月报
30 0 1 * * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main monthly

# 每年 1 月 1 号 01:00 年报
0 1 1 1 * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main yearly
</code></pre>
<h2>6. 日志</h2>
<p>按模式分文件，保留 90 天：</p>
<pre><code>logs/
├── daily_2026-10-19.log
├── weekly_2026-10-19.log
├── monthly_2026-10-19.log
└── yearly_2026-10-19.log
</code></pre>
<h2>7. 更新</h2>
<pre><code class="language-bash">cd /home/deploy/gogs-diary
git pull
uv sync
</code></pre>
', 'private', NULL, 'gogs-diary · 部署与运行 1. 环境要求 Python 3.12+ uv 同服务器可访问 Gogs SQLite 思源笔记 HTTP API 可达 2. 安装 cd /home/deploy git clone https://git.nbook.icu/kairo/gogs-diary.git cd gogs-diary uv sync cp .env.example .env # 编辑 .env 填入配置 3. 配置项 .env GOGS_DB_PATH=/home/deploy/selfhost/gogs/data/gogs/data/gogs.db GOGS_URL=http://localhost:3000 GOGS_TOKEN= DEEPSEEK_API_KEY= DEEPSEEK_MODEL=deepseek-flash SIYUAN_URL=https://note.nbook.icu SIYUAN_TOKEN= SIYUAN_NOTEBOOK_ID=20261015151147-ivwb5le prompts.toml 四个周期的提示词模板，改完直接生效，不用动代码。注意：标题由代码统一控制，DS 只输出正文。 4. 运行命令 # 日记（默认模式） uv run python -m gogs_diary.main # 周报/月报/年报 uv run python -m gogs_diary.main weekly uv run python -m gogs_diary.main monthly uv run python -m gogs_diary.main yearly # 补历史数据 uv run python -m gogs_diary.main daily --date 2026-10-18 uv run python -m gogs_diary.main weekly --date 2026-10-15 uv run python -m gogs_diary.main monthly --date 2026-10-15 uv run python -m gogs_diary.main yearly --date 2025-06-01 5. cron 配置 # 每天 19:00 日记 0 19 * * * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main # 每周一 09:00 周报 0 9 * * 1 cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main weekly # 每月 1 号 00:30 月报 30 0 1 * * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main monthly # 每年 1 月 1 号 01:00 年报 0 1 1 1 * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main yearly 6. 日志 按模式分文件，保留 90 天： logs/ ├── daily_2026-10-19.log ├── weekly_2026-10-19.log ├── monthly_2026-10-19.log └── yearly_2026-10-19.log 7. 更新 cd /home/deploy/gogs-diary git pull uv sync', '2026-10-31 17:43:09.967121+08'::timestamptz, '2026-10-31 17:43:29.051792+08'::timestamptz, 'a1e7e98b-f958-4d11-9727-964a23a0415e'::uuid, 0, NULL),
  ('1c7bd1df-9a26-4efd-89d4-36566e37b995'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'gogs-diary · 架构设计', '<h2>1. 设计目标</h2>
<table>
<thead>
<tr>
<th>目标</th>
<th>说明</th>
</tr>
</thead>
<tbody>
<tr>
<td>服务器端运行</td>
<td>和 Gogs 同服务器，直接读本地 SQLite，不需要公网 API</td>
</tr>
<tr>
<td>四级总结</td>
<td>日/周/月/年层层递进，每级读上一级手写内容，不循环 AI 输出</td>
</tr>
<tr>
<td>配置友好</td>
<td>密钥走 .env，提示词走 prompts.toml，改文案不动代码</td>
</tr>
<tr>
<td>可追溯</td>
<td>日志按模式分文件，保留 90 天</td>
</tr>
<tr>
<td>补数据灵活</td>
<td>支持 --date 指定日期补历史</td>
</tr>
</tbody>
</table>
<h2>2. 技术选型</h2>
<h3>2.1 AI：DeepSeek API</h3>
<ul>
<li>用 openai SDK 兼容接口，base_url 指向 DeepSeek</li>
<li>默认 deepseek-flash，成本低速度快</li>
<li>prompt 模板外置到 prompts.toml</li>
</ul>
<h3>2.2 数据源：Gogs SQLite 直读</h3>
<ul>
<li>不依赖 Gogs 公网 API，直接只读连接 gogs.db</li>
<li>查 action 表 op_type=5（push 事件）</li>
<li>Gogs action 表没有 commit_sha 列，改动文件通过 Gogs API 按时间范围查</li>
</ul>
<h3>2.3 笔记写入：思源 HTTP API</h3>
<ul>
<li>createDocWithMd 创建文档链</li>
<li>appendBlock 追加内容</li>
<li>SQL 查询定位文档（按 hpath）</li>
<li>getDoc 读取文档内容（参数是 id，不是 docID）</li>
</ul>
<h3>2.4 日志：loguru</h3>
<ul>
<li>控制台 INFO 级别</li>
<li>文件 DEBUG 级别，按模式分文件（daily_日期.log 等）</li>
<li>保留 90 天</li>
</ul>
<h2>3. 模块划分</h2>
<table>
<thead>
<tr>
<th>模块</th>
<th>文件</th>
<th>职责</th>
</tr>
</thead>
<tbody>
<tr>
<td>数据采集</td>
<td>fetch_pushes / fetch_commits_with_files</td>
<td>从 Gogs 读 push 和改动文件</td>
</tr>
<tr>
<td>AI 生成</td>
<td>generate_report</td>
<td>组装数据，调 DeepSeek</td>
</tr>
<tr>
<td>笔记操作</td>
<td>siyuan_post / ensure_doc_chain / append_to_siyuan</td>
<td>思源文档创建和追加</td>
</tr>
<tr>
<td>配置</td>
<td>.env / prompts.toml</td>
<td>密钥和提示词模板</td>
</tr>
<tr>
<td>入口</td>
<td>main()</td>
<td>argparse 解析模式，分发执行</td>
</tr>
</tbody>
</table>
<h2>4. 文档层级结构</h2>
<pre><code>daily note/
└── 2026/
    ├── 年度总结（2025）           ← 年报
    └── 10/
        ├── 月度总结（2026-10）      ← 月报
        ├── 第1周/
        │   ├── 周报（9月28日~10月4日）  ← 周报
        │   └── 2026-10-01           ← 日记
        ├── 第2周/
        └── 第4周/
            └── 2026-10-19
</code></pre>
<p>周编号规则：以周一为一周开始，每月1号所在的那周为第1周，之后每跨一个周一加一周。跨月的周按周一所在月份归档。</p>
<h2>5. 四级总结数据流向</h2>
<table>
<thead>
<tr>
<th>级别</th>
<th>时间范围</th>
<th>数据源</th>
<th>写入位置</th>
</tr>
</thead>
<tbody>
<tr>
<td>日记</td>
<td>当天</td>
<td>Gogs push + Gogs API 改动文件</td>
<td>daily note/&lt;年&gt;/&lt;月&gt;/&lt;第X周&gt;/&lt;日期&gt;</td>
</tr>
<tr>
<td>周报</td>
<td>上周一~周日</td>
<td>Gogs push + 思源手写日记</td>
<td>daily note/&lt;年&gt;/&lt;月&gt;/&lt;第X周&gt;</td>
</tr>
<tr>
<td>月报</td>
<td>上一自然月</td>
<td>Gogs push + 思源手写周报</td>
<td>daily note/&lt;年&gt;/&lt;月&gt;</td>
</tr>
<tr>
<td>年报</td>
<td>上一自然年</td>
<td>Gogs push + 思源手写月报</td>
<td>daily note/&lt;年&gt;</td>
</tr>
</tbody>
</table>
<p>关键设计：每一级读取上一级文档中&#34;自动生成&#34;标记之前的手写内容，AI 生成的内容不会被循环喂给下一级。</p>
', 'private', NULL, 'gogs-diary · 架构设计 1. 设计目标 目标 说明 服务器端运行 和 Gogs 同服务器，直接读本地 SQLite，不需要公网 API 四级总结 日/周/月/年层层递进，每级读上一级手写内容，不循环 AI 输出 配置友好 密钥走 .env，提示词走 prompts.toml，改文案不动代码 可追溯 日志按模式分文件，保留 90 天 补数据灵活 支持 --date 指定日期补历史 2. 技术选型 2.1 AI：DeepSeek API 用 openai SDK 兼容接口，base_url 指向 DeepSeek 默认 deepseek-flash，成本低速度快 prompt 模板外置到 prompts.toml 2.2 数据源：Gogs SQLite 直读 不依赖 Gogs 公网 API，直接只读连接 gogs.db 查 action 表 op_type=5（push 事件） Gogs action 表没有 commit_sha 列，改动文件通过 Gogs API 按时间范围查 2.3 笔记写入：思源 HTTP API createDocWithMd 创建文档链 appendBlock 追加内容 SQL 查询定位文档（按 hpath） getDoc 读取文档内容（参数是 id，不是 docID） 2.4 日志：loguru 控制台 INFO 级别 文件 DEBUG 级别，按模式分文件（daily_日期.log 等） 保留 90 天 3. 模块划分 模块 文件 职责 数据采集 fetch_pushes / fetch_commits_with_files 从 Gogs 读 push 和改动文件 AI 生成 generate_report 组装数据，调 DeepSeek 笔记操作 siyuan_post / ensure_doc_chain / append_to_siyuan 思源文档创建和追加 配置 .env / prompts.toml 密钥和提示词模板 入口 main() argparse 解析模式，分发执行 4. 文档层级结构 daily note/ └── 2026/ ├── 年度总结（2025） ← 年报 └── 10/ ├── 月度总结（2026-10） ← 月报 ├── 第1周/ │ ├── 周报（9月28日~10月4日） ← 周报 │ └── 2026-10-01 ← 日记 ├── 第2周/ └── 第4周/ └── 2026-10-19 周编号规则：以周一为一周开始，每月1号所在的那周为第1周，之后每跨一个周一加一周。跨月的周按周一所在月份归档。 5. 四级总结数据流向 级别 时间范围 数据源 写入位置 日记 当天 Gogs push + Gogs API 改动文件 daily note/&lt;年&gt;/&lt;月&gt;/&lt;第X周&gt;/&lt;日期&gt; 周报 上周一~周日 Gogs push + 思源手写日记 daily note/&lt;年&gt;/&lt;月&gt;/&lt;第X周&gt; 月报 上一自然月 Gogs push + 思源手写周报 daily note/&lt;年&gt;/&lt;月&gt; 年报 上一自然年 Gogs push + 思源手写月报 daily note/&lt;年&gt; 关键设计：每一级读取上一级文档中&#34;自动生成&#34;标记之前的手写内容，AI 生成的内容不会被循环喂给下一级。', '2026-10-31 17:43:08.917215+08'::timestamptz, '2026-10-31 17:43:08.917215+08'::timestamptz, 'a1e7e98b-f958-4d11-9727-964a23a0415e'::uuid, 0, NULL),
  ('dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'CVE-2026-123158 漏洞学习笔记（OpenSSH + musl libc 密码绕过）', '<blockquote><p><strong>📌 基础信息概览</strong><br>漏洞代号：sshole｜披露时间：2026-11-05｜补丁版本：OpenSSH ≥ 10.6p2</p></blockquote><h2>触发条件（全部满足才可利用）</h2><ol><li><p>OpenSSH 版本 &lt; 10.6p2（未合并补丁）</p></li><li><p>系统 libc 为 musl（Alpine、OpenWrt 默认；glibc 不受影响）</p></li><li><p><code>sshd_config</code> 开启 <code>UsePAM no</code>，走传统 crypt 认证路径</p></li><li><p>目标用户在 <code>/etc/shadow</code> 的密码字段为 <code>*</code>，账号锁定、禁止密码登录</p></li><li><p>系统内至少存在一个正常用户，拥有合法 sha512 哈希，为 crypt 提供 salt</p></li></ol><h2>漏洞原理</h2><p>这是一个<strong>跨组件语义冲突漏洞</strong>，不是代码崩溃，也不是哈希算法被破解。</p><ul><li><p>Unix 标准函数 <code>crypt()</code>，规范约定：计算失败时应当返回 <code>NULL</code></p></li><li><p>musl 的实现取舍：密码长度 ≥ 257 字节时超限，不返回 NULL，返回静态字符串 <code>*</code><br>musl 设计者本意：<code>*</code> 是密码生态公认的「哈希计算失败标记」，避免上层无判空代码直接空指针崩溃。</p></li><li><p>shadow 体系约定：<code>*</code> / <code>!</code> 代表<strong>账号锁定，禁止密码登录</strong>，两套语义撞在了同一个字符串上。</p></li><li><p>旧 OpenSSH 校验逻辑：拿到 crypt 返回值，只判断不为 NULL，直接做字符串相等对比。</p></li></ul><blockquote><p>攻击链路：传入257字节超长密码 → musl crypt 返回 <code>*</code> → 和 shadow 里锁定标记 <code>*</code> 字符串相等 → 认证放行，绕过锁定限制。</p></blockquote><h2>三段核心C代码对比</h2><h3>1. 存在漏洞的原始校验逻辑</h3><pre class="hljs"><code>char *computed = crypt(password, stored_hash);
if (computed &amp;&amp; strcmp(computed, stored_hash) == 0) {
    return 1; // 校验通过，放行
}
</code></pre><p>缺陷：没有提前判断账号锁定标记，不区分 crypt 返回值是正常哈希，还是错误标记。</p><h3>2. musl crypt 超长密码分支（简化）</h3><pre class="hljs"><code>if (keylen &gt; 256) {
    strcpy(result, "*");
    return result;
}
</code></pre><h3>3. OpenSSH 官方补丁逻辑（修复方案）</h3><pre class="hljs"><code>// 调用crypt之前，优先判断账号锁定语义
if (stored_hash[0] == ''*'' || stored_hash[0] == ''!'') {
    return 0; // 直接拒绝，不再执行密码哈希计算
}
// 再往下才调用 crypt 做比对
</code></pre><p><strong>💡 重点区分：</strong> 不是限制密码长度（只针对musl的hack方案），而是<strong>遵循shadow语义，锁定账号直接拦截</strong>，通用、可移植，不受libc差异影响。</p><h2>本次复现失败原因</h2><p>Alpine官方源已经升级 OpenSSH 至带补丁的版本，读到 <code>*</code> 锁定标记就直接打印日志：</p><p><code>User testuser not allowed because account is locked</code></p><p>直接跳出，根本不会进入 crypt 函数调用，漏洞无法触发。</p><h2>Python逻辑模拟代码（仅演示原理，非可利用EXP）</h2><pre class="hljs"><code>def musl_crypt_sim(password: str, salt: str):
    if len(password) &gt;= 257:
        # musl超长密码的异常行为：返回 *
        return "*"
    import hashlib
    return hashlib.sha512((password + salt).encode()).hexdigest()

shadow = {
    "testuser": "*",
    "normaluser": "$6$rounds=5000$abc123$FAKEHASH"
}
real_hash = shadow["normaluser"]
salt = real_hash.split("$")[2]

print("=== 短密码 aaaa ===")
ret1 = musl_crypt_sim("aaaa", salt)
print(f"crypt返回：{ret1}")
print(f"比对结果：{''放行'' if ret1 == shadow[''testuser''] else ''拒绝''}")

print("\n=== payload：257个A ===")
ret2 = musl_crypt_sim("A"*257, salt)
print(f"比对结果：{''放行'' if ret2 == shadow[''testuser''] else ''拒绝''}")
</code></pre><h2>开发学习收获 &amp; 教训</h2><ul><li><p>第三方库、系统调用返回值<strong>不可无条件信任</strong>，文档契约和不同平台实现经常不一致。</p></li><li><p>异常分支是高危点：报错时有可能返回一个具备业务含义的字符串，而不是NULL。</p></li><li><p>单纯字符串相等是非常弱的校验，优先校验<strong>数据语义、状态</strong>，而不是只比对内容。</p></li><li><p>跨组件边界是漏洞高发区：单独看每个组件逻辑都合理，但隐性行为组合之后产生绕过。</p></li><li><p>修复优先选择语义层拦截，尽量避免写死平台私有阈值的临时hack。</p></li></ul><h2>官方参考链接</h2><ul><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="http://CVE.org">CVE.org</a><a target="_blank" rel="noopener noreferrer nofollow" href="https://cve.org/CVERecord?id=CVE-2026-123158"> 官方记录</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://nvd.nist.gov/vuln/detail/cve-2026-123158">NVD 漏洞详情</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://www.openssh.com/releasenotes.html#10.6p2">OpenSSH Release Notes 10.6p2</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://sshhole.com/">sshhole 漏洞专题页</a></p></li></ul><p></p>', 'private', NULL, 'CVE-2026-123158 漏洞学习笔记（OpenSSH + musl libc 密码绕过） 📌 基础信息概览 漏洞代号：sshole｜披露时间：2026-11-05｜补丁版本：OpenSSH ≥ 10.6p2 触发条件（全部满足才可利用） OpenSSH 版本 &lt; 10.6p2（未合并补丁） 系统 libc 为 musl（Alpine、OpenWrt 默认；glibc 不受影响） sshd_config 开启 UsePAM no ，走传统 crypt 认证路径 目标用户在 /etc/shadow 的密码字段为 * ，账号锁定、禁止密码登录 系统内至少存在一个正常用户，拥有合法 sha512 哈希，为 crypt 提供 salt 漏洞原理 这是一个 跨组件语义冲突漏洞 ，不是代码崩溃，也不是哈希算法被破解。 Unix 标准函数 crypt() ，规范约定：计算失败时应当返回 NULL musl 的实现取舍：密码长度 ≥ 257 字节时超限，不返回 NULL，返回静态字符串 * musl 设计者本意： * 是密码生态公认的「哈希计算失败标记」，避免上层无判空代码直接空指针崩溃。 shadow 体系约定： * / ! 代表 账号锁定，禁止密码登录 ，两套语义撞在了同一个字符串上。 旧 OpenSSH 校验逻辑：拿到 crypt 返回值，只判断不为 NULL，直接做字符串相等对比。 攻击链路：传入257字节超长密码 → musl crypt 返回 * → 和 shadow 里锁定标记 * 字符串相等 → 认证放行，绕过锁定限制。 三段核心C代码对比 1. 存在漏洞的原始校验逻辑 char *computed = crypt(password, stored_hash); if (computed &amp;&amp; strcmp(computed, stored_hash) == 0) { return 1; // 校验通过，放行 } 缺陷：没有提前判断账号锁定标记，不区分 crypt 返回值是正常哈希，还是错误标记。 2. musl crypt 超长密码分支（简化） if (keylen &gt; 256) { strcpy(result, "*"); return result; } 3. OpenSSH 官方补丁逻辑（修复方案） // 调用crypt之前，优先判断账号锁定语义 if (stored_hash[0] == ''*'' || stored_hash[0] == ''!'') { return 0; // 直接拒绝，不再执行密码哈希计算 } // 再往下才调用 crypt 做比对 💡 重点区分： 不是限制密码长度（只针对musl的hack方案），而是 遵循shadow语义，锁定账号直接拦截 ，通用、可移植，不受libc差异影响。 本次复现失败原因 Alpine官方源已经升级 OpenSSH 至带补丁的版本，读到 * 锁定标记就直接打印日志： User testuser not allowed because account is locked 直接跳出，根本不会进入 crypt 函数调用，漏洞无法触发。 Python逻辑模拟代码（仅演示原理，非可利用EXP） def musl_crypt_sim(password: str, salt: str): if len(password) &gt;= 257: # musl超长密码的异常行为：返回 * return "*" import hashlib return hashlib.sha512((password + salt).encode()).hexdigest() shadow = { "testuser": "*", "normaluser": "$6$rounds=5000$abc123$FAKEHASH" } real_hash = shadow["normaluser"] salt = real_hash.split("$")[2] print("=== 短密码 aaaa ===") ret1 = musl_crypt_sim("aaaa", salt) print(f"crypt返回：{ret1}") print(f"比对结果：{''放行'' if ret1 == shadow[''testuser''] else ''拒绝''}") print("\n=== payload：257个A ===") ret2 = musl_crypt_sim("A"*257, salt) print(f"比对结果：{''放行'' if ret2 == shadow[''testuser''] else ''拒绝''}") 开发学习收获 &amp; 教训 第三方库、系统调用返回值 不可无条件信任 ，文档契约和不同平台实现经常不一致。 异常分支是高危点：报错时有可能返回一个具备业务含义的字符串，而不是NULL。 单纯字符串相等是非常弱的校验，优先校验 数据语义、状态 ，而不是只比对内容。 跨组件边界是漏洞高发区：单独看每个组件逻辑都合理，但隐性行为组合之后产生绕过。 修复优先选择语义层拦截，尽量避免写死平台私有阈值的临时hack。 官方参考链接 CVE.org 官方记录 NVD 漏洞详情 OpenSSH Release Notes 10.6p2 sshhole 漏洞专题页', '2026-11-06 14:55:40.639897+08'::timestamptz, '2026-11-06 15:18:02.074718+08'::timestamptz, '1298a12a-a471-41df-aa57-e3f2ef56e992'::uuid, 0, NULL),
  ('df15267d-3eb5-4da6-b161-fe38e1bbf7a4'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'archlinux 简明指南', '<blockquote><h3>⛵ 万事俱备，只欠东风 <a target="_blank" rel="noopener noreferrer nofollow" href="#⛵-万事俱备-只欠东风">​</a></h3><p>经过了上一节的准备工作，我们可以开始正式安装 archlinux 了。如果你还没有完成前面的阅读，请先仔细阅读章节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-install.html">安装前的准备</a>。如果对本节的步骤不理解或者有疑问，请阅读下一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a></p></blockquote><p>本节从安装最基础的、无图形化界面的 archlinux 系统开始。如有需要可以参阅 <a target="_blank" rel="noreferrer" href="https://wiki.archlinux.org/title/Installation_guide_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)">ArchWiki 官方安装指南</a>。</p><p>ℹ️ 提示</p><p>本节中的截图来自虚拟机和已经安装好的 archlinux。不用担心！和你在实体机看到的是一样的。</p><p>⚠️ 注意</p><p>请按照指南的步骤一步一步进行！不要跳步、也不要在步骤中添加多余的动作！</p><p>另外，如果安装中有报错，请弄清楚报错的原因（这要求你起码能看懂有报错）！常见的原因包括但不限于输错了命令、添加了多余的步骤等。在解决了问题之后再进行下一步！</p><h2>0. 进入安装环境 <a target="_blank" rel="noopener noreferrer nofollow" href="#_0-进入安装环境">​</a></h2><p></p><img src="https://arch.icekylin.online/assets/pre-virt_vb-14.pyALUo_J.png" alt="archlinux-iso-1"><ol><li><p>在第一个选项回车</p></li></ol><p></p><img src="https://arch.icekylin.online/assets/pre-virt_vb-15.CqUq5u2n.png" alt="archlinux-iso-2"><ol start="2"><li><p>进入安装环境后，便可以开始通过命令安装 archlinux 了</p></li></ol><p>ℹ️ 提示</p><ul><li><p>在2025年后，用于自动更新 <code>mirrorlist</code>（软件包管理器 <code>pacman</code> 的软件源）的 <code>reflector</code> 服务由于会误删某些有用的源信息已被默认禁用，无需再手动禁用。</p></li></ul><p>ℹ️ 提示</p><ul><li><p>在命令行中你可以使用如下命令清屏：</p><p>zsh</p><pre class="hljs"><code>clear</code></pre><p>同时，你可以使用 <code>Tab</code> 键在输入命令的时候对命令、参数或文件路径进行自动补全，提高效率的同时降低输入错误的风险。</p></li><li><p><code>Tab</code> 无法补全时，有些设备的蜂鸣器会发出“哔——”声，可以使用如下命令禁用蜂鸣器内核模块：</p><p>zsh</p><pre class="hljs"><code>rmmod pcspkr</code></pre></li><li><p>要永久禁用蜂鸣器内核模块, 请创建并编辑 <code>/etc/modprobe.d/blacklist.conf</code></p><p>zsh</p><pre class="hljs"><code>sudoedit /etc/modprobe.d/blacklist.conf</code></pre><p>加入以下内容</p><pre class="hljs"><code>blacklist pcspkr</code></pre><p>这样下次启动就不会加载 pcspkr 模块了</p></li></ul><h2>1. 确认是否为 UEFI 模式 <a target="_blank" rel="noopener noreferrer nofollow" href="#_1-确认是否为-uefi-模式">​</a></h2><p>我们先来确认一下是否为 <code>UEFI</code> 模式：</p><p>zsh</p><pre class="hljs"><code>ls /sys/firmware/efi/efivars</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_check-efi.Cst0GaUE.png" alt="check-efi"><p>若输出了一堆东西（<code>efi</code> 变量），则说明已在 <code>UEFI</code> 模式。否则请确认你的启动方式是否为 <code>UEFI</code>。</p><h2>2. 连接网络 <a target="_blank" rel="noopener noreferrer nofollow" href="#_2-连接网络">​</a></h2><p>ℹ️ 提示</p><p>archlinux 的安装<strong>必须</strong>要求网络环境。</p><p>ℹ️ 提示</p><p>若为虚拟机且按照上一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-virt.html#_3-%E9%85%8D%E7%BD%AE-virtualbox">虚拟机安装前的准备</a> 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。</p><h3>若使用<strong>无线连接</strong> <a target="_blank" rel="noopener noreferrer nofollow" href="#若使用无线连接">​</a></h3><p>使用 <code>iwctl</code> 进行连接：</p><p>zsh</p><pre class="hljs"><code>iwctl # 进入交互式命令行device list # 列出无线网卡设备名，比如无线网卡看到叫 wlan0station wlan0 scan # 扫描网络station wlan0 get-networks # 列出所有 wifi 网络station wlan0 connect wifi-name # 进行连接，注意这里无法输入中文。回车后输入密码即可exit # 连接成功后退出</code></pre><p>ℹ️ 提示</p><p>若无线网卡无法显示，请按照上一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-install.html#_1-%E7%A1%AE%E4%BF%9D%E7%BD%91%E7%BB%9C%E7%8E%AF%E5%A2%83">确保网络环境</a> 的说明<strong>确保你的无线网卡硬件开关处于打开状态</strong>。</p><p>你可以使用如下命令查看内核是否加载了你的无线网卡驱动。</p><p>zsh</p><pre class="hljs"><code>lspci -k | grep Network</code></pre><p>以我的硬件为例，输出如下：</p><p>zsh</p><pre class="hljs"><code>00:14.3 Network controller: Intel Corporation Wi-Fi 6 AX201 (rev 20)</code></pre><p>如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 <code>WIFI</code></p><p>zsh</p><pre class="hljs"><code>rfkill list #查看无线连接 是否被禁用(blocked: yes)ip link set wlan0 up #比如无线网卡看到叫 wlan0</code></pre><p>若看到类似<code>Operation not possible due to RF-kill</code>的报错，继续尝试<code>rfkill unblock wifi</code>来解锁无线网卡。</p><p>zsh</p><pre class="hljs"><code>rfkill unblock wifi</code></pre><p>部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。</p><h3>若使用<strong>有线连接</strong> <a target="_blank" rel="noopener noreferrer nofollow" href="#若使用有线连接">​</a></h3><p>正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。</p><p>可以等待几秒等网络建立连接后再进行下一步测试网络的操作。</p><p>若笔记本没有网线接口请使用带网线接口的扩展坞。</p><h2>3. 测试网络连通性 <a target="_blank" rel="noopener noreferrer nofollow" href="#_3-测试网络连通性">​</a></h2><p>通过 <code>ping</code> 命令测试网络连通性：</p><p>zsh</p><pre class="hljs"><code>ping www.bilibili.com</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_ping.BDHpp9ke.png" alt="ping"><p>稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 <code>Ctrl</code> + <code>C</code> 手动退出 <code>ping</code> 命令。</p><p>ℹ️ 提示</p><p>如果无线网络还是无法连接，请使用 <code>ip link</code> 命令查看无线网卡设备，使用 <code>ip link set &lt;设备名&gt; up</code> 命令激活对应的无线网卡。若看到类似 <code>Operation not possible due to RF-kill</code> 的报错，继续尝试 <code>rfkill unblock wifi</code> 来解锁无线网卡。</p><p>如有需要，可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinux.org/title/Network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Wireless_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E6%A3%80%E6%9F%A5%E8%AE%BE%E5%A4%87%E7%8A%B6%E6%80%81">ArchWiki 相关内容</a>。</p><h2>4. 更新系统时钟 <a target="_blank" rel="noopener noreferrer nofollow" href="#_4-更新系统时钟">​</a></h2><p>使用 <code>timedatectl</code> 确保系统时间是准确的。这一步<strong>不是</strong>可选的，正确的系统时间对于部分程序来说非常重要：</p><p>zsh</p><pre class="hljs"><code>timedatectl set-ntp true # 将系统时间与网络时间进行同步timedatectl status # 检查服务状态</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_time.Dmuxtefc.png" alt="time"><h2>5. 更换国内软件仓库镜像源加快下载速度 <a target="_blank" rel="noopener noreferrer nofollow" href="#_5-更换国内软件仓库镜像源加快下载速度">​</a></h2><p>使用 <code>vim</code> 编辑器修改 <code>/etc/pacman.d/mirrorlist</code> 文件。将 <code>pacman</code> 软件仓库源更换为国内软件仓库镜像源：</p><p>zsh</p><pre class="hljs"><code>vim /etc/pacman.d/mirrorlist</code></pre><p>ℹ️ 提示</p><p>如果不会使用 <code>vim</code> 编辑器，请参阅 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/advanced/system-ctl.html#%E7%BB%88%E7%AB%AF%E7%BC%96%E8%BE%91%E5%99%A8-vim-%E7%9A%84%E4%BD%BF%E7%94%A8">这里</a>。</p><p><code>vim</code> 编辑器在安装和配置系统的过程中还需要使用多次。</p><p>放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下：</p><p>mirrorlist</p><pre class="hljs"><code>Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mirrorlist-1.DS2ha-4u.png" alt="mirrorlist-1"><p>修改完成的 <code>/etc/pacman.d/mirrorlist</code> 文件如图所示。</p><p>ℹ️ 提示</p><p>如果发现 <code>/etc/pacman.d/mirrorlist</code> 是如图这个样子的，那么说明你禁用 <code>reflector</code> 服务晚了。<code>reflector</code> 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。</p><p></p><img src="https://arch.icekylin.online/assets/basic-install_mirrorlist-2.CITp5j1o.png" alt="mirrorlist-2"><p>⚠️ 注意</p><p>前车之鉴 —— 请不在这一步中添加 <code>archlinuxcn</code> 源！如果你在 <code>/etc/pacman.conf</code> 中添加了内容，请将它们删掉。</p><h2>6. 分区和格式化（使用 Btrfs 文件系统） <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-分区和格式化-使用-btrfs-文件系统">​</a></h2><h3>6-1. 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-1-分区">​</a></h3><p>☢️ 警告</p><p>分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！</p><p>同时，请提前做好数据备份，防止数据丢失！</p><p>本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。</p><ul><li><p><code>/</code> 根目录：<code>&gt;= 128GB</code>（和用户主目录在同一个 <code>Btrfs</code> 文件系统上）</p></li><li><p><code>/home</code> 用户主目录：<code>&gt;= 128GB</code>（和根目录在同一个 <code>Btrfs</code> 文件系统上）</p></li><li><p><code>/boot</code> EFI 分区：<code>256MB</code>（由电脑厂商或 Windows 决定，无需再次创建）</p></li><li><p>Swap 分区：<code>&gt;= 电脑实际运行内存的 60%</code>（设置这个大小是为了配置休眠准备）</p></li></ul><p>ℹ️ 提示</p><p>因为采用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。</p><ol><li><p>通过 <code>lsblk</code> 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>lsblk # 显示当前分区情况</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-1.Bh1Xqg5R.png" alt="partition-1"><p>此处要分区和安装 archlinux 的磁盘即为 <code>sda</code>。请根据你的实际情况判断！</p><p>ℹ️ 提示</p><p>为了模拟真实的环境，笔者手动创建了三个分区分别代表：</p><ol><li><p><code>sda1</code> —— EFI 分区</p></li><li><p><code>sda2</code> —— win10 下的 C 盘（象征性的分了 <code>1GB</code>）</p></li><li><p><code>sda3</code> —— win10 下的 D 盘（象征性的分了 <code>1GB</code>）</p></li></ol><p>ℹ️ 提示</p><p>注意此处并不会显出出未分配的磁盘空间！只有在使用 <code>cfdisk</code> 执行分区操作后才会显示出来。</p><p>ℹ️ 提示</p><p>如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 <code>sdx</code> 而是 <code>nvmexn1</code>。</p><ol start="2"><li><p>接下来使用 <code>cfdisk</code> 命令对磁盘分区（对于 SATA 协议的硬盘，<code>x</code> 为字母 <code>a</code>、<code>b</code> 或 <code>c</code> 等等；对于 NVME 协议的硬盘，<code>x</code> 为数字 <code>0</code>、<code>1</code> 或 <code>2</code> 等等，请根据实际情况判断）：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>cfdisk /dev/sdx # 对安装 archlinux 的磁盘分区</code></pre><p>zsh</p><pre class="hljs"><code>cfdisk /dev/nvmexn1 # 对安装 archlinux 的磁盘分区</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-2.DLT4hhE7.png" alt="partition-2"><p>进入 <code>cfdisk</code> 分区工具之后，你会看到如图所示的界面。通过方向键 <code>↑</code> 和 <code>↓</code> 可以在要操作磁盘分区或空余空间中移动；通过方向键 <code>←</code> 和 <code>→</code> 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。</p><ol start="3"><li><p>首先创建 Swap 分区。选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建 <code>swap</code> 分区（类似 Windows 的交换文件）</p></li></ol><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-3.BjLUGd3s.png" alt="partition-3"><ol start="4"><li><p>按下回车后会提示输入 <code>分区大小</code>，Swap 分区建议为<strong>电脑内存大小的 60%</strong>，或者和内存大小相等 &gt; 然后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-4.Dqv4NCG5.png" alt="partition-4"><p>ℹ️ 提示</p><p>单位可以自行输入，如 <code>GB</code>、<code>MB</code> 等等。</p><ol start="5"><li><p>默认新建的类型是 <code>Linux filesystem</code>，我们需要将类型更改为 <code>Linux swap</code>。选中操作 <code>[Type]</code> &gt; 然后按下回车 <code>Enter</code> &gt; 通过方向键 <code>↑</code> 和 <code>↓</code> 选中 <code>Linux swap</code> &gt; 最后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-5.Dyfk--lB.png" alt="partition-5"><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-6.B8rtj9qg.png" alt="partition-6"><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-7._YVoQizt.png" alt="partition-7"><ol start="6"><li><p>我们再只需要一个分区即可（因为使用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建分区</p></li></ol><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-8.B5Mxus1B.png" alt="partition-8"><ol start="7"><li><p>输入 <code>分区大小</code>（默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-9.CHsqU1Wz.png" alt="partition-9"><ol start="8"><li><p>分区类型默认即可，无需更改。接下来选中操作 <code>[Write]</code> 并回车 <code>Enter</code> &gt; 输入 <code>yes</code> 并回车 <code>Enter</code> 确认分区操作</p></li></ol><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-10.B4WDaAwE.png" alt="partition-10"><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-11.BbqbEG9-.png" alt="partition-11"><p>⚠️ 注意</p><p>只有写入了操作分区表才会更改。</p><ol start="9"><li><p>选中操作 <code>[Quit]</code> 并回车 <code>Enter</code> 以退出 <code>cfdisk</code> 分区工具</p></li></ol><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-12.CDCzeWEA.png" alt="partition-12"><p>☢️ 警告</p><p>再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！</p><p>常见的错误包括不小心把 Windows 的分区删掉了 😥。</p><ol start="10"><li><p>分区完成后，使用 <code>fdisk</code> 或 <code>lsblk</code> 命令复查分区情况：</p></li></ol><p>fdisklsblk</p><p>zsh</p><pre class="hljs"><code>fdisk -l # 复查磁盘情况</code></pre><p>zsh</p><pre class="hljs"><code>lsblk # 复查磁盘情况</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-13.BZSCCyuz.png" alt="partition-13"><p></p><img src="https://arch.icekylin.online/assets/basic-install_partition-14.BzdDh6PY.png" alt="partition-14"><h3>6-2. 格式化并创建 Btrfs 子卷 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-格式化并创建-btrfs-子卷">​</a></h3><h4>6-2.0. 格式化 EFI 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-0-格式化-efi-分区">​</a></h4><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkfs.fat -F32 /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkfs.fat -F32 /dev/nvmexn1pn</code></pre><p>⚠️ 注意</p><p>如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。</p><h4>6-2-1. 格式化 Swap 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-1-格式化-swap-分区">​</a></h4><p>通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 <code>x</code> 和 <code>n</code>（下同）：</p><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkswap /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkswap /dev/nvmexn1pn</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mkswap.CzM8dA_8.png" alt="mkswap"><h4>6-2-2. 格式化 Btrfs 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-2-格式化-btrfs-分区">​</a></h4><ol><li><p>首先我们需要将整一个分区格式化为 <code>Btrfs</code> 文件系统。使用如下命令进行格式化：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkfs.btrfs -L myArch /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkfs.btrfs -L myArch /dev/nvmexn1pn</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-L</code> 选项后指定该分区的 <code>LABLE</code>，这里以 <code>myArch</code> 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义</p></li></ul></blockquote><p></p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-1.CpWxbwoC.png" alt="mkbtrfs_step-1"><ol start="2"><li><p>为了创建子卷，我们需要先将 <code>Btrfs</code> 分区挂载到 <code>/mnt</code> 下：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o compress=zstd /dev/sdxn /mnt</code></pre><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o compress=zstd /dev/nvmexn1pn /mnt</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-t</code> 选项后指定挂载分区文件系统类型</p></li><li><p><code>-o</code> 选项后添加挂载参数：</p><ul><li><p><code>compress=zstd</code> —— 开启透明压缩</p></li></ul></li></ul></blockquote><ol start="3"><li><p>使用 <code>df</code> 命令复查挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>df -h # -h 选项会使输出以人类可读的单位显示</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-2.CNm0O5gq.png" alt="mkbtrfs_step-2"><h4>6-2-3. 创建 Btrfs 子卷 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-3-创建-btrfs-子卷">​</a></h4><ol><li><p>通过以下命令创建两个 <code>Btrfs</code> 子卷，之后将分别挂载到 <code>/</code> 根目录和 <code>/home</code> 用户主目录：</p></li></ol><p>zsh</p><pre class="hljs"><code>btrfs subvolume create /mnt/@ # 创建 / 目录子卷btrfs subvolume create /mnt/@home # 创建 /home 目录子卷</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-3.DnVJ6tP6.png" alt="mkbtrfs_step-3"><p>⚠️ 注意</p><p>除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 <code>timeshift</code> 只支持这种子卷布局。</p><ol start="2"><li><p>通过以下命令复查子卷情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>btrfs subvolume list -p /mnt</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-4.Q0fek3jd.png" alt="mkbtrfs_step-4"><ol start="3"><li><p>子卷创建好后，我们需要将 <code>/mnt</code> 卸载掉，以挂载子卷：</p></li></ol><p>zsh</p><pre class="hljs"><code>umount /mnt</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-5.EEnZGPJv.png" alt="mkbtrfs_step-5"><h2>7. 挂载 <a target="_blank" rel="noopener noreferrer nofollow" href="#_7-挂载">​</a></h2><ol><li><p>在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o subvol=/@,compress=zstd /dev/sdxn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/sdxn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/sdxn /mnt/boot # 挂载 /boot 目录swapon /dev/sdxn # 挂载交换分区</code></pre><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o subvol=/@,compress=zstd /dev/nvmexn1pn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/nvmexn1pn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/nvmexn1pn /mnt/boot # 挂载 /boot 目录swapon /dev/nvmexn1pn # 挂载交换分区</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mount-1.DSGPGhwn.png" alt="mount_step-1"><p></p><img src="https://arch.icekylin.online/assets/basic-install_mount-2.C_eaivrb.png" alt="mount_step-2"><ol start="2"><li><p>使用 <code>df</code> 命令复查挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>df -h</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mount-3.9HC0QeP4.png" alt="mount_step-3"><ol start="3"><li><p>使用 <code>free</code> 命令复查 Swap 分区挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>free -h # -h 选项会使输出以人类可读的单位显示</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_mount-4.BOyAfSXA.png" alt="mount_step-4"><h2>8. 安装系统 <a target="_blank" rel="noopener noreferrer nofollow" href="#_8-安装系统">​</a></h2><ol><li><p>通过如下命令使用 <code>pacstrap</code> 脚本安装基础包：</p></li></ol><p>bash</p><pre class="hljs"><code>pacstrap /mnt base base-devel linux linux-firmware btrfs-progs# 如果使用btrfs文件系统，额外安装一个btrfs-progs包</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>base-devel</code> —— <code>base-devel</code> 在 <code>AUR</code> 包的安装过程中是必须用到的</p></li><li><p><code>linux</code> —— 内核软件包，这里建议先不要替换为其它内核</p></li></ul></blockquote><p></p><img src="https://arch.icekylin.online/assets/basic-install_pacstrap-1.Q3dLs9X-.png" alt="pacstrap_step-1"><p>如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 <code>archlinux-keyring</code> 解决此问题</p><p>bash</p><pre class="hljs"><code>pacman -S archlinux-keyring</code></pre><ol start="2"><li><p>通过如下命令使用 <code>pacstrap</code> 脚本安装其它必要的功能性软件：</p></li></ol><p>bash</p><pre class="hljs"><code>pacstrap /mnt networkmanager vim sudo zsh zsh-completions</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>zsh</code> —— <code>zsh-completions</code> 如果你是 bash 的爱好者，请把这两个包换成<code>bash-completion</code></p></li><li><p>如果你是第一次接触*nix 系统的新手，不建议换成 bash</p></li></ul></blockquote><p></p><img src="https://arch.icekylin.online/assets/basic-install_pacstrap-2.6jDXL0pu.png" alt="pacstrap_step-2"><p>经过一系列安装时提示信息的刷屏，这些包就安装好了。</p><p>⚠️ 注意</p><p>在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。</p><p>很多人在后续的步骤中报错就是因为这里漏装了东西。</p><p>如果报错，请<strong>检查拼写</strong>，同时请确保之前的步骤 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-更换国内软件仓库镜像源加快下载速度">更换国内软件仓库镜像源加快下载速度</a> 中<strong>没有</strong>添加 <code>archlinuxcn</code> 源。</p><h2>9. 生成 fstab 文件 <a target="_blank" rel="noopener noreferrer nofollow" href="#_9-生成-fstab-文件">​</a></h2><ol><li><p><code>fstab</code> 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 <code>genfstab</code> 自动根据当前挂载情况生成并写入 <code>fstab</code> 文件：</p></li></ol><p>zsh</p><pre class="hljs"><code>genfstab -U /mnt &gt; /mnt/etc/fstab</code></pre><ol start="2"><li><p>复查一下 <code>/mnt/etc/fstab</code> 确保没有错误：</p></li></ol><p>zsh</p><pre class="hljs"><code>cat /mnt/etc/fstab</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_fstab.CtqAJn7q.png" alt="fstab"><p>若为 NVME 协议的硬盘，输出结果应该与此类似：</p><p>fstab</p><pre class="hljs"><code># /dev/nvme0n1p6  /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@  0 0# /dev/nvme0n1p1  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro      0 2UUID=522C-80C6  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2# /dev/nvme0n1p6  /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0# /dev/nvme0n1p5  none  swap  defaults  0 0UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none  swap  defaults  0 0</code></pre><h2>10. change root <a target="_blank" rel="noopener noreferrer nofollow" href="#_10-change-root">​</a></h2><p>使用以下命令把系统环境切换到新系统下：</p><p>zsh</p><pre class="hljs"><code>arch-chroot /mnt</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_chroot.d0svrCrQ.png" alt="arch-chroot"><p>此时，原来安装盘下的 <code>/mnt</code> 目录就变成了新系统的 <code>/</code> 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。</p><h2>11. 设置主机名与时区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_11-设置主机名与时区">​</a></h2><ol><li><p>首先在 <code>/etc/hostname</code> 设置主机名：</p></li></ol><p>bash</p><pre class="hljs"><code>vim /etc/hostname</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-1.B918CSnw.png" alt="set-name-and-timezone_step-1"><p>加入你想为主机取的主机名，这里比如叫 myarch。</p><p>ℹ️ 提示</p><p>主机名不要包含特殊字符以及空格。</p><ol start="2"><li><p>接下来在 <code>/etc/hosts</code> 设置与其匹配的条目：</p></li></ol><p>bash</p><pre class="hljs"><code>vim /etc/hosts</code></pre><p>加入如下内容：</p><p>bash</p><pre class="hljs"><code>127.0.0.1   localhost::1         localhost127.0.1.1   myarch.localdomain myarch</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-2.CLbXR1mh.png" alt="set-name-and-timezone_step-2"><p>ℹ️ 提示</p><p>你可以使用 <code>Tab</code> 对齐。</p><p>ℹ️ 提示</p><p>某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 <code>No protocol specified qt.qpa.xcb: could not connect to display</code> 的错误。这种情况极为少见。</p><p>但不管如何，即使没有问题，我们都应该设置好主机名。</p><ol start="3"><li><p>随后设置时区，在 <code>/etc/localtime</code> 下用 <code>/usr</code> 中合适的时区创建符号链接：</p></li></ol><p>bash</p><pre class="hljs"><code>ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-3.BFRWq2B4.png" alt="set-name-and-timezone_step-3"><blockquote><h4>🍧 碎碎念 <a target="_blank" rel="noopener noreferrer nofollow" href="#🍧-碎碎念">​</a></h4><p>不要找北京啦！这里没有北京，只有上海啦！🚀</p></blockquote><p>ℹ️ 提示</p><p>同时，你也可以使用其它时区：</p><p></p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-4.BCj7m2n9.png" alt="set-name-and-timezone_step-4"><h2>12. 硬件时间设置 <a target="_blank" rel="noopener noreferrer nofollow" href="#_12-硬件时间设置">​</a></h2><p>使用如下命令将系统时间同步到硬件时间：</p><p>bash</p><pre class="hljs"><code>hwclock --systohc</code></pre><h2>13. 设置 Locale <a target="_blank" rel="noopener noreferrer nofollow" href="#_13-设置-locale">​</a></h2><p><code>Locale</code> 决定了软件使用的语言、书写习惯和字符集。</p><ol><li><p>编辑 <code>/etc/locale.gen</code>，去掉 <code>en_US.UTF-8 UTF-8</code> 以及 <code>zh_CN.UTF-8 UTF-8</code> 行前的注释符号（<code>#</code>）：</p></li></ol><p>bash</p><pre class="hljs"><code>vim /etc/locale.gen</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_locale-1.BesWF7lc.png" alt="locale_step-1"><p></p><img src="https://arch.icekylin.online/assets/basic-install_locale-2.DWnbYuMb.png" alt="locale_step-2"><p>ℹ️ 提示</p><p>有几个选项极具迷惑性，请不要取消注释错了。</p><ol start="2"><li><p>然后使用如下命令生成 <code>locale</code>：</p></li></ol><p>bash</p><pre class="hljs"><code>locale-gen</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_locale-3.lyU3oGqg.png" alt="locale_step-3"><ol start="3"><li><p>向 <code>/etc/locale.conf</code> 输入内容：</p></li></ol><p>bash</p><pre class="hljs"><code>echo ''LANG=en_US.UTF-8''  &gt; /etc/locale.conf</code></pre><p>⚠️ 注意</p><p>不推荐在此设置任何中文 <code>locale</code>，会导致 <code>tty</code> 乱码。</p><h2>14. 为 root 用户设置密码 <a target="_blank" rel="noopener noreferrer nofollow" href="#_14-为-root-用户设置密码">​</a></h2><p>bash</p><pre class="hljs"><code>passwd root</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_passwd.C4vgFnXJ.png" alt="password"><p>ℹ️ 提示</p><p>根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。</p><h2>15. 安装微码 <a target="_blank" rel="noopener noreferrer nofollow" href="#_15-安装微码">​</a></h2><p>通过以下命令安装对应芯片制造商的微码：</p><p>bash</p><pre class="hljs"><code>pacman -S intel-ucode # Intelpacman -S amd-ucode # AMD</code></pre><p>ℹ️ 提示</p><p>🎉 恭喜你！这是你在新系统中第一次使用 <code>pacman</code> 软件包管理器安装软件！在这里一路回车完成安装即可。</p><p>如果你不会使用，请参阅 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/.html">这里</a>。</p><h2>16. 安装引导程序 <a target="_blank" rel="noopener noreferrer nofollow" href="#_16-安装引导程序">​</a></h2><p>如有需要可以参阅 <a target="_blank" rel="noreferrer" href="https://wiki.archlinux.org/title/GRUB_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)">ArchWiki 相关内容</a>。</p><ol><li><p>安装相应的包：</p></li></ol><p>bash</p><pre class="hljs"><code>pacman -S grub efibootmgr os-prober</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-S</code> 选项后指定要通过 <code>pacman</code> 包管理器安装的包：</p><ul><li><p><code>grub</code> —— 启动引导器</p></li><li><p><code>efibootmgr</code> —— <code>efibootmgr</code> 被 <code>grub</code> 脚本用来将启动项写入 NVRAM</p></li><li><p><code>os-prober</code> —— 为了能够引导 win10，需要安装 <code>os-prober</code> 以检测到它</p></li></ul></li></ul></blockquote><ol start="2"><li><p>安装 GRUB 到 EFI 分区：</p></li></ol><p>bash</p><pre class="hljs"><code>grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>--efi-directory=/boot</code> —— 将 <code>grubx64.efi</code> 安装到之前的指定位置（EFI 分区）</p></li><li><p><code>--bootloader-id=ARCH</code> —— 取名为 <code>ARCH</code></p></li></ul></blockquote><p></p><img src="https://arch.icekylin.online/assets/basic-install_grub-1.BRcfVSlw.png" alt="grub_step-1"><ol start="3"><li><p>接下来使用 <code>vim</code> 编辑 <code>/etc/default/grub</code> 文件：</p></li></ol><p>bash</p><pre class="hljs"><code>vim /etc/default/grub</code></pre><p>进行如下修改：</p><ul><li><p>去掉 <code>GRUB_CMDLINE_LINUX_DEFAULT</code> 一行中最后的 <code>quiet</code> 参数</p></li><li><p>把 <code>loglevel</code> 的数值从 <code>3</code> 改成 <code>5</code>。这样是为了后续如果出现系统错误，方便排错</p></li><li><p>加入 <code>nowatchdog</code> 参数，这可以显著提高开关机速度</p></li></ul><p></p><img src="https://arch.icekylin.online/assets/basic-install_grub-2.HfHVvAuo.png" alt="grub_step-2"><ul><li><p>为了引导 win10，则还需要添加新的一行 <code>GRUB_DISABLE_OS_PROBER=false</code></p></li></ul><p>grub</p><pre class="hljs"><code># GRUB boot loader configurationGRUB_DEFAULT=0GRUB_TIMEOUT=5GRUB_DISTRIBUTOR="Arch"GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"GRUB_CMDLINE_LINUX=""GRUB_DISABLE_OS_PROBER=false...</code></pre><p>ℹ️ 提示</p><p><code>nowatchdog</code> 参数无法禁用英特尔的看门狗硬件，改为 <code>modprobe.blacklist=iTCO_wdt</code> 即可。如有需要可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinuxcn.org/wiki/%E6%80%A7%E8%83%BD%E4%BC%98%E5%8C%96#%E7%9C%8B%E9%97%A8%E7%8B%97">ArchWiki 对应内容</a></p><ol start="4"><li><p>最后生成 <code>GRUB</code> 所需的配置文件：</p></li></ol><p>bash</p><pre class="hljs"><code>grub-mkconfig -o /boot/grub/grub.cfg</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_grub-3.1YkNI2Qy.png" alt="grub_step-3"><p>若引导了 win10，则输出应该包含倒数第二行：</p><p></p><img src="https://arch.icekylin.online/assets/os-prober-1.CUiTrPp8.png" alt="os-prober-1"><p>若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令</p><p>ℹ️ 提示</p><p>1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 <code>efi</code> 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 <code>GRUB</code>。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了），<code>chroot</code> 到 <code>/mnt</code>，然后你可以重新用 <code>--removable</code> 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinuxcn.org/wiki/GRUB#%E7%BC%BA%E7%9C%81/%E5%90%8E%E5%A4%87%E5%90%AF%E5%8A%A8%E8%B7%AF%E5%BE%84">ArchWiki 对应内容</a>。</p><p>bash</p><pre class="hljs"><code>grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH --removable</code></pre><p>2.<code>os-prober</code> 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。</p><h2>17. 完成安装 <a target="_blank" rel="noopener noreferrer nofollow" href="#_17-完成安装">​</a></h2><ol><li><p>输入以下命令：</p></li></ol><p>bash</p><pre class="hljs"><code>exit # 退回安装环境umount -R /mnt # 卸载新分区reboot # 重启</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_finish.BFJMMeTg.png" alt="finish-install"><p>注意，<strong>重启前要先拔掉优盘</strong>，否则你重启后还是进安装程序而不是安装好的系统。</p><p>ℹ️ 提示</p><p>虚拟机直接重启即可。</p><p></p><img src="https://arch.icekylin.online/assets/basic-install_last-step-1.BbAeF2iD.png" alt="last-step-1"><p>如图即为 GRUB 引导界面。</p><p>ℹ️ 提示</p><p>若引导了 win10 也会显示出来。</p><p>ℹ️ 提示</p><p>若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。</p><p>你应该在步骤 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-install.html#_5-%E8%8E%B7%E5%8F%96-bitlocker-%E6%81%A2%E5%A4%8D%E5%AF%86%E9%92%A5">5. 获取 Bitlocker 恢复密钥</a> 中已经知晓了 Bitlocker 解锁密钥。</p><p>若无法从 <a target="_blank" rel="noreferrer" href="https://aka.ms/myrecoverykey">aka.ms 相关页面</a> 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。</p><ol start="2"><li><p>重启后使用 root 账户登录系统：</p></li></ol><p></p><img src="https://arch.icekylin.online/assets/basic-install_last-step-2.OQfzBdal.png" alt="last-step-2"><ol start="3"><li><p>设置开机自启并立即启动 networkmanager 服务，即可连接网络：</p></li></ol><p>bash</p><pre class="hljs"><code>systemctl enable --now NetworkManager # 设置开机自启并立即启动 NetworkManager 服务ping www.bilibili.com # 测试网络连接</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_last-step-3.CRy-Yj5U.png" alt="last-step-3"><ol start="4"><li><p>若为无线连接，则需要在启动 <code>networkmanager</code> 后使用 <code>nmcli</code> 连接网络：</p></li></ol><p>bash</p><pre class="hljs"><code>nmcli dev wifi list # 显示附近的 Wi-Fi 网络nmcli dev wifi connect "Wi-Fi名（SSID）" password "网络密码" # 连接指定的无线网络</code></pre><p>也可以使用 <code>nmtui</code> 来配置网络</p><p>bash</p><pre class="hljs"><code>nmtui</code></pre><p>ℹ️ 提示</p><p>neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 <code>fastfetch</code> 代替 <code>neofetch</code>。</p><ol start="5"><li><p><code>fastfetch</code> 可以将系统信息和发行版 logo 一并打印出来。通过 <code>pacman</code> 安装 <code>fastfetch</code>：</p></li></ol><p>bash</p><pre class="hljs"><code>pacman -S fastfetch</code></pre><p>使用 <code>fastfetch</code> 打印系统信息：</p><p>bash</p><pre class="hljs"><code>fastfetch</code></pre><p></p><img src="https://arch.icekylin.online/assets/basic-install_fastfetch.Dc0n1esH.png" alt="fastfetch"><blockquote><h4>🍧 碎碎念 <a target="_blank" rel="noopener noreferrer nofollow" href="#🍧-碎碎念-1">​</a></h4><p>又到了 <code>fastfetch</code> 的时间了吗？</p></blockquote><h2>🎉 祝贺！🎉 <a target="_blank" rel="noopener noreferrer nofollow" href="#🎉-祝贺-🎉">​</a></h2><p>到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！</p><p>如果你对本节的部分步骤不理解，请仔细阅读下一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a>。在此之后，我们来安装图形界面。</p><p>ℹ️ 提示</p><p>你可以使用以下命令关机：</p><p>bash</p><pre class="hljs"><code>shutdown -h now# 或者poweroff</code></pre><p>ℹ️ 提示</p><p>archlinux 在 2021 年 4 月在安装镜像中内置了一个 <a target="_blank" rel="noreferrer" href="https://archlinux.org/packages/extra/any/archinstall/">安装脚本</a>，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于：</p><ol><li><p>只提供有限的文件系统格式</p></li><li><p>只可限定在一个磁盘</p></li><li><p>不能指定软件仓库镜像源</p></li><li><p>只提供有限的桌面选择</p></li><li><p>自动分区不可手动干预</p></li><li><p>输入错误直接崩溃退出</p></li><li><p>仅支持 UEFI 等</p></li></ol><p>不建议使用这个安装脚本，除了以上各种原因，初学者也无法在这种安装过程中学到任何东西。如果你因为某些原因需要快速启动一个基础的 archlinux 环境，那么可以尝试此脚本。</p>', 'private', NULL, 'archlinux 简明指南 ⛵ 万事俱备，只欠东风 ​ 经过了上一节的准备工作，我们可以开始正式安装 archlinux 了。如果你还没有完成前面的阅读，请先仔细阅读章节 安装前的准备 。如果对本节的步骤不理解或者有疑问，请阅读下一节 基础安装详解 本节从安装最基础的、无图形化界面的 archlinux 系统开始。如有需要可以参阅 ArchWiki 官方安装指南 。 ℹ️ 提示 本节中的截图来自虚拟机和已经安装好的 archlinux。不用担心！和你在实体机看到的是一样的。 ⚠️ 注意 请按照指南的步骤一步一步进行！不要跳步、也不要在步骤中添加多余的动作！ 另外，如果安装中有报错，请弄清楚报错的原因（这要求你起码能看懂有报错）！常见的原因包括但不限于输错了命令、添加了多余的步骤等。在解决了问题之后再进行下一步！ 0. 进入安装环境 ​ 在第一个选项回车 进入安装环境后，便可以开始通过命令安装 archlinux 了 ℹ️ 提示 在2025年后，用于自动更新 mirrorlist （软件包管理器 pacman 的软件源）的 reflector 服务由于会误删某些有用的源信息已被默认禁用，无需再手动禁用。 ℹ️ 提示 在命令行中你可以使用如下命令清屏： zsh clear 同时，你可以使用 Tab 键在输入命令的时候对命令、参数或文件路径进行自动补全，提高效率的同时降低输入错误的风险。 Tab 无法补全时，有些设备的蜂鸣器会发出“哔——”声，可以使用如下命令禁用蜂鸣器内核模块： zsh rmmod pcspkr 要永久禁用蜂鸣器内核模块, 请创建并编辑 /etc/modprobe.d/blacklist.conf zsh sudoedit /etc/modprobe.d/blacklist.conf 加入以下内容 blacklist pcspkr 这样下次启动就不会加载 pcspkr 模块了 1. 确认是否为 UEFI 模式 ​ 我们先来确认一下是否为 UEFI 模式： zsh ls /sys/firmware/efi/efivars 若输出了一堆东西（ efi 变量），则说明已在 UEFI 模式。否则请确认你的启动方式是否为 UEFI 。 2. 连接网络 ​ ℹ️ 提示 archlinux 的安装 必须 要求网络环境。 ℹ️ 提示 若为虚拟机且按照上一节 虚拟机安装前的准备 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。 若使用 无线连接 ​ 使用 iwctl 进行连接： zsh iwctl # 进入交互式命令行device list # 列出无线网卡设备名，比如无线网卡看到叫 wlan0station wlan0 scan # 扫描网络station wlan0 get-networks # 列出所有 wifi 网络station wlan0 connect wifi-name # 进行连接，注意这里无法输入中文。回车后输入密码即可exit # 连接成功后退出 ℹ️ 提示 若无线网卡无法显示，请按照上一节 确保网络环境 的说明 确保你的无线网卡硬件开关处于打开状态 。 你可以使用如下命令查看内核是否加载了你的无线网卡驱动。 zsh lspci -k | grep Network 以我的硬件为例，输出如下： zsh 00:14.3 Network controller: Intel Corporation Wi-Fi 6 AX201 (rev 20) 如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 WIFI zsh rfkill list #查看无线连接 是否被禁用(blocked: yes)ip link set wlan0 up #比如无线网卡看到叫 wlan0 若看到类似 Operation not possible due to RF-kill 的报错，继续尝试 rfkill unblock wifi 来解锁无线网卡。 zsh rfkill unblock wifi 部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。 若使用 有线连接 ​ 正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。 可以等待几秒等网络建立连接后再进行下一步测试网络的操作。 若笔记本没有网线接口请使用带网线接口的扩展坞。 3. 测试网络连通性 ​ 通过 ping 命令测试网络连通性： zsh ping www.bilibili.com 稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 Ctrl + C 手动退出 ping 命令。 ℹ️ 提示 如果无线网络还是无法连接，请使用 ip link 命令查看无线网卡设备，使用 ip link set &lt;设备名&gt; up 命令激活对应的无线网卡。若看到类似 Operation not possible due to RF-kill 的报错，继续尝试 rfkill unblock wifi 来解锁无线网卡。 如有需要，可以参考 ArchWiki 相关内容 。 4. 更新系统时钟 ​ 使用 timedatectl 确保系统时间是准确的。这一步 不是 可选的，正确的系统时间对于部分程序来说非常重要： zsh timedatectl set-ntp true # 将系统时间与网络时间进行同步timedatectl status # 检查服务状态 5. 更换国内软件仓库镜像源加快下载速度 ​ 使用 vim 编辑器修改 /etc/pacman.d/mirrorlist 文件。将 pacman 软件仓库源更换为国内软件仓库镜像源： zsh vim /etc/pacman.d/mirrorlist ℹ️ 提示 如果不会使用 vim 编辑器，请参阅 这里 。 vim 编辑器在安装和配置系统的过程中还需要使用多次。 放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下： mirrorlist Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站 修改完成的 /etc/pacman.d/mirrorlist 文件如图所示。 ℹ️ 提示 如果发现 /etc/pacman.d/mirrorlist 是如图这个样子的，那么说明你禁用 reflector 服务晚了。 reflector 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。 ⚠️ 注意 前车之鉴 —— 请不在这一步中添加 archlinuxcn 源！如果你在 /etc/pacman.conf 中添加了内容，请将它们删掉。 6. 分区和格式化（使用 Btrfs 文件系统） ​ 6-1. 分区 ​ ☢️ 警告 分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！ 同时，请提前做好数据备份，防止数据丢失！ 本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。 / 根目录： &gt;= 128GB （和用户主目录在同一个 Btrfs 文件系统上） /home 用户主目录： &gt;= 128GB （和根目录在同一个 Btrfs 文件系统上） /boot EFI 分区： 256MB （由电脑厂商或 Windows 决定，无需再次创建） Swap 分区： &gt;= 电脑实际运行内存的 60% （设置这个大小是为了配置休眠准备） ℹ️ 提示 因为采用 Btrfs 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。 通过 lsblk 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况： zsh lsblk # 显示当前分区情况 此处要分区和安装 archlinux 的磁盘即为 sda 。请根据你的实际情况判断！ ℹ️ 提示 为了模拟真实的环境，笔者手动创建了三个分区分别代表： sda1 —— EFI 分区 sda2 —— win10 下的 C 盘（象征性的分了 1GB ） sda3 —— win10 下的 D 盘（象征性的分了 1GB ） ℹ️ 提示 注意此处并不会显出出未分配的磁盘空间！只有在使用 cfdisk 执行分区操作后才会显示出来。 ℹ️ 提示 如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 sdx 而是 nvmexn1 。 接下来使用 cfdisk 命令对磁盘分区（对于 SATA 协议的硬盘， x 为字母 a 、 b 或 c 等等；对于 NVME 协议的硬盘， x 为数字 0 、 1 或 2 等等，请根据实际情况判断）： SATANVME zsh cfdisk /dev/sdx # 对安装 archlinux 的磁盘分区 zsh cfdisk /dev/nvmexn1 # 对安装 archlinux 的磁盘分区 进入 cfdisk 分区工具之后，你会看到如图所示的界面。通过方向键 ↑ 和 ↓ 可以在要操作磁盘分区或空余空间中移动；通过方向键 ← 和 → 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。 首先创建 Swap 分区。选中 Free space &gt; 再选中操作 [New] &gt; 然后按下回车 Enter 以新建 swap 分区（类似 Windows 的交换文件） 按下回车后会提示输入 分区大小 ，Swap 分区建议为 电脑内存大小的 60% ，或者和内存大小相等 &gt; 然后按下回车 Enter ℹ️ 提示 单位可以自行输入，如 GB 、 MB 等等。 默认新建的类型是 Linux filesystem ，我们需要将类型更改为 Linux swap 。选中操作 [Type] &gt; 然后按下回车 Enter &gt; 通过方向键 ↑ 和 ↓ 选中 Linux swap &gt; 最后按下回车 Enter 我们再只需要一个分区即可（因为使用 Btrfs 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 Free space &gt; 再选中操作 [New] &gt; 然后按下回车 Enter 以新建分区 输入 分区大小 （默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 Enter 分区类型默认即可，无需更改。接下来选中操作 [Write] 并回车 Enter &gt; 输入 yes 并回车 Enter 确认分区操作 ⚠️ 注意 只有写入了操作分区表才会更改。 选中操作 [Quit] 并回车 Enter 以退出 cfdisk 分区工具 ☢️ 警告 再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！ 常见的错误包括不小心把 Windows 的分区删掉了 😥。 分区完成后，使用 fdisk 或 lsblk 命令复查分区情况： fdisklsblk zsh fdisk -l # 复查磁盘情况 zsh lsblk # 复查磁盘情况 6-2. 格式化并创建 Btrfs 子卷 ​ 6-2.0. 格式化 EFI 分区 ​ SATANVME zsh mkfs.fat -F32 /dev/sdxn zsh mkfs.fat -F32 /dev/nvmexn1pn ⚠️ 注意 如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。 6-2-1. 格式化 Swap 分区 ​ 通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 x 和 n （下同）： SATANVME zsh mkswap /dev/sdxn zsh mkswap /dev/nvmexn1pn 6-2-2. 格式化 Btrfs 分区 ​ 首先我们需要将整一个分区格式化为 Btrfs 文件系统。使用如下命令进行格式化： SATANVME zsh mkfs.btrfs -L myArch /dev/sdxn zsh mkfs.btrfs -L myArch /dev/nvmexn1pn 📑 命令参数说明： -L 选项后指定该分区的 LABLE ，这里以 myArch 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义 为了创建子卷，我们需要先将 Btrfs 分区挂载到 /mnt 下： SATANVME zsh mount -t btrfs -o compress=zstd /dev/sdxn /mnt zsh mount -t btrfs -o compress=zstd /dev/nvmexn1pn /mnt 📑 命令参数说明： -t 选项后指定挂载分区文件系统类型 -o 选项后添加挂载参数： compress=zstd —— 开启透明压缩 使用 df 命令复查挂载情况： zsh df -h # -h 选项会使输出以人类可读的单位显示 6-2-3. 创建 Btrfs 子卷 ​ 通过以下命令创建两个 Btrfs 子卷，之后将分别挂载到 / 根目录和 /home 用户主目录： zsh btrfs subvolume create /mnt/@ # 创建 / 目录子卷btrfs subvolume create /mnt/@home # 创建 /home 目录子卷 ⚠️ 注意 除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 timeshift 只支持这种子卷布局。 通过以下命令复查子卷情况： zsh btrfs subvolume list -p /mnt 子卷创建好后，我们需要将 /mnt 卸载掉，以挂载子卷： zsh umount /mnt 7. 挂载 ​ 在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷： SATANVME zsh mount -t btrfs -o subvol=/@,compress=zstd /dev/sdxn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/sdxn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/sdxn /mnt/boot # 挂载 /boot 目录swapon /dev/sdxn # 挂载交换分区 zsh mount -t btrfs -o subvol=/@,compress=zstd /dev/nvmexn1pn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/nvmexn1pn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/nvmexn1pn /mnt/boot # 挂载 /boot 目录swapon /dev/nvmexn1pn # 挂载交换分区 使用 df 命令复查挂载情况： zsh df -h 使用 free 命令复查 Swap 分区挂载情况： zsh free -h # -h 选项会使输出以人类可读的单位显示 8. 安装系统 ​ 通过如下命令使用 pacstrap 脚本安装基础包： bash pacstrap /mnt base base-devel linux linux-firmware btrfs-progs# 如果使用btrfs文件系统，额外安装一个btrfs-progs包 📑 命令参数说明： base-devel —— base-devel 在 AUR 包的安装过程中是必须用到的 linux —— 内核软件包，这里建议先不要替换为其它内核 如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 archlinux-keyring 解决此问题 bash pacman -S archlinux-keyring 通过如下命令使用 pacstrap 脚本安装其它必要的功能性软件： bash pacstrap /mnt networkmanager vim sudo zsh zsh-completions 📑 命令参数说明： zsh —— zsh-completions 如果你是 bash 的爱好者，请把这两个包换成 bash-completion 如果你是第一次接触*nix 系统的新手，不建议换成 bash 经过一系列安装时提示信息的刷屏，这些包就安装好了。 ⚠️ 注意 在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。 很多人在后续的步骤中报错就是因为这里漏装了东西。 如果报错，请 检查拼写 ，同时请确保之前的步骤 更换国内软件仓库镜像源加快下载速度 中 没有 添加 archlinuxcn 源。 9. 生成 fstab 文件 ​ fstab 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 genfstab 自动根据当前挂载情况生成并写入 fstab 文件： zsh genfstab -U /mnt &gt; /mnt/etc/fstab 复查一下 /mnt/etc/fstab 确保没有错误： zsh cat /mnt/etc/fstab 若为 NVME 协议的硬盘，输出结果应该与此类似： fstab # /dev/nvme0n1p6 / btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 / btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0# /dev/nvme0n1p1 /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2UUID=522C-80C6 /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2# /dev/nvme0n1p6 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0# /dev/nvme0n1p5 none swap defaults 0 0UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none swap defaults 0 0 10. change root ​ 使用以下命令把系统环境切换到新系统下： zsh arch-chroot /mnt 此时，原来安装盘下的 /mnt 目录就变成了新系统的 / 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。 11. 设置主机名与时区 ​ 首先在 /etc/hostname 设置主机名： bash vim /etc/hostname 加入你想为主机取的主机名，这里比如叫 myarch。 ℹ️ 提示 主机名不要包含特殊字符以及空格。 接下来在 /etc/hosts 设置与其匹配的条目： bash vim /etc/hosts 加入如下内容： bash 127.0.0.1 localhost::1 localhost127.0.1.1 myarch.localdomain myarch ℹ️ 提示 你可以使用 Tab 对齐。 ℹ️ 提示 某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 No protocol specified qt.qpa.xcb: could not connect to display 的错误。这种情况极为少见。 但不管如何，即使没有问题，我们都应该设置好主机名。 随后设置时区，在 /etc/localtime 下用 /usr 中合适的时区创建符号链接： bash ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 🍧 碎碎念 ​ 不要找北京啦！这里没有北京，只有上海啦！🚀 ℹ️ 提示 同时，你也可以使用其它时区： 12. 硬件时间设置 ​ 使用如下命令将系统时间同步到硬件时间： bash hwclock --systohc 13. 设置 Locale ​ Locale 决定了软件使用的语言、书写习惯和字符集。 编辑 /etc/locale.gen ，去掉 en_US.UTF-8 UTF-8 以及 zh_CN.UTF-8 UTF-8 行前的注释符号（ # ）： bash vim /etc/locale.gen ℹ️ 提示 有几个选项极具迷惑性，请不要取消注释错了。 然后使用如下命令生成 locale ： bash locale-gen 向 /etc/locale.conf 输入内容： bash echo ''LANG=en_US.UTF-8'' &gt; /etc/locale.conf ⚠️ 注意 不推荐在此设置任何中文 locale ，会导致 tty 乱码。 14. 为 root 用户设置密码 ​ bash passwd root ℹ️ 提示 根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。 15. 安装微码 ​ 通过以下命令安装对应芯片制造商的微码： bash pacman -S intel-ucode # Intelpacman -S amd-ucode # AMD ℹ️ 提示 🎉 恭喜你！这是你在新系统中第一次使用 pacman 软件包管理器安装软件！在这里一路回车完成安装即可。 如果你不会使用，请参阅 这里 。 16. 安装引导程序 ​ 如有需要可以参阅 ArchWiki 相关内容 。 安装相应的包： bash pacman -S grub efibootmgr os-prober 📑 命令参数说明： -S 选项后指定要通过 pacman 包管理器安装的包： grub —— 启动引导器 efibootmgr —— efibootmgr 被 grub 脚本用来将启动项写入 NVRAM os-prober —— 为了能够引导 win10，需要安装 os-prober 以检测到它 安装 GRUB 到 EFI 分区： bash grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH 📑 命令参数说明： --efi-directory=/boot —— 将 grubx64.efi 安装到之前的指定位置（EFI 分区） --bootloader-id=ARCH —— 取名为 ARCH 接下来使用 vim 编辑 /etc/default/grub 文件： bash vim /etc/default/grub 进行如下修改： 去掉 GRUB_CMDLINE_LINUX_DEFAULT 一行中最后的 quiet 参数 把 loglevel 的数值从 3 改成 5 。这样是为了后续如果出现系统错误，方便排错 加入 nowatchdog 参数，这可以显著提高开关机速度 为了引导 win10，则还需要添加新的一行 GRUB_DISABLE_OS_PROBER=false grub # GRUB boot loader configurationGRUB_DEFAULT=0GRUB_TIMEOUT=5GRUB_DISTRIBUTOR="Arch"GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"GRUB_CMDLINE_LINUX=""GRUB_DISABLE_OS_PROBER=false... ℹ️ 提示 nowatchdog 参数无法禁用英特尔的看门狗硬件，改为 modprobe.blacklist=iTCO_wdt 即可。如有需要可以参考 ArchWiki 对应内容 最后生成 GRUB 所需的配置文件： bash grub-mkconfig -o /boot/grub/grub.cfg 若引导了 win10，则输出应该包含倒数第二行： 若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令 ℹ️ 提示 1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 efi 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 GRUB 。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了）， chroot 到 /mnt ，然后你可以重新用 --removable 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 ArchWiki 对应内容 。 bash grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH --removable 2. os-prober 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。 17. 完成安装 ​ 输入以下命令： bash exit # 退回安装环境umount -R /mnt # 卸载新分区reboot # 重启 注意， 重启前要先拔掉优盘 ，否则你重启后还是进安装程序而不是安装好的系统。 ℹ️ 提示 虚拟机直接重启即可。 如图即为 GRUB 引导界面。 ℹ️ 提示 若引导了 win10 也会显示出来。 ℹ️ 提示 若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。 你应该在步骤 5. 获取 Bitlocker 恢复密钥 中已经知晓了 Bitlocker 解锁密钥。 若无法从 aka.ms 相关页面 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。 重启后使用 root 账户登录系统： 设置开机自启并立即启动 networkmanager 服务，即可连接网络： bash systemctl enable --now NetworkManager # 设置开机自启并立即启动 NetworkManager 服务ping www.bilibili.com # 测试网络连接 若为无线连接，则需要在启动 networkmanager 后使用 nmcli 连接网络： bash nmcli dev wifi list # 显示附近的 Wi-Fi 网络nmcli dev wifi connect "Wi-Fi名（SSID）" password "网络密码" # 连接指定的无线网络 也可以使用 nmtui 来配置网络 bash nmtui ℹ️ 提示 neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 fastfetch 代替 neofetch 。 fastfetch 可以将系统信息和发行版 logo 一并打印出来。通过 pacman 安装 fastfetch ： bash pacman -S fastfetch 使用 fastfetch 打印系统信息： bash fastfetch 🍧 碎碎念 ​ 又到了 fastfetch 的时间了吗？ 🎉 祝贺！🎉 ​ 到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！ 如果你对本节的部分步骤不理解，请仔细阅读下一节 基础安装详解 。在此之后，我们来安装图形界面。 ℹ️ 提示 你可以使用以下命令关机： bash shutdown -h now# 或者poweroff ℹ️ 提示 archlinux 在 2021 年 4 月在安装镜像中内置了一个 安装脚本 ，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于： 只提供有限的文件系统格式 只可限定在一个磁盘 不能指定软件仓库镜像源 只提供有限的桌面选择 自动分区不可手动干预 输入错误直接崩溃退出 仅支持 UEFI 等 不建议使用这个安装脚本，除了以上各种原因，初学者也无法在这种安装过程中学到任何东西。如果你因为某些原因需要快速启动一个基础的 archlinux 环境，那么可以尝试此脚本。', '2026-11-06 10:33:41.169328+08'::timestamptz, '2026-11-06 10:55:05.514866+08'::timestamptz, 'c59ba8f6-bf7e-4c30-81e4-327ea96f7fa4'::uuid, 0, '2026-11-06 11:16:07.0629+08'::timestamptz),
  ('c26f377b-d321-41a5-ac63-29c29c670e9e'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'archlinux 简明指南', '<div id="readability-page-1" class="page"><div data-v-fc4727e6=""><blockquote><h3 id="⛵-万事俱备-只欠东风" tabindex="-1">⛵ 万事俱备，只欠东风 <a href="#⛵-万事俱备-只欠东风" aria-label="Permalink to &quot;⛵ 万事俱备，只欠东风&quot;">​</a></h3><p>经过了上一节的准备工作，我们可以开始正式安装 archlinux 了。如果你还没有完成前面的阅读，请先仔细阅读章节 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html">安装前的准备</a>。如果对本节的步骤不理解或者有疑问，请阅读下一节 <a href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a></p></blockquote><p>本节从安装最基础的、无图形化界面的 archlinux 系统开始。如有需要可以参阅 <a href="https://wiki.archlinux.org/title/Installation_guide_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)" target="_blank" rel="noreferrer">ArchWiki 官方安装指南</a>。</p><div><p>ℹ️ 提示</p><p>本节中的截图来自虚拟机和已经安装好的 archlinux。不用担心！和你在实体机看到的是一样的。</p></div><div><p>⚠️ 注意</p><p>请按照指南的步骤一步一步进行！不要跳步、也不要在步骤中添加多余的动作！</p><p>另外，如果安装中有报错，请弄清楚报错的原因（这要求你起码能看懂有报错）！常见的原因包括但不限于输错了命令、添加了多余的步骤等。在解决了问题之后再进行下一步！</p></div><h2 id="_0-进入安装环境" tabindex="-1">0. 进入安装环境 <a href="#_0-进入安装环境" aria-label="Permalink to &quot;0. 进入安装环境&quot;">​</a></h2><p><img src="https://arch.icekylin.online/assets/pre-virt_vb-14.pyALUo_J.png" alt="archlinux-iso-1"></p><ol><li>在第一个选项回车</li></ol><p><img src="https://arch.icekylin.online/assets/pre-virt_vb-15.CqUq5u2n.png" alt="archlinux-iso-2"></p><ol start="2"><li>进入安装环境后，便可以开始通过命令安装 archlinux 了</li></ol><div><p>ℹ️ 提示</p><ul><li>在2025年后，用于自动更新 <code>mirrorlist</code>（软件包管理器 <code>pacman</code> 的软件源）的 <code>reflector</code> 服务由于会误删某些有用的源信息已被默认禁用，无需再手动禁用。</li></ul></div><div><p>ℹ️ 提示</p><ul><li><p>在命令行中你可以使用如下命令清屏：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>clear</span></span></code></pre></div><p>同时，你可以使用 <code>Tab</code> 键在输入命令的时候对命令、参数或文件路径进行自动补全，提高效率的同时降低输入错误的风险。</p></li><li><p><code>Tab</code> 无法补全时，有些设备的蜂鸣器会发出“哔——”声，可以使用如下命令禁用蜂鸣器内核模块：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rmmod</span><span> pcspkr</span></span></code></pre></div></li><li><p>要永久禁用蜂鸣器内核模块, 请创建并编辑 <code>/etc/modprobe.d/blacklist.conf</code></p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>sudoedit</span><span> /etc/modprobe.d/blacklist.conf</span></span></code></pre></div><p>加入以下内容</p><div><pre tabindex="0"><code><span><span>blacklist pcspkr</span></span></code></pre></div><p>这样下次启动就不会加载 pcspkr 模块了</p></li></ul></div><h2 id="_1-确认是否为-uefi-模式" tabindex="-1">1. 确认是否为 UEFI 模式 <a href="#_1-确认是否为-uefi-模式" aria-label="Permalink to &quot;1. 确认是否为 UEFI 模式&quot;">​</a></h2><p>我们先来确认一下是否为 <code>UEFI</code> 模式：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>ls</span><span> /sys/firmware/efi/efivars</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_check-efi.Cst0GaUE.png" alt="check-efi"></p><p>若输出了一堆东西（<code>efi</code> 变量），则说明已在 <code>UEFI</code> 模式。否则请确认你的启动方式是否为 <code>UEFI</code>。</p><h2 id="_2-连接网络" tabindex="-1">2. 连接网络 <a href="#_2-连接网络" aria-label="Permalink to &quot;2. 连接网络&quot;">​</a></h2><div><p>ℹ️ 提示</p><p>archlinux 的安装<strong>必须</strong>要求网络环境。</p></div><div><p>ℹ️ 提示</p><p>若为虚拟机且按照上一节 <a href="https://arch.icekylin.online/guide/rookie/pre-virt.html#_3-%E9%85%8D%E7%BD%AE-virtualbox">虚拟机安装前的准备</a> 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。</p></div><h3 id="若使用无线连接" tabindex="-1">若使用<strong>无线连接</strong> <a href="#若使用无线连接" aria-label="Permalink to &quot;若使用**无线连接**&quot;">​</a></h3><p>使用 <code>iwctl</code> 进行连接：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>iwctl</span><span> # 进入交互式命令行</span></span>
<span><span>device</span><span> list</span><span> # 列出无线网卡设备名，比如无线网卡看到叫 wlan0</span></span>
<span><span>station</span><span> wlan0</span><span> scan</span><span> # 扫描网络</span></span>
<span><span>station</span><span> wlan0</span><span> get-networks</span><span> # 列出所有 wifi 网络</span></span>
<span><span>station</span><span> wlan0</span><span> connect</span><span> wifi-name</span><span> # 进行连接，注意这里无法输入中文。回车后输入密码即可</span></span>
<span><span>exit</span><span> # 连接成功后退出</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>若无线网卡无法显示，请按照上一节 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html#_1-%E7%A1%AE%E4%BF%9D%E7%BD%91%E7%BB%9C%E7%8E%AF%E5%A2%83">确保网络环境</a> 的说明<strong>确保你的无线网卡硬件开关处于打开状态</strong>。</p><p>你可以使用如下命令查看内核是否加载了你的无线网卡驱动。</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lspci</span><span> -k</span><span> |</span><span> grep</span><span> Network</span></span></code></pre></div><p>以我的硬件为例，输出如下：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>00:14.3</span><span> Network</span><span> controller:</span><span> Intel</span><span> Corporation</span><span> Wi-Fi</span><span> 6</span><span> AX201</span><span> (rev </span><span>20</span><span>)</span></span></code></pre></div><p>如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 <code>WIFI</code></p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rfkill</span><span> list</span><span> #查看无线连接 是否被禁用(blocked: yes)</span></span>
<span><span>ip</span><span> link</span><span> set</span><span> wlan0</span><span> up</span><span> #比如无线网卡看到叫 wlan0</span></span></code></pre></div><p>若看到类似<code>Operation not possible due to RF-kill</code>的报错，继续尝试<code>rfkill unblock wifi</code>来解锁无线网卡。</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rfkill</span><span> unblock</span><span> wifi</span></span></code></pre></div><p>部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。</p></div><h3 id="若使用有线连接" tabindex="-1">若使用<strong>有线连接</strong> <a href="#若使用有线连接" aria-label="Permalink to &quot;若使用**有线连接**&quot;">​</a></h3><p>正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。</p><p>可以等待几秒等网络建立连接后再进行下一步测试网络的操作。</p><p>若笔记本没有网线接口请使用带网线接口的扩展坞。</p><h2 id="_3-测试网络连通性" tabindex="-1">3. 测试网络连通性 <a href="#_3-测试网络连通性" aria-label="Permalink to &quot;3. 测试网络连通性&quot;">​</a></h2><p>通过 <code>ping</code> 命令测试网络连通性：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>ping</span><span> www.bilibili.com</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_ping.BDHpp9ke.png" alt="ping"></p><p>稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 <code>Ctrl</code> + <code>C</code> 手动退出 <code>ping</code> 命令。</p><div><p>ℹ️ 提示</p><p>如果无线网络还是无法连接，请使用 <code>ip link</code> 命令查看无线网卡设备，使用 <code>ip link set &lt;设备名&gt; up</code> 命令激活对应的无线网卡。若看到类似 <code>Operation not possible due to RF-kill</code> 的报错，继续尝试 <code>rfkill unblock wifi</code> 来解锁无线网卡。</p><p>如有需要，可以参考 <a href="https://wiki.archlinux.org/title/Network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Wireless_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E6%A3%80%E6%9F%A5%E8%AE%BE%E5%A4%87%E7%8A%B6%E6%80%81" target="_blank" rel="noreferrer">ArchWiki 相关内容</a>。</p></div><h2 id="_4-更新系统时钟" tabindex="-1">4. 更新系统时钟 <a href="#_4-更新系统时钟" aria-label="Permalink to &quot;4. 更新系统时钟&quot;">​</a></h2><p>使用 <code>timedatectl</code> 确保系统时间是准确的。这一步<strong>不是</strong>可选的，正确的系统时间对于部分程序来说非常重要：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>timedatectl</span><span> set-ntp</span><span> true</span><span> # 将系统时间与网络时间进行同步</span></span>
<span><span>timedatectl</span><span> status</span><span> # 检查服务状态</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_time.Dmuxtefc.png" alt="time"></p><h2 id="_5-更换国内软件仓库镜像源加快下载速度" tabindex="-1">5. 更换国内软件仓库镜像源加快下载速度 <a href="#_5-更换国内软件仓库镜像源加快下载速度" aria-label="Permalink to &quot;5. 更换国内软件仓库镜像源加快下载速度&quot;">​</a></h2><p>使用 <code>vim</code> 编辑器修改 <code>/etc/pacman.d/mirrorlist</code> 文件。将 <code>pacman</code> 软件仓库源更换为国内软件仓库镜像源：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/pacman.d/mirrorlist</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>如果不会使用 <code>vim</code> 编辑器，请参阅 <a href="https://arch.icekylin.online/guide/advanced/system-ctl.html#%E7%BB%88%E7%AB%AF%E7%BC%96%E8%BE%91%E5%99%A8-vim-%E7%9A%84%E4%BD%BF%E7%94%A8">这里</a>。</p><p><code>vim</code> 编辑器在安装和配置系统的过程中还需要使用多次。</p></div><p>放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下：</p><div><p><span>mirrorlist</span></p><pre tabindex="0"><code><span><span>Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站</span></span>
<span><span>Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站</span></span>
<span><span>Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站</span></span>
<span><span>Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mirrorlist-1.DS2ha-4u.png" alt="mirrorlist-1"></p><p>修改完成的 <code>/etc/pacman.d/mirrorlist</code> 文件如图所示。</p><div><p>ℹ️ 提示</p><p>如果发现 <code>/etc/pacman.d/mirrorlist</code> 是如图这个样子的，那么说明你禁用 <code>reflector</code> 服务晚了。<code>reflector</code> 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。</p><p><img src="https://arch.icekylin.online/assets/basic-install_mirrorlist-2.CITp5j1o.png" alt="mirrorlist-2"></p></div><div><p>⚠️ 注意</p><p>前车之鉴 —— 请不在这一步中添加 <code>archlinuxcn</code> 源！如果你在 <code>/etc/pacman.conf</code> 中添加了内容，请将它们删掉。</p></div><h2 id="_6-分区和格式化-使用-btrfs-文件系统" tabindex="-1">6. 分区和格式化（使用 Btrfs 文件系统） <a href="#_6-分区和格式化-使用-btrfs-文件系统" aria-label="Permalink to &quot;6. 分区和格式化（使用 Btrfs 文件系统）&quot;">​</a></h2><h3 id="_6-1-分区" tabindex="-1">6-1. 分区 <a href="#_6-1-分区" aria-label="Permalink to &quot;6-1. 分区&quot;">​</a></h3><div><p>☢️ 警告</p><p>分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！</p><p>同时，请提前做好数据备份，防止数据丢失！</p></div><p>本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。</p><ul><li><code>/</code> 根目录：<code>&gt;= 128GB</code>（和用户主目录在同一个 <code>Btrfs</code> 文件系统上）</li><li><code>/home</code> 用户主目录：<code>&gt;= 128GB</code>（和根目录在同一个 <code>Btrfs</code> 文件系统上）</li><li><code>/boot</code> EFI 分区：<code>256MB</code>（由电脑厂商或 Windows 决定，无需再次创建）</li><li>Swap 分区：<code>&gt;= 电脑实际运行内存的 60%</code>（设置这个大小是为了配置休眠准备）</li></ul><div><p>ℹ️ 提示</p><p>因为采用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。</p></div><ol><li>通过 <code>lsblk</code> 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lsblk</span><span> # 显示当前分区情况</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_partition-1.Bh1Xqg5R.png" alt="partition-1"></p><p>此处要分区和安装 archlinux 的磁盘即为 <code>sda</code>。请根据你的实际情况判断！</p><div><p>ℹ️ 提示</p><p>为了模拟真实的环境，笔者手动创建了三个分区分别代表：</p><ol><li><code>sda1</code> —— EFI 分区</li><li><code>sda2</code> —— win10 下的 C 盘（象征性的分了 <code>1GB</code>）</li><li><code>sda3</code> —— win10 下的 D 盘（象征性的分了 <code>1GB</code>）</li></ol></div><div><p>ℹ️ 提示</p><p>注意此处并不会显出出未分配的磁盘空间！只有在使用 <code>cfdisk</code> 执行分区操作后才会显示出来。</p></div><div><p>ℹ️ 提示</p><p>如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 <code>sdx</code> 而是 <code>nvmexn1</code>。</p></div><ol start="2"><li>接下来使用 <code>cfdisk</code> 命令对磁盘分区（对于 SATA 协议的硬盘，<code>x</code> 为字母 <code>a</code>、<code>b</code> 或 <code>c</code> 等等；对于 NVME 协议的硬盘，<code>x</code> 为数字 <code>0</code>、<code>1</code> 或 <code>2</code> 等等，请根据实际情况判断）：</li></ol><div><p><label data-title="SATA" for="tab-JNt3hoI">SATA</label><label data-title="NVME" for="tab-GnrA27S">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cfdisk</span><span> /dev/sdx</span><span> # 对安装 archlinux 的磁盘分区</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cfdisk</span><span> /dev/nvmexn1</span><span> # 对安装 archlinux 的磁盘分区</span></span></code></pre></div></div></div><p><img src="https://arch.icekylin.online/assets/basic-install_partition-2.DLT4hhE7.png" alt="partition-2"></p><p>进入 <code>cfdisk</code> 分区工具之后，你会看到如图所示的界面。通过方向键 <code>↑</code> 和 <code>↓</code> 可以在要操作磁盘分区或空余空间中移动；通过方向键 <code>←</code> 和 <code>→</code> 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。</p><ol start="3"><li>首先创建 Swap 分区。选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建 <code>swap</code> 分区（类似 Windows 的交换文件）</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-3.BjLUGd3s.png" alt="partition-3"></p><ol start="4"><li>按下回车后会提示输入 <code>分区大小</code>，Swap 分区建议为<strong>电脑内存大小的 60%</strong>，或者和内存大小相等 &gt; 然后按下回车 <code>Enter</code></li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-4.Dqv4NCG5.png" alt="partition-4"></p><div><p>ℹ️ 提示</p><p>单位可以自行输入，如 <code>GB</code>、<code>MB</code> 等等。</p></div><ol start="5"><li>默认新建的类型是 <code>Linux filesystem</code>，我们需要将类型更改为 <code>Linux swap</code>。选中操作 <code>[Type]</code> &gt; 然后按下回车 <code>Enter</code> &gt; 通过方向键 <code>↑</code> 和 <code>↓</code> 选中 <code>Linux swap</code> &gt; 最后按下回车 <code>Enter</code></li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-5.Dyfk--lB.png" alt="partition-5"></p><p><img src="https://arch.icekylin.online/assets/basic-install_partition-6.B8rtj9qg.png" alt="partition-6"></p><p><img src="https://arch.icekylin.online/assets/basic-install_partition-7._YVoQizt.png" alt="partition-7"></p><ol start="6"><li>我们再只需要一个分区即可（因为使用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建分区</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-8.B5Mxus1B.png" alt="partition-8"></p><ol start="7"><li>输入 <code>分区大小</code>（默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 <code>Enter</code></li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-9.CHsqU1Wz.png" alt="partition-9"></p><ol start="8"><li>分区类型默认即可，无需更改。接下来选中操作 <code>[Write]</code> 并回车 <code>Enter</code> &gt; 输入 <code>yes</code> 并回车 <code>Enter</code> 确认分区操作</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-10.B4WDaAwE.png" alt="partition-10"></p><p><img src="https://arch.icekylin.online/assets/basic-install_partition-11.BbqbEG9-.png" alt="partition-11"></p><div><p>⚠️ 注意</p><p>只有写入了操作分区表才会更改。</p></div><ol start="9"><li>选中操作 <code>[Quit]</code> 并回车 <code>Enter</code> 以退出 <code>cfdisk</code> 分区工具</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-12.CDCzeWEA.png" alt="partition-12"></p><div><p>☢️ 警告</p><p>再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！</p><p>常见的错误包括不小心把 Windows 的分区删掉了 😥。</p></div><ol start="10"><li>分区完成后，使用 <code>fdisk</code> 或 <code>lsblk</code> 命令复查分区情况：</li></ol><div><p><label data-title="fdisk" for="tab-JTCp_Om">fdisk</label><label data-title="lsblk" for="tab-NYjisnf">lsblk</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>fdisk</span><span> -l</span><span> # 复查磁盘情况</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lsblk</span><span> # 复查磁盘情况</span></span></code></pre></div></div></div><p><img src="https://arch.icekylin.online/assets/basic-install_partition-13.BZSCCyuz.png" alt="partition-13"></p><p><img src="https://arch.icekylin.online/assets/basic-install_partition-14.BzdDh6PY.png" alt="partition-14"></p><h3 id="_6-2-格式化并创建-btrfs-子卷" tabindex="-1">6-2. 格式化并创建 Btrfs 子卷 <a href="#_6-2-格式化并创建-btrfs-子卷" aria-label="Permalink to &quot;6-2. 格式化并创建 Btrfs 子卷&quot;">​</a></h3><h4 id="_6-2-0-格式化-efi-分区" tabindex="-1">6-2.0. 格式化 EFI 分区 <a href="#_6-2-0-格式化-efi-分区" aria-label="Permalink to &quot;6-2.0. 格式化 EFI 分区&quot;">​</a></h4><div><p><label data-title="SATA" for="tab-fB977cO">SATA</label><label data-title="NVME" for="tab-oSPbfYl">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.fat</span><span> -F32</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.fat</span><span> -F32</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><div><p>⚠️ 注意</p><p>如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。</p></div><h4 id="_6-2-1-格式化-swap-分区" tabindex="-1">6-2-1. 格式化 Swap 分区 <a href="#_6-2-1-格式化-swap-分区" aria-label="Permalink to &quot;6-2-1. 格式化 Swap 分区&quot;">​</a></h4><p>通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 <code>x</code> 和 <code>n</code>（下同）：</p><div><p><label data-title="SATA" for="tab-bMYjshz">SATA</label><label data-title="NVME" for="tab-bJdH8q5">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkswap</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkswap</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkswap.CzM8dA_8.png" alt="mkswap"></p><h4 id="_6-2-2-格式化-btrfs-分区" tabindex="-1">6-2-2. 格式化 Btrfs 分区 <a href="#_6-2-2-格式化-btrfs-分区" aria-label="Permalink to &quot;6-2-2. 格式化 Btrfs 分区&quot;">​</a></h4><ol><li>首先我们需要将整一个分区格式化为 <code>Btrfs</code> 文件系统。使用如下命令进行格式化：</li></ol><div><p><label data-title="SATA" for="tab-yKWcJNq">SATA</label><label data-title="NVME" for="tab-7zPnUOS">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.btrfs</span><span> -L</span><span> myArch</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.btrfs</span><span> -L</span><span> myArch</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-L</code> 选项后指定该分区的 <code>LABLE</code>，这里以 <code>myArch</code> 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义</li></ul></blockquote><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-1.CpWxbwoC.png" alt="mkbtrfs_step-1"></p><ol start="2"><li>为了创建子卷，我们需要先将 <code>Btrfs</code> 分区挂载到 <code>/mnt</code> 下：</li></ol><div><p><label data-title="SATA" for="tab-8eEMaUS">SATA</label><label data-title="NVME" for="tab-b_uxJkQ">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> compress=zstd</span><span> /dev/sdxn</span><span> /mnt</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt</span></span></code></pre></div></div></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-t</code> 选项后指定挂载分区文件系统类型</li><li><code>-o</code> 选项后添加挂载参数： <ul><li><code>compress=zstd</code> —— 开启透明压缩</li></ul></li></ul></blockquote><ol start="3"><li>使用 <code>df</code> 命令复查挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>df</span><span> -h</span><span> # -h 选项会使输出以人类可读的单位显示</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-2.CNm0O5gq.png" alt="mkbtrfs_step-2"></p><h4 id="_6-2-3-创建-btrfs-子卷" tabindex="-1">6-2-3. 创建 Btrfs 子卷 <a href="#_6-2-3-创建-btrfs-子卷" aria-label="Permalink to &quot;6-2-3. 创建 Btrfs 子卷&quot;">​</a></h4><ol><li>通过以下命令创建两个 <code>Btrfs</code> 子卷，之后将分别挂载到 <code>/</code> 根目录和 <code>/home</code> 用户主目录：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>btrfs</span><span> subvolume</span><span> create</span><span> /mnt/@</span><span> # 创建 / 目录子卷</span></span>
<span><span>btrfs</span><span> subvolume</span><span> create</span><span> /mnt/@home</span><span> # 创建 /home 目录子卷</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-3.DnVJ6tP6.png" alt="mkbtrfs_step-3"></p><div><p>⚠️ 注意</p><p>除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 <code>timeshift</code> 只支持这种子卷布局。</p></div><ol start="2"><li>通过以下命令复查子卷情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>btrfs</span><span> subvolume</span><span> list</span><span> -p</span><span> /mnt</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-4.Q0fek3jd.png" alt="mkbtrfs_step-4"></p><ol start="3"><li>子卷创建好后，我们需要将 <code>/mnt</code> 卸载掉，以挂载子卷：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>umount</span><span> /mnt</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-5.EEnZGPJv.png" alt="mkbtrfs_step-5"></p><h2 id="_7-挂载" tabindex="-1">7. 挂载 <a href="#_7-挂载" aria-label="Permalink to &quot;7. 挂载&quot;">​</a></h2><ol><li>在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷：</li></ol><div><p><label data-title="SATA" for="tab-OEzwwGo">SATA</label><label data-title="NVME" for="tab-Zic-Y0O">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@,compress=zstd</span><span> /dev/sdxn</span><span> /mnt</span><span> # 挂载 / 目录</span></span>
<span><span>mkdir</span><span> /mnt/home</span><span> # 创建 /home 目录</span></span>
<span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@home,compress=zstd</span><span> /dev/sdxn</span><span> /mnt/home</span><span> # 挂载 /home 目录</span></span>
<span><span>mkdir</span><span> -p</span><span> /mnt/boot</span><span> # 创建 /boot 目录</span></span>
<span><span>mount</span><span> /dev/sdxn</span><span> /mnt/boot</span><span> # 挂载 /boot 目录</span></span>
<span><span>swapon</span><span> /dev/sdxn</span><span> # 挂载交换分区</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@,compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt</span><span> # 挂载 / 目录</span></span>
<span><span>mkdir</span><span> /mnt/home</span><span> # 创建 /home 目录</span></span>
<span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@home,compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt/home</span><span> # 挂载 /home 目录</span></span>
<span><span>mkdir</span><span> -p</span><span> /mnt/boot</span><span> # 创建 /boot 目录</span></span>
<span><span>mount</span><span> /dev/nvmexn1pn</span><span> /mnt/boot</span><span> # 挂载 /boot 目录</span></span>
<span><span>swapon</span><span> /dev/nvmexn1pn</span><span> # 挂载交换分区</span></span></code></pre></div></div></div><p><img src="https://arch.icekylin.online/assets/basic-install_mount-1.DSGPGhwn.png" alt="mount_step-1"></p><p><img src="https://arch.icekylin.online/assets/basic-install_mount-2.C_eaivrb.png" alt="mount_step-2"></p><ol start="2"><li>使用 <code>df</code> 命令复查挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>df</span><span> -h</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mount-3.9HC0QeP4.png" alt="mount_step-3"></p><ol start="3"><li>使用 <code>free</code> 命令复查 Swap 分区挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>free</span><span> -h</span><span> # -h 选项会使输出以人类可读的单位显示</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mount-4.BOyAfSXA.png" alt="mount_step-4"></p><h2 id="_8-安装系统" tabindex="-1">8. 安装系统 <a href="#_8-安装系统" aria-label="Permalink to &quot;8. 安装系统&quot;">​</a></h2><ol><li>通过如下命令使用 <code>pacstrap</code> 脚本安装基础包：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacstrap</span><span> /mnt</span><span> base</span><span> base-devel</span><span> linux</span><span> linux-firmware</span><span> btrfs-progs</span></span>
<span><span># 如果使用btrfs文件系统，额外安装一个btrfs-progs包</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>base-devel</code> —— <code>base-devel</code> 在 <code>AUR</code> 包的安装过程中是必须用到的</li><li><code>linux</code> —— 内核软件包，这里建议先不要替换为其它内核</li></ul></blockquote><p><img src="https://arch.icekylin.online/assets/basic-install_pacstrap-1.Q3dLs9X-.png" alt="pacstrap_step-1"></p><p>如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 <code>archlinux-keyring</code> 解决此问题</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> archlinux-keyring</span></span></code></pre></div><ol start="2"><li>通过如下命令使用 <code>pacstrap</code> 脚本安装其它必要的功能性软件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacstrap</span><span> /mnt</span><span> networkmanager</span><span> vim</span><span> sudo</span><span> zsh</span><span> zsh-completions</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>zsh</code> —— <code>zsh-completions</code> 如果你是 bash 的爱好者，请把这两个包换成<code>bash-completion</code></li><li>如果你是第一次接触*nix 系统的新手，不建议换成 bash</li></ul></blockquote><p><img src="https://arch.icekylin.online/assets/basic-install_pacstrap-2.6jDXL0pu.png" alt="pacstrap_step-2"></p><p>经过一系列安装时提示信息的刷屏，这些包就安装好了。</p><div><p>⚠️ 注意</p><p>在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。</p><p>很多人在后续的步骤中报错就是因为这里漏装了东西。</p><p>如果报错，请<strong>检查拼写</strong>，同时请确保之前的步骤 <a href="#_6-更换国内软件仓库镜像源加快下载速度">更换国内软件仓库镜像源加快下载速度</a> 中<strong>没有</strong>添加 <code>archlinuxcn</code> 源。</p></div><h2 id="_9-生成-fstab-文件" tabindex="-1">9. 生成 fstab 文件 <a href="#_9-生成-fstab-文件" aria-label="Permalink to &quot;9. 生成 fstab 文件&quot;">​</a></h2><ol><li><code>fstab</code> 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 <code>genfstab</code> 自动根据当前挂载情况生成并写入 <code>fstab</code> 文件：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>genfstab</span><span> -U</span><span> /mnt</span><span> &gt;</span><span> /mnt/etc/fstab</span></span></code></pre></div><ol start="2"><li>复查一下 <code>/mnt/etc/fstab</code> 确保没有错误：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cat</span><span> /mnt/etc/fstab</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_fstab.CtqAJn7q.png" alt="fstab"></p><p>若为 NVME 协议的硬盘，输出结果应该与此类似：</p><div><p><span>fstab</span></p><pre tabindex="0"><code><span><span># /dev/nvme0n1p6  /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0</span></span>
<span><span>UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@  0 0</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p1  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro      0 2</span></span>
<span><span>UUID=522C-80C6  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p6  /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0</span></span>
<span><span>UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p5  none  swap  defaults  0 0</span></span>
<span><span>UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none  swap  defaults  0 0</span></span></code></pre></div><h2 id="_10-change-root" tabindex="-1">10. change root <a href="#_10-change-root" aria-label="Permalink to &quot;10. change root&quot;">​</a></h2><p>使用以下命令把系统环境切换到新系统下：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>arch-chroot</span><span> /mnt</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_chroot.d0svrCrQ.png" alt="arch-chroot"></p><p>此时，原来安装盘下的 <code>/mnt</code> 目录就变成了新系统的 <code>/</code> 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。</p><h2 id="_11-设置主机名与时区" tabindex="-1">11. 设置主机名与时区 <a href="#_11-设置主机名与时区" aria-label="Permalink to &quot;11. 设置主机名与时区&quot;">​</a></h2><ol><li>首先在 <code>/etc/hostname</code> 设置主机名：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/hostname</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-1.B918CSnw.png" alt="set-name-and-timezone_step-1"></p><p>加入你想为主机取的主机名，这里比如叫 myarch。</p><div><p>ℹ️ 提示</p><p>主机名不要包含特殊字符以及空格。</p></div><ol start="2"><li>接下来在 <code>/etc/hosts</code> 设置与其匹配的条目：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/hosts</span></span></code></pre></div><p>加入如下内容：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>127.0.0.1</span><span>   localhost</span></span>
<span><span>:</span><span>:1</span><span>         localhost</span></span>
<span><span>127.0.1.1</span><span>   myarch.localdomain</span><span> myarch</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-2.CLbXR1mh.png" alt="set-name-and-timezone_step-2"></p><div><p>ℹ️ 提示</p><p>你可以使用 <code>Tab</code> 对齐。</p></div><div><p>ℹ️ 提示</p><p>某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 <code>No protocol specified qt.qpa.xcb: could not connect to display</code> 的错误。这种情况极为少见。</p><p>但不管如何，即使没有问题，我们都应该设置好主机名。</p></div><ol start="3"><li>随后设置时区，在 <code>/etc/localtime</code> 下用 <code>/usr</code> 中合适的时区创建符号链接：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>ln</span><span> -sf</span><span> /usr/share/zoneinfo/Asia/Shanghai</span><span> /etc/localtime</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-3.BFRWq2B4.png" alt="set-name-and-timezone_step-3"></p><blockquote><h4 id="🍧-碎碎念" tabindex="-1">🍧 碎碎念 <a href="#🍧-碎碎念" aria-label="Permalink to &quot;🍧 碎碎念&quot;">​</a></h4><p>不要找北京啦！这里没有北京，只有上海啦！🚀</p></blockquote><div><p>ℹ️ 提示</p><p>同时，你也可以使用其它时区：</p><p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-4.BCj7m2n9.png" alt="set-name-and-timezone_step-4"></p></div><h2 id="_12-硬件时间设置" tabindex="-1">12. 硬件时间设置 <a href="#_12-硬件时间设置" aria-label="Permalink to &quot;12. 硬件时间设置&quot;">​</a></h2><p>使用如下命令将系统时间同步到硬件时间：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>hwclock</span><span> --systohc</span></span></code></pre></div><h2 id="_13-设置-locale" tabindex="-1">13. 设置 Locale <a href="#_13-设置-locale" aria-label="Permalink to &quot;13. 设置 Locale&quot;">​</a></h2><p><code>Locale</code> 决定了软件使用的语言、书写习惯和字符集。</p><ol><li>编辑 <code>/etc/locale.gen</code>，去掉 <code>en_US.UTF-8 UTF-8</code> 以及 <code>zh_CN.UTF-8 UTF-8</code> 行前的注释符号（<code>#</code>）：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/locale.gen</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_locale-1.BesWF7lc.png" alt="locale_step-1"></p><p><img src="https://arch.icekylin.online/assets/basic-install_locale-2.DWnbYuMb.png" alt="locale_step-2"></p><div><p>ℹ️ 提示</p><p>有几个选项极具迷惑性，请不要取消注释错了。</p></div><ol start="2"><li>然后使用如下命令生成 <code>locale</code>：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>locale-gen</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_locale-3.lyU3oGqg.png" alt="locale_step-3"></p><ol start="3"><li>向 <code>/etc/locale.conf</code> 输入内容：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>echo</span><span> ''LANG=en_US.UTF-8''</span><span>  &gt;</span><span> /etc/locale.conf</span></span></code></pre></div><div><p>⚠️ 注意</p><p>不推荐在此设置任何中文 <code>locale</code>，会导致 <code>tty</code> 乱码。</p></div><h2 id="_14-为-root-用户设置密码" tabindex="-1">14. 为 root 用户设置密码 <a href="#_14-为-root-用户设置密码" aria-label="Permalink to &quot;14. 为 root 用户设置密码&quot;">​</a></h2><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>passwd</span><span> root</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_passwd.C4vgFnXJ.png" alt="password"></p><div><p>ℹ️ 提示</p><p>根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。</p></div><h2 id="_15-安装微码" tabindex="-1">15. 安装微码 <a href="#_15-安装微码" aria-label="Permalink to &quot;15. 安装微码&quot;">​</a></h2><p>通过以下命令安装对应芯片制造商的微码：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> intel-ucode</span><span> # Intel</span></span>
<span><span>pacman</span><span> -S</span><span> amd-ucode</span><span> # AMD</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>🎉 恭喜你！这是你在新系统中第一次使用 <code>pacman</code> 软件包管理器安装软件！在这里一路回车完成安装即可。</p><p>如果你不会使用，请参阅 <a href="https://arch.icekylin.online/guide/rookie/.html">这里</a>。</p></div><h2 id="_16-安装引导程序" tabindex="-1">16. 安装引导程序 <a href="#_16-安装引导程序" aria-label="Permalink to &quot;16. 安装引导程序&quot;">​</a></h2><p>如有需要可以参阅 <a href="https://wiki.archlinux.org/title/GRUB_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)" target="_blank" rel="noreferrer">ArchWiki 相关内容</a>。</p><ol><li>安装相应的包：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> grub</span><span> efibootmgr</span><span> os-prober</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-S</code> 选项后指定要通过 <code>pacman</code> 包管理器安装的包： <ul><li><code>grub</code> —— 启动引导器</li><li><code>efibootmgr</code> —— <code>efibootmgr</code> 被 <code>grub</code> 脚本用来将启动项写入 NVRAM</li><li><code>os-prober</code> —— 为了能够引导 win10，需要安装 <code>os-prober</code> 以检测到它</li></ul></li></ul></blockquote><ol start="2"><li>安装 GRUB 到 EFI 分区：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-install</span><span> --target=x86_64-efi</span><span> --efi-directory=/boot</span><span> --bootloader-id=ARCH</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>--efi-directory=/boot</code> —— 将 <code>grubx64.efi</code> 安装到之前的指定位置（EFI 分区）</li><li><code>--bootloader-id=ARCH</code> —— 取名为 <code>ARCH</code></li></ul></blockquote><p><img src="https://arch.icekylin.online/assets/basic-install_grub-1.BRcfVSlw.png" alt="grub_step-1"></p><ol start="3"><li>接下来使用 <code>vim</code> 编辑 <code>/etc/default/grub</code> 文件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/default/grub</span></span></code></pre></div><p>进行如下修改：</p><ul><li>去掉 <code>GRUB_CMDLINE_LINUX_DEFAULT</code> 一行中最后的 <code>quiet</code> 参数</li><li>把 <code>loglevel</code> 的数值从 <code>3</code> 改成 <code>5</code>。这样是为了后续如果出现系统错误，方便排错</li><li>加入 <code>nowatchdog</code> 参数，这可以显著提高开关机速度</li></ul><p><img src="https://arch.icekylin.online/assets/basic-install_grub-2.HfHVvAuo.png" alt="grub_step-2"></p><ul><li>为了引导 win10，则还需要添加新的一行 <code>GRUB_DISABLE_OS_PROBER=false</code></li></ul><div><p><span>grub</span></p><pre tabindex="0"><code><span><span># GRUB boot loader configuration</span></span>
<span><span></span></span>
<span><span>GRUB_DEFAULT=0</span></span>
<span><span>GRUB_TIMEOUT=5</span></span>
<span><span>GRUB_DISTRIBUTOR="Arch"</span></span>
<span><span>GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"</span></span>
<span><span>GRUB_CMDLINE_LINUX=""</span></span>
<span><span>GRUB_DISABLE_OS_PROBER=false</span></span>
<span><span>...</span></span></code></pre></div><div><p>ℹ️ 提示</p><p><code>nowatchdog</code> 参数无法禁用英特尔的看门狗硬件，改为 <code>modprobe.blacklist=iTCO_wdt</code> 即可。如有需要可以参考 <a href="https://wiki.archlinuxcn.org/wiki/%E6%80%A7%E8%83%BD%E4%BC%98%E5%8C%96#%E7%9C%8B%E9%97%A8%E7%8B%97" target="_blank" rel="noreferrer">ArchWiki 对应内容</a></p></div><ol start="4"><li>最后生成 <code>GRUB</code> 所需的配置文件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-mkconfig</span><span> -o</span><span> /boot/grub/grub.cfg</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_grub-3.1YkNI2Qy.png" alt="grub_step-3"></p><p>若引导了 win10，则输出应该包含倒数第二行：</p><p><img src="https://arch.icekylin.online/assets/os-prober-1.CUiTrPp8.png" alt="os-prober-1"></p><p>若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令</p><div><p>ℹ️ 提示</p><p>1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 <code>efi</code> 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 <code>GRUB</code>。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了），<code>chroot</code> 到 <code>/mnt</code>，然后你可以重新用 <code>--removable</code> 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 <a href="https://wiki.archlinuxcn.org/wiki/GRUB#%E7%BC%BA%E7%9C%81/%E5%90%8E%E5%A4%87%E5%90%AF%E5%8A%A8%E8%B7%AF%E5%BE%84" target="_blank" rel="noreferrer">ArchWiki 对应内容</a>。</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-install</span><span> --target=x86_64-efi</span><span> --efi-directory=/boot</span><span> --bootloader-id=ARCH</span><span> --removable</span></span></code></pre></div><p>2.<code>os-prober</code> 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。</p></div><h2 id="_17-完成安装" tabindex="-1">17. 完成安装 <a href="#_17-完成安装" aria-label="Permalink to &quot;17. 完成安装&quot;">​</a></h2><ol><li>输入以下命令：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>exit</span><span> # 退回安装环境</span></span>
<span><span>umount</span><span> -R</span><span> /mnt</span><span> # 卸载新分区</span></span>
<span><span>reboot</span><span> # 重启</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_finish.BFJMMeTg.png" alt="finish-install"></p><p>注意，<strong>重启前要先拔掉优盘</strong>，否则你重启后还是进安装程序而不是安装好的系统。</p><div><p>ℹ️ 提示</p><p>虚拟机直接重启即可。</p></div><p><img src="https://arch.icekylin.online/assets/basic-install_last-step-1.BbAeF2iD.png" alt="last-step-1"></p><p>如图即为 GRUB 引导界面。</p><div><p>ℹ️ 提示</p><p>若引导了 win10 也会显示出来。</p></div><div><p>ℹ️ 提示</p><p>若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。</p><p>你应该在步骤 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html#_5-%E8%8E%B7%E5%8F%96-bitlocker-%E6%81%A2%E5%A4%8D%E5%AF%86%E9%92%A5">5. 获取 Bitlocker 恢复密钥</a> 中已经知晓了 Bitlocker 解锁密钥。</p><p>若无法从 <a href="https://aka.ms/myrecoverykey" target="_blank" rel="noreferrer">aka.ms 相关页面</a> 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。</p></div><ol start="2"><li>重启后使用 root 账户登录系统：</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_last-step-2.OQfzBdal.png" alt="last-step-2"></p><ol start="3"><li>设置开机自启并立即启动 networkmanager 服务，即可连接网络：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>systemctl</span><span> enable</span><span> --now</span><span> NetworkManager</span><span> # 设置开机自启并立即启动 NetworkManager 服务</span></span>
<span><span>ping</span><span> www.bilibili.com</span><span> # 测试网络连接</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_last-step-3.CRy-Yj5U.png" alt="last-step-3"></p><ol start="4"><li>若为无线连接，则需要在启动 <code>networkmanager</code> 后使用 <code>nmcli</code> 连接网络：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>nmcli</span><span> dev</span><span> wifi</span><span> list</span><span> # 显示附近的 Wi-Fi 网络</span></span>
<span><span>nmcli</span><span> dev</span><span> wifi</span><span> connect</span><span> "Wi-Fi名（SSID）"</span><span> password</span><span> "网络密码"</span><span> # 连接指定的无线网络</span></span></code></pre></div><p>也可以使用 <code>nmtui</code> 来配置网络</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>nmtui</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 <code>fastfetch</code> 代替 <code>neofetch</code>。</p></div><ol start="5"><li><code>fastfetch</code> 可以将系统信息和发行版 logo 一并打印出来。通过 <code>pacman</code> 安装 <code>fastfetch</code>：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> fastfetch</span></span></code></pre></div><p>使用 <code>fastfetch</code> 打印系统信息：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>fastfetch</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_fastfetch.Dc0n1esH.png" alt="fastfetch"></p><blockquote><h4 id="🍧-碎碎念-1" tabindex="-1">🍧 碎碎念 <a href="#🍧-碎碎念-1" aria-label="Permalink to &quot;🍧 碎碎念&quot;">​</a></h4><p>又到了 <code>fastfetch</code> 的时间了吗？</p></blockquote><h2 id="🎉-祝贺-🎉" tabindex="-1">🎉 祝贺！🎉 <a href="#🎉-祝贺-🎉" aria-label="Permalink to &quot;🎉 祝贺！🎉&quot;">​</a></h2><p>到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！</p><p>如果你对本节的部分步骤不理解，请仔细阅读下一节 <a href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a>。在此之后，我们来安装图形界面。</p><div><p>ℹ️ 提示</p><p>你可以使用以下命令关机：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>shutdown</span><span> -h</span><span> now</span></span>
<span><span># 或者</span></span>
<span><span>poweroff</span></span></code></pre></div></div><div><p>ℹ️ 提示</p><p>archlinux 在 2021 年 4 月在安装镜像中内置了一个 <a href="https://archlinux.org/packages/extra/any/archinstall/" target="_blank" rel="noreferrer">安装脚本</a>，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于：</p><ol><li>只提供有限的文件系统格式</li><li>只可限定在一个磁盘</li><li>不能指定软件仓库镜像源</li><li>只提供有限的桌面选择</li><li>自动分区不可手动干预</li><li>输入错误直接崩溃退出</li><li>仅支持 UEFI 等</li></ol><p>不建议使用这个安装脚本，除了以上各种原因，初学者也无法在这种安装过程中学到任何东西。如果你因为某些原因需要快速启动一个基础的 archlinux 环境，那么可以尝试此脚本。</p></div></div></div>', 'private', NULL, 'archlinux 简明指南 ⛵ 万事俱备，只欠东风 ​ 经过了上一节的准备工作，我们可以开始正式安装 archlinux 了。如果你还没有完成前面的阅读，请先仔细阅读章节 安装前的准备 。如果对本节的步骤不理解或者有疑问，请阅读下一节 基础安装详解 本节从安装最基础的、无图形化界面的 archlinux 系统开始。如有需要可以参阅 ArchWiki 官方安装指南 。 ℹ️ 提示 本节中的截图来自虚拟机和已经安装好的 archlinux。不用担心！和你在实体机看到的是一样的。 ⚠️ 注意 请按照指南的步骤一步一步进行！不要跳步、也不要在步骤中添加多余的动作！ 另外，如果安装中有报错，请弄清楚报错的原因（这要求你起码能看懂有报错）！常见的原因包括但不限于输错了命令、添加了多余的步骤等。在解决了问题之后再进行下一步！ 0. 进入安装环境 ​ 在第一个选项回车 进入安装环境后，便可以开始通过命令安装 archlinux 了 ℹ️ 提示 在2025年后，用于自动更新 mirrorlist （软件包管理器 pacman 的软件源）的 reflector 服务由于会误删某些有用的源信息已被默认禁用，无需再手动禁用。 ℹ️ 提示 在命令行中你可以使用如下命令清屏： zsh clear 同时，你可以使用 Tab 键在输入命令的时候对命令、参数或文件路径进行自动补全，提高效率的同时降低输入错误的风险。 Tab 无法补全时，有些设备的蜂鸣器会发出“哔——”声，可以使用如下命令禁用蜂鸣器内核模块： zsh rmmod pcspkr 要永久禁用蜂鸣器内核模块, 请创建并编辑 /etc/modprobe.d/blacklist.conf zsh sudoedit /etc/modprobe.d/blacklist.conf 加入以下内容 blacklist pcspkr 这样下次启动就不会加载 pcspkr 模块了 1. 确认是否为 UEFI 模式 ​ 我们先来确认一下是否为 UEFI 模式： zsh ls /sys/firmware/efi/efivars 若输出了一堆东西（ efi 变量），则说明已在 UEFI 模式。否则请确认你的启动方式是否为 UEFI 。 2. 连接网络 ​ ℹ️ 提示 archlinux 的安装 必须 要求网络环境。 ℹ️ 提示 若为虚拟机且按照上一节 虚拟机安装前的准备 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。 若使用 无线连接 ​ 使用 iwctl 进行连接： zsh iwctl # 进入交互式命令行 device list # 列出无线网卡设备名，比如无线网卡看到叫 wlan0 station wlan0 scan # 扫描网络 station wlan0 get-networks # 列出所有 wifi 网络 station wlan0 connect wifi-name # 进行连接，注意这里无法输入中文。回车后输入密码即可 exit # 连接成功后退出 ℹ️ 提示 若无线网卡无法显示，请按照上一节 确保网络环境 的说明 确保你的无线网卡硬件开关处于打开状态 。 你可以使用如下命令查看内核是否加载了你的无线网卡驱动。 zsh lspci -k | grep Network 以我的硬件为例，输出如下： zsh 00:14.3 Network controller: Intel Corporation Wi-Fi 6 AX201 (rev 20 ) 如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 WIFI zsh rfkill list #查看无线连接 是否被禁用(blocked: yes) ip link set wlan0 up #比如无线网卡看到叫 wlan0 若看到类似 Operation not possible due to RF-kill 的报错，继续尝试 rfkill unblock wifi 来解锁无线网卡。 zsh rfkill unblock wifi 部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。 若使用 有线连接 ​ 正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。 可以等待几秒等网络建立连接后再进行下一步测试网络的操作。 若笔记本没有网线接口请使用带网线接口的扩展坞。 3. 测试网络连通性 ​ 通过 ping 命令测试网络连通性： zsh ping www.bilibili.com 稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 Ctrl + C 手动退出 ping 命令。 ℹ️ 提示 如果无线网络还是无法连接，请使用 ip link 命令查看无线网卡设备，使用 ip link set &lt;设备名&gt; up 命令激活对应的无线网卡。若看到类似 Operation not possible due to RF-kill 的报错，继续尝试 rfkill unblock wifi 来解锁无线网卡。 如有需要，可以参考 ArchWiki 相关内容 。 4. 更新系统时钟 ​ 使用 timedatectl 确保系统时间是准确的。这一步 不是 可选的，正确的系统时间对于部分程序来说非常重要： zsh timedatectl set-ntp true # 将系统时间与网络时间进行同步 timedatectl status # 检查服务状态 5. 更换国内软件仓库镜像源加快下载速度 ​ 使用 vim 编辑器修改 /etc/pacman.d/mirrorlist 文件。将 pacman 软件仓库源更换为国内软件仓库镜像源： zsh vim /etc/pacman.d/mirrorlist ℹ️ 提示 如果不会使用 vim 编辑器，请参阅 这里 。 vim 编辑器在安装和配置系统的过程中还需要使用多次。 放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下： mirrorlist Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站 Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站 Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站 Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站 修改完成的 /etc/pacman.d/mirrorlist 文件如图所示。 ℹ️ 提示 如果发现 /etc/pacman.d/mirrorlist 是如图这个样子的，那么说明你禁用 reflector 服务晚了。 reflector 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。 ⚠️ 注意 前车之鉴 —— 请不在这一步中添加 archlinuxcn 源！如果你在 /etc/pacman.conf 中添加了内容，请将它们删掉。 6. 分区和格式化（使用 Btrfs 文件系统） ​ 6-1. 分区 ​ ☢️ 警告 分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！ 同时，请提前做好数据备份，防止数据丢失！ 本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。 / 根目录： &gt;= 128GB （和用户主目录在同一个 Btrfs 文件系统上） /home 用户主目录： &gt;= 128GB （和根目录在同一个 Btrfs 文件系统上） /boot EFI 分区： 256MB （由电脑厂商或 Windows 决定，无需再次创建） Swap 分区： &gt;= 电脑实际运行内存的 60% （设置这个大小是为了配置休眠准备） ℹ️ 提示 因为采用 Btrfs 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。 通过 lsblk 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况： zsh lsblk # 显示当前分区情况 此处要分区和安装 archlinux 的磁盘即为 sda 。请根据你的实际情况判断！ ℹ️ 提示 为了模拟真实的环境，笔者手动创建了三个分区分别代表： sda1 —— EFI 分区 sda2 —— win10 下的 C 盘（象征性的分了 1GB ） sda3 —— win10 下的 D 盘（象征性的分了 1GB ） ℹ️ 提示 注意此处并不会显出出未分配的磁盘空间！只有在使用 cfdisk 执行分区操作后才会显示出来。 ℹ️ 提示 如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 sdx 而是 nvmexn1 。 接下来使用 cfdisk 命令对磁盘分区（对于 SATA 协议的硬盘， x 为字母 a 、 b 或 c 等等；对于 NVME 协议的硬盘， x 为数字 0 、 1 或 2 等等，请根据实际情况判断）： SATA NVME zsh cfdisk /dev/sdx # 对安装 archlinux 的磁盘分区 zsh cfdisk /dev/nvmexn1 # 对安装 archlinux 的磁盘分区 进入 cfdisk 分区工具之后，你会看到如图所示的界面。通过方向键 ↑ 和 ↓ 可以在要操作磁盘分区或空余空间中移动；通过方向键 ← 和 → 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。 首先创建 Swap 分区。选中 Free space &gt; 再选中操作 [New] &gt; 然后按下回车 Enter 以新建 swap 分区（类似 Windows 的交换文件） 按下回车后会提示输入 分区大小 ，Swap 分区建议为 电脑内存大小的 60% ，或者和内存大小相等 &gt; 然后按下回车 Enter ℹ️ 提示 单位可以自行输入，如 GB 、 MB 等等。 默认新建的类型是 Linux filesystem ，我们需要将类型更改为 Linux swap 。选中操作 [Type] &gt; 然后按下回车 Enter &gt; 通过方向键 ↑ 和 ↓ 选中 Linux swap &gt; 最后按下回车 Enter 我们再只需要一个分区即可（因为使用 Btrfs 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 Free space &gt; 再选中操作 [New] &gt; 然后按下回车 Enter 以新建分区 输入 分区大小 （默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 Enter 分区类型默认即可，无需更改。接下来选中操作 [Write] 并回车 Enter &gt; 输入 yes 并回车 Enter 确认分区操作 ⚠️ 注意 只有写入了操作分区表才会更改。 选中操作 [Quit] 并回车 Enter 以退出 cfdisk 分区工具 ☢️ 警告 再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！ 常见的错误包括不小心把 Windows 的分区删掉了 😥。 分区完成后，使用 fdisk 或 lsblk 命令复查分区情况： fdisk lsblk zsh fdisk -l # 复查磁盘情况 zsh lsblk # 复查磁盘情况 6-2. 格式化并创建 Btrfs 子卷 ​ 6-2.0. 格式化 EFI 分区 ​ SATA NVME zsh mkfs.fat -F32 /dev/sdxn zsh mkfs.fat -F32 /dev/nvmexn1pn ⚠️ 注意 如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。 6-2-1. 格式化 Swap 分区 ​ 通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 x 和 n （下同）： SATA NVME zsh mkswap /dev/sdxn zsh mkswap /dev/nvmexn1pn 6-2-2. 格式化 Btrfs 分区 ​ 首先我们需要将整一个分区格式化为 Btrfs 文件系统。使用如下命令进行格式化： SATA NVME zsh mkfs.btrfs -L myArch /dev/sdxn zsh mkfs.btrfs -L myArch /dev/nvmexn1pn 📑 命令参数说明： -L 选项后指定该分区的 LABLE ，这里以 myArch 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义 为了创建子卷，我们需要先将 Btrfs 分区挂载到 /mnt 下： SATA NVME zsh mount -t btrfs -o compress=zstd /dev/sdxn /mnt zsh mount -t btrfs -o compress=zstd /dev/nvmexn1pn /mnt 📑 命令参数说明： -t 选项后指定挂载分区文件系统类型 -o 选项后添加挂载参数： compress=zstd —— 开启透明压缩 使用 df 命令复查挂载情况： zsh df -h # -h 选项会使输出以人类可读的单位显示 6-2-3. 创建 Btrfs 子卷 ​ 通过以下命令创建两个 Btrfs 子卷，之后将分别挂载到 / 根目录和 /home 用户主目录： zsh btrfs subvolume create /mnt/@ # 创建 / 目录子卷 btrfs subvolume create /mnt/@home # 创建 /home 目录子卷 ⚠️ 注意 除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 timeshift 只支持这种子卷布局。 通过以下命令复查子卷情况： zsh btrfs subvolume list -p /mnt 子卷创建好后，我们需要将 /mnt 卸载掉，以挂载子卷： zsh umount /mnt 7. 挂载 ​ 在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷： SATA NVME zsh mount -t btrfs -o subvol=/@,compress=zstd /dev/sdxn /mnt # 挂载 / 目录 mkdir /mnt/home # 创建 /home 目录 mount -t btrfs -o subvol=/@home,compress=zstd /dev/sdxn /mnt/home # 挂载 /home 目录 mkdir -p /mnt/boot # 创建 /boot 目录 mount /dev/sdxn /mnt/boot # 挂载 /boot 目录 swapon /dev/sdxn # 挂载交换分区 zsh mount -t btrfs -o subvol=/@,compress=zstd /dev/nvmexn1pn /mnt # 挂载 / 目录 mkdir /mnt/home # 创建 /home 目录 mount -t btrfs -o subvol=/@home,compress=zstd /dev/nvmexn1pn /mnt/home # 挂载 /home 目录 mkdir -p /mnt/boot # 创建 /boot 目录 mount /dev/nvmexn1pn /mnt/boot # 挂载 /boot 目录 swapon /dev/nvmexn1pn # 挂载交换分区 使用 df 命令复查挂载情况： zsh df -h 使用 free 命令复查 Swap 分区挂载情况： zsh free -h # -h 选项会使输出以人类可读的单位显示 8. 安装系统 ​ 通过如下命令使用 pacstrap 脚本安装基础包： bash pacstrap /mnt base base-devel linux linux-firmware btrfs-progs # 如果使用btrfs文件系统，额外安装一个btrfs-progs包 📑 命令参数说明： base-devel —— base-devel 在 AUR 包的安装过程中是必须用到的 linux —— 内核软件包，这里建议先不要替换为其它内核 如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 archlinux-keyring 解决此问题 bash pacman -S archlinux-keyring 通过如下命令使用 pacstrap 脚本安装其它必要的功能性软件： bash pacstrap /mnt networkmanager vim sudo zsh zsh-completions 📑 命令参数说明： zsh —— zsh-completions 如果你是 bash 的爱好者，请把这两个包换成 bash-completion 如果你是第一次接触*nix 系统的新手，不建议换成 bash 经过一系列安装时提示信息的刷屏，这些包就安装好了。 ⚠️ 注意 在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。 很多人在后续的步骤中报错就是因为这里漏装了东西。 如果报错，请 检查拼写 ，同时请确保之前的步骤 更换国内软件仓库镜像源加快下载速度 中 没有 添加 archlinuxcn 源。 9. 生成 fstab 文件 ​ fstab 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 genfstab 自动根据当前挂载情况生成并写入 fstab 文件： zsh genfstab -U /mnt &gt; /mnt/etc/fstab 复查一下 /mnt/etc/fstab 确保没有错误： zsh cat /mnt/etc/fstab 若为 NVME 协议的硬盘，输出结果应该与此类似： fstab # /dev/nvme0n1p6 / btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0 UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 / btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0 # /dev/nvme0n1p1 /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2 UUID=522C-80C6 /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2 # /dev/nvme0n1p6 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0 UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0 # /dev/nvme0n1p5 none swap defaults 0 0 UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none swap defaults 0 0 10. change root ​ 使用以下命令把系统环境切换到新系统下： zsh arch-chroot /mnt 此时，原来安装盘下的 /mnt 目录就变成了新系统的 / 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。 11. 设置主机名与时区 ​ 首先在 /etc/hostname 设置主机名： bash vim /etc/hostname 加入你想为主机取的主机名，这里比如叫 myarch。 ℹ️ 提示 主机名不要包含特殊字符以及空格。 接下来在 /etc/hosts 设置与其匹配的条目： bash vim /etc/hosts 加入如下内容： bash 127.0.0.1 localhost : :1 localhost 127.0.1.1 myarch.localdomain myarch ℹ️ 提示 你可以使用 Tab 对齐。 ℹ️ 提示 某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 No protocol specified qt.qpa.xcb: could not connect to display 的错误。这种情况极为少见。 但不管如何，即使没有问题，我们都应该设置好主机名。 随后设置时区，在 /etc/localtime 下用 /usr 中合适的时区创建符号链接： bash ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 🍧 碎碎念 ​ 不要找北京啦！这里没有北京，只有上海啦！🚀 ℹ️ 提示 同时，你也可以使用其它时区： 12. 硬件时间设置 ​ 使用如下命令将系统时间同步到硬件时间： bash hwclock --systohc 13. 设置 Locale ​ Locale 决定了软件使用的语言、书写习惯和字符集。 编辑 /etc/locale.gen ，去掉 en_US.UTF-8 UTF-8 以及 zh_CN.UTF-8 UTF-8 行前的注释符号（ # ）： bash vim /etc/locale.gen ℹ️ 提示 有几个选项极具迷惑性，请不要取消注释错了。 然后使用如下命令生成 locale ： bash locale-gen 向 /etc/locale.conf 输入内容： bash echo ''LANG=en_US.UTF-8'' &gt; /etc/locale.conf ⚠️ 注意 不推荐在此设置任何中文 locale ，会导致 tty 乱码。 14. 为 root 用户设置密码 ​ bash passwd root ℹ️ 提示 根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。 15. 安装微码 ​ 通过以下命令安装对应芯片制造商的微码： bash pacman -S intel-ucode # Intel pacman -S amd-ucode # AMD ℹ️ 提示 🎉 恭喜你！这是你在新系统中第一次使用 pacman 软件包管理器安装软件！在这里一路回车完成安装即可。 如果你不会使用，请参阅 这里 。 16. 安装引导程序 ​ 如有需要可以参阅 ArchWiki 相关内容 。 安装相应的包： bash pacman -S grub efibootmgr os-prober 📑 命令参数说明： -S 选项后指定要通过 pacman 包管理器安装的包： grub —— 启动引导器 efibootmgr —— efibootmgr 被 grub 脚本用来将启动项写入 NVRAM os-prober —— 为了能够引导 win10，需要安装 os-prober 以检测到它 安装 GRUB 到 EFI 分区： bash grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH 📑 命令参数说明： --efi-directory=/boot —— 将 grubx64.efi 安装到之前的指定位置（EFI 分区） --bootloader-id=ARCH —— 取名为 ARCH 接下来使用 vim 编辑 /etc/default/grub 文件： bash vim /etc/default/grub 进行如下修改： 去掉 GRUB_CMDLINE_LINUX_DEFAULT 一行中最后的 quiet 参数 把 loglevel 的数值从 3 改成 5 。这样是为了后续如果出现系统错误，方便排错 加入 nowatchdog 参数，这可以显著提高开关机速度 为了引导 win10，则还需要添加新的一行 GRUB_DISABLE_OS_PROBER=false grub # GRUB boot loader configuration GRUB_DEFAULT=0 GRUB_TIMEOUT=5 GRUB_DISTRIBUTOR="Arch" GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog" GRUB_CMDLINE_LINUX="" GRUB_DISABLE_OS_PROBER=false ... ℹ️ 提示 nowatchdog 参数无法禁用英特尔的看门狗硬件，改为 modprobe.blacklist=iTCO_wdt 即可。如有需要可以参考 ArchWiki 对应内容 最后生成 GRUB 所需的配置文件： bash grub-mkconfig -o /boot/grub/grub.cfg 若引导了 win10，则输出应该包含倒数第二行： 若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令 ℹ️ 提示 1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 efi 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 GRUB 。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了）， chroot 到 /mnt ，然后你可以重新用 --removable 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 ArchWiki 对应内容 。 bash grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH --removable 2. os-prober 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。 17. 完成安装 ​ 输入以下命令： bash exit # 退回安装环境 umount -R /mnt # 卸载新分区 reboot # 重启 注意， 重启前要先拔掉优盘 ，否则你重启后还是进安装程序而不是安装好的系统。 ℹ️ 提示 虚拟机直接重启即可。 如图即为 GRUB 引导界面。 ℹ️ 提示 若引导了 win10 也会显示出来。 ℹ️ 提示 若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。 你应该在步骤 5. 获取 Bitlocker 恢复密钥 中已经知晓了 Bitlocker 解锁密钥。 若无法从 aka.ms 相关页面 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。 重启后使用 root 账户登录系统： 设置开机自启并立即启动 networkmanager 服务，即可连接网络： bash systemctl enable --now NetworkManager # 设置开机自启并立即启动 NetworkManager 服务 ping www.bilibili.com # 测试网络连接 若为无线连接，则需要在启动 networkmanager 后使用 nmcli 连接网络： bash nmcli dev wifi list # 显示附近的 Wi-Fi 网络 nmcli dev wifi connect "Wi-Fi名（SSID）" password "网络密码" # 连接指定的无线网络 也可以使用 nmtui 来配置网络 bash nmtui ℹ️ 提示 neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 fastfetch 代替 neofetch 。 fastfetch 可以将系统信息和发行版 logo 一并打印出来。通过 pacman 安装 fastfetch ： bash pacman -S fastfetch 使用 fastfetch 打印系统信息： bash fastfetch 🍧 碎碎念 ​ 又到了 fastfetch 的时间了吗？ 🎉 祝贺！🎉 ​ 到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！ 如果你对本节的部分步骤不理解，请仔细阅读下一节 基础安装详解 。在此之后，我们来安装图形界面。 ℹ️ 提示 你可以使用以下命令关机： bash shutdown -h now # 或者 poweroff ℹ️ 提示 archlinux 在 2021 年 4 月在安装镜像中内置了一个 安装脚本 ，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于： 只提供有限的文件系统格式 只可限定在一个磁盘 不能指定软件仓库镜像源 只提供有限的桌面选择 自动分区不可手动干预 输入错误直接崩溃退出 仅支持 UEFI 等 不建议使用这个安装脚本，除了以上各种原因，初学者也无法在这种安装过程中学到任何东西。如果你因为某些原因需要快速启动一个基础的 archlinux 环境，那么可以尝试此脚本。', '2026-11-06 11:25:11.2+08'::timestamptz, '2026-11-06 11:25:11.2+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-06 11:40:45.102511+08'::timestamptz),
  ('aab6e375-c564-4d2c-872c-46601ccaf204'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'gogs-diary · 核心技术方案', '<h2>1. Gogs 数据采集</h2>
<h3>1.1 push 记录（SQLite 直读）</h3>
<pre><code class="language-sql">SELECT act_user_name, repo_user_name, repo_name, ref_name, content, created_unix
FROM action
WHERE op_type = 5
  AND created_unix &gt;= ?
  AND created_unix &lt; ?
ORDER BY created_unix
</code></pre>
<p>op_type=5 对应 push 事件。只读连接，不写数据库。</p>
<h3>1.2 改动文件（Gogs API）</h3>
<p>Gogs action 表没有 commit_sha 列，改动文件通过 Gogs API 获取：</p>
<pre><code>GET /api/v1/repos/{owner}/{repo}/commits?since={start}&amp;until={end}
</code></pre>
<p>返回的每个 commit 包含 files 列表（filename + status）。日记模式才查，周/月/年报不需要。</p>
<h2>2. 思源文档操作</h2>
<h3>2.1 创建文档链</h3>
<p>按 parts 逐级创建：​<code>daily note</code>​ → ​<code>2026</code>​ → ​<code>10</code>​ → ​<code>第4周</code>​ → ​<code>2026-10-19</code>。</p>
<p>先通过 SQL 查询文档是否已存在：</p>
<pre><code class="language-sql">SELECT id FROM blocks WHERE type=&#39;d&#39; AND box=&#39;{notebook_id}&#39; AND hpath=&#39;{path}&#39; LIMIT 1
</code></pre>
<p>不存在则调 ​<code>createDocWithMd</code> 创建。</p>
<h3>2.2 追加内容</h3>
<p>文档已存在时，调 ​<code>appendBlock</code> 追加内容。标题层级由代码控制：</p>
<p><strong>日记文档：</strong></p>
<pre><code class="language-markdown">## 自动生成（16:30）
### &lt;仓库名&gt;
...
### 总结
...
</code></pre>
<p><strong>周/月/年报文档：</strong></p>
<pre><code class="language-markdown"># 周报（10月12日 ~ 10月18日）
---
## 自动生成（16:30）
...
</code></pre>
<h3>2.3 读取手写内容</h3>
<p>调 ​<code>/api/filetree/getDoc</code>​（参数是 ​<code>id</code>），拿到文档 markdown 内容。截取&#34;自动生成&#34;标记之前的部分，就是用户手写的内容。AI 生成的部分跳过，不会循环喂给下一级。</p>
<h2>3. 四级总结层级</h2>
<pre><code>日记（读 Gogs push + 改动文件）
  ↓ 周报读手写日记
周报（读 Gogs push + 手写日记）
  ↓ 月报读手写周报
月报（读 Gogs push + 手写周报）
  ↓ 年报读手写月报
年报（读 Gogs push + 手写月报）
</code></pre>
<p>每一级的输入 = Gogs push 汇总 + 上一级文档的手写内容。不直接读下下级，避免数据量过大。</p>
<h2>4. 周编号</h2>
<p>以周一为一周开始。每月1号所在的那周为第1周，之后每跨一个周一加一周。跨月的周按周一所在月份归档。</p>
<h2>5. 补历史数据</h2>
<pre><code class="language-bash">uv run python -m gogs_diary.main daily --date 2026-10-18
uv run python -m gogs_diary.main weekly --date 2026-10-15
</code></pre>
<p>指定日期后，程序会自动算出对应的时间范围和文档路径。</p>
', 'private', NULL, 'gogs-diary · 核心技术方案 1. Gogs 数据采集 1.1 push 记录（SQLite 直读） SELECT act_user_name, repo_user_name, repo_name, ref_name, content, created_unix FROM action WHERE op_type = 5 AND created_unix &gt;= ? AND created_unix &lt; ? ORDER BY created_unix op_type=5 对应 push 事件。只读连接，不写数据库。 1.2 改动文件（Gogs API） Gogs action 表没有 commit_sha 列，改动文件通过 Gogs API 获取： GET /api/v1/repos/{owner}/{repo}/commits?since={start}&amp;until={end} 返回的每个 commit 包含 files 列表（filename + status）。日记模式才查，周/月/年报不需要。 2. 思源文档操作 2.1 创建文档链 按 parts 逐级创建：​ daily note ​ → ​ 2026 ​ → ​ 10 ​ → ​ 第4周 ​ → ​ 2026-10-19 。 先通过 SQL 查询文档是否已存在： SELECT id FROM blocks WHERE type=&#39;d&#39; AND box=&#39;{notebook_id}&#39; AND hpath=&#39;{path}&#39; LIMIT 1 不存在则调 ​ createDocWithMd 创建。 2.2 追加内容 文档已存在时，调 ​ appendBlock 追加内容。标题层级由代码控制： 日记文档： ## 自动生成（16:30） ### &lt;仓库名&gt; ... ### 总结 ... 周/月/年报文档： # 周报（10月12日 ~ 10月18日） --- ## 自动生成（16:30） ... 2.3 读取手写内容 调 ​ /api/filetree/getDoc ​（参数是 ​ id ），拿到文档 markdown 内容。截取&#34;自动生成&#34;标记之前的部分，就是用户手写的内容。AI 生成的部分跳过，不会循环喂给下一级。 3. 四级总结层级 日记（读 Gogs push + 改动文件） ↓ 周报读手写日记 周报（读 Gogs push + 手写日记） ↓ 月报读手写周报 月报（读 Gogs push + 手写周报） ↓ 年报读手写月报 年报（读 Gogs push + 手写月报） 每一级的输入 = Gogs push 汇总 + 上一级文档的手写内容。不直接读下下级，避免数据量过大。 4. 周编号 以周一为一周开始。每月1号所在的那周为第1周，之后每跨一个周一加一周。跨月的周按周一所在月份归档。 5. 补历史数据 uv run python -m gogs_diary.main daily --date 2026-10-18 uv run python -m gogs_diary.main weekly --date 2026-10-15 指定日期后，程序会自动算出对应的时间范围和文档路径。', '2026-10-31 17:43:09.586064+08'::timestamptz, '2026-10-31 17:43:09.586064+08'::timestamptz, 'a1e7e98b-f958-4d11-9727-964a23a0415e'::uuid, 0, NULL),
  ('c9dd856e-0e52-4c39-8ee3-4cee5b00275b'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '沙利文后台系统', '<div id="readability-page-1" class="page"><div data-v-73470880="" data-prefix="el" data-v-8201b000="" data-v-34116364="" id="app" data-v-app=""><table><colgroup><col name="el-table_1_column_1" width="404"><col name="el-table_1_column_2" width="134"><col name="el-table_1_column_3" width="134"><col name="el-table_1_column_4" width="160"><col name="el-table_1_column_5" width="442"><col name="el-table_1_column_6" width="80"><col name="el-table_1_column_7" width="321"><col name="el-table_1_column_8" width="150"></colgroup><!--v-if--><tbody tabindex="-1"><tr><td colspan="1" rowspan="1"><p>专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:23:53</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:34</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文全球研讨会预告（11/4 - 11/12）</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:41:26</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:40:33</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:54</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:04</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981889121551301feca09" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981889121551301feca09</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>校招 | 2027，与沙利文中国一起成长，迎接无限可能！</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-11-02 11:48:02</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:39</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式）</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:12</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:31:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:30:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:28:19</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖”</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-10-29 10:26:56</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr></tbody><!--v-if--></table><!--v-if--><!--v-if--></div></div>', 'private', NULL, '沙利文后台系统 专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读 传媒中心 公司动态 2026-11-04 11:23:53 https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊 最新洞察 企业研究 2026-11-04 11:22:59 https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》 最新洞察 趋势研读 2026-11-04 11:22:34 https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文全球研讨会预告（11/4 - 11/12） 传媒中心 公司动态 2026-11-03 14:41:26 https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》 最新洞察 趋势研读 2026-11-03 14:40:33 https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台 传媒中心 公司动态 2026-11-03 14:39:54 https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行 传媒中心 公司动态 2026-11-03 14:39:04 https://www.frostchina.com/content/news/detail/6ae981889121551301feca09 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 校招 | 2027，与沙利文中国一起成长，迎接无限可能！ — — 2026-11-02 11:48:02 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》 最新洞察 趋势研读 2026-10-30 11:28:39 https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》 最新洞察 趋势研读 2026-10-30 11:28:27 https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式） 最新洞察 趋势研读 2026-10-30 11:28:12 https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》 最新洞察 趋势研读 2026-10-29 10:31:27 https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势 传媒中心 公司动态 2026-10-29 10:30:59 https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖 最新洞察 企业研究 2026-10-29 10:28:19 https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖” — — 2026-10-29 10:26:56 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 —', '2026-11-05 11:35:31.080679+08'::timestamptz, '2026-11-05 11:35:31.080679+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:35:46.665238+08'::timestamptz),
  ('5595efba-f221-4806-9a91-ad05cd4a5b08'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'archlinux 安装', '<h2>1. 确认是否为 UEFI 模式 <a target="_blank" rel="noopener noreferrer nofollow" href="#_1-确认是否为-uefi-模式">​</a></h2><p>我们先来确认一下是否为 <code>UEFI</code> 模式：</p><pre class="hljs"><code>ls /sys/firmware/efi/efivars</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/7e9ffb9a2afd541ddcca19ecc245718f.png" alt="check-efi"><p>若输出了一堆东西（<code>efi</code> 变量），则说明已在 <code>UEFI</code> 模式。否则请确认你的启动方式是否为 <code>UEFI</code>。</p><h2>2. 连接网络 <a target="_blank" rel="noopener noreferrer nofollow" href="#_2-连接网络">​</a></h2><blockquote><p>ℹ️ 提示</p><p>archlinux 的安装<strong>必须</strong>要求网络环境。</p><p>ℹ️ 提示</p><p>若为虚拟机且按照上一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-virt.html#_3-%E9%85%8D%E7%BD%AE-virtualbox">虚拟机安装前的准备</a> 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。</p></blockquote><h3>若使用<strong>无线连接</strong> <a target="_blank" rel="noopener noreferrer nofollow" href="#若使用无线连接">​</a></h3><p>使用 <code>iwctl</code> 进行连接：</p><pre class="hljs"><code>iwctl # 进入交互式命令行device list # 列出无线网卡设备名，比如无线网卡看到叫 wlan0station wlan0 scan # 扫描网络station wlan0 get-networks # 列出所有 wifi 网络station wlan0 connect wifi-name # 进行连接，注意这里无法输入中文。回车后输入密码即可exit # 连接成功后退出</code></pre><blockquote><p>ℹ️ 提示</p><p>若无线网卡无法显示，请按照上一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-install.html#_1-%E7%A1%AE%E4%BF%9D%E7%BD%91%E7%BB%9C%E7%8E%AF%E5%A2%83">确保网络环境</a> 的说明<strong>确保你的无线网卡硬件开关处于打开状态</strong>。</p><p>你可以使用如下命令查看内核是否加载了你的无线网卡驱动。</p></blockquote><pre class="hljs"><code>lspci -k | grep Network</code></pre><p>以我的硬件为例，输出如下：</p><pre class="hljs"><code>00:14.3 Network controller: Intel Corporation Wi-Fi 6 AX201 (rev 20)</code></pre><p>如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 <code>WIFI</code></p><pre class="hljs"><code>rfkill list #查看无线连接 是否被禁用(blocked: yes)ip link set wlan0 up #比如无线网卡看到叫 wlan0</code></pre><p>若看到类似<code>Operation not possible due to RF-kill</code>的报错，继续尝试<code>rfkill unblock wifi</code>来解锁无线网卡。</p><p>zsh</p><pre class="hljs"><code>rfkill unblock wifi</code></pre><p>部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。</p><h3>若使用<strong>有线连接</strong> <a target="_blank" rel="noopener noreferrer nofollow" href="#若使用有线连接">​</a></h3><p>正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。</p><p>可以等待几秒等网络建立连接后再进行下一步测试网络的操作。</p><p>若笔记本没有网线接口请使用带网线接口的扩展坞。</p><h2>3. 测试网络连通性 <a target="_blank" rel="noopener noreferrer nofollow" href="#_3-测试网络连通性">​</a></h2><p>通过 <code>ping</code> 命令测试网络连通性：</p><p>zsh</p><pre class="hljs"><code>ping www.bilibili.com</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/4d711234e173867eb91cbccada70d0dd.png" alt="ping"><p>稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 <code>Ctrl</code> + <code>C</code> 手动退出 <code>ping</code> 命令。</p><blockquote><p>ℹ️ 提示</p><p>如果无线网络还是无法连接，请使用 <code>ip link</code> 命令查看无线网卡设备，使用 <code>ip link set &lt;设备名&gt; up</code> 命令激活对应的无线网卡。若看到类似 <code>Operation not possible due to RF-kill</code> 的报错，继续尝试 <code>rfkill unblock wifi</code> 来解锁无线网卡。</p><p>如有需要，可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinux.org/title/Network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Wireless_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E6%A3%80%E6%9F%A5%E8%AE%BE%E5%A4%87%E7%8A%B6%E6%80%81">ArchWiki 相关内容</a>。</p></blockquote><h2>4. 更新系统时钟 <a target="_blank" rel="noopener noreferrer nofollow" href="#_4-更新系统时钟">​</a></h2><p>使用 <code>timedatectl</code> 确保系统时间是准确的。这一步<strong>不是</strong>可选的，正确的系统时间对于部分程序来说非常重要：</p><p>zsh</p><pre class="hljs"><code>timedatectl set-ntp true # 将系统时间与网络时间进行同步timedatectl status # 检查服务状态</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/161741754b0badb9456bdc1fb2cca328.png" alt="time"><h2>5. 更换国内软件仓库镜像源加快下载速度 <a target="_blank" rel="noopener noreferrer nofollow" href="#_5-更换国内软件仓库镜像源加快下载速度">​</a></h2><p>使用 <code>vim</code> 编辑器修改 <code>/etc/pacman.d/mirrorlist</code> 文件。将 <code>pacman</code> 软件仓库源更换为国内软件仓库镜像源：</p><p>zsh</p><pre class="hljs"><code>vim /etc/pacman.d/mirrorlist</code></pre><p>ℹ️ 提示</p><p>如果不会使用 <code>vim</code> 编辑器，请参阅 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/advanced/system-ctl.html#%E7%BB%88%E7%AB%AF%E7%BC%96%E8%BE%91%E5%99%A8-vim-%E7%9A%84%E4%BD%BF%E7%94%A8">这里</a>。</p><p><code>vim</code> 编辑器在安装和配置系统的过程中还需要使用多次。</p><p>放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下：</p><p>mirrorlist</p><pre class="hljs"><code>Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/71c7b33c15cd6630f9ce08e818504730.png" alt="mirrorlist-1"><p>修改完成的 <code>/etc/pacman.d/mirrorlist</code> 文件如图所示。</p><blockquote><p>ℹ️ 提示</p><p>如果发现 <code>/etc/pacman.d/mirrorlist</code> 是如图这个样子的，那么说明你禁用 <code>reflector</code> 服务晚了。<code>reflector</code> 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。</p></blockquote><img src="https://note.vorin.icu/uploads/notes/2026/11/14a6dcf29c9548f821f0b2ca30b343c6.png" alt="mirrorlist-2"><blockquote><p>⚠️ 注意</p><p>前车之鉴 —— 请不在这一步中添加 <code>archlinuxcn</code> 源！如果你在 <code>/etc/pacman.conf</code> 中添加了内容，请将它们删掉。</p></blockquote><h2>6. 分区和格式化（使用 Btrfs 文件系统） <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-分区和格式化-使用-btrfs-文件系统">​</a></h2><h3>6-1. 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-1-分区">​</a></h3><p>☢️ 警告</p><p>分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！</p><p>同时，请提前做好数据备份，防止数据丢失！</p><p>本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。</p><ul><li><p><code>/</code> 根目录：<code>&gt;= 128GB</code>（和用户主目录在同一个 <code>Btrfs</code> 文件系统上）</p></li><li><p><code>/home</code> 用户主目录：<code>&gt;= 128GB</code>（和根目录在同一个 <code>Btrfs</code> 文件系统上）</p></li><li><p><code>/boot</code> EFI 分区：<code>256MB</code>（由电脑厂商或 Windows 决定，无需再次创建）</p></li><li><p>Swap 分区：<code>&gt;= 电脑实际运行内存的 60%</code>（设置这个大小是为了配置休眠准备）</p></li></ul><blockquote><p>ℹ️ 提示</p><p>因为采用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。</p></blockquote><ol><li><p>通过 <code>lsblk</code> 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况：</p></li></ol><pre class="hljs"><code>lsblk # 显示当前分区情况</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/016eb074a697dbbf3fc67e447406d906.png" alt="partition-1"><p>此处要分区和安装 archlinux 的磁盘即为 <code>sda</code>。请根据你的实际情况判断！</p><p>ℹ️ 提示</p><p>为了模拟真实的环境，笔者手动创建了三个分区分别代表：</p><ol><li><p><code>sda1</code> —— EFI 分区</p></li><li><p><code>sda2</code> —— win10 下的 C 盘（象征性的分了 <code>1GB</code>）</p></li><li><p><code>sda3</code> —— win10 下的 D 盘（象征性的分了 <code>1GB</code>）</p></li></ol><p>ℹ️ 提示</p><p>注意此处并不会显出出未分配的磁盘空间！只有在使用 <code>cfdisk</code> 执行分区操作后才会显示出来。</p><p>ℹ️ 提示</p><p>如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 <code>sdx</code> 而是 <code>nvmexn1</code>。</p><ol start="2"><li><p>接下来使用 <code>cfdisk</code> 命令对磁盘分区（对于 SATA 协议的硬盘，<code>x</code> 为字母 <code>a</code>、<code>b</code> 或 <code>c</code> 等等；对于 NVME 协议的硬盘，<code>x</code> 为数字 <code>0</code>、<code>1</code> 或 <code>2</code> 等等，请根据实际情况判断）：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>cfdisk /dev/sdx # 对安装 archlinux 的磁盘分区</code></pre><p>zsh</p><pre class="hljs"><code>cfdisk /dev/nvmexn1 # 对安装 archlinux 的磁盘分区</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/1e13934a1f04511c2e6ddd219ec5b4b2.png" alt="partition-2"><p>进入 <code>cfdisk</code> 分区工具之后，你会看到如图所示的界面。通过方向键 <code>↑</code> 和 <code>↓</code> 可以在要操作磁盘分区或空余空间中移动；通过方向键 <code>←</code> 和 <code>→</code> 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。</p><ol start="3"><li><p>首先创建 Swap 分区。选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建 <code>swap</code> 分区（类似 Windows 的交换文件）</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/740f059974d6a532798e88cad6709df9.png" alt="partition-3"><ol start="4"><li><p>按下回车后会提示输入 <code>分区大小</code>，Swap 分区建议为<strong>电脑内存大小的 60%</strong>，或者和内存大小相等 &gt; 然后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/07584afc577e71873270fcfcaf257210.png" alt="partition-4"><p>ℹ️ 提示</p><p>单位可以自行输入，如 <code>GB</code>、<code>MB</code> 等等。</p><ol start="5"><li><p>默认新建的类型是 <code>Linux filesystem</code>，我们需要将类型更改为 <code>Linux swap</code>。选中操作 <code>[Type]</code> &gt; 然后按下回车 <code>Enter</code> &gt; 通过方向键 <code>↑</code> 和 <code>↓</code> 选中 <code>Linux swap</code> &gt; 最后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/ce33cab00aa2eed6521056b197e1d0e3.png" alt="partition-5"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/5dfd710025e102444b2f0c275b239df0.png" alt="partition-6"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/d604b3eb1b89bb857033a5f85fd94a43.png" alt="partition-7"><ol start="6"><li><p>我们再只需要一个分区即可（因为使用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建分区</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/143318a7f8a966527ff63182a792f89a.png" alt="partition-8"><ol start="7"><li><p>输入 <code>分区大小</code>（默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/510ac8c843a89dc2c96af1c9a0946c91.png" alt="partition-9"><ol start="8"><li><p>分区类型默认即可，无需更改。接下来选中操作 <code>[Write]</code> 并回车 <code>Enter</code> &gt; 输入 <code>yes</code> 并回车 <code>Enter</code> 确认分区操作</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/7a67d13f48fd024e0a9b76a61caf0357.png" alt="partition-10"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/b17e518b2b7ab8670c6d9cad70450a25.png" alt="partition-11"><p>⚠️ 注意</p><p>只有写入了操作分区表才会更改。</p><ol start="9"><li><p>选中操作 <code>[Quit]</code> 并回车 <code>Enter</code> 以退出 <code>cfdisk</code> 分区工具</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/996e7763e7450a7e130dabd78cab57bb.png" alt="partition-12"><p>☢️ 警告</p><p>再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！</p><p>常见的错误包括不小心把 Windows 的分区删掉了 😥。</p><ol start="10"><li><p>分区完成后，使用 <code>fdisk</code> 或 <code>lsblk</code> 命令复查分区情况：</p></li></ol><p>fdisklsblk</p><p>zsh</p><pre class="hljs"><code>fdisk -l # 复查磁盘情况</code></pre><p>zsh</p><pre class="hljs"><code>lsblk # 复查磁盘情况</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/ff5d7b426d380404d0de4dba029b01ed.png" alt="partition-13"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/11e1037a913515a5d5c3dd8b4095f26e.png" alt="partition-14"><h3>6-2. 格式化并创建 Btrfs 子卷 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-格式化并创建-btrfs-子卷">​</a></h3><h4>6-2.0. 格式化 EFI 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-0-格式化-efi-分区">​</a></h4><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkfs.fat -F32 /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkfs.fat -F32 /dev/nvmexn1pn</code></pre><p>⚠️ 注意</p><p>如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。</p><h4>6-2-1. 格式化 Swap 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-1-格式化-swap-分区">​</a></h4><p>通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 <code>x</code> 和 <code>n</code>（下同）：</p><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkswap /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkswap /dev/nvmexn1pn</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/4fbedb00c5a03febda64833d3fd3f254.png" alt="mkswap"><h4>6-2-2. 格式化 Btrfs 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-2-格式化-btrfs-分区">​</a></h4><ol><li><p>首先我们需要将整一个分区格式化为 <code>Btrfs</code> 文件系统。使用如下命令进行格式化：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkfs.btrfs -L myArch /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkfs.btrfs -L myArch /dev/nvmexn1pn</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-L</code> 选项后指定该分区的 <code>LABLE</code>，这里以 <code>myArch</code> 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义</p></li></ul></blockquote><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/ca059c15ad2026eea54f378b39e4e03e.png" alt="mkbtrfs_step-1"><ol start="2"><li><p>为了创建子卷，我们需要先将 <code>Btrfs</code> 分区挂载到 <code>/mnt</code> 下：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o compress=zstd /dev/sdxn /mnt</code></pre><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o compress=zstd /dev/nvmexn1pn /mnt</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-t</code> 选项后指定挂载分区文件系统类型</p></li><li><p><code>-o</code> 选项后添加挂载参数：</p><ul><li><p><code>compress=zstd</code> —— 开启透明压缩</p></li></ul></li></ul></blockquote><ol start="3"><li><p>使用 <code>df</code> 命令复查挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>df -h # -h 选项会使输出以人类可读的单位显示</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/7690b7d52b0f67d6ca3ca6a55b83b221.png" alt="mkbtrfs_step-2"><h4>6-2-3. 创建 Btrfs 子卷 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-3-创建-btrfs-子卷">​</a></h4><ol><li><p>通过以下命令创建两个 <code>Btrfs</code> 子卷，之后将分别挂载到 <code>/</code> 根目录和 <code>/home</code> 用户主目录：</p></li></ol><p>zsh</p><pre class="hljs"><code>btrfs subvolume create /mnt/@ # 创建 / 目录子卷btrfs subvolume create /mnt/@home # 创建 /home 目录子卷</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/7a3a3da28ec004600ad88a6021edb709.png" alt="mkbtrfs_step-3"><p>⚠️ 注意</p><p>除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 <code>timeshift</code> 只支持这种子卷布局。</p><ol start="2"><li><p>通过以下命令复查子卷情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>btrfs subvolume list -p /mnt</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/7f9e2178de84670b3e77a9ba6e968ef4.png" alt="mkbtrfs_step-4"><ol start="3"><li><p>子卷创建好后，我们需要将 <code>/mnt</code> 卸载掉，以挂载子卷：</p></li></ol><p>zsh</p><pre class="hljs"><code>umount /mnt</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/edcf936430061b33ca22a72e16ad7d62.png" alt="mkbtrfs_step-5"><h2>7. 挂载 <a target="_blank" rel="noopener noreferrer nofollow" href="#_7-挂载">​</a></h2><ol><li><p>在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o subvol=/@,compress=zstd /dev/sdxn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/sdxn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/sdxn /mnt/boot # 挂载 /boot 目录swapon /dev/sdxn # 挂载交换分区</code></pre><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o subvol=/@,compress=zstd /dev/nvmexn1pn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/nvmexn1pn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/nvmexn1pn /mnt/boot # 挂载 /boot 目录swapon /dev/nvmexn1pn # 挂载交换分区</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/b894b8e0c9839b0526138aea5f4e78d6.png" alt="mount_step-1"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/506c4e34b10b8ff8ae17f63294e55850.png" alt="mount_step-2"><ol start="2"><li><p>使用 <code>df</code> 命令复查挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>df -h</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/d739761ac153fbc43d84973353e203ad.png" alt="mount_step-3"><ol start="3"><li><p>使用 <code>free</code> 命令复查 Swap 分区挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>free -h # -h 选项会使输出以人类可读的单位显示</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/62e1d02735c22000a5d04b98099467cd.png" alt="mount_step-4"><h2>8. 安装系统 <a target="_blank" rel="noopener noreferrer nofollow" href="#_8-安装系统">​</a></h2><ol><li><p>通过如下命令使用 <code>pacstrap</code> 脚本安装基础包：</p></li></ol><pre class="hljs"><code>pacstrap /mnt base base-devel linux linux-firmware btrfs-progs# 如果使用btrfs文件系统，额外安装一个btrfs-progs包</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>base-devel</code> —— <code>base-devel</code> 在 <code>AUR</code> 包的安装过程中是必须用到的</p></li><li><p><code>linux</code> —— 内核软件包，这里建议先不要替换为其它内核</p></li></ul></blockquote><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/ae760f45a34f6fddc4c4ec61036858e8.png" alt="pacstrap_step-1"><p>如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 <code>archlinux-keyring</code> 解决此问题</p><pre class="hljs"><code>pacman -S archlinux-keyring</code></pre><ol start="2"><li><p>通过如下命令使用 <code>pacstrap</code> 脚本安装其它必要的功能性软件：</p></li></ol><pre class="hljs"><code>pacstrap /mnt networkmanager vim sudo zsh zsh-completions</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>zsh</code> —— <code>zsh-completions</code> 如果你是 bash 的爱好者，请把这两个包换成<code>bash-completion</code></p></li><li><p>如果你是第一次接触*nix 系统的新手，不建议换成 bash</p></li></ul></blockquote><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/167d4cb5774ba77f01eefefd4e79100e.png" alt="pacstrap_step-2"><p>经过一系列安装时提示信息的刷屏，这些包就安装好了。</p><p>⚠️ 注意</p><p>在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。</p><p>很多人在后续的步骤中报错就是因为这里漏装了东西。</p><p>如果报错，请<strong>检查拼写</strong>，同时请确保之前的步骤 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-更换国内软件仓库镜像源加快下载速度">更换国内软件仓库镜像源加快下载速度</a> 中<strong>没有</strong>添加 <code>archlinuxcn</code> 源。</p><h2>9. 生成 fstab 文件 <a target="_blank" rel="noopener noreferrer nofollow" href="#_9-生成-fstab-文件">​</a></h2><ol><li><p><code>fstab</code> 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 <code>genfstab</code> 自动根据当前挂载情况生成并写入 <code>fstab</code> 文件：</p></li></ol><p>zsh</p><pre class="hljs"><code>genfstab -U /mnt &gt; /mnt/etc/fstab</code></pre><ol start="2"><li><p>复查一下 <code>/mnt/etc/fstab</code> 确保没有错误：</p></li></ol><p>zsh</p><pre class="hljs"><code>cat /mnt/etc/fstab</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/44b99b8a73112951d535f1baaa9d5e42.png" alt="fstab"><p>若为 NVME 协议的硬盘，输出结果应该与此类似：</p><p>fstab</p><pre class="hljs"><code># /dev/nvme0n1p6  /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@  0 0# /dev/nvme0n1p1  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro      0 2UUID=522C-80C6  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2# /dev/nvme0n1p6  /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0# /dev/nvme0n1p5  none  swap  defaults  0 0UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none  swap  defaults  0 0</code></pre><h2>10. change root <a target="_blank" rel="noopener noreferrer nofollow" href="#_10-change-root">​</a></h2><p>使用以下命令把系统环境切换到新系统下：</p><p>zsh</p><pre class="hljs"><code>arch-chroot /mnt</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/55fb96520f3e6f49388bd5c59a121842.png" alt="arch-chroot"><p>此时，原来安装盘下的 <code>/mnt</code> 目录就变成了新系统的 <code>/</code> 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。</p><h2>11. 设置主机名与时区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_11-设置主机名与时区">​</a></h2><ol><li><p>首先在 <code>/etc/hostname</code> 设置主机名：</p></li></ol><pre class="hljs"><code>vim /etc/hostname</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/e20d8d3ebdda3d1864638b4ed9322239.png" alt="set-name-and-timezone_step-1"><p>加入你想为主机取的主机名，这里比如叫 myarch。</p><blockquote><p>ℹ️ 提示</p><p>主机名不要包含特殊字符以及空格。</p></blockquote><ol start="2"><li><p>接下来在 <code>/etc/hosts</code> 设置与其匹配的条目：</p></li></ol><pre class="hljs"><code>vim /etc/hosts</code></pre><p>加入如下内容：</p><pre class="hljs"><code>127.0.0.1   localhost::1         localhost127.0.1.1   myarch.localdomain myarch</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/80a6d0135d981c9b639ef6b14f8ec283.png" alt="set-name-and-timezone_step-2"><blockquote><p>ℹ️ 提示</p><p>你可以使用 <code>Tab</code> 对齐。</p><p>ℹ️ 提示</p><p>某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 <code>No protocol specified qt.qpa.xcb: could not connect to display</code> 的错误。这种情况极为少见。</p><p>但不管如何，即使没有问题，我们都应该设置好主机名。</p></blockquote><ol start="3"><li><p>随后设置时区，在 <code>/etc/localtime</code> 下用 <code>/usr</code> 中合适的时区创建符号链接：</p></li></ol><pre class="hljs"><code>ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/134dcad892ba4b2119c3f810b442d979.png" alt="set-name-and-timezone_step-3"><blockquote><h4>🍧 碎碎念 <a target="_blank" rel="noopener noreferrer nofollow" href="#🍧-碎碎念">​</a></h4><p>不要找北京啦！这里没有北京，只有上海啦！🚀</p></blockquote><p>ℹ️ 提示</p><p>同时，你也可以使用其它时区：</p><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/629a744e7bce9f793ba977302de58742.png" alt="set-name-and-timezone_step-4"><h2>12. 硬件时间设置 <a target="_blank" rel="noopener noreferrer nofollow" href="#_12-硬件时间设置">​</a></h2><p>使用如下命令将系统时间同步到硬件时间：</p><pre class="hljs"><code>hwclock --systohc</code></pre><h2>13. 设置 Locale <a target="_blank" rel="noopener noreferrer nofollow" href="#_13-设置-locale">​</a></h2><p><code>Locale</code> 决定了软件使用的语言、书写习惯和字符集。</p><ol><li><p>编辑 <code>/etc/locale.gen</code>，去掉 <code>en_US.UTF-8 UTF-8</code> 以及 <code>zh_CN.UTF-8 UTF-8</code> 行前的注释符号（<code>#</code>）：</p></li></ol><pre class="hljs"><code>vim /etc/locale.gen</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/6aaa345096e18758d8e4b2aeba7e54b7.png" alt="locale_step-1"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/8b78db6150971360bb2673f714810840.png" alt="locale_step-2"><p>ℹ️ 提示</p><p>有几个选项极具迷惑性，请不要取消注释错了。</p><ol start="2"><li><p>然后使用如下命令生成 <code>locale</code>：</p></li></ol><pre class="hljs"><code>locale-gen</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/c7f9237c69e49eb1e32d8cde93faf967.png" alt="locale_step-3"><ol start="3"><li><p>向 <code>/etc/locale.conf</code> 输入内容：</p></li></ol><pre class="hljs"><code>echo ''LANG=en_US.UTF-8''  &gt; /etc/locale.conf</code></pre><p>⚠️ 注意</p><p>不推荐在此设置任何中文 <code>locale</code>，会导致 <code>tty</code> 乱码。</p><h2>14. 为 root 用户设置密码 <a target="_blank" rel="noopener noreferrer nofollow" href="#_14-为-root-用户设置密码">​</a></h2><pre class="hljs"><code>passwd root</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/516b20a72ccd89dfdc436e36826805e8.png" alt="password"><p>ℹ️ 提示</p><p>根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。</p><h2>15. 安装微码 <a target="_blank" rel="noopener noreferrer nofollow" href="#_15-安装微码">​</a></h2><p>通过以下命令安装对应芯片制造商的微码：</p><pre class="hljs"><code>pacman -S intel-ucode # Intelpacman -S amd-ucode # AMD</code></pre><p>ℹ️ 提示</p><p>🎉 恭喜你！这是你在新系统中第一次使用 <code>pacman</code> 软件包管理器安装软件！在这里一路回车完成安装即可。</p><p>如果你不会使用，请参阅 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/.html">这里</a>。</p><h2>16. 安装引导程序 <a target="_blank" rel="noopener noreferrer nofollow" href="#_16-安装引导程序">​</a></h2><p>如有需要可以参阅 <a target="_blank" rel="noreferrer" href="https://wiki.archlinux.org/title/GRUB_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)">ArchWiki 相关内容</a>。</p><ol><li><p>安装相应的包：</p></li></ol><pre class="hljs"><code>pacman -S grub efibootmgr os-prober</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-S</code> 选项后指定要通过 <code>pacman</code> 包管理器安装的包：</p><ul><li><p><code>grub</code> —— 启动引导器</p></li><li><p><code>efibootmgr</code> —— <code>efibootmgr</code> 被 <code>grub</code> 脚本用来将启动项写入 NVRAM</p></li><li><p><code>os-prober</code> —— 为了能够引导 win10，需要安装 <code>os-prober</code> 以检测到它</p></li></ul></li></ul></blockquote><ol start="2"><li><p>安装 GRUB 到 EFI 分区：</p></li></ol><pre class="hljs"><code>grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>--efi-directory=/boot</code> —— 将 <code>grubx64.efi</code> 安装到之前的指定位置（EFI 分区）</p></li><li><p><code>--bootloader-id=ARCH</code> —— 取名为 <code>ARCH</code></p></li></ul></blockquote><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/157b21463e390e2a9f510d1cc88826a4.png" alt="grub_step-1"><ol start="3"><li><p>接下来使用 <code>vim</code> 编辑 <code>/etc/default/grub</code> 文件：</p></li></ol><pre class="hljs"><code>vim /etc/default/grub</code></pre><p>进行如下修改：</p><ul><li><p>去掉 <code>GRUB_CMDLINE_LINUX_DEFAULT</code> 一行中最后的 <code>quiet</code> 参数</p></li><li><p>把 <code>loglevel</code> 的数值从 <code>3</code> 改成 <code>5</code>。这样是为了后续如果出现系统错误，方便排错</p></li><li><p>加入 <code>nowatchdog</code> 参数，这可以显著提高开关机速度</p></li></ul><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/11392c08e07e08fe58e2a8f5b1081457.png" alt="grub_step-2"><ul><li><p>为了引导 win10，则还需要添加新的一行 <code>GRUB_DISABLE_OS_PROBER=false</code></p></li></ul><p>grub</p><pre class="hljs"><code># GRUB boot loader configurationGRUB_DEFAULT=0GRUB_TIMEOUT=5GRUB_DISTRIBUTOR="Arch"GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"GRUB_CMDLINE_LINUX=""GRUB_DISABLE_OS_PROBER=false...</code></pre><p>ℹ️ 提示</p><p><code>nowatchdog</code> 参数无法禁用英特尔的看门狗硬件，改为 <code>modprobe.blacklist=iTCO_wdt</code> 即可。如有需要可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinuxcn.org/wiki/%E6%80%A7%E8%83%BD%E4%BC%98%E5%8C%96#%E7%9C%8B%E9%97%A8%E7%8B%97">ArchWiki 对应内容</a></p><ol start="4"><li><p>最后生成 <code>GRUB</code> 所需的配置文件：</p></li></ol><pre class="hljs"><code>grub-mkconfig -o /boot/grub/grub.cfg</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/b4b7c7a4e0d0f0974884a26028d6e899.png" alt="grub_step-3"><p>若引导了 win10，则输出应该包含倒数第二行：</p><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/e64d1fc8406dfde2ad9a244c14747070.png" alt="os-prober-1"><p>若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令</p><blockquote><p>ℹ️ 提示</p><p>1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 <code>efi</code> 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 <code>GRUB</code>。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了），<code>chroot</code> 到 <code>/mnt</code>，然后你可以重新用 <code>--removable</code> 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinuxcn.org/wiki/GRUB#%E7%BC%BA%E7%9C%81/%E5%90%8E%E5%A4%87%E5%90%AF%E5%8A%A8%E8%B7%AF%E5%BE%84">ArchWiki 对应内容</a>。</p></blockquote><pre class="hljs"><code>grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH --removable</code></pre><p>2.<code>os-prober</code> 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。</p><h2>17. 完成安装 <a target="_blank" rel="noopener noreferrer nofollow" href="#_17-完成安装">​</a></h2><ol><li><p>输入以下命令：</p></li></ol><pre class="hljs"><code>exit # 退回安装环境umount -R /mnt # 卸载新分区reboot # 重启</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/766bd448e0ab11d14d45ed55342f6076.png" alt="finish-install"><p>注意，<strong>重启前要先拔掉优盘</strong>，否则你重启后还是进安装程序而不是安装好的系统。</p><p>ℹ️ 提示</p><p>虚拟机直接重启即可。</p><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/63eea508bb8df5b93e6bc7b2980061ac.png" alt="last-step-1"><p>如图即为 GRUB 引导界面。</p><p>ℹ️ 提示</p><p>若引导了 win10 也会显示出来。</p><p>ℹ️ 提示</p><p>若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。</p><p>你应该在步骤 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-install.html#_5-%E8%8E%B7%E5%8F%96-bitlocker-%E6%81%A2%E5%A4%8D%E5%AF%86%E9%92%A5">5. 获取 Bitlocker 恢复密钥</a> 中已经知晓了 Bitlocker 解锁密钥。</p><p>若无法从 <a target="_blank" rel="noreferrer" href="https://aka.ms/myrecoverykey">aka.ms 相关页面</a> 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。</p><ol start="2"><li><p>重启后使用 root 账户登录系统：</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/73984846fea4c629a35b35a656f23d3c.png" alt="last-step-2"><ol start="3"><li><p>设置开机自启并立即启动 networkmanager 服务，即可连接网络：</p></li></ol><pre class="hljs"><code>systemctl enable --now NetworkManager # 设置开机自启并立即启动 NetworkManager 服务ping www.bilibili.com # 测试网络连接</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/d5089bdf6f69a37bb4caa1510f98f744.png" alt="last-step-3"><ol start="4"><li><p>若为无线连接，则需要在启动 <code>networkmanager</code> 后使用 <code>nmcli</code> 连接网络：</p></li></ol><pre class="hljs"><code>nmcli dev wifi list # 显示附近的 Wi-Fi 网络nmcli dev wifi connect "Wi-Fi名（SSID）" password "网络密码" # 连接指定的无线网络</code></pre><p>也可以使用 <code>nmtui</code> 来配置网络</p><pre class="hljs"><code>nmtui</code></pre><p>ℹ️ 提示</p><p>neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 <code>fastfetch</code> 代替 <code>neofetch</code>。</p><ol start="5"><li><p><code>fastfetch</code> 可以将系统信息和发行版 logo 一并打印出来。通过 <code>pacman</code> 安装 <code>fastfetch</code>：</p></li></ol><pre class="hljs"><code>pacman -S fastfetch</code></pre><p>使用 <code>fastfetch</code> 打印系统信息：</p><pre class="hljs"><code>fastfetch</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/b880d1920a5c09db5b03262406da0d7a.png" alt="fastfetch"><blockquote><h4>🍧 碎碎念 <a target="_blank" rel="noopener noreferrer nofollow" href="#🍧-碎碎念-1">​</a></h4><p>又到了 <code>fastfetch</code> 的时间了吗？</p></blockquote><h2>🎉 祝贺！🎉 <a target="_blank" rel="noopener noreferrer nofollow" href="#🎉-祝贺-🎉">​</a></h2><p>到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！</p><p>如果你对本节的部分步骤不理解，请仔细阅读下一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a>。在此之后，我们来安装图形界面。</p><p>ℹ️ 提示</p><p>你可以使用以下命令关机：</p><pre class="hljs"><code>shutdown -h now# 或者poweroff</code></pre><blockquote><p>ℹ️ 提示</p><p>archlinux 在 2021 年 4 月在安装镜像中内置了一个 <a target="_blank" rel="noreferrer" href="https://archlinux.org/packages/extra/any/archinstall/">安装脚本</a>，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于：</p><ol><li><p>只提供有限的文件系统格式</p></li><li><p>只可限定在一个磁盘</p></li><li><p>不能指定软件仓库镜像源</p></li><li><p>只提供有限的桌面选择</p></li><li><p>自动分区不可手动干预</p></li><li><p>输入错误直接崩溃退出</p></li><li><p>仅支持 UEFI 等</p></li></ol></blockquote><p></p>', 'private', NULL, 'archlinux 安装 1. 确认是否为 UEFI 模式 ​ 我们先来确认一下是否为 UEFI 模式： ls /sys/firmware/efi/efivars 若输出了一堆东西（ efi 变量），则说明已在 UEFI 模式。否则请确认你的启动方式是否为 UEFI 。 2. 连接网络 ​ ℹ️ 提示 archlinux 的安装 必须 要求网络环境。 ℹ️ 提示 若为虚拟机且按照上一节 虚拟机安装前的准备 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。 若使用 无线连接 ​ 使用 iwctl 进行连接： iwctl # 进入交互式命令行device list # 列出无线网卡设备名，比如无线网卡看到叫 wlan0station wlan0 scan # 扫描网络station wlan0 get-networks # 列出所有 wifi 网络station wlan0 connect wifi-name # 进行连接，注意这里无法输入中文。回车后输入密码即可exit # 连接成功后退出 ℹ️ 提示 若无线网卡无法显示，请按照上一节 确保网络环境 的说明 确保你的无线网卡硬件开关处于打开状态 。 你可以使用如下命令查看内核是否加载了你的无线网卡驱动。 lspci -k | grep Network 以我的硬件为例，输出如下： 00:14.3 Network controller: Intel Corporation Wi-Fi 6 AX201 (rev 20) 如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 WIFI rfkill list #查看无线连接 是否被禁用(blocked: yes)ip link set wlan0 up #比如无线网卡看到叫 wlan0 若看到类似 Operation not possible due to RF-kill 的报错，继续尝试 rfkill unblock wifi 来解锁无线网卡。 zsh rfkill unblock wifi 部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。 若使用 有线连接 ​ 正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。 可以等待几秒等网络建立连接后再进行下一步测试网络的操作。 若笔记本没有网线接口请使用带网线接口的扩展坞。 3. 测试网络连通性 ​ 通过 ping 命令测试网络连通性： zsh ping www.bilibili.com 稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 Ctrl + C 手动退出 ping 命令。 ℹ️ 提示 如果无线网络还是无法连接，请使用 ip link 命令查看无线网卡设备，使用 ip link set &lt;设备名&gt; up 命令激活对应的无线网卡。若看到类似 Operation not possible due to RF-kill 的报错，继续尝试 rfkill unblock wifi 来解锁无线网卡。 如有需要，可以参考 ArchWiki 相关内容 。 4. 更新系统时钟 ​ 使用 timedatectl 确保系统时间是准确的。这一步 不是 可选的，正确的系统时间对于部分程序来说非常重要： zsh timedatectl set-ntp true # 将系统时间与网络时间进行同步timedatectl status # 检查服务状态 5. 更换国内软件仓库镜像源加快下载速度 ​ 使用 vim 编辑器修改 /etc/pacman.d/mirrorlist 文件。将 pacman 软件仓库源更换为国内软件仓库镜像源： zsh vim /etc/pacman.d/mirrorlist ℹ️ 提示 如果不会使用 vim 编辑器，请参阅 这里 。 vim 编辑器在安装和配置系统的过程中还需要使用多次。 放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下： mirrorlist Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站 修改完成的 /etc/pacman.d/mirrorlist 文件如图所示。 ℹ️ 提示 如果发现 /etc/pacman.d/mirrorlist 是如图这个样子的，那么说明你禁用 reflector 服务晚了。 reflector 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。 ⚠️ 注意 前车之鉴 —— 请不在这一步中添加 archlinuxcn 源！如果你在 /etc/pacman.conf 中添加了内容，请将它们删掉。 6. 分区和格式化（使用 Btrfs 文件系统） ​ 6-1. 分区 ​ ☢️ 警告 分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！ 同时，请提前做好数据备份，防止数据丢失！ 本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。 / 根目录： &gt;= 128GB （和用户主目录在同一个 Btrfs 文件系统上） /home 用户主目录： &gt;= 128GB （和根目录在同一个 Btrfs 文件系统上） /boot EFI 分区： 256MB （由电脑厂商或 Windows 决定，无需再次创建） Swap 分区： &gt;= 电脑实际运行内存的 60% （设置这个大小是为了配置休眠准备） ℹ️ 提示 因为采用 Btrfs 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。 通过 lsblk 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况： lsblk # 显示当前分区情况 此处要分区和安装 archlinux 的磁盘即为 sda 。请根据你的实际情况判断！ ℹ️ 提示 为了模拟真实的环境，笔者手动创建了三个分区分别代表： sda1 —— EFI 分区 sda2 —— win10 下的 C 盘（象征性的分了 1GB ） sda3 —— win10 下的 D 盘（象征性的分了 1GB ） ℹ️ 提示 注意此处并不会显出出未分配的磁盘空间！只有在使用 cfdisk 执行分区操作后才会显示出来。 ℹ️ 提示 如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 sdx 而是 nvmexn1 。 接下来使用 cfdisk 命令对磁盘分区（对于 SATA 协议的硬盘， x 为字母 a 、 b 或 c 等等；对于 NVME 协议的硬盘， x 为数字 0 、 1 或 2 等等，请根据实际情况判断）： SATANVME zsh cfdisk /dev/sdx # 对安装 archlinux 的磁盘分区 zsh cfdisk /dev/nvmexn1 # 对安装 archlinux 的磁盘分区 进入 cfdisk 分区工具之后，你会看到如图所示的界面。通过方向键 ↑ 和 ↓ 可以在要操作磁盘分区或空余空间中移动；通过方向键 ← 和 → 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。 首先创建 Swap 分区。选中 Free space &gt; 再选中操作 [New] &gt; 然后按下回车 Enter 以新建 swap 分区（类似 Windows 的交换文件） 按下回车后会提示输入 分区大小 ，Swap 分区建议为 电脑内存大小的 60% ，或者和内存大小相等 &gt; 然后按下回车 Enter ℹ️ 提示 单位可以自行输入，如 GB 、 MB 等等。 默认新建的类型是 Linux filesystem ，我们需要将类型更改为 Linux swap 。选中操作 [Type] &gt; 然后按下回车 Enter &gt; 通过方向键 ↑ 和 ↓ 选中 Linux swap &gt; 最后按下回车 Enter 我们再只需要一个分区即可（因为使用 Btrfs 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 Free space &gt; 再选中操作 [New] &gt; 然后按下回车 Enter 以新建分区 输入 分区大小 （默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 Enter 分区类型默认即可，无需更改。接下来选中操作 [Write] 并回车 Enter &gt; 输入 yes 并回车 Enter 确认分区操作 ⚠️ 注意 只有写入了操作分区表才会更改。 选中操作 [Quit] 并回车 Enter 以退出 cfdisk 分区工具 ☢️ 警告 再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！ 常见的错误包括不小心把 Windows 的分区删掉了 😥。 分区完成后，使用 fdisk 或 lsblk 命令复查分区情况： fdisklsblk zsh fdisk -l # 复查磁盘情况 zsh lsblk # 复查磁盘情况 6-2. 格式化并创建 Btrfs 子卷 ​ 6-2.0. 格式化 EFI 分区 ​ SATANVME zsh mkfs.fat -F32 /dev/sdxn zsh mkfs.fat -F32 /dev/nvmexn1pn ⚠️ 注意 如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。 6-2-1. 格式化 Swap 分区 ​ 通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 x 和 n （下同）： SATANVME zsh mkswap /dev/sdxn zsh mkswap /dev/nvmexn1pn 6-2-2. 格式化 Btrfs 分区 ​ 首先我们需要将整一个分区格式化为 Btrfs 文件系统。使用如下命令进行格式化： SATANVME zsh mkfs.btrfs -L myArch /dev/sdxn zsh mkfs.btrfs -L myArch /dev/nvmexn1pn 📑 命令参数说明： -L 选项后指定该分区的 LABLE ，这里以 myArch 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义 为了创建子卷，我们需要先将 Btrfs 分区挂载到 /mnt 下： SATANVME zsh mount -t btrfs -o compress=zstd /dev/sdxn /mnt zsh mount -t btrfs -o compress=zstd /dev/nvmexn1pn /mnt 📑 命令参数说明： -t 选项后指定挂载分区文件系统类型 -o 选项后添加挂载参数： compress=zstd —— 开启透明压缩 使用 df 命令复查挂载情况： zsh df -h # -h 选项会使输出以人类可读的单位显示 6-2-3. 创建 Btrfs 子卷 ​ 通过以下命令创建两个 Btrfs 子卷，之后将分别挂载到 / 根目录和 /home 用户主目录： zsh btrfs subvolume create /mnt/@ # 创建 / 目录子卷btrfs subvolume create /mnt/@home # 创建 /home 目录子卷 ⚠️ 注意 除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 timeshift 只支持这种子卷布局。 通过以下命令复查子卷情况： zsh btrfs subvolume list -p /mnt 子卷创建好后，我们需要将 /mnt 卸载掉，以挂载子卷： zsh umount /mnt 7. 挂载 ​ 在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷： SATANVME zsh mount -t btrfs -o subvol=/@,compress=zstd /dev/sdxn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/sdxn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/sdxn /mnt/boot # 挂载 /boot 目录swapon /dev/sdxn # 挂载交换分区 zsh mount -t btrfs -o subvol=/@,compress=zstd /dev/nvmexn1pn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/nvmexn1pn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/nvmexn1pn /mnt/boot # 挂载 /boot 目录swapon /dev/nvmexn1pn # 挂载交换分区 使用 df 命令复查挂载情况： zsh df -h 使用 free 命令复查 Swap 分区挂载情况： zsh free -h # -h 选项会使输出以人类可读的单位显示 8. 安装系统 ​ 通过如下命令使用 pacstrap 脚本安装基础包： pacstrap /mnt base base-devel linux linux-firmware btrfs-progs# 如果使用btrfs文件系统，额外安装一个btrfs-progs包 📑 命令参数说明： base-devel —— base-devel 在 AUR 包的安装过程中是必须用到的 linux —— 内核软件包，这里建议先不要替换为其它内核 如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 archlinux-keyring 解决此问题 pacman -S archlinux-keyring 通过如下命令使用 pacstrap 脚本安装其它必要的功能性软件： pacstrap /mnt networkmanager vim sudo zsh zsh-completions 📑 命令参数说明： zsh —— zsh-completions 如果你是 bash 的爱好者，请把这两个包换成 bash-completion 如果你是第一次接触*nix 系统的新手，不建议换成 bash 经过一系列安装时提示信息的刷屏，这些包就安装好了。 ⚠️ 注意 在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。 很多人在后续的步骤中报错就是因为这里漏装了东西。 如果报错，请 检查拼写 ，同时请确保之前的步骤 更换国内软件仓库镜像源加快下载速度 中 没有 添加 archlinuxcn 源。 9. 生成 fstab 文件 ​ fstab 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 genfstab 自动根据当前挂载情况生成并写入 fstab 文件： zsh genfstab -U /mnt &gt; /mnt/etc/fstab 复查一下 /mnt/etc/fstab 确保没有错误： zsh cat /mnt/etc/fstab 若为 NVME 协议的硬盘，输出结果应该与此类似： fstab # /dev/nvme0n1p6 / btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 / btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0# /dev/nvme0n1p1 /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2UUID=522C-80C6 /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2# /dev/nvme0n1p6 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0# /dev/nvme0n1p5 none swap defaults 0 0UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none swap defaults 0 0 10. change root ​ 使用以下命令把系统环境切换到新系统下： zsh arch-chroot /mnt 此时，原来安装盘下的 /mnt 目录就变成了新系统的 / 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。 11. 设置主机名与时区 ​ 首先在 /etc/hostname 设置主机名： vim /etc/hostname 加入你想为主机取的主机名，这里比如叫 myarch。 ℹ️ 提示 主机名不要包含特殊字符以及空格。 接下来在 /etc/hosts 设置与其匹配的条目： vim /etc/hosts 加入如下内容： 127.0.0.1 localhost::1 localhost127.0.1.1 myarch.localdomain myarch ℹ️ 提示 你可以使用 Tab 对齐。 ℹ️ 提示 某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 No protocol specified qt.qpa.xcb: could not connect to display 的错误。这种情况极为少见。 但不管如何，即使没有问题，我们都应该设置好主机名。 随后设置时区，在 /etc/localtime 下用 /usr 中合适的时区创建符号链接： ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 🍧 碎碎念 ​ 不要找北京啦！这里没有北京，只有上海啦！🚀 ℹ️ 提示 同时，你也可以使用其它时区： 12. 硬件时间设置 ​ 使用如下命令将系统时间同步到硬件时间： hwclock --systohc 13. 设置 Locale ​ Locale 决定了软件使用的语言、书写习惯和字符集。 编辑 /etc/locale.gen ，去掉 en_US.UTF-8 UTF-8 以及 zh_CN.UTF-8 UTF-8 行前的注释符号（ # ）： vim /etc/locale.gen ℹ️ 提示 有几个选项极具迷惑性，请不要取消注释错了。 然后使用如下命令生成 locale ： locale-gen 向 /etc/locale.conf 输入内容： echo ''LANG=en_US.UTF-8'' &gt; /etc/locale.conf ⚠️ 注意 不推荐在此设置任何中文 locale ，会导致 tty 乱码。 14. 为 root 用户设置密码 ​ passwd root ℹ️ 提示 根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。 15. 安装微码 ​ 通过以下命令安装对应芯片制造商的微码： pacman -S intel-ucode # Intelpacman -S amd-ucode # AMD ℹ️ 提示 🎉 恭喜你！这是你在新系统中第一次使用 pacman 软件包管理器安装软件！在这里一路回车完成安装即可。 如果你不会使用，请参阅 这里 。 16. 安装引导程序 ​ 如有需要可以参阅 ArchWiki 相关内容 。 安装相应的包： pacman -S grub efibootmgr os-prober 📑 命令参数说明： -S 选项后指定要通过 pacman 包管理器安装的包： grub —— 启动引导器 efibootmgr —— efibootmgr 被 grub 脚本用来将启动项写入 NVRAM os-prober —— 为了能够引导 win10，需要安装 os-prober 以检测到它 安装 GRUB 到 EFI 分区： grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH 📑 命令参数说明： --efi-directory=/boot —— 将 grubx64.efi 安装到之前的指定位置（EFI 分区） --bootloader-id=ARCH —— 取名为 ARCH 接下来使用 vim 编辑 /etc/default/grub 文件： vim /etc/default/grub 进行如下修改： 去掉 GRUB_CMDLINE_LINUX_DEFAULT 一行中最后的 quiet 参数 把 loglevel 的数值从 3 改成 5 。这样是为了后续如果出现系统错误，方便排错 加入 nowatchdog 参数，这可以显著提高开关机速度 为了引导 win10，则还需要添加新的一行 GRUB_DISABLE_OS_PROBER=false grub # GRUB boot loader configurationGRUB_DEFAULT=0GRUB_TIMEOUT=5GRUB_DISTRIBUTOR="Arch"GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"GRUB_CMDLINE_LINUX=""GRUB_DISABLE_OS_PROBER=false... ℹ️ 提示 nowatchdog 参数无法禁用英特尔的看门狗硬件，改为 modprobe.blacklist=iTCO_wdt 即可。如有需要可以参考 ArchWiki 对应内容 最后生成 GRUB 所需的配置文件： grub-mkconfig -o /boot/grub/grub.cfg 若引导了 win10，则输出应该包含倒数第二行： 若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令 ℹ️ 提示 1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 efi 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 GRUB 。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了）， chroot 到 /mnt ，然后你可以重新用 --removable 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 ArchWiki 对应内容 。 grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH --removable 2. os-prober 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。 17. 完成安装 ​ 输入以下命令： exit # 退回安装环境umount -R /mnt # 卸载新分区reboot # 重启 注意， 重启前要先拔掉优盘 ，否则你重启后还是进安装程序而不是安装好的系统。 ℹ️ 提示 虚拟机直接重启即可。 如图即为 GRUB 引导界面。 ℹ️ 提示 若引导了 win10 也会显示出来。 ℹ️ 提示 若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。 你应该在步骤 5. 获取 Bitlocker 恢复密钥 中已经知晓了 Bitlocker 解锁密钥。 若无法从 aka.ms 相关页面 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。 重启后使用 root 账户登录系统： 设置开机自启并立即启动 networkmanager 服务，即可连接网络： systemctl enable --now NetworkManager # 设置开机自启并立即启动 NetworkManager 服务ping www.bilibili.com # 测试网络连接 若为无线连接，则需要在启动 networkmanager 后使用 nmcli 连接网络： nmcli dev wifi list # 显示附近的 Wi-Fi 网络nmcli dev wifi connect "Wi-Fi名（SSID）" password "网络密码" # 连接指定的无线网络 也可以使用 nmtui 来配置网络 nmtui ℹ️ 提示 neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 fastfetch 代替 neofetch 。 fastfetch 可以将系统信息和发行版 logo 一并打印出来。通过 pacman 安装 fastfetch ： pacman -S fastfetch 使用 fastfetch 打印系统信息： fastfetch 🍧 碎碎念 ​ 又到了 fastfetch 的时间了吗？ 🎉 祝贺！🎉 ​ 到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！ 如果你对本节的部分步骤不理解，请仔细阅读下一节 基础安装详解 。在此之后，我们来安装图形界面。 ℹ️ 提示 你可以使用以下命令关机： shutdown -h now# 或者poweroff ℹ️ 提示 archlinux 在 2021 年 4 月在安装镜像中内置了一个 安装脚本 ，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于： 只提供有限的文件系统格式 只可限定在一个磁盘 不能指定软件仓库镜像源 只提供有限的桌面选择 自动分区不可手动干预 输入错误直接崩溃退出 仅支持 UEFI 等', '2026-11-06 11:42:33.43975+08'::timestamptz, '2026-11-06 13:13:02.205498+08'::timestamptz, 'c59ba8f6-bf7e-4c30-81e4-327ea96f7fa4'::uuid, 0, NULL),
  ('295e7f3b-c195-4c04-ab1a-7ccc3639e4ce'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '沙利文后台系统', '<div id="readability-page-1" class="page"><div data-v-73470880="" data-prefix="el" data-v-8201b000="" data-v-34116364="" id="app" data-v-app=""><table><colgroup><col name="el-table_1_column_1" width="404"><col name="el-table_1_column_2" width="134"><col name="el-table_1_column_3" width="134"><col name="el-table_1_column_4" width="160"><col name="el-table_1_column_5" width="442"><col name="el-table_1_column_6" width="80"><col name="el-table_1_column_7" width="321"><col name="el-table_1_column_8" width="150"></colgroup><!--v-if--><tbody tabindex="-1"><tr><td colspan="1" rowspan="1"><p>专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:23:53</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:34</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文全球研讨会预告（11/4 - 11/12）</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:41:26</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:40:33</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:54</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:04</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981889121551301feca09" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981889121551301feca09</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>校招 | 2027，与沙利文中国一起成长，迎接无限可能！</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-11-02 11:48:02</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:39</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式）</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:12</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:31:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:30:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:28:19</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖”</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-10-29 10:26:56</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr></tbody><!--v-if--></table><!--v-if--><!--v-if--></div></div>', 'private', NULL, '沙利文后台系统 专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读 传媒中心 公司动态 2026-11-04 11:23:53 https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊 最新洞察 企业研究 2026-11-04 11:22:59 https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》 最新洞察 趋势研读 2026-11-04 11:22:34 https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文全球研讨会预告（11/4 - 11/12） 传媒中心 公司动态 2026-11-03 14:41:26 https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》 最新洞察 趋势研读 2026-11-03 14:40:33 https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台 传媒中心 公司动态 2026-11-03 14:39:54 https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行 传媒中心 公司动态 2026-11-03 14:39:04 https://www.frostchina.com/content/news/detail/6ae981889121551301feca09 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 校招 | 2027，与沙利文中国一起成长，迎接无限可能！ — — 2026-11-02 11:48:02 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》 最新洞察 趋势研读 2026-10-30 11:28:39 https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》 最新洞察 趋势研读 2026-10-30 11:28:27 https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式） 最新洞察 趋势研读 2026-10-30 11:28:12 https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》 最新洞察 趋势研读 2026-10-29 10:31:27 https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势 传媒中心 公司动态 2026-10-29 10:30:59 https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖 最新洞察 企业研究 2026-10-29 10:28:19 https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖” — — 2026-10-29 10:26:56 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 —', '2026-11-05 11:35:29.821717+08'::timestamptz, '2026-11-05 11:35:29.821717+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:35:48.714281+08'::timestamptz),
  ('61cef616-51b1-4878-b911-ce8af21ad6cb'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '沙利文后台系统', '<div id="readability-page-1" class="page"><div data-v-73470880="" data-prefix="el" data-v-8201b000="" data-v-34116364="" id="app" data-v-app=""><table><colgroup><col name="el-table_1_column_1" width="404"><col name="el-table_1_column_2" width="134"><col name="el-table_1_column_3" width="134"><col name="el-table_1_column_4" width="160"><col name="el-table_1_column_5" width="442"><col name="el-table_1_column_6" width="80"><col name="el-table_1_column_7" width="321"><col name="el-table_1_column_8" width="150"></colgroup><!--v-if--><tbody tabindex="-1"><tr><td colspan="1" rowspan="1"><p>专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:23:53</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:34</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文全球研讨会预告（11/4 - 11/12）</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:41:26</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:40:33</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:54</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:04</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981889121551301feca09" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981889121551301feca09</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>校招 | 2027，与沙利文中国一起成长，迎接无限可能！</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-11-02 11:48:02</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:39</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式）</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:12</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:31:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:30:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:28:19</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖”</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-10-29 10:26:56</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr></tbody><!--v-if--></table><!--v-if--><!--v-if--></div></div>', 'private', NULL, '沙利文后台系统 专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读 传媒中心 公司动态 2026-11-04 11:23:53 https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊 最新洞察 企业研究 2026-11-04 11:22:59 https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》 最新洞察 趋势研读 2026-11-04 11:22:34 https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文全球研讨会预告（11/4 - 11/12） 传媒中心 公司动态 2026-11-03 14:41:26 https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》 最新洞察 趋势研读 2026-11-03 14:40:33 https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台 传媒中心 公司动态 2026-11-03 14:39:54 https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行 传媒中心 公司动态 2026-11-03 14:39:04 https://www.frostchina.com/content/news/detail/6ae981889121551301feca09 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 校招 | 2027，与沙利文中国一起成长，迎接无限可能！ — — 2026-11-02 11:48:02 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》 最新洞察 趋势研读 2026-10-30 11:28:39 https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》 最新洞察 趋势研读 2026-10-30 11:28:27 https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式） 最新洞察 趋势研读 2026-10-30 11:28:12 https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》 最新洞察 趋势研读 2026-10-29 10:31:27 https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势 传媒中心 公司动态 2026-10-29 10:30:59 https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖 最新洞察 企业研究 2026-10-29 10:28:19 https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖” — — 2026-10-29 10:26:56 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 —', '2026-11-05 11:43:50.243598+08'::timestamptz, '2026-11-05 11:43:50.243598+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:44:05.836256+08'::timestamptz),
  ('be0cee0a-4709-4fec-a51d-eb7753e46bb5'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '面试官让你把 LLM、RAG、Agent、MCP 串起来讲清楚，90% 的 Java 工程师当场露馅', '<p></p>', 'private', NULL, '面试官让你把 LLM、RAG、Agent、MCP 串起来讲清楚，90% 的 Java 工程师当场露馅', '2026-11-05 11:44:23.122172+08'::timestamptz, '2026-11-05 11:44:52.026119+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:44:54.994388+08'::timestamptz),
  ('ae2b8a88-3f84-4a67-b092-139f4789ae78'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '沙利文后台系统', '<div id="readability-page-1" class="page"><div data-v-73470880="" data-prefix="el" data-v-8201b000="" data-v-34116364="" id="app" data-v-app=""><table><colgroup><col name="el-table_1_column_1" width="404"><col name="el-table_1_column_2" width="134"><col name="el-table_1_column_3" width="134"><col name="el-table_1_column_4" width="160"><col name="el-table_1_column_5" width="442"><col name="el-table_1_column_6" width="80"><col name="el-table_1_column_7" width="321"><col name="el-table_1_column_8" width="150"></colgroup><!--v-if--><tbody tabindex="-1"><tr><td colspan="1" rowspan="1"><p>专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:23:53</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:34</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文全球研讨会预告（11/4 - 11/12）</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:41:26</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:40:33</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:54</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:04</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981889121551301feca09" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981889121551301feca09</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>校招 | 2027，与沙利文中国一起成长，迎接无限可能！</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-11-02 11:48:02</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:39</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式）</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:12</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:31:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:30:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:28:19</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖”</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-10-29 10:26:56</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr></tbody><!--v-if--></table><!--v-if--><!--v-if--></div></div>', 'private', NULL, '沙利文后台系统 专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读 传媒中心 公司动态 2026-11-04 11:23:53 https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊 最新洞察 企业研究 2026-11-04 11:22:59 https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》 最新洞察 趋势研读 2026-11-04 11:22:34 https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文全球研讨会预告（11/4 - 11/12） 传媒中心 公司动态 2026-11-03 14:41:26 https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》 最新洞察 趋势研读 2026-11-03 14:40:33 https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台 传媒中心 公司动态 2026-11-03 14:39:54 https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行 传媒中心 公司动态 2026-11-03 14:39:04 https://www.frostchina.com/content/news/detail/6ae981889121551301feca09 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 校招 | 2027，与沙利文中国一起成长，迎接无限可能！ — — 2026-11-02 11:48:02 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》 最新洞察 趋势研读 2026-10-30 11:28:39 https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》 最新洞察 趋势研读 2026-10-30 11:28:27 https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式） 最新洞察 趋势研读 2026-10-30 11:28:12 https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》 最新洞察 趋势研读 2026-10-29 10:31:27 https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势 传媒中心 公司动态 2026-10-29 10:30:59 https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖 最新洞察 企业研究 2026-10-29 10:28:19 https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖” — — 2026-10-29 10:26:56 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 —', '2026-11-05 11:41:02.880134+08'::timestamptz, '2026-11-05 11:41:02.880134+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:44:07.835319+08'::timestamptz),
  ('e06e0185-d65e-4e3a-bb07-6a85b7b135c6'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '沙利文后台系统', '<div id="readability-page-1" class="page"><div data-v-73470880="" data-prefix="el" data-v-8201b000="" data-v-34116364="" id="app" data-v-app=""><table><colgroup><col name="el-table_1_column_1" width="404"><col name="el-table_1_column_2" width="134"><col name="el-table_1_column_3" width="134"><col name="el-table_1_column_4" width="160"><col name="el-table_1_column_5" width="442"><col name="el-table_1_column_6" width="80"><col name="el-table_1_column_7" width="321"><col name="el-table_1_column_8" width="150"></colgroup><!--v-if--><tbody tabindex="-1"><tr><td colspan="1" rowspan="1"><p>专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:23:53</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-04 11:22:34</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文全球研讨会预告（11/4 - 11/12）</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:41:26</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:40:33</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:54</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-11-03 14:39:04</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae981889121551301feca09" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae981889121551301feca09</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>校招 | 2027，与沙利文中国一起成长，迎接无限可能！</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-11-02 11:48:02</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:39</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式）</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-30 11:28:12</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>趋势研读</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:31:27</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势</p></td><td colspan="1" rowspan="1"><div><!----><p>传媒中心</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>公司动态</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:30:59</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖</p></td><td colspan="1" rowspan="1"><div><!----><p>最新洞察</p><!----></div></td><td colspan="1" rowspan="1"><div><!----><p>企业研究</p><!----></div></td><td colspan="1" rowspan="1"><p>2026-10-29 10:28:19</p></td><td colspan="1" rowspan="1"><div data-v-73470880=""><p><a data-v-73470880="" href="https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9" target="_blank" rel="noopener noreferrer">https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9</a></p></div></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><p>当前已有文章发布，原失败记录保留</p><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr><tr><td colspan="1" rowspan="1"><p>沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖”</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p>2026-10-29 10:26:56</p></td><td colspan="1" rowspan="1"><p><span data-v-73470880="">—</span></p></td><td colspan="1" rowspan="1"><p><span data-v-73470880=""><span>失败</span><!--v-if--></span></p></td><td colspan="1" rowspan="1"><div><!----><!----><p>模型分类失败，已保存草稿，请在同步日志指定栏目后发布</p></div></td><td colspan="1" rowspan="1"><div><!----><p><span data-v-73470880="">—</span></p></div></td></tr></tbody><!--v-if--></table><!--v-if--><!--v-if--></div></div>', 'private', NULL, '沙利文后台系统 专家视角 | 为AI搜索时代的信任树准则——中国广告协会GEO三项团体标准解读 传媒中心 公司动态 2026-11-04 11:23:53 https://www.frostchina.com/content/news/detail/6aeaa5499121551301070887 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 穿透噪音、直抵信号： 《沙利文商业洞察评论》2026年10月刊 最新洞察 企业研究 2026-11-04 11:22:59 https://www.frostchina.com/content/insight/detail/6aeaa5139121551301070632 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026全球ECM行业现状与发展趋势白皮书》 最新洞察 趋势研读 2026-11-04 11:22:34 https://www.frostchina.com/content/insight/detail/6aeaa4fa912155130107055e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文全球研讨会预告（11/4 - 11/12） 传媒中心 公司动态 2026-11-03 14:41:26 https://www.frostchina.com/content/news/detail/6ae982169121551301fecf8e 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026年中国领先指数系列研究报告第三期：中国彩妆与粉底粉膏行业》 最新洞察 趋势研读 2026-11-03 14:40:33 https://www.frostchina.com/content/insight/detail/6ae981e19121551301fecdeb 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 熵基科技脑景中心正式启幕，构建非侵入式脑机接口全栈技术与应用平台 传媒中心 公司动态 2026-11-03 14:39:54 https://www.frostchina.com/content/news/detail/6ae981ba9121551301fecc64 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 议程公布 | 浦江创新论坛·2026脑机接口大会投融资分论坛将于12月4日在上海举行 传媒中心 公司动态 2026-11-03 14:39:04 https://www.frostchina.com/content/news/detail/6ae981889121551301feca09 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 校招 | 2027，与沙利文中国一起成长，迎接无限可能！ — — 2026-11-02 11:48:02 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国医疗健康数字营销白皮书》 最新洞察 趋势研读 2026-10-30 11:28:39 https://www.frostchina.com/content/insight/detail/6ae40ee79121551301f12771 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函 | 沙利文即将发布《2026中国糖尿病健康管理行业发展白皮书》 最新洞察 趋势研读 2026-10-30 11:28:27 https://www.frostchina.com/content/insight/detail/6ae40edb9121551301f1268a 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文发布《2026全球医疗机器人行业发展蓝皮书》（内附获取方式） 最新洞察 趋势研读 2026-10-30 11:28:12 https://www.frostchina.com/content/insight/detail/6ae40ecc9121551301f12610 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 合作邀请函丨沙利文即将发布《2026年中国企业级智能体落地实践与案例研究报告》 最新洞察 趋势研读 2026-10-29 10:31:27 https://www.frostchina.com/content/insight/detail/6ae2afff9121551301ee2065 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文高管受邀出席2026第六届中国医药数字营销论坛，深度解析AI赋能下医疗健康数字营销新生态与发展趋势 传媒中心 公司动态 2026-10-29 10:30:59 https://www.frostchina.com/content/news/detail/6ae2afe39121551301ee1fb3 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德2026年沙利文全球CRDMO年度公司奖 最新洞察 企业研究 2026-10-29 10:28:19 https://www.frostchina.com/content/insight/detail/6ae2af439121551301ee1cb9 失败 当前已有文章发布，原失败记录保留 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 — 沙利文授予药明康德“2026年沙利文全球CRDMO年度公司奖” — — 2026-10-29 10:26:56 — 失败 模型分类失败，已保存草稿，请在同步日志指定栏目后发布 —', '2026-11-05 11:41:01.475769+08'::timestamptz, '2026-11-05 11:41:01.475769+08'::timestamptz, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, 0, '2026-11-05 11:44:09.730769+08'::timestamptz);

-- note_tags: 50 条
INSERT INTO note_tags (note_id, tag_id) VALUES
  ('f1ce4cae-ff94-438e-8a23-b8d7b5524299'::uuid, '9075fcb6-c1f0-49c5-a7b7-c9970bec24b3'::uuid),
  ('f1ce4cae-ff94-438e-8a23-b8d7b5524299'::uuid, 'e8423ea4-8068-4be0-a0ab-8bf5ebb4b450'::uuid),
  ('f1ce4cae-ff94-438e-8a23-b8d7b5524299'::uuid, '570ba71b-e352-460f-852e-722462579e2f'::uuid),
  ('f1ce4cae-ff94-438e-8a23-b8d7b5524299'::uuid, '42a9a8a7-8362-4a04-b654-16869832ccc9'::uuid),
  ('f84dbe36-4332-4c04-953a-cb68bf45d2e4'::uuid, 'af010e50-e6f8-4baa-a377-dc96a5f57f93'::uuid),
  ('1c7bd1df-9a26-4efd-89d4-36566e37b995'::uuid, '9681d3b8-48a7-480e-83c4-6200ee284713'::uuid),
  ('1c7bd1df-9a26-4efd-89d4-36566e37b995'::uuid, '946ac7b7-f0bf-45de-bb64-841e3b576425'::uuid),
  ('1c7bd1df-9a26-4efd-89d4-36566e37b995'::uuid, '89465eb5-3afc-46f6-b5f4-7d7f6d026c41'::uuid),
  ('1c7bd1df-9a26-4efd-89d4-36566e37b995'::uuid, '39a8213f-2aeb-405d-be6b-46da2be66a11'::uuid),
  ('1c7bd1df-9a26-4efd-89d4-36566e37b995'::uuid, 'b15e4dc4-6bba-4756-aeef-7bccf61a8195'::uuid),
  ('aab6e375-c564-4d2c-872c-46601ccaf204'::uuid, '39a8213f-2aeb-405d-be6b-46da2be66a11'::uuid),
  ('aab6e375-c564-4d2c-872c-46601ccaf204'::uuid, '9681d3b8-48a7-480e-83c4-6200ee284713'::uuid),
  ('aab6e375-c564-4d2c-872c-46601ccaf204'::uuid, 'b15e4dc4-6bba-4756-aeef-7bccf61a8195'::uuid),
  ('aab6e375-c564-4d2c-872c-46601ccaf204'::uuid, 'e8423ea4-8068-4be0-a0ab-8bf5ebb4b450'::uuid),
  ('1b81688f-7adc-4704-a659-93ba65d04be0'::uuid, '3aa752ed-37d3-481f-9c54-b2b675268341'::uuid),
  ('658d28be-4798-49af-83a7-50b99d145613'::uuid, 'af010e50-e6f8-4baa-a377-dc96a5f57f93'::uuid),
  ('c839c163-7732-4c7b-bd46-2902a657f07b'::uuid, '851a701b-b49d-4ce6-8b1d-c211570aa741'::uuid),
  ('7d338283-a450-4153-abcc-4690fdff38ca'::uuid, '510b60dd-7256-427f-b83b-b35c5cb0ca59'::uuid),
  ('7d338283-a450-4153-abcc-4690fdff38ca'::uuid, '9075fcb6-c1f0-49c5-a7b7-c9970bec24b3'::uuid),
  ('7d338283-a450-4153-abcc-4690fdff38ca'::uuid, '42a9a8a7-8362-4a04-b654-16869832ccc9'::uuid),
  ('7d338283-a450-4153-abcc-4690fdff38ca'::uuid, 'e8423ea4-8068-4be0-a0ab-8bf5ebb4b450'::uuid),
  ('7d338283-a450-4153-abcc-4690fdff38ca'::uuid, '570ba71b-e352-460f-852e-722462579e2f'::uuid),
  ('7d338283-a450-4153-abcc-4690fdff38ca'::uuid, 'de2e29eb-0948-49f1-81da-7c83fb12064f'::uuid),
  ('8e88609d-abab-4108-a0d6-070714bb60cc'::uuid, '42a9a8a7-8362-4a04-b654-16869832ccc9'::uuid),
  ('8e88609d-abab-4108-a0d6-070714bb60cc'::uuid, '53675993-ee21-4980-9d3b-5d66b31d4816'::uuid),
  ('8e88609d-abab-4108-a0d6-070714bb60cc'::uuid, '5557fdfc-b99c-488f-97ae-1d5deee7612d'::uuid),
  ('8e88609d-abab-4108-a0d6-070714bb60cc'::uuid, '83663bcb-0c24-4440-8d8f-466c2541276c'::uuid),
  ('5c4272b6-bb10-40ab-a07c-e3cf267721c4'::uuid, '74cf4d60-cb10-4ccf-affc-52e0d112245d'::uuid),
  ('5c4272b6-bb10-40ab-a07c-e3cf267721c4'::uuid, '89465eb5-3afc-46f6-b5f4-7d7f6d026c41'::uuid),
  ('5c4272b6-bb10-40ab-a07c-e3cf267721c4'::uuid, '9075fcb6-c1f0-49c5-a7b7-c9970bec24b3'::uuid),
  ('5c4272b6-bb10-40ab-a07c-e3cf267721c4'::uuid, '8d89061c-aeba-4dfa-9767-e3750fb326ea'::uuid),
  ('091ccc31-caaf-48d0-842d-a3e1b77e1951'::uuid, 'ad0abb97-30ed-4c5b-9214-b4f284e55da6'::uuid),
  ('091ccc31-caaf-48d0-842d-a3e1b77e1951'::uuid, '5e055b7c-a86d-431e-befd-12fc20efe7f9'::uuid),
  ('091ccc31-caaf-48d0-842d-a3e1b77e1951'::uuid, '74cf4d60-cb10-4ccf-affc-52e0d112245d'::uuid),
  ('6f62b534-b4b4-4d3c-8970-13d8306c2b13'::uuid, '570ba71b-e352-460f-852e-722462579e2f'::uuid),
  ('cdada194-4a76-42dd-b258-f21040e60c5d'::uuid, 'b767bb06-ef15-450f-9943-68e887972679'::uuid),
  ('cdada194-4a76-42dd-b258-f21040e60c5d'::uuid, '49e2ecbb-5626-4a2a-9096-7fb9789b728d'::uuid),
  ('26561010-f249-4b0d-a786-f9114ec06230'::uuid, '7d6af0eb-8ea0-40ba-9c21-d19b280bbf40'::uuid),
  ('26561010-f249-4b0d-a786-f9114ec06230'::uuid, 'cd8c8114-2847-4f91-95ea-34371f555fc1'::uuid),
  ('26561010-f249-4b0d-a786-f9114ec06230'::uuid, '46c2112e-23a4-4326-9ff6-209dfe846532'::uuid),
  ('26561010-f249-4b0d-a786-f9114ec06230'::uuid, '056e5d4d-db31-47dd-9966-c4585abc861a'::uuid),
  ('26561010-f249-4b0d-a786-f9114ec06230'::uuid, '1c15d77e-9812-4118-a33b-64f011ca8409'::uuid),
  ('5595efba-f221-4806-9a91-ad05cd4a5b08'::uuid, '48a09afc-cc0f-4a48-bc10-4a5bdbd4dcc4'::uuid),
  ('5595efba-f221-4806-9a91-ad05cd4a5b08'::uuid, '5e055b7c-a86d-431e-befd-12fc20efe7f9'::uuid),
  ('dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, '7657dad3-b0bb-4cd3-8b7a-4ea382aef526'::uuid),
  ('dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, '6c1df245-5e8a-42e2-86b7-8c82dfa5b737'::uuid),
  ('dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, '5e055b7c-a86d-431e-befd-12fc20efe7f9'::uuid),
  ('dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, '0e919136-6a50-458d-ae70-3a2cde87d866'::uuid),
  ('dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, 'a8bdd31d-6a36-4ba4-941a-cc0bdefb123e'::uuid),
  ('dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, '7b5f1d69-c6c9-4733-84c8-6c395f23199d'::uuid);

-- note_versions: 24 条
INSERT INTO note_versions (id, note_id, user_id, title, content, folder_id, tag_ids, created_at) VALUES
  ('f5cbaa60-05ad-4de0-a2e0-52a99be592a7'::uuid, 'cdada194-4a76-42dd-b258-f21040e60c5d'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '# 分析报告：Windows 登录微软账户时要求“上次锁屏密码”的意义与安全边界  > 报告用途：个人笔记整理   > 主题：Windows 微软账户登录验证机制、本地管理员权限边界，以及与 macOS 安全模型的对比  ---  ## 一、摘要  Windows 在登录微软账户时要求输入“上次锁屏密码”，并不是简单的重复验证，而是 **本地凭据缓存** 与 **高风险场景降级验证** 两种机制共同作用的结果。  但这一机制存在一个清晰的边界：**当一个人拥有本地管理员权限并能物理接触设备时，他可以通过创建本地管理员账户、删除原微软账户的方式，改变系统需要验证的“身份主体”本身。** 此时“上次密码”机制并非被攻破，而是被验证对象已经被替换。  这与 macOS 的设计形成鲜明对比：macOS 将本地 UNIX 账户与 Apple ID 分离，并在启用 FileVault 时把登录密码与数据解密密钥深度绑定。结果是：**Windows 中“获得管理员权限”更接近获得设备控制权；macOS 中“重置登录密码”不等于获得原有数据的访问权。**  ---  ## 二、Windows 要求“上次锁屏密码”的核心意义  ### 1. 离线可用性：本地缓存的账户凭据  Windows 允许设备在没有网络连接时登录微软账户。为了实现这一点，系统会在上次成功登录后，将账户密码或其派生验证信息加密缓存在本地。  当设备离线、无法连接微软服务器时，系统无法实时验证微软账户，只能使用本地缓存的凭据核对用户输入。  因此，该提示的含义可以理解为：  > “当前无法连接微软服务器，只能依赖本机缓存的上次登录凭据来验证身份。”  如果用户在另一台设备上修改了微软账户密码，而这台 Windows 设备仍处于离线状态，则可能需要输入修改前的旧密码才能通过本地验证。  ### 2. 高风险场景下的安全降级验证  Windows Hello PIN 是设备绑定的本地便捷凭证，适合日常登录和锁屏解锁。但它不是完整账户密码，权限边界有限。  当系统判断当前场景属于高风险或超出 PIN 的授权范围时，会要求使用与微软账户直接绑定的账户密码重新证明身份。典型场景包括：  - 多次输错密码或 PIN； - 更改 PIN、重置 Windows Hello 凭据； - 执行涉及账户凭据变更的敏感操作； - 远程桌面、访问某些网络资源或需要完整账户授权的场景。  因此，“上次密码”机制的本质是：**在便捷性与更高等级身份验证之间进行动态权衡。**  ---  ## 三、同事操作复盘：为什么创建本地账号并删除微软账户可以绕过  ### 1. 操作路径的本质  同事的操作大致是：  1. 拥有本地管理员权限； 2. 创建一个新的本地管理员账户； 3. 使用新账户登录； 4. 删除原来的微软账户及其关联登录凭据； 5. 为新本地账户设置密码； 6. 再次登录时，系统要求验证的是这个新本地账户的密码。  ### 2. 被绕过的不是密码验证，而是验证对象  关键点在于：**系统后来验证的已经不再是原来的微软账户，而是新建的本地账户。**  原来的微软账户被删除后，针对该账户的“上次密码”验证自然失去意义。此时系统要求为新本地账户设置密码，并验证这个新密码，逻辑上是自洽的。  所以，这不是“上次密码机制失效”，而是：  > **拥有本地管理员权限的人，重新定义了“谁可以登录这台设备”。**  ### 3. Windows 安全模型的固有边界  Windows 的消费级设计优先保障账户体系的可管理性与可恢复性。本地管理员权限在软件层面接近设备配置的最终权限。  当一个人已经拥有管理员权限，并且能物理接触设备时，他可以：  - 创建新的本地管理员账户； - 删除原微软账户； - 替换登录凭据； - 重置 Windows Hello 容器； - 重新配置安全规则。  因此，针对旧账户的验证机制无法阻止这种操作，因为操作者已经越过了“正常登录验证”的边界，进入了“重新配置身份体系”的层级。  ---  ## 四、Windows 与 macOS 的安全哲学差异  | 维度 | Windows | macOS | |---|---|---| | 身份模型 | 消费级版本强力推行微软账户作为系统登录身份 | 本地 UNIX 账户与 Apple ID 分离，登录密码是本地账户密码 | | 管理员权限意义 | 本地管理员权限接近设备安全配置的最终控制权 | 管理员权限可重置访问权，但不自动等于解密原有数据 | | 数据加密绑定 | BitLocker 可选，需另行启用 | FileVault 与登录密码、硬件 UID、Secure Enclave 深度绑定 | | 忘记密码后的结果 | 管理员可通过替换账户等方式恢复设备可用性 | 可重置登录密码，但无恢复密钥时可能无法解密原有数据 | | 安全优先级 | 账户可管理性、可恢复性 | 静态数据机密性、防物理接触泄露 | | 核心边界 | 拥有管理员权限≈获得设备控制权 | 获得登录密码≠获得原有数据访问权 |  ---  ## 五、macOS 为什么不同  ### 1. 本地账户与 Apple ID 分离  macOS 的登录账户本质上是本地 UNIX 账户，和 Apple ID 是两个可以独立存在的身份。删除 Apple ID 不会自动动摇本地账户的根基。  ### 2. FileVault 与 Secure Enclave 的密钥保护  在 Apple Silicon 或带 T2 芯片的 Mac 上，启用 FileVault 后，解密硬盘的密钥由登录密码和硬件 UID 共同保护，密钥派生与验证在 Secure Enclave 中完成。  这意味着：  - 可以重置登录密码； - 但如果没有 FileVault 恢复密钥或 Apple ID 解锁能力； - 可能无法解密硬盘原有数据； - 登入的可能是无法访问原有数据的空壳环境。  ### 3. 关键结论  > **Windows：权限可以替换验证主体，管理员权限接近最终控制权。**   > **macOS：访问权可以重置，但数据解密权不会自动随之恢复。**  ---  ## 六、安全启示  ### 对个人设备  1. **保护好本地管理员账户密码**，不要随意让陌生人物理接触已登录设备。 2. **启用 BitLocker**，降低设备被物理接触后通过 PE 等方式重置密码、访问数据的风险。 3. 理解“登录密码”“PIN”“微软账户密码”不是同一层级凭证。 4. 重要数据应额外备份，不能只依赖系统登录安全。  ### 对公司或共享设备  1. **限制普通用户的本地管理员权限**，从根源上阻止“创建管理员账户→删除原账户”的路径。 2. 物理管控不可替代：软件登录验证无法完全替代对设备实体的控制。 3. 对共享设备应使用标准用户权限、集中账户管理和磁盘加密策略。  ---  ## 七、最终结论  Windows 要求“上次锁屏密码”的意义，主要在于：  1. **离线时使用本地缓存凭据验证身份**； 2. **高风险或越权场景下要求更高等级账户密码验证**。  同事通过创建本地账号并删除微软账户来绕过锁屏密码，说明的不是该机制本身无效，而是揭示了 Windows 安全模型的边界：  > **当本地管理员权限与物理接触同时具备时，操作者可以替换被验证的身份主体，而不是攻破某一次密码验证。**  与 macOS 相比，两者体现了不同的安全优先级：  - **Windows 更重视账户体系的可管理性与可恢复性；** - **macOS 更重视静态数据的机密性，将登录密码与数据解密密钥深度绑定。**  因此，真正的安全启示不是依赖单一登录验证，而是：**保护管理员权限、启用磁盘加密、限制共享设备权限，并做好数据备份与物理管控。**  ---  ## 八、笔记版一句话总结  > Windows 的“上次密码”验证是离线缓存与高风险降级验证机制；本地管理员可通过替换账户主体绕过它，因为管理员权限接近设备最终控制权。macOS 则将本地账户与 Apple ID 分离，并用 FileVault 和 Secure Enclave 把登录密码与数据解密绑定，因此“重置访问权”不等于“恢复数据访问权”。', NULL, '75ea30a2-6b56-499b-8a67-2bdf0a8ce5fc'::uuid, '{}'::uuid[], '2026-11-01 14:16:52.467257+08'::timestamptz),
  ('d5f52abb-f33e-4be7-a700-8bdbbbc5c64a'::uuid, 'a6866ed7-62a8-4405-a43e-af98fa312041'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Js', NULL, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-02 13:39:30.69008+08'::timestamptz),
  ('529af308-e81b-49f5-95ab-5b01ff5eef4e'::uuid, '2a0e9fc4-421d-4e43-8362-0556bc4b1e56'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '功能', NULL, '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-02 17:50:32.183567+08'::timestamptz),
  ('1e0e5e38-27b1-4542-bd7a-aae64d5dd626'::uuid, '2a0e9fc4-421d-4e43-8362-0556bc4b1e56'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '功能', '<ol>
<li>新的页面，复制展示保存的网页。</li>
<li>保存网页的功能</li>
</ol>
', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-03 20:55:05.594922+08'::timestamptz),
  ('04aabce6-ee5b-48dd-ae83-6d3e00704687'::uuid, 'dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'CVE-2026-123158 漏洞学习笔记（OpenSSH + musl libc 密码绕过）', '<blockquote><p><strong>📌 基础信息概览</strong><br>漏洞代号：sshole｜披露时间：2026-11-05｜补丁版本：OpenSSH ≥ 10.6p2</p></blockquote><h2>触发条件（全部满足才可利用）</h2><ol><li><p>OpenSSH 版本 &lt; 10.6p2（未合并补丁）</p></li><li><p>系统 libc 为 musl（Alpine、OpenWrt 默认；glibc 不受影响）</p></li><li><p><code>sshd_config</code> 开启 <code>UsePAM no</code>，走传统 crypt 认证路径</p></li><li><p>目标用户在 <code>/etc/shadow</code> 的密码字段为 <code>*</code>，账号锁定、禁止密码登录</p></li><li><p>系统内至少存在一个正常用户，拥有合法 sha512 哈希，为 crypt 提供 salt</p></li></ol><h2>漏洞原理</h2><p>这是一个<strong>跨组件语义冲突漏洞</strong>，不是代码崩溃，也不是哈希算法被破解。</p><ul><li><p>Unix 标准函数 <code>crypt()</code>，规范约定：计算失败时应当返回 <code>NULL</code></p></li><li><p>musl 的实现取舍：密码长度 ≥ 257 字节时超限，不返回 NULL，返回静态字符串 <code>*</code><br>musl 设计者本意：<code>*</code> 是密码生态公认的「哈希计算失败标记」，避免上层无判空代码直接空指针崩溃。</p></li><li><p>shadow 体系约定：<code>*</code> / <code>!</code> 代表<strong>账号锁定，禁止密码登录</strong>，两套语义撞在了同一个字符串上。</p></li><li><p>旧 OpenSSH 校验逻辑：拿到 crypt 返回值，只判断不为 NULL，直接做字符串相等对比。</p></li></ul><blockquote><p>攻击链路：传入257字节超长密码 → musl crypt 返回 <code>*</code> → 和 shadow 里锁定标记 <code>*</code> 字符串相等 → 认证放行，绕过锁定限制。</p></blockquote><h2>三段核心C代码对比</h2><h3>1. 存在漏洞的原始校验逻辑</h3><pre class="hljs"><code>char *computed = crypt(password, stored_hash);
if (computed &amp;&amp; strcmp(computed, stored_hash) == 0) {
    return 1; // 校验通过，放行
}
</code></pre><p>缺陷：没有提前判断账号锁定标记，不区分 crypt 返回值是正常哈希，还是错误标记。</p><h3>2. musl crypt 超长密码分支（简化）</h3><pre class="hljs"><code>if (keylen &gt; 256) {
    strcpy(result, "*");
    return result;
}
</code></pre><h3>3. OpenSSH 官方补丁逻辑（修复方案）</h3><pre class="hljs"><code>// 调用crypt之前，优先判断账号锁定语义
if (stored_hash[0] == ''*'' || stored_hash[0] == ''!'') {
    return 0; // 直接拒绝，不再执行密码哈希计算
}
// 再往下才调用 crypt 做比对
</code></pre><p><strong>💡 重点区分：</strong> 不是限制密码长度（只针对musl的hack方案），而是<strong>遵循shadow语义，锁定账号直接拦截</strong>，通用、可移植，不受libc差异影响。</p><h2>本次复现失败原因</h2><p>Alpine官方源已经升级 OpenSSH 至带补丁的版本，读到 <code>*</code> 锁定标记就直接打印日志：</p><p><code>User testuser not allowed because account is locked</code></p><p>直接跳出，根本不会进入 crypt 函数调用，漏洞无法触发。</p><h2>Python逻辑模拟代码（仅演示原理，非可利用EXP）</h2><pre class="hljs"><code>def musl_crypt_sim(password: str, salt: str):
    if len(password) &gt;= 257:
        # musl超长密码的异常行为：返回 *
        return "*"
    import hashlib
    return hashlib.sha512((password + salt).encode()).hexdigest()

shadow = {
    "testuser": "*",
    "normaluser": "$6$rounds=5000$abc123$FAKEHASH"
}
real_hash = shadow["normaluser"]
salt = real_hash.split("$")[2]

print("=== 短密码 aaaa ===")
ret1 = musl_crypt_sim("aaaa", salt)
print(f"crypt返回：{ret1}")
print(f"比对结果：{''放行'' if ret1 == shadow[''testuser''] else ''拒绝''}")

print("\n=== payload：257个A ===")
ret2 = musl_crypt_sim("A"*257, salt)
print(f"比对结果：{''放行'' if ret2 == shadow[''testuser''] else ''拒绝''}")
</code></pre><h2>开发学习收获 &amp; 教训</h2><ul><li><p>第三方库、系统调用返回值<strong>不可无条件信任</strong>，文档契约和不同平台实现经常不一致。</p></li><li><p>异常分支是高危点：报错时有可能返回一个具备业务含义的字符串，而不是NULL。</p></li><li><p>单纯字符串相等是非常弱的校验，优先校验<strong>数据语义、状态</strong>，而不是只比对内容。</p></li><li><p>跨组件边界是漏洞高发区：单独看每个组件逻辑都合理，但隐性行为组合之后产生绕过。</p></li><li><p>修复优先选择语义层拦截，尽量避免写死平台私有阈值的临时hack。</p></li></ul><h2>官方参考链接</h2><ul><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="http://CVE.org">CVE.org</a><a target="_blank" rel="noopener noreferrer nofollow" href="https://cve.org/CVERecord?id=CVE-2026-123158"> 官方记录</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://nvd.nist.gov/vuln/detail/cve-2026-123158">NVD 漏洞详情</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://www.openssh.com/releasenotes.html#10.6p2">OpenSSH Release Notes 10.6p2</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://sshhole.com/">sshhole 漏洞专题页</a></p></li></ul><p></p>', '5eee4f85-0aaf-4fb0-9447-cc7dc089047b'::uuid, '{0e919136-6a50-458d-ae70-3a2cde87d866,5e055b7c-a86d-431e-befd-12fc20efe7f9,6c1df245-5e8a-42e2-86b7-8c82dfa5b737,7657dad3-b0bb-4cd3-8b7a-4ea382aef526,7b5f1d69-c6c9-4733-84c8-6c395f23199d,a8bdd31d-6a36-4ba4-941a-cc0bdefb123e}'::uuid[], '2026-11-06 15:18:02.080504+08'::timestamptz),
  ('e559a078-3954-4497-b1de-c42dc2db2cf1'::uuid, '091ccc31-caaf-48d0-842d-a3e1b77e1951'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'gogs-diary · 部署与运行', '<h2>1. 环境要求</h2>
<ul>
<li>Python 3.12+</li>
<li>uv</li>
<li>同服务器可访问 Gogs SQLite</li>
<li>思源笔记 HTTP API 可达</li>
</ul>
<h2>2. 安装</h2>
<pre><code class="language-bash">cd /home/deploy
git clone https://git.nbook.icu/kairo/gogs-diary.git
cd gogs-diary
uv sync
cp .env.example .env
# 编辑 .env 填入配置
</code></pre>
<h2>3. 配置项</h2>
<h3>.env</h3>
<pre><code>GOGS_DB_PATH=/home/deploy/selfhost/gogs/data/gogs/data/gogs.db
GOGS_URL=http://localhost:3000
GOGS_TOKEN=
DEEPSEEK_API_KEY=
DEEPSEEK_MODEL=deepseek-flash
SIYUAN_URL=https://note.nbook.icu
SIYUAN_TOKEN=
SIYUAN_NOTEBOOK_ID=20261015151147-ivwb5le
</code></pre>
<h3>prompts.toml</h3>
<p>四个周期的提示词模板，改完直接生效，不用动代码。注意：标题由代码统一控制，DS 只输出正文。</p>
<h2>4. 运行命令</h2>
<pre><code class="language-bash"># 日记（默认模式）
uv run python -m gogs_diary.main

# 周报/月报/年报
uv run python -m gogs_diary.main weekly
uv run python -m gogs_diary.main monthly
uv run python -m gogs_diary.main yearly

# 补历史数据
uv run python -m gogs_diary.main daily --date 2026-10-18
uv run python -m gogs_diary.main weekly --date 2026-10-15
uv run python -m gogs_diary.main monthly --date 2026-10-15
uv run python -m gogs_diary.main yearly --date 2025-06-01
</code></pre>
<h2>5. cron 配置</h2>
<pre><code class="language-cron"># 每天 19:00 日记
0 19 * * * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main

# 每周一 09:00 周报
0 9 * * 1 cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main weekly

# 每月 1 号 00:30 月报
30 0 1 * * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main monthly

# 每年 1 月 1 号 01:00 年报
0 1 1 1 * cd /home/deploy/gogs-diary &amp;&amp; /home/deploy/.local/bin/uv run python -m gogs_diary.main yearly
</code></pre>
<h2>6. 日志</h2>
<p>按模式分文件，保留 90 天：</p>
<pre><code>logs/
├── daily_2026-10-19.log
├── weekly_2026-10-19.log
├── monthly_2026-10-19.log
└── yearly_2026-10-19.log
</code></pre>
<h2>7. 更新</h2>
<pre><code class="language-bash">cd /home/deploy/gogs-diary
git pull
uv sync
</code></pre>
', 'a1e7e98b-f958-4d11-9727-964a23a0415e'::uuid, '{5e055b7c-a86d-431e-befd-12fc20efe7f9,74cf4d60-cb10-4ccf-affc-52e0d112245d,ad0abb97-30ed-4c5b-9214-b4f284e55da6}'::uuid[], '2026-10-31 17:43:29.057323+08'::timestamptz),
  ('f6361c86-7102-48f8-8539-00b90cc79d8a'::uuid, '59f4dcc0-7ee3-44ba-a4b6-9310830c5b55'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '搜索查重工具方案', '<h2>1 概述</h2>
<p>本工具为浏览器端 Tampermonkey（油猴）查重工具，<strong>同时支持百度、必应搜索结果实时检测</strong>，用于在搜索浏览过程中自动识别命中规则的搜索标题。 核心设计目标：<strong>脱敏、本地存储、无硬编码敏感内容、笔记可安全同步</strong>。</p>
<blockquote>
<p>所有业务关键词、匹配规则全部抽离，脚本源码仅为通用逻辑，不包含任何业务标识、标题、品牌词，采用 <code>example</code> 作为内部标记，适合存入思源笔记等同步知识库。</p>
</blockquote>
<h2>2 功能清单</h2>
<ol>
<li>覆盖平台：百度（PC+移动端搜索页）、必应（PC搜索页）</li>
<li>匹配方式：正则表达式数组，<strong>不区分大小写</strong>，模糊匹配标题文本</li>
<li>触发时机：页面初次加载、滚动加载新结果、DOM动态更新</li>
<li>防抖控制：400ms 防抖，避免频繁扫描</li>
<li>通知方式：浏览器原生通知弹窗，控制台打印命中日志</li>
<li>去重机制：内存集合缓存已命中标题，同一条结果不会重复弹窗</li>
<li>规则存储：规则数组保存在浏览器 <code>localStorage</code>，脚本内无硬编码规则</li>
<li>日志输出：仅打印搜索词 + 结果总数；只有命中时输出命中详情，日志干净</li>
</ol>
<h2>3 架构与数据流向</h2>
<pre><code>浏览器打开百度/必应搜索页 → Tampermonkey 脚本启动
→ 读取 localStorage 内 example 规则数组
→ 编译为不区分大小写正则
→ 监听页面DOM变化、滚动事件
→ 抓取搜索结果标题+链接
→ 循环正则匹配标题
→ 命中：控制台输出记录 + 浏览器通知；做内存去重
→ 未命中：无输出

</code></pre>
<blockquote>
<p>数据边界：<strong>规则只存在当前浏览器实例，无痕窗口、其他浏览器需要重新导入</strong>；脚本本身不向任何外部服务器上传搜索词、标题、匹配规则。</p>
</blockquote>
<h2>4 平台适配说明</h2>
<h3>4.1 百度（PC+移动端）</h3>
<ul>
<li>匹配URL：<code>www.baidu.com/s</code>、<code>m.baidu.com/s</code></li>
<li>DOM选择器
<ul>
<li>PC结果：<code>a.normal-sub_11u5j</code></li>
<li>移动端结果：<code>section.cosc-card-content</code></li>
</ul>
</li>
<li>标题节点：<code>h3[data-module=&#34;top_title&#34;]</code></li>
<li>搜索关键词取自URL参数 <code>word</code></li>
</ul>
<h3>4.2 必应（PC）</h3>
<ul>
<li>匹配URL：<code>cn.bing.com/search</code>、<code>www.bing.com/search</code></li>
<li>DOM选择器：<code>li.b_algo</code></li>
<li>标题节点：<code>h2 a</code></li>
<li>搜索关键词取自URL参数 <code>q</code></li>
</ul>
<blockquote>
<p>风险：搜索引擎前端DOM结构改版会导致选择器失效，需要更新对应选择器。</p>
</blockquote>
<h2>5 脱敏与安全设计（重点）</h2>
<ol>
<li><strong>规则抽离</strong>：所有匹配正则不写在脚本源码，统一放在 <code>localStorage.example_check_exp</code></li>
<li><strong>源码脱敏</strong>：脚本内部标记统一使用 <code>example</code>，不存在业务名称、项目代号、产品词</li>
<li><strong>无持久化泄露</strong>：脚本本身不写任何业务内容到笔记、云端；笔记只保存通用脚本逻辑文档</li>
<li><strong>本地运算</strong>：全部匹配逻辑在浏览器前端完成，无后端、无API、无数据外发</li>
<li><strong>隔离特性</strong>：localStorage 是浏览器域隔离，不同浏览器、无痕模式相互独立</li>
</ol>
<h2>6 规则管理操作手册（控制台执行）</h2>
<p>存储键：<code>example_check_exp</code>，值为 JSON 字符串数组，正则<strong>不需要前后 <code>/</code></strong>。</p>
<pre><code>// 导入/更新规则
const expList = [
    &#34;xxx.*aaa&#34;,
    &#34;bbb.*ccc&#34;
];
localStorage.setItem(&#34;example_check_exp&#34;, JSON.stringify(expList));

// 查看当前规则
JSON.parse(localStorage.getItem(&#34;example_check_exp&#34;))

// 复制规则到剪贴板，用于备份
copy(JSON.parse(localStorage.getItem(&#34;example_check_exp&#34;)))

// 清空全部规则
localStorage.removeItem(&#34;example_check_exp&#34;)

</code></pre>
<ul>
<li>规则示例：<code>工业触摸.*显示器</code>、<code>医疗.*触控屏</code></li>
<li>语法：标准 JS 正则字符串，<code>.*</code> 代表任意字符，匹配时忽略大小写</li>
</ul>
<h2>7 日志输出格式</h2>
<pre><code>=====搜索词===== 页面链接总数：N
✅命中 | 标题：xxx | 链接：xxx

</code></pre>
<ul>
<li>无规则时提示：<code>=====搜索词===== 页面链接总数：0，未配置example规则</code></li>
<li>控制台仅保留必要信息，不批量打印全部搜索结果</li>
</ul>
<h2>8 依赖与前置条件</h2>
<ol>
<li>浏览器扩展：Tampermonkey（油猴）</li>
<li>浏览器权限：页面通知权限（否则弹窗通知不生效）</li>
<li>限制：
<ul>
<li>搜索引擎前端改版 → 选择器失效，扫描失效</li>
<li>无痕模式默认隔离 localStorage，规则丢失</li>
<li>多浏览器使用需要分别导入规则</li>
</ul>
</li>
<li>部署方式：百度、必应分为两个独立脚本，在 Tampermonkey 分别新建脚本粘贴</li>
</ol>
<h2>9 维护与迭代清单</h2>
<table>
<thead>
<tr>
<th style="text-align:left">事项</th>
<th style="text-align:left">操作</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">新增/修改匹配关键词</td>
<td style="text-align:left">控制台重新导入 exp 数组</td>
</tr>
<tr>
<td style="text-align:left">百度页面改版</td>
<td style="text-align:left">更新 pcCards、mobileCards 选择器</td>
</tr>
<tr>
<td style="text-align:left">必应页面改版</td>
<td style="text-align:left">更新 <code>li.b_algo</code> 结果选择器</td>
</tr>
<tr>
<td style="text-align:left">更换浏览器</td>
<td style="text-align:left">重新导入规则</td>
</tr>
<tr>
<td style="text-align:left">停用</td>
<td style="text-align:left">Tampermonkey 内关闭脚本开关</td>
</tr>
</tbody>
</table>
<h2>10 风险说明</h2>
<ol>
<li>搜索引擎前端结构不定期升级，属于外部依赖，无法保证长期稳定；</li>
<li>localStorage 仅本地存储，无自动备份，建议定期 <code>copy</code> 导出规则单独备份；</li>
<li>仅做标题文本匹配，不做内容正文抓取，只能判断标题命中；</li>
<li>浏览器通知权限被拦截时，仅保留控制台日志，不会弹窗提醒。</li>
</ol>
<p>如果你需要，我可以再给一份精简摘要版（适合放在笔记顶部）。</p>
', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-02 13:42:37.543091+08'::timestamptz),
  ('fde347e3-8966-4855-82d4-7fe1b62b4ba2'::uuid, '59f4dcc0-7ee3-44ba-a4b6-9310830c5b55'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '搜索查重工具方案', '<h2>1 概述</h2>
<p>本工具为浏览器端 Tampermonkey（油猴）查重工具，<strong>同时支持百度、必应搜索结果实时检测</strong>，用于在搜索浏览过程中自动识别命中规则的搜索标题。 核心设计目标：<strong>脱敏、本地存储、无硬编码敏感内容、笔记可安全同步</strong>。</p>
<h2>2 功能清单</h2>
<ol>
<li>覆盖平台：百度（PC+移动端搜索页）、必应（PC搜索页）</li>
<li>匹配方式：正则表达式数组，<strong>不区分大小写</strong>，模糊匹配标题文本</li>
<li>触发时机：页面初次加载、滚动加载新结果、DOM动态更新</li>
<li>防抖控制：400ms 防抖，避免频繁扫描</li>
<li>通知方式：浏览器原生通知弹窗，控制台打印命中日志</li>
<li>去重机制：内存集合缓存已命中标题，同一条结果不会重复弹窗</li>
<li>规则存储：规则数组保存在浏览器 <code>localStorage</code>，脚本内无硬编码规则</li>
<li>日志输出：仅打印搜索词 + 结果总数；只有命中时输出命中详情，日志干净</li>
</ol>
<h2>3 架构与数据流向</h2>
<pre><code>浏览器打开百度/必应搜索页 → Tampermonkey 脚本启动
→ 读取 localStorage 内 example 规则数组
→ 编译为不区分大小写正则
→ 监听页面DOM变化、滚动事件
→ 抓取搜索结果标题+链接
→ 循环正则匹配标题
→ 命中：控制台输出记录 + 浏览器通知；做内存去重
→ 未命中：无输出

</code></pre>
<blockquote>
<p>数据边界：<strong>规则只存在当前浏览器实例，无痕窗口、其他浏览器需要重新导入</strong>；脚本本身不向任何外部服务器上传搜索词、标题、匹配规则。</p>
</blockquote>
<h2>4 平台适配说明</h2>
<h3>4.1 百度（PC+移动端）</h3>
<ul>
<li>匹配URL：<code>www.baidu.com/s</code>、<code>m.baidu.com/s</code></li>
<li>DOM选择器
<ul>
<li>PC结果：<code>a.normal-sub_11u5j</code></li>
<li>移动端结果：<code>section.cosc-card-content</code></li>
</ul>
</li>
<li>标题节点：<code>h3[data-module=&#34;top_title&#34;]</code></li>
<li>搜索关键词取自URL参数 <code>word</code></li>
</ul>
<h3>4.2 必应（PC）</h3>
<ul>
<li>匹配URL：<code>cn.bing.com/search</code>、<code>www.bing.com/search</code></li>
<li>DOM选择器：<code>li.b_algo</code></li>
<li>标题节点：<code>h2 a</code></li>
<li>搜索关键词取自URL参数 <code>q</code></li>
</ul>
<blockquote>
<p>风险：搜索引擎前端DOM结构改版会导致选择器失效，需要更新对应选择器。</p>
</blockquote>
<h2>5 脱敏与安全设计（重点）</h2>
<ol>
<li><strong>规则抽离</strong>：所有匹配正则不写在脚本源码，统一放在 <code>localStorage.example_check_exp</code></li>
<li><strong>源码脱敏</strong>：脚本内部标记统一使用 <code>example</code>，不存在业务名称、项目代号、产品词</li>
<li><strong>无持久化泄露</strong>：脚本本身不写任何业务内容到笔记、云端；笔记只保存通用脚本逻辑文档</li>
<li><strong>本地运算</strong>：全部匹配逻辑在浏览器前端完成，无后端、无API、无数据外发</li>
<li><strong>隔离特性</strong>：localStorage 是浏览器域隔离，不同浏览器、无痕模式相互独立</li>
</ol>
<h2>6 规则管理操作手册（控制台执行）</h2>
<p>存储键：<code>example_check_exp</code>，值为 JSON 字符串数组，正则<strong>不需要前后 <code>/</code></strong>。</p>
<pre><code>// 导入/更新规则
const expList = [
    &#34;xxx.*aaa&#34;,
    &#34;bbb.*ccc&#34;
];
localStorage.setItem(&#34;example_check_exp&#34;, JSON.stringify(expList));

// 查看当前规则
JSON.parse(localStorage.getItem(&#34;example_check_exp&#34;))

// 复制规则到剪贴板，用于备份
copy(JSON.parse(localStorage.getItem(&#34;example_check_exp&#34;)))

// 清空全部规则
localStorage.removeItem(&#34;example_check_exp&#34;)

</code></pre>
<ul>
<li>规则示例：<code>工业触摸.*显示器</code>、<code>医疗.*触控屏</code></li>
<li>语法：标准 JS 正则字符串，<code>.*</code> 代表任意字符，匹配时忽略大小写</li>
</ul>
<h2>7 日志输出格式</h2>
<pre><code>=====搜索词===== 页面链接总数：N
✅命中 | 标题：xxx | 链接：xxx

</code></pre>
<ul>
<li>无规则时提示：<code>=====搜索词===== 页面链接总数：0，未配置example规则</code></li>
<li>控制台仅保留必要信息，不批量打印全部搜索结果</li>
</ul>
<h2>8 依赖与前置条件</h2>
<ol>
<li>浏览器扩展：Tampermonkey（油猴）</li>
<li>浏览器权限：页面通知权限（否则弹窗通知不生效）</li>
<li>限制：
<ul>
<li>搜索引擎前端改版 → 选择器失效，扫描失效</li>
<li>无痕模式默认隔离 localStorage，规则丢失</li>
<li>多浏览器使用需要分别导入规则</li>
</ul>
</li>
<li>部署方式：百度、必应分为两个独立脚本，在 Tampermonkey 分别新建脚本粘贴</li>
</ol>
<h2>9 维护与迭代清单</h2>
<table>
<thead>
<tr>
<th style="text-align:left">事项</th>
<th style="text-align:left">操作</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">新增/修改匹配关键词</td>
<td style="text-align:left">控制台重新导入 exp 数组</td>
</tr>
<tr>
<td style="text-align:left">百度页面改版</td>
<td style="text-align:left">更新 pcCards、mobileCards 选择器</td>
</tr>
<tr>
<td style="text-align:left">必应页面改版</td>
<td style="text-align:left">更新 <code>li.b_algo</code> 结果选择器</td>
</tr>
<tr>
<td style="text-align:left">更换浏览器</td>
<td style="text-align:left">重新导入规则</td>
</tr>
<tr>
<td style="text-align:left">停用</td>
<td style="text-align:left">Tampermonkey 内关闭脚本开关</td>
</tr>
</tbody>
</table>
<h2>10 风险说明</h2>
<ol>
<li>搜索引擎前端结构不定期升级，属于外部依赖，无法保证长期稳定；</li>
<li>localStorage 仅本地存储，无自动备份，建议定期 <code>copy</code> 导出规则单独备份；</li>
<li>仅做标题文本匹配，不做内容正文抓取，只能判断标题命中；</li>
<li>浏览器通知权限被拦截时，仅保留控制台日志，不会弹窗提醒。</li>
</ol>
<p>如果你需要，我可以再给一份精简摘要版（适合放在笔记顶部）。</p>
', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-03 20:48:30.524308+08'::timestamptz),
  ('7f72e3c6-50f2-40e7-b0b2-55aa55f3a9b0'::uuid, '2a0e9fc4-421d-4e43-8362-0556bc4b1e56'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '功能', '<ol>
<li>新的页面，复制展示保存的网页。</li>
<li>保存网页的功能</li>
</ol>
<ul data-type="taskList">
<li data-type="taskItem" data-checked="false"><br/></li>
</ul>
', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-04 13:20:30.327284+08'::timestamptz),
  ('f2290dde-1aa4-44e6-8b8e-31e6c8832304'::uuid, '6f62b534-b4b4-4d3c-8970-13d8306c2b13'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'wx-image-downloader 项目知识沉淀', '<blockquote>
<p>一键下载微信公众号文章封面与正文图片的工具。本文只记录可复用的技术知识，不写功能介绍。</p>
</blockquote>
<h2>项目架构速览</h2>
<table>
<thead>
<tr>
<th style="text-align:left">层</th>
<th style="text-align:left">技术</th>
<th style="text-align:left">说明</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">前端</td>
<td style="text-align:left">Vue 3.5 + naive-ui + Vite 6</td>
<td style="text-align:left">单页应用，缩略图勾选式 UI</td>
</tr>
<tr>
<td style="text-align:left">后端</td>
<td style="text-align:left">Fastify 5 + cheerio + undici + jszip</td>
<td style="text-align:left">API 服务 + 图片代理 + zip 打包</td>
</tr>
<tr>
<td style="text-align:left">包管理</td>
<td style="text-align:left">pnpm 12.11.2（corepack 启用）</td>
<td style="text-align:left"><code>pnpm-workspace.yaml</code> 锁定 esbuild 构建</td>
</tr>
<tr>
<td style="text-align:left">端口</td>
<td style="text-align:left">后端 3000 / dev 前端 5173</td>
<td style="text-align:left">Vite proxy 把 ​<code>/api</code> 转发到 3000</td>
</tr>
<tr>
<td style="text-align:left">启动</td>
<td style="text-align:left"><code>start.bat</code>​ → ​<code>pnpm start</code></td>
<td style="text-align:left">生产模式 Fastify 同时静态托管 ​<code>dist/</code></td>
</tr>
</tbody>
</table>
<pre><code>开发:  pnpm dev   → Vite(5173) 代理 /api → Fastify(3000)
生产:  pnpm build → pnpm start → Fastify(3000) 单端口服务 API + 静态文件
</code></pre>
<p>API 端点：​<code>POST /api/preview</code>​（解析文章）、​<code>POST /api/download</code>​（打包 zip）、​<code>GET /api/thumb</code>​（图片代理）、​<code>POST /api/open-folder</code>。</p>
<hr/>
<h2>核心知识一：微信公众号图片爬取的五个关键坑</h2>
<h3>1. 懒加载：真实地址在 ​<code>data-src</code>​ 而非 ​<code>src</code></h3>
<p>微信文章正文 ​<code>&lt;img&gt;</code>​ 的 ​<code>src</code>​ 通常是占位图或空，真实图片 URL 在 ​<code>data-src</code>​ 属性。解析时必须优先读 ​<code>data-src</code>：</p>
<pre><code class="language-js">let url = $(child).attr(&#39;data-src&#39;) || $(child).attr(&#39;src&#39;) || &#39;&#39;
</code></pre>
<h3>2. 清理懒加载参数才能拿原图</h3>
<p>微信图片 URL 会带 ​<code>wxfrom</code>​、​<code>wx_lazy</code>​、​<code>wx_co</code>​、​<code>tp</code>​、​<code>wx_header</code> 等参数。这些参数会触发微信的压缩/降级逻辑，去掉后才能拿到原图：</p>
<pre><code class="language-js">const WX_LAZY_PARAMS = new Set([&#39;wxfrom&#39;, &#39;wx_lazy&#39;, &#39;wx_co&#39;, &#39;tp&#39;, &#39;wx_header&#39;])
function cleanWxUrl(url) {
  const u = new URL(url)
  const keep = [...u.searchParams.entries()].filter(([k]) =&gt; !WX_LAZY_PARAMS.has(k))
  u.search = new URLSearchParams(keep).toString()
  return u.toString()
}
</code></pre>
<h3>3. 防盗链：必须带 Referer</h3>
<p>微信图片服务器校验 ​<code>Referer</code>​，直接请求返回 403。Referer 必须是文章页 URL。这也是<strong>前端不能直接加载微信图片</strong>的根本原因——浏览器会带页面 origin 作为 Referer，被微信拒绝。因此需要后端做图片代理：</p>
<pre><code class="language-js">// 后端 GET /api/thumb 代理图片，注入正确的 Referer
headers: { &#39;User-Agent&#39;: USER_AGENT, Referer: articleUrl, Accept: &#39;image/*&#39; }
</code></pre>
<p>前端缩略图 URL 构造成：​<code>/api/thumb?url=&lt;encodeURIComponent(图片URL)&gt;&amp;referer=&lt;encodeURIComponent(文章URL)&gt;</code></p>
<h3>4. 封面图提取优先级</h3>
<pre><code>meta[property=&#34;og:image&#34;] → meta[name=&#34;og:image&#34;]
→ meta[property=&#34;twitter:image&#34;] → meta[name=&#34;twitter:image&#34;]
→ #js_content / .rich_media_content 内第一张 img 的 data-src
</code></pre>
<h3>5. 微信动画轮播图（SVG 长图滑动）</h3>
<p>公众号里常见的&#34;横向滑动长图/多帧轮播&#34;不是 ​<code>&lt;img&gt;</code>​，而是一个 ​<code>&lt;svg&gt;</code>​ 包裹 ​<code>&lt;foreignObject&gt;</code>​，配合 ​<code>animateTransform</code> 做平移动画。每一帧图片藏在：</p>
<ul>
<li><code>foreignObject &gt; svg[data-lazy-bgimg]</code>​ 的 ​<code>data-lazy-bgimg</code></li>
<li>或内部 ​<code>svg[data-src]</code></li>
<li>或 ​<code>style=&#34;background-image: url(...)&#34;</code> 里</li>
</ul>
<p>提取方式：检测 ​<code>$svg.find(&#39;animateTransform&#39;).length &gt; 0</code>​，然后遍历 ​<code>foreignObject</code>​，从 ​<code>data-lazy-bgimg</code>​ / ​<code>data-src</code>​ / CSS ​<code>url()</code>​ 中正则提取每帧 URL，结合 ​<code>viewBox</code> 解析宽高比。</p>
<h3>6. HTML 可能被 JSON 转义包裹</h3>
<p>部分微信文章返回的 HTML 最外层是一个 JSON 字符串（带 BOM），需要先尝试 ​<code>JSON.parse</code> 解一层再交给 cheerio：</p>
<pre><code class="language-js">function decodePossibleEscaped(html) {
  const stripped = html.replace(/^﻿\s*/, &#39;&#39;)  // 去 BOM
  try { const d = JSON.parse(stripped); if (typeof d === &#39;string&#39;) return d } catch {}
  return html
}
</code></pre>
<hr/>
<h2>核心知识二：图片格式识别的三级策略</h2>
<p>微信图片 URL 不一定带扩展名，需要按优先级判定保存后缀：</p>
<ol>
<li><strong>URL 参数</strong> ​<strong>​<code>wx_fmt</code>​</strong>​：微信特有参数，值如 ​<code>jpeg</code>​、​<code>png</code>​、​<code>gif</code>​、​<code>webp</code></li>
<li><strong>Content-Type 响应头</strong>：MIME 映射到扩展名</li>
<li><strong>文件头魔数（magic bytes）</strong> ：前 16 字节判定</li>
</ol>
<pre><code class="language-js">// 魔数判定
FF D8 FF                          → jpg
89 50 4E 47 (‰PNG)               → png
47 49 46 38 (GIF8)               → gif
52 49 46 46 ... 57 45 42 50     → webp (RIFF....WEBP)
</code></pre>
<hr/>
<h2>核心知识三：并发下载与重试模式</h2>
<ul>
<li><strong>Worker pool</strong>：固定 5 个并发消费者，共享一个队列，​<code>queue.shift()</code> 逐个取任务</li>
<li><strong>重试退避</strong>：HTML 请求重试 3 次，间隔 ​<code>i * 2000ms</code>​；图片请求间隔 ​<code>i * 1000ms</code></li>
<li><strong>超时</strong>：​<code>bodyTimeout: 20000, headersTimeout: 20000</code>（undici）</li>
<li><strong>下载结果</strong>：直接在内存中用 JSZip 打包成 ​<code>nodebuffer</code>​，通过 ​<code>Content-Disposition: attachment</code> 返回浏览器，不落盘</li>
</ul>
<hr/>
<h2>核心知识四：目录与文件名清理</h2>
<pre><code class="language-js">// Windows 非法字符替换为下划线，截断到 80 字符
name = name.replace(/[\\/:*?&#34;&lt;&gt;|\r\n\t]/g, &#39;_&#39;).trim()
name = name.replace(/\s+/g, &#39; &#39;)
name = name.slice(0, 80).trim().replace(/^[ .]+|[ .]+$/, &#39;&#39;)
</code></pre>
<p>文章标题去掉开头的&#34;原创&#34;前缀后作为 zip 内文件夹名。图片按出现顺序三位编号：​<code>cover</code>​（封面）、​<code>001</code>​（正文图）、​<code>001_01</code>（动画帧）。</p>
<hr/>
<h2>工程要点</h2>
<ul>
<li><strong>​<code>@fastify/static</code>​</strong>​ <strong>仅在非 dev 模式注册</strong>，避免 dev 时 Vite 与静态服务冲突</li>
<li><strong>Vite dev proxy</strong>：​<code>&#39;/api&#39;: &#39;http://localhost:3000&#39;</code>，前端 fetch 用相对路径</li>
<li><strong>pnpm onlyBuiltDependencies</strong>：​<code>pnpm-workspace.yaml</code>​ 中显式允许 esbuild 构建，配合 ​<code>.npmrc</code>​ 的 ​<code>strict-dep-builds=false</code></li>
<li><strong>start.bat 首跑逻辑</strong>：检测 pnpm → ​<code>corepack enable</code>​ → 无 ​<code>node_modules</code>​ 则 ​<code>pnpm install --allow-build=esbuild</code>​ → ​<code>pnpm start</code></li>
<li><strong>CORS</strong>：​<code>@fastify/cors</code>​ 设 ​<code>origin: true</code>，本地工具无需严格限制</li>
<li><strong>旧版</strong> ​<strong>​<code>python-legacy/</code>​</strong> ​：Python + tkinter + PyInstaller 实现，用 ​<code>requests</code>​ + ​<code>beautifulsoup4</code>​ + ​<code>ttkbootstrap</code>，GitHub Actions 推 tag 自动三平台打包；已被 Node 版取代但保留参考</li>
</ul>
<h2>可复用清单</h2>
<ul data-type="taskList">
<li data-type="taskItem" data-checked="false">微信文章 HTML 解析：cheerio + ​<code>#js_content</code> 容器</li>
<li data-type="taskItem" data-checked="false">图片代理模式：后端注入 Referer 解决防盗链 + CORS</li>
<li data-type="taskItem" data-checked="false">三级格式识别：URL 参数 → MIME → magic bytes</li>
<li data-type="taskItem" data-checked="false">SVG foreignObject 动画帧提取</li>
<li data-type="taskItem" data-checked="false">Worker pool 并发 + 指数退避重试</li>
<li data-type="taskItem" data-checked="false">JSZip 内存打包直传浏览器</li>
</ul>
', '6f9b36f3-b5ee-4cd6-aeb0-1c011a524893'::uuid, '{570ba71b-e352-460f-852e-722462579e2f}'::uuid[], '2026-11-04 13:21:01.597251+08'::timestamptz),
  ('bd7317ad-f474-4d2c-a870-d22fbfc0d4e6'::uuid, '2a0e9fc4-421d-4e43-8362-0556bc4b1e56'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '功能', '<ol><li><p>新的页面，复制展示保存的网页。</p></li><li><p>保存网页的功能</p></li></ol><p></p><ul data-type="taskList"><li data-checked="false" data-type="taskItem"><label><input type="checkbox"><span></span></label><div><p>发大水</p></div></li></ul><p></p>', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-04 13:33:28.142291+08'::timestamptz),
  ('e3bb7234-0ab8-44ce-9adb-d7a6b55b0c1f'::uuid, 'a6866ed7-62a8-4405-a43e-af98fa312041'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Js', '<pre><code class="language-javascript">// ==UserScript==
// @name         搜索查重（百度｜example脱敏版）
// @namespace    http://tampermonkey.net/
// @version      2.14
// @description  百度PC/移动端查重，匹配规则从localStorage读取，无硬编码敏感内容；仅浏览器通知，精简日志
// @author       You
// @match        https://www.baidu.com/s*
// @match        https://baidu.com/s*
// @match        https://m.baidu.com/s*
// @match        https://m.baidu.com/from=*/ssid=*/s?*
// @grant        none
// ==/UserScript==


(function() {
    &#39;use strict&#39;;
    console.log(&#34;=====example 搜索查重（百度）脚本启动=====&#34;);

    const CONFIG = {
        STORAGE_KEY: &#34;example_check_exp&#34;
    };

    // 读取正则表达式数组
    function getExpList() {
        const raw = localStorage.getItem(CONFIG.STORAGE_KEY);
        if (!raw) return [];
        try {
            const arr = JSON.parse(raw);
            return arr.map(item =&gt; new RegExp(item, &#34;i&#34;));
        } catch (e) {
            return [];
        }
    }

    function normalize(str){
        return str.replace(/\s+/g,&#39; &#39;).trim();
    }

    function getSearchWord() {
        const urlParams = new URLSearchParams(location.search);
        return urlParams.get(&#39;word&#39;) || &#39;&#39;;
    }

    let isRunning = false;
    let debounceTimer = null;
    const notifiedSet = new Set();

    function sendNotify(titleText, matchText){
        const msg = `标题：${titleText}\n${matchText}`;
        if(&#34;Notification&#34; in window &amp;&amp; Notification.permission === &#34;granted&#34;){
            new Notification(&#39;example 查重命中&#39;, { body: msg });
        }
    }

    function scan(){
        if(isRunning) return;
        isRunning = true;
        try{
            const keyword = getSearchWord();
            const expList = getExpList();
            if(expList.length === 0) {
                console.log(`=====${keyword}===== 页面链接总数：0，未配置example规则`);
                return;
            }

            const pcCards = document.querySelectorAll(&#39;a.normal-sub_11u5j&#39;);
            const mobileCards = document.querySelectorAll(&#39;section.cosc-card-content&#39;);
            const allCards = [...pcCards, ...mobileCards];
            console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`);

            allCards.forEach(card=&gt;{
                let rawTitle = &#34;&#34;;
                let linkUrl = &#34;&#34;;
                let hitReason = null;

                if (card.tagName === &#34;A&#34;) {
                    const titleEl = card.querySelector(&#39;h3[data-module=&#34;top_title&#34;]&#39;);
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    linkUrl = card.href;
                } else {
                    const titleEl = card.querySelector(&#39;div[data-module=&#34;title&#34;] h3&#39;);
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    const aTag = card.querySelector(&#34;a&#34;);
                    linkUrl = aTag?.href || &#34;&#34;;
                }

                const titleNorm = normalize(rawTitle);
                for(const exp of expList){
                    if(exp.test(titleNorm)){
                        hitReason = `example 正则匹配：${exp.source}`;
                        break;
                    }
                }

                const titleKey = rawTitle;
                if(notifiedSet.has(titleKey)) return;

                if(hitReason){
                    notifiedSet.add(titleKey);
                    console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl}`);
                    sendNotify(rawTitle, hitReason);
                }
            })
        }finally{
            isRunning = false;
        }
    }

    function debounceScan(){
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(scan, 400);
    }

    function start(){
        if (&#34;Notification&#34; in window &amp;&amp; Notification.permission !== &#34;granted&#34; &amp;&amp; Notification.permission !== &#34;denied&#34;){
            Notification.requestPermission();
        }
        const observer = new MutationObserver(()=&gt; debounceScan());
        observer.observe(document.body, {childList:true, subtree:true});

        window.addEventListener(&#39;scroll&#39;, debounceScan, {passive:true});
        scan();
        setTimeout(scan, 1200);
    }
    if(document.body) start();
    else document.addEventListener(&#39;DOMContentLoaded&#39;, start);
})();

</code></pre>
<pre><code class="language-javascript">// ==UserScript==
// @name         搜索查重（必应｜example脱敏版）
// @namespace    http://tampermonkey.net/
// @version      1.5
// @description  必应PC/移动端查重，匹配规则从localStorage读取，无硬编码敏感内容；仅浏览器通知，精简日志
// @author       You
// @match        https://cn.bing.com/search*
// @match        https://www.bing.com/search*
// @grant        none
// ==/UserScript==


(function() {
    &#39;use strict&#39;;
    console.log(&#34;=====example 搜索查重（必应）脚本启动=====&#34;);

    const CONFIG = {
        STORAGE_KEY: &#34;example_check_exp&#34;
    };

    function getExpList() {
        const raw = localStorage.getItem(CONFIG.STORAGE_KEY);
        if (!raw) return [];
        try {
            const arr = JSON.parse(raw);
            return arr.map(item =&gt; new RegExp(item, &#34;i&#34;));
        } catch (e) {
            return [];
        }
    }

    function normalize(str){
        return str.replace(/\s+/g,&#39; &#39;).trim();
    }

    function getSearchWord() {
        const urlParams = new URLSearchParams(location.search);
        return urlParams.get(&#39;q&#39;) || &#39;&#39;;
    }

    let isRunning = false;
    let debounceTimer = null;
    const notifiedSet = new Set();

    function sendNotify(titleText, matchText){
        const msg = `标题：${titleText}\n${matchText}`;
        if(&#34;Notification&#34; in window &amp;&amp; Notification.permission === &#34;granted&#34;){
            new Notification(&#39;example 查重命中【必应】&#39;, { body: msg });
        }
    }

    function scan(){
        if(isRunning) return;
        isRunning = true;
        try{
            const keyword = getSearchWord();
            const expList = getExpList();
            if(expList.length === 0) {
                console.log(`=====${keyword}===== 页面链接总数：0，未配置example规则`);
                return;
            }

            const cards = document.querySelectorAll(&#39;li.b_algo&#39;);
            console.log(`=====${keyword}===== 页面链接总数：${cards.length}`);

            cards.forEach(card=&gt;{
                let rawTitle = &#34;&#34;;
                let linkUrl = &#34;&#34;;
                let hitReason = null;

                const titleEl = card.querySelector(&#39;h2 a&#39;);
                if(!titleEl) return;
                rawTitle = titleEl.innerText.trim();
                linkUrl = titleEl.href;

                const titleNorm = normalize(rawTitle);
                for(const exp of expList){
                    if(exp.test(titleNorm)){
                        hitReason = `example 正则匹配：${exp.source}`;
                        break;
                    }
                }

                const titleKey = rawTitle;
                if(notifiedSet.has(titleKey)) return;

                if(hitReason){
                    notifiedSet.add(titleKey);
                    console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl}`);
                    sendNotify(rawTitle, hitReason);
                }
            })
        }finally{
            isRunning = false;
        }
    }

    function debounceScan(){
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(scan, 400);
    }

    function start(){
        if (&#34;Notification&#34; in window &amp;&amp; Notification.permission !== &#34;granted&#34; &amp;&amp; Notification.permission !== &#34;denied&#34;){
            Notification.requestPermission();
        }
        const observer = new MutationObserver(()=&gt; debounceScan());
        observer.observe(document.body, {childList:true, subtree:true});

        window.addEventListener(&#39;scroll&#39;, debounceScan, {passive:true});
        scan();
        setTimeout(scan, 1200);
    }
    if(document.body) start();
    else document.addEventListener(&#39;DOMContentLoaded&#39;, start);
})();

</code></pre>
', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-04 13:34:18.861049+08'::timestamptz),
  ('c0aa7fa7-72e7-48ba-b3d4-0b9125bcb149'::uuid, '2a0e9fc4-421d-4e43-8362-0556bc4b1e56'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '功能', '<ul><li><p>新的页面，复制展示保存的网页。</p></li><li><p style="text-align: left;">保存网页的功能</p></li></ul><p></p>', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-04 14:10:02.266809+08'::timestamptz),
  ('ffea8e51-a1cb-4e74-a70c-2f34e0c8450b'::uuid, '59f4dcc0-7ee3-44ba-a4b6-9310830c5b55'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '搜索查重工具方案', '<h2>1 概述</h2>
<p>本工具为浏览器端 Tampermonkey（油猴）查重工具，<strong>同时支持百度、必应搜索结果实时检测</strong>，用于在搜索浏览过程中自动识别命中规则的搜索标题。 核心设计目标：<strong>脱敏、本地存储、无硬编码敏感内容、笔记可安全同步</strong>。</p>
<h2>2 功能清单</h2>
<ol>
<li>覆盖平台：百度（PC+移动端搜索页）、必应（PC搜索页）</li>
<li>匹配方式：正则表达式数组，<strong>不区分大小写</strong>，模糊匹配标题文本</li>
<li>触发时机：页面初次加载、滚动加载新结果、DOM动态更新</li>
<li>防抖控制：400ms 防抖，避免频繁扫描</li>
<li>通知方式：浏览器原生通知弹窗，控制台打印命中日志</li>
<li>去重机制：内存集合缓存已命中标题，同一条结果不会重复弹窗</li>
<li>规则存储：规则数组保存在浏览器 <code>localStorage</code>，脚本内无硬编码规则</li>
<li>日志输出：仅打印搜索词 + 结果总数；只有命中时输出命中详情，日志干净</li>
</ol>
<h2>3 架构与数据流向</h2>
<pre><code>浏览器打开百度/必应搜索页 → Tampermonkey 脚本启动
→ 读取 localStorage 内 example 规则数组
→ 编译为不区分大小写正则
→ 监听页面DOM变化、滚动事件
→ 抓取搜索结果标题+链接
→ 循环正则匹配标题
→ 命中：控制台输出记录 + 浏览器通知；做内存去重
→ 未命中：无输出

</code></pre>
<blockquote>
<p>数据边界：<strong>规则只存在当前浏览器实例，无痕窗口、其他浏览器需要重新导入</strong>；脚本本身不向任何外部服务器上传搜索词、标题、匹配规则。</p>
</blockquote>
<h2>4 平台适配说明</h2>
<h3>4.1 百度（PC+移动端）</h3>
<ul>
<li>匹配URL：<code>www.baidu.com/s</code>、<code>m.baidu.com/s</code></li>
<li>DOM选择器
<ul>
<li>PC结果：<code>a.normal-sub_11u5j</code></li>
<li>移动端结果：<code>section.cosc-card-content</code></li>
</ul>
</li>
<li>标题节点：<code>h3[data-module=&#34;top_title&#34;]</code></li>
<li>搜索关键词取自URL参数 <code>word</code></li>
</ul>
<h3>4.2 必应（PC）</h3>
<ul>
<li>匹配URL：<code>cn.bing.com/search</code>、<code>www.bing.com/search</code></li>
<li>DOM选择器：<code>li.b_algo</code></li>
<li>标题节点：<code>h2 a</code></li>
<li>搜索关键词取自URL参数 <code>q</code></li>
</ul>
<blockquote>
<p>风险：搜索引擎前端DOM结构改版会导致选择器失效，需要更新对应选择器。</p>
</blockquote>
<h2>5 脱敏与安全设计（重点）</h2>
<ol>
<li><strong>规则抽离</strong>：所有匹配正则不写在脚本源码，统一放在 <code>localStorage.example_check_exp</code></li>
<li><strong>源码脱敏</strong>：脚本内部标记统一使用 <code>example</code>，不存在业务名称、项目代号、产品词</li>
<li><strong>无持久化泄露</strong>：脚本本身不写任何业务内容到笔记、云端；笔记只保存通用脚本逻辑文档</li>
<li><strong>本地运算</strong>：全部匹配逻辑在浏览器前端完成，无后端、无API、无数据外发</li>
<li><strong>隔离特性</strong>：localStorage 是浏览器域隔离，不同浏览器、无痕模式相互独立</li>
</ol>
<h2>6 规则管理操作手册（控制台执行）</h2>
<p>存储键：<code>example_check_exp</code>，值为 JSON 字符串数组，正则<strong>不需要前后 <code>/</code></strong>。</p>
<pre><code>// 导入/更新规则
const expList = [
    &#34;xxx.*aaa&#34;,
    &#34;bbb.*ccc&#34;
];
localStorage.setItem(&#34;example_check_exp&#34;, JSON.stringify(expList));

// 查看当前规则
JSON.parse(localStorage.getItem(&#34;example_check_exp&#34;))

// 复制规则到剪贴板，用于备份
copy(JSON.parse(localStorage.getItem(&#34;example_check_exp&#34;)))

// 清空全部规则
localStorage.removeItem(&#34;example_check_exp&#34;)

</code></pre>
<ul>
<li>规则示例：<code>工业触摸.*显示器</code>、<code>医疗.*触控屏</code></li>
<li>语法：标准 JS 正则字符串，<code>.*</code> 代表任意字符，匹配时忽略大小写</li>
</ul>
<h2>7 日志输出格式</h2>
<pre><code>=====搜索词===== 页面链接总数：N
✅命中 | 标题：xxx | 链接：xxx

</code></pre>
<ul>
<li>无规则时提示：<code>=====搜索词===== 页面链接总数：0，未配置example规则</code></li>
<li>控制台仅保留必要信息，不批量打印全部搜索结果</li>
</ul>
<h2>8 依赖与前置条件</h2>
<ol>
<li>浏览器扩展：Tampermonkey（油猴）</li>
<li>浏览器权限：页面通知权限（否则弹窗通知不生效）</li>
<li>限制：
<ul>
<li>搜索引擎前端改版 → 选择器失效，扫描失效</li>
<li>无痕模式默认隔离 localStorage，规则丢失</li>
<li>多浏览器使用需要分别导入规则</li>
</ul>
</li>
<li>部署方式：百度、必应分为两个独立脚本，在 Tampermonkey 分别新建脚本粘贴</li>
</ol>
<h2>9 维护与迭代清单</h2>
<table>
<thead>
<tr>
<th style="text-align:left">事项</th>
<th style="text-align:left">操作</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">新增/修改匹配关键词</td>
<td style="text-align:left">控制台重新导入 exp 数组</td>
</tr>
<tr>
<td style="text-align:left">百度页面改版</td>
<td style="text-align:left">更新 pcCards、mobileCards 选择器</td>
</tr>
<tr>
<td style="text-align:left">必应页面改版</td>
<td style="text-align:left">更新 <code>li.b_algo</code> 结果选择器</td>
</tr>
<tr>
<td style="text-align:left">更换浏览器</td>
<td style="text-align:left">重新导入规则</td>
</tr>
<tr>
<td style="text-align:left">停用</td>
<td style="text-align:left">Tampermonkey 内关闭脚本开关</td>
</tr>
</tbody>
</table>
<h2>10 风险说明</h2>
<ol>
<li>搜索引擎前端结构不定期升级，属于外部依赖，无法保证长期稳定；</li>
<li>localStorage 仅本地存储，无自动备份，建议定期 <code>copy</code> 导出规则单独备份；</li>
<li>仅做标题文本匹配，不做内容正文抓取，只能判断标题命中；</li>
<li>浏览器通知权限被拦截时，仅保留控制台日志，不会弹窗提醒。</li>
</ol>
<p>如果你需要，我可以再给一份精简摘要版（适合放在笔记顶部）。</p>
', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{42d2b22d-fcba-4b90-b59f-160aab8ee27a}'::uuid[], '2026-11-04 17:52:23.573002+08'::timestamptz),
  ('f35231e8-63ef-4655-80f3-51a197651800'::uuid, 'cdada194-4a76-42dd-b258-f21040e60c5d'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '分析报告：Windows 登录微软账户时要求“上次锁屏密码”的意义与安全边界', '<h2>一、摘要</h2>
<p>Windows 在登录微软账户时要求输入“上次锁屏密码”，并不是简单的重复验证，而是 <strong>本地凭据缓存</strong> 与 <strong>高风险场景降级验证</strong> 两种机制共同作用的结果。</p>
<p>但这一机制存在一个清晰的边界：<strong>当一个人拥有本地管理员权限并能物理接触设备时，他可以通过创建本地管理员账户、删除原微软账户的方式，改变系统需要验证的“身份主体”本身。</strong> 此时“上次密码”机制并非被攻破，而是被验证对象已经被替换。</p>
<p>这与 macOS 的设计形成鲜明对比：macOS 将本地 UNIX 账户与 Apple ID 分离，并在启用 FileVault 时把登录密码与数据解密密钥深度绑定。结果是：<strong>Windows 中“获得管理员权限”更接近获得设备控制权；macOS 中“重置登录密码”不等于获得原有数据的访问权。</strong></p>
<hr/>
<h2>二、Windows 要求“上次锁屏密码”的核心意义</h2>
<h3>1. 离线可用性：本地缓存的账户凭据</h3>
<p>Windows 允许设备在没有网络连接时登录微软账户。为了实现这一点，系统会在上次成功登录后，将账户密码或其派生验证信息加密缓存在本地。</p>
<p>当设备离线、无法连接微软服务器时，系统无法实时验证微软账户，只能使用本地缓存的凭据核对用户输入。</p>
<p>因此，该提示的含义可以理解为：</p>
<blockquote>
<p>“当前无法连接微软服务器，只能依赖本机缓存的上次登录凭据来验证身份。”</p>
</blockquote>
<p>如果用户在另一台设备上修改了微软账户密码，而这台 Windows 设备仍处于离线状态，则可能需要输入修改前的旧密码才能通过本地验证。</p>
<h3>2. 高风险场景下的安全降级验证</h3>
<p>Windows Hello PIN 是设备绑定的本地便捷凭证，适合日常登录和锁屏解锁。但它不是完整账户密码，权限边界有限。</p>
<p>当系统判断当前场景属于高风险或超出 PIN 的授权范围时，会要求使用与微软账户直接绑定的账户密码重新证明身份。典型场景包括：</p>
<ul>
<li>多次输错密码或 PIN；</li>
<li>更改 PIN、重置 Windows Hello 凭据；</li>
<li>执行涉及账户凭据变更的敏感操作；</li>
<li>远程桌面、访问某些网络资源或需要完整账户授权的场景。</li>
</ul>
<p>因此，“上次密码”机制的本质是：<strong>在便捷性与更高等级身份验证之间进行动态权衡。</strong></p>
<hr/>
<h2>三、同事操作复盘：为什么创建本地账号并删除微软账户可以绕过</h2>
<h3>1. 操作路径的本质</h3>
<p>同事的操作大致是：</p>
<ol>
<li>拥有本地管理员权限；</li>
<li>创建一个新的本地管理员账户；</li>
<li>使用新账户登录；</li>
<li>删除原来的微软账户及其关联登录凭据；</li>
<li>为新本地账户设置密码；</li>
<li>再次登录时，系统要求验证的是这个新本地账户的密码。</li>
</ol>
<h3>2. 被绕过的不是密码验证，而是验证对象</h3>
<p>关键点在于：<strong>系统后来验证的已经不再是原来的微软账户，而是新建的本地账户。</strong></p>
<p>原来的微软账户被删除后，针对该账户的“上次密码”验证自然失去意义。此时系统要求为新本地账户设置密码，并验证这个新密码，逻辑上是自洽的。</p>
<p>所以，这不是“上次密码机制失效”，而是：</p>
<blockquote>
<p><strong>拥有本地管理员权限的人，重新定义了“谁可以登录这台设备”。</strong></p>
</blockquote>
<h3>3. Windows 安全模型的固有边界</h3>
<p>Windows 的消费级设计优先保障账户体系的可管理性与可恢复性。本地管理员权限在软件层面接近设备配置的最终权限。</p>
<p>当一个人已经拥有管理员权限，并且能物理接触设备时，他可以：</p>
<ul>
<li>创建新的本地管理员账户；</li>
<li>删除原微软账户；</li>
<li>替换登录凭据；</li>
<li>重置 Windows Hello 容器；</li>
<li>重新配置安全规则。</li>
</ul>
<p>因此，针对旧账户的验证机制无法阻止这种操作，因为操作者已经越过了“正常登录验证”的边界，进入了“重新配置身份体系”的层级。</p>
<hr/>
<h2>四、Windows 与 macOS 的安全哲学差异</h2>
<table>
<thead>
<tr>
<th style="text-align:left">维度</th>
<th style="text-align:left">Windows</th>
<th style="text-align:left">macOS</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left">身份模型</td>
<td style="text-align:left">消费级版本强力推行微软账户作为系统登录身份</td>
<td style="text-align:left">本地 UNIX 账户与 Apple ID 分离，登录密码是本地账户密码</td>
</tr>
<tr>
<td style="text-align:left">管理员权限意义</td>
<td style="text-align:left">本地管理员权限接近设备安全配置的最终控制权</td>
<td style="text-align:left">管理员权限可重置访问权，但不自动等于解密原有数据</td>
</tr>
<tr>
<td style="text-align:left">数据加密绑定</td>
<td style="text-align:left">BitLocker 可选，需另行启用</td>
<td style="text-align:left">FileVault 与登录密码、硬件 UID、Secure Enclave 深度绑定</td>
</tr>
<tr>
<td style="text-align:left">忘记密码后的结果</td>
<td style="text-align:left">管理员可通过替换账户等方式恢复设备可用性</td>
<td style="text-align:left">可重置登录密码，但无恢复密钥时可能无法解密原有数据</td>
</tr>
<tr>
<td style="text-align:left">安全优先级</td>
<td style="text-align:left">账户可管理性、可恢复性</td>
<td style="text-align:left">静态数据机密性、防物理接触泄露</td>
</tr>
<tr>
<td style="text-align:left">核心边界</td>
<td style="text-align:left">拥有管理员权限≈获得设备控制权</td>
<td style="text-align:left">获得登录密码≠获得原有数据访问权</td>
</tr>
</tbody>
</table>
<hr/>
<h2>五、macOS 为什么不同</h2>
<h3>1. 本地账户与 Apple ID 分离</h3>
<p>macOS 的登录账户本质上是本地 UNIX 账户，和 Apple ID 是两个可以独立存在的身份。删除 Apple ID 不会自动动摇本地账户的根基。</p>
<h3>2. FileVault 与 Secure Enclave 的密钥保护</h3>
<p>在 Apple Silicon 或带 T2 芯片的 Mac 上，启用 FileVault 后，解密硬盘的密钥由登录密码和硬件 UID 共同保护，密钥派生与验证在 Secure Enclave 中完成。</p>
<p>这意味着：</p>
<ul>
<li>可以重置登录密码；</li>
<li>但如果没有 FileVault 恢复密钥或 Apple ID 解锁能力；</li>
<li>可能无法解密硬盘原有数据；</li>
<li>登入的可能是无法访问原有数据的空壳环境。</li>
</ul>
<h3>3. 关键结论</h3>
<blockquote>
<p><strong>Windows：权限可以替换验证主体，管理员权限接近最终控制权。</strong><br/>
<strong>macOS：访问权可以重置，但数据解密权不会自动随之恢复。</strong></p>
</blockquote>
<hr/>
<h2>六、安全启示</h2>
<h3>对个人设备</h3>
<ol>
<li><strong>保护好本地管理员账户密码</strong>，不要随意让陌生人物理接触已登录设备。</li>
<li><strong>启用 BitLocker</strong>，降低设备被物理接触后通过 PE 等方式重置密码、访问数据的风险。</li>
<li>理解“登录密码”“PIN”“微软账户密码”不是同一层级凭证。</li>
<li>重要数据应额外备份，不能只依赖系统登录安全。</li>
</ol>
<h3>对公司或共享设备</h3>
<ol>
<li><strong>限制普通用户的本地管理员权限</strong>，从根源上阻止“创建管理员账户→删除原账户”的路径。</li>
<li>物理管控不可替代：软件登录验证无法完全替代对设备实体的控制。</li>
<li>对共享设备应使用标准用户权限、集中账户管理和磁盘加密策略。</li>
</ol>
<hr/>
<h2>七、最终结论</h2>
<p>Windows 要求“上次锁屏密码”的意义，主要在于：</p>
<ol>
<li><strong>离线时使用本地缓存凭据验证身份</strong>；</li>
<li><strong>高风险或越权场景下要求更高等级账户密码验证</strong>。</li>
</ol>
<p>同事通过创建本地账号并删除微软账户来绕过锁屏密码，说明的不是该机制本身无效，而是揭示了 Windows 安全模型的边界：</p>
<blockquote>
<p><strong>当本地管理员权限与物理接触同时具备时，操作者可以替换被验证的身份主体，而不是攻破某一次密码验证。</strong></p>
</blockquote>
<p>与 macOS 相比，两者体现了不同的安全优先级：</p>
<ul>
<li><strong>Windows 更重视账户体系的可管理性与可恢复性；</strong></li>
<li><strong>macOS 更重视静态数据的机密性，将登录密码与数据解密密钥深度绑定。</strong></li>
</ul>
<p>因此，真正的安全启示不是依赖单一登录验证，而是：<strong>保护管理员权限、启用磁盘加密、限制共享设备权限，并做好数据备份与物理管控。</strong></p>
', '75ea30a2-6b56-499b-8a67-2bdf0a8ce5fc'::uuid, '{}'::uuid[], '2026-11-05 11:23:39.825897+08'::timestamptz),
  ('c9240ea6-fcd1-473e-bfb9-0f3519be5d85'::uuid, 'be0cee0a-4709-4fec-a51d-eb7753e46bb5'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '面试官让你把 LLM、RAG、Agent、MCP 串起来讲清楚，90% 的 Java 工程师当场露馅', '<div id="readability-page-1" class="page"><div id="cnblogs_post_body">
<h2 id="面试官让你把-llmragagentmcp-串起来讲清楚90-的-java-工程师当场露馅">面试官让你把 LLM、RAG、Agent、MCP 串起来讲清楚，90% 的 Java 工程师当场露馅</h2>
<h2 id="-本文导读建议先花-60-秒">📌 本文导读（建议先花 60 秒）</h2>
<p><strong>说句扎心的：LLM、RAG、Agent、MCP、向量、余弦相似度……这些词你个个都听过，但面试官让你“串起来讲一遍”的时候，是不是瞬间就卡壳了？</strong></p>
<p>别慌，这恰恰说明你缺的不是知识点，而是一张<strong>全景图</strong>。</p>
<p>这篇文章不堆概念、不背定义，用<strong>一条真实的电商客服请求</strong>做主线，带你从“用户问：我的订单为什么还没发货”一路走到最后流式输出的答复，中间每个环节用到的技术、写的 Java 代码、踩过的坑，全都摆到台面上。</p>
<p><strong>读完这篇，你能带走什么？</strong></p>
<ul>
<li>🧭 <strong>一句话隐喻串起所有概念</strong>：LLM 是发动机，Embedding 是坐标系，余弦相似度是尺子，向量库是图书馆索引卡，RAG 是外挂资料室，Tool 是手脚，MCP 是 USB-C 插座，Skills 是岗位手册，Agent 是那个会自己干活的数字员工</li>
<li>🏗️ <strong>五层架构 + 依赖关系两张图</strong>：搞清每一层是谁的活，顺便把“为什么招 Java 而不是招算法”这句话说到位</li>
<li>🧮 <strong>余弦相似度的三个数学关系</strong>：归一化后余弦 == 内积、余弦越大 L2 越小、排序等价 ≠ 阈值通用——面试答不出来基本就露馅的那几个点</li>
<li>💻 <strong>可以直接抄的生产级代码</strong>：<code>float</code> 存储 <code>double</code> 累加防精度污染、零向量短路防 NaN、JDK Vector API 上 SIMD、RRF 融合、带四道防护的 ReAct 循环、三分钟把 Spring Boot 服务变成 MCP Server</li>
<li>⚡ <strong>反直觉但救命的结论</strong>：RAG 的瓶颈在<strong>检索</strong>不在生成；Skills 别塞进 System Prompt 要用<strong>渐进式披露</strong>；工具集要从 28 个收敛到 5~8 个；MCP 的 HTTP 端点<strong>默认无鉴权，裸暴露就是裸奔</strong></li>
<li>🕳️ <strong>16 个生产踩坑对照表 + 13 个面试连环追问速答</strong>：建议直接收藏当检查清单，改分块、换模型、调阈值之前先过一遍</li>
</ul>
<p><strong>这篇适合谁？</strong><br>
想转 AI 方向的后端、正在做企业知识库或智能客服的 Java 研发、以及下周就要面试、现在有点慌的朋友。</p>
<p><strong>这篇不适合谁？</strong><br>
想学怎么训练大模型、调 LoRA 的——这里一个梯度都不推。<strong>本文只讲一件事：怎么把不确定的模型能力，装进确定的工程系统里。</strong></p>
<p>⏱️ 全文约 1.5 万字，建议<strong>先收藏、再细看</strong>，通勤路上刷不完的。</p>
<blockquote>
<p>看到最后有个小彩蛋：文末问了大家“做 RAG 或 Agent 落地时踩过最疼的坑”，评论区聊两句，我看到会挨个回。觉得有用的话，<strong>点个赞、点个在看</strong>，别让这篇在收藏夹里吃灰 👇</p>
</blockquote>
<p>--</p>
<h2 id="一个请求串起-llmragagentmcpjava-工程师的-ai-工程化落地全景">一个请求串起 LLM、RAG、Agent、MCP：Java 工程师的 AI 工程化落地全景</h2>
<p>面试里有道高频题：把 LLM、Agent、Skills、MCP、RAG、向量、余弦相似度串起来讲清楚。大多数人单个概念都能背，一连起来就露馅。这篇文章用一条真实的客服请求做主线，结合我们在电商客服、企业知识库项目里的落地经验，讲透每个概念的原理、Java 实现和踩过的坑。适合想转 AI 方向的后端朋友，建议先收藏再细看。</p>
<h2 id="一先立全景一句话--两张图串起所有概念">一、先立全景：一句话 + 两张图串起所有概念</h2>
<p>学 AI 概念最大的痛点是"每个都听过，串不起来"。别急着一头扎进细节，先花三分钟建立全局认知，后面怎么学都不会迷路。</p>
<p><strong>先用一句话把所有概念放进同一个隐喻体系：</strong></p>
<blockquote>
<p><strong>LLM 是发动机；Embedding 是语言的坐标系；余弦相似度是尺子；向量库是图书馆的索引卡；RAG 是给模型配的"外挂资料室"；Tool 是模型的手脚；MCP 是统一的 USB 插座；Skills 是岗位行为手册；Agent 是那个会自己拆任务、干完还会复盘的数字员工。</strong></p>
<p>而 Java 工程师的价值，从来不在"造发动机"，而在<strong>造整车、修高速、建加油站</strong>。</p>
</blockquote>
<p>再来一张"人话版"速查表：</p>
<div><table>
<thead>
<tr>
<th>概念</th>
<th>一句话人话</th>
<th>类比</th>
<th>Java 侧抓手</th>
</tr>
</thead>
<tbody>
<tr>
<td>LLM</td>
<td>只会预测下一个 token 的续写机器</td>
<td>大脑 / 发动机</td>
<td>Spring AI、LangChain4j、WebClient 调 API + SSE 流式</td>
</tr>
<tr>
<td>向量 Embedding</td>
<td>把文本变成语义坐标</td>
<td>坐标系</td>
<td><code>EmbeddingModel</code> 输出 <code>float[]</code>，存 pgvector / Milvus</td>
</tr>
<tr>
<td>余弦相似度</td>
<td>看两个向量方向像不像</td>
<td>尺子 / 罗盘</td>
<td><code>cos = A·B / (|A||B|)</code>，用于 TopK 召回</td>
</tr>
<tr>
<td>RAG</td>
<td>开卷考试：先查资料再回答</td>
<td>外挂资料室</td>
<td>切块 → 向量化 → 检索 → 拼 Prompt</td>
</tr>
<tr>
<td>Skills</td>
<td>某类任务的标准作业流程</td>
<td>岗位手册 / 工具箱</td>
<td><code>@Tool</code> 方法 + 按需加载的 <code>SKILL.md</code></td>
</tr>
<tr>
<td>MCP</td>
<td>工具接入的统一协议</td>
<td>USB-C 插座</td>
<td><code>spring-ai-starter-mcp-server-*</code></td>
</tr>
<tr>
<td>Agent</td>
<td>会拆任务、调工具、循环决策</td>
<td>数字员工</td>
<td><code>AiServices</code> + ReAct 循环 / 状态机</td>
</tr>
</tbody>
</table></div>
<h3 id="11-五层架构搞清楚每一层是谁的活">1.1 五层架构：搞清楚每一层是谁的活</h3>
<p>把概念放进分层架构里看，职责一目了然——这和咱们熟悉的 MVC 分层是一个思路：</p>
<p><img alt="image" loading="lazy" data-src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093554581-2000788845.png" src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093554581-2000788845.png"></p>
<div><table>
<thead>
<tr>
<th>层</th>
<th>一句话职责</th>
<th>Java 侧抓手</th>
</tr>
</thead>
<tbody>
<tr>
<td>① 模型层</td>
<td>提供"理解与生成"的算力</td>
<td>HTTP/SSE 调用、Spring AI <code>ChatModel</code></td>
</tr>
<tr>
<td>② 上下文层</td>
<td>把语义变成<strong>可计算的距离</strong></td>
<td><code>MilvusVectorStore</code>、<code>PgVectorStore</code>、ES 8.x <code>dense_vector</code></td>
</tr>
<tr>
<td>③ 能力层</td>
<td>让模型<strong>看得见知识、摸得着系统</strong></td>
<td>LangChain4j <code>ContentRetriever</code>、Spring AI <code>ToolCallback</code></td>
</tr>
<tr>
<td>④ 编排层</td>
<td>让模型<strong>自己决定下一步干什么</strong></td>
<td><code>AiServices</code>、Spring StateMachine、<code>ToolProvider</code></td>
</tr>
<tr>
<td>⑤ 工程治理层</td>
<td>让 AI <strong>稳定、安全、便宜</strong>地上线</td>
<td>WebFlux + SSE、Redis 令牌桶、Micrometer、网关</td>
</tr>
</tbody>
</table></div>
<blockquote>
<p>💡 <strong>技术亮点（面试加分句）</strong>：这五层里，<strong>①②是买来的，③④是框架给的，⑤才是企业自己的护城河</strong>。这一句话，基本就把"为什么招 Java 而不是招算法"说透了。</p>
</blockquote>
<h3 id="12-概念依赖关系它们是怎么咬合的">1.2 概念依赖关系：它们是怎么咬合的</h3>
<p><img alt="image" loading="lazy" data-src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093608698-1378876174.png" src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093608698-1378876174.png"></p>
<p>一句话串完：<strong>向量和余弦相似度是语义计算的地基，RAG 给大模型装知识库，Skills 和 MCP 给大模型接业务手脚，Agent 把所有能力组装成能自主完成任务的智能体。</strong></p>
<p>接下来自底向上逐个拆。先从不那么性感、但决定一切的地基讲起。</p>
<h2 id="二llm别神化它就是个下一个-token-预测器">二、LLM：别神化，它就是个"下一个 token 预测器"</h2>
<p>很多人把大模型当百科全书用，这是所有工程问题的根源。先把三个关键认知钉死：</p>
<ul>
<li><strong>它是概率生成器，不是数据库</strong>。LLM 本质是函数 <code>f(文本上下文) → 下一个 token 的概率分布</code>，它生成的是<strong>最像样的文本</strong>，不是<strong>最真实的文本</strong>；</li>
<li><strong>知识冻结</strong>：训练完那一天，参数里的知识就冻住了。你上周发的产品文档，它天然不知道；</li>
<li><strong>幻觉的根因</strong>：模型优化的是<strong>流畅度</strong>而不是<strong>真实性</strong>，不知道又必须答的时候，它会用概率分布"编一个最像样的"。</li>
</ul>
<p>再加两条：<strong>它没有记忆</strong>，所谓多轮对话，全靠我们把历史消息一遍遍塞进 <code>messages</code> 数组；<strong>它不联网、不查数据库</strong>，强在语言理解与生成，弱在精确计算、实时数据和私域知识。</p>
<p>想明白这些，Java 研发的定位就清楚了：</p>
<blockquote>
<p>💡 <strong>一句话记忆</strong>：大模型在 Java 世界里，本质上就是<strong>另一个能聊天的第三方 REST 服务——只是它特别慢、特别贵、还偶尔胡说八道</strong>。我们要做的不是转行搞算法，而是当一名 LLM Application Engineer：像治理任何"不可靠依赖"一样，做超时、重试、熔断、降级、可观测。</p>
</blockquote>
<h3 id="21-token上下文temperature都是预算">2.1 Token、上下文、Temperature：都是预算</h3>
<div><table>
<thead>
<tr>
<th>概念</th>
<th>本质</th>
<th>工程含义</th>
</tr>
</thead>
<tbody>
<tr>
<td>Token</td>
<td>模型最小计费与处理单位，是子词不是字</td>
<td>中文约 1 字 ≈ 1~1.5 token（不同分词器有差异），<strong>成本与延迟都按 token 计</strong></td>
</tr>
<tr>
<td>Prompt</td>
<td>发给模型的输入模板</td>
<td>Prompt 也是"代码"：要<strong>版本化、要评测、要回归</strong></td>
</tr>
<tr>
<td>上下文窗口</td>
<td>模型一次能看见的全部内容</td>
<td>是<strong>预算</strong>而非容量：检索塞多少、历史留多少、输出留多少，都要算账</td>
</tr>
<tr>
<td>Temperature</td>
<td>控制概率分布的"锐度"</td>
<td>抽取/分类/事实问答用 0~0.3，创意写作 0.7+</td>
</tr>
<tr>
<td>结构化输出</td>
<td>让模型吐合法 JSON 对接 Java 类型</td>
<td><code>BeanOutputConverter</code> + 校验 + 失败重试</td>
</tr>
</tbody>
</table></div>
<p>上下文越长越贵，也越容易"迷失中间信息"（Lost in the Middle）。所以别把上下文当硬盘用，它是稀缺资源——这个观点后面讲 Skills 时还会再用到。</p>
<h3 id="22-别把-llm-当数据库">2.2 别把 LLM 当数据库</h3>
<p>这是我踩坑之后总结的分工原则，实际开发中非常管用：</p>
<blockquote>
<p><strong>事实数据</strong>：查数据库 / 知识库；<strong>流程操作</strong>：走业务接口 / MCP；<strong>语言表达</strong>：才交给 LLM。</p>
</blockquote>
<p>LLM 擅长推理和组织表达，不擅长长期记忆和精确事实。让它干它不擅长的事，就是幻觉的开始。</p>
<p>模型本身这么多毛病，怎么补？答案是给它配外挂——先外挂知识（RAG），再外挂手脚（Tool/MCP）。但在那之前，得先解决一个数学问题：<strong>机器怎么理解"意思"？</strong></p>
<h2 id="三向量--余弦相似度把语义变成可计算的数字">三、向量 + 余弦相似度：把"语义"变成可计算的数字</h2>
<h3 id="31-为什么需要向量">3.1 为什么需要向量</h3>
<p>传统 SQL 只擅长精确匹配和模糊匹配，<code>like ''%car%''</code> 永远匹配不到 <code>automobile</code>。关键词检索匹配的是<strong>字</strong>，而我们要匹配的是<strong>意思</strong>。</p>
<p>Embedding 模型把一段文本压成一串高维浮点数（常见 768 / 1024 / 1536 / 3072 维），<strong>语义越近的文本，在向量空间里距离越近</strong>：</p>
<pre highlighted="true"><code>"如何申请年假"  → [0.012, -0.231,  0.548, ...]  ┐ 夹角很小 → 语义几乎等价
"年假怎么请"    → [0.009, -0.198,  0.561, ...]  ┘
"如何申请离职"  → [-0.34,  0.087, -0.112, ...]  → 夹角很大 → 语义不同
</code></pre>
<p>几个关键工程认知，都是血泪换来的：</p>
<ul>
<li><strong>不用关心每一维代表什么</strong>，只关心"距离能不能用"；</li>
<li><strong>向量是模型给的，不是算出来的</strong>——换 Embedding 模型，整个向量库必须<strong>全量重建</strong>，这是迁移成本的地雷；</li>
<li><strong>入库和查询必须用同一个 Embedding 模型</strong>，否则坐标系都不一样，算出来的相似度是纯噪声；</li>
<li>生产上 Embedding 通常<strong>离线批量跑 + 增量幂等重放</strong>，别把它放进用户请求的同步链路。</li>
</ul>
<p>维度怎么选？维度越高语义表达越细，但存储和计算成本线性增长。<code>float</code> 存储下 1536 维 × 4B ≈ 6KB/条，企业级常见选 1024 维再配 PQ 量化压缩。</p>
<h3 id="32-余弦相似度为什么不用欧氏距离">3.2 余弦相似度：为什么不用欧氏距离</h3>
<p>公式很简单，值域 <code>[-1, 1]</code>：</p>
<pre highlighted="true"><code>cos(θ) = (A·B) / (‖A‖ × ‖B‖) = Σ(aᵢbᵢ) / (√Σaᵢ² × √Σbᵢ²)
</code></pre>
<p>分数怎么解读，心里要有杆秤：</p>
<div><table>
<thead>
<tr>
<th>相似度</th>
<th>含义</th>
<th>场景</th>
</tr>
</thead>
<tbody>
<tr>
<td>1.0</td>
<td>完全同方向</td>
<td>同义句</td>
</tr>
<tr>
<td>0.7+</td>
<td>高度相关</td>
<td>常用的召回阈值</td>
</tr>
<tr>
<td>0.0</td>
<td>正交，无关</td>
<td>—</td>
</tr>
<tr>
<td>负数</td>
<td>方向相反</td>
<td>文本向量中少见</td>
</tr>
</tbody>
</table></div>
<p><strong>为什么文本场景默认选余弦而不是欧氏距离？</strong></p>
<div><table>
<thead>
<tr>
<th>度量</th>
<th>公式</th>
<th>区间</th>
<th>适用场景</th>
</tr>
</thead>
<tbody>
<tr>
<td>余弦相似度</td>
<td><code>Σ(aᵢbᵢ) / (‖a‖‖b‖)</code></td>
<td>[-1, 1]</td>
<td><strong>文本语义检索默认选它</strong>（只看方向，不看长度）</td>
</tr>
<tr>
<td>内积 / 点积</td>
<td><code>Σ(aᵢbᵢ)</code></td>
<td>(-∞, +∞)</td>
<td>推荐系统（模长可编码热度、置信度）</td>
</tr>
<tr>
<td>欧氏距离</td>
<td><code>√Σ(aᵢ-bᵢ)²</code></td>
<td>[0, +∞)</td>
<td>图像特征等<strong>模长本身有意义</strong>的场景</td>
</tr>
</tbody>
</table></div>
<p>文本向量的模长受文本长度影响——"今天天气很好"和"今天天气很好很好很好"意思一样，欧氏距离却会变大；余弦只看方向，对长度不敏感。而且高维空间里欧氏距离有维度灾难，距离趋同，区分度越来越差。</p>
<h3 id="33-三个数学关系答不出来基本就露馅">3.3 三个数学关系：答不出来基本就露馅</h3>
<blockquote>
<p>⭐ <strong>面试必答</strong>：</p>
<ol>
<li><strong>归一化后，余弦 == 内积</strong>。做 L2 归一化使 <code>‖a‖=‖b‖=1</code>，代入公式即得 <code>cosθ = a·b</code>。工程价值：查询时只需一次乘法累加，<strong>省掉每次开方和除法</strong>。FAISS 里 <code>IndexFlatIP</code> 配归一化向量，算的就是余弦。</li>
<li><strong>归一化后，余弦越大 ⇔ L2 距离越小</strong>。<code>‖a-b‖² = 2 - 2cosθ = 2(1-cosθ)</code>，三种度量的<strong>排序结果完全等价</strong>，只差一个分数刻度。</li>
<li><strong>排序等价 ≠ 阈值通用</strong>。如果拿余弦分数做绝对阈值过滤（比如"低于 0.6 判定无答案"），度量选择和归一化状态就至关重要——混用归一化/未归一化向量，阈值会直接失效。</li>
</ol>
</blockquote>
<h3 id="34-三个容易被追问的坑">3.4 三个容易被追问的坑</h3>
<div><table>
<thead>
<tr>
<th>坑</th>
<th>现象</th>
<th>本质与应对</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>相似 ≠ 相关</strong></td>
<td>"苹果公司 CEO"和"Tim Cook"向量距离可能很远</td>
<td>向量衡量的是<strong>表述分布</strong>相似度，不是事实关联。靠混合检索 + Rerank + 知识图谱补</td>
</tr>
<tr>
<td><strong>Hubness 枢纽点</strong></td>
<td>某些向量成为"万能近邻"，谁查都排前面</td>
<td>高维空间固有现象。去重、聚类打散、结果多样性约束（MMR）缓解</td>
</tr>
<tr>
<td><strong>重复文档刷分</strong></td>
<td>同一文档存 10 份，更容易被召回</td>
<td>入库做<strong>内容指纹去重</strong>，召回后按 <code>doc_id</code> 聚合</td>
</tr>
</tbody>
</table></div>
<h3 id="35-生产级代码三个细节比公式本身更重要">3.5 生产级代码：三个细节比公式本身更重要</h3>
<pre highlighted="true"><code><span>public</span> <span>final</span> <span>class</span> <span>CosineSimilarity</span> {

    <span>private</span> <span>CosineSimilarity</span><span>()</span> {}

    <span>/**
     * 通用余弦相似度，三个工程细节：
     * ① 用 double 累加——1536 维 float 连续累加会丢精度，污染 Top-K 排序；
     * ② 零向量必须短路——否则 NaN 一路污染到排序结果，Comparator 行为不可预测；
     * ③ 维度校验——入库与查询的坐标系必须一致。
     */</span>
    <span>public</span> <span>static</span> <span>double</span> <span>cosine</span><span>(<span>float</span>[] a, <span>float</span>[] b)</span> {
        <span>if</span> (a.length != b.length) {
            <span>throw</span> <span>new</span> <span>IllegalArgumentException</span>(<span>"向量维度不一致: "</span> + a.length + <span>" vs "</span> + b.length);
        }
        <span>double</span> <span>dot</span> <span>=</span> <span>0.0</span>, na = <span>0.0</span>, nb = <span>0.0</span>;
        <span>for</span> (<span>int</span> <span>i</span> <span>=</span> <span>0</span>; i &lt; a.length; i++) {
            dot += (<span>double</span>) a[i] * b[i];   <span>// 提升到 double 再累加</span>
            na  += (<span>double</span>) a[i] * a[i];
            nb  += (<span>double</span>) b[i] * b[i];
        }
        <span>if</span> (na == <span>0.0</span> || nb == <span>0.0</span>) {      <span>// 零向量短路，防 NaN</span>
            <span>return</span> <span>0.0</span>;
        }
        <span>return</span> dot / (Math.sqrt(na) * Math.sqrt(nb));
    }

    <span>/** 入库前 L2 归一化：之后检索退化为内积，省掉 2 次开方 + 1 次除法 */</span>
    <span>public</span> <span>static</span> <span>float</span>[] l2Normalize(<span>float</span>[] v) {
        <span>double</span> <span>n</span> <span>=</span> <span>0.0</span>;
        <span>for</span> (<span>float</span> x : v) n += (<span>double</span>) x * x;
        <span>if</span> (n == <span>0.0</span>) <span>return</span> v;
        <span>double</span> <span>inv</span> <span>=</span> <span>1.0</span> / Math.sqrt(n);
        <span>float</span>[] out = <span>new</span> <span>float</span>[v.length];
        <span>for</span> (<span>int</span> <span>i</span> <span>=</span> <span>0</span>; i &lt; v.length; i++) out[i] = (<span>float</span>) (v[i] * inv);
        <span>return</span> out;
    }

    <span>/** 归一化向量之间的内积 == 余弦相似度（检索热路径用这个） */</span>
    <span>public</span> <span>static</span> <span>double</span> <span>dot</span><span>(<span>float</span>[] a, <span>float</span>[] b)</span> {
        <span>double</span> <span>s</span> <span>=</span> <span>0.0</span>;
        <span>for</span> (<span>int</span> <span>i</span> <span>=</span> <span>0</span>; i &lt; a.length; i++) {
            s += (<span>double</span>) a[i] * b[i];
        }
        <span>return</span> s;
    }
}
</code></pre>
<blockquote>
<p>💡 <strong>技术亮点</strong>：<code>float</code> 存储省一半内存与带宽，但<strong>累加用 double</strong> 防精度丢失；零向量返回 0 而不是 <code>NaN</code>——<code>NaN</code> 会让 <code>Comparator</code> 排序结果不可预测，这是真实踩过的坑。另外"写入时归一化、查询时退化为点积"这一招，实测百万级向量打分性能提升 2~3 倍，千万级批量检索能提升约 40%。</p>
</blockquote>
<p>批量点积还可以交给 SIMD：</p>
<pre highlighted="true"><code><span>import</span> jdk.incubator.vector.FloatVector;
<span>import</span> jdk.incubator.vector.VectorOperators;
<span>import</span> jdk.incubator.vector.VectorSpecies;

<span>/**
 * JDK Vector API（jdk.incubator.vector，孵化阶段，需 --add-modules）：
 * 让 JIT 生成 SIMD 指令，批量点积性能可达标量循环的数倍。
 * 定位：离线建库/重排序阶段的自研算子；在线检索一律交给向量库。
 */</span>
<span>public</span> <span>final</span> <span>class</span> <span>SimdDotProduct</span> {

    <span>private</span> <span>static</span> <span>final</span> VectorSpecies&lt;Float&gt; SPECIES = FloatVector.SPECIES_PREFERRED;

    <span>public</span> <span>static</span> <span>double</span> <span>dot</span><span>(<span>float</span>[] a, <span>float</span>[] b)</span> {
        <span>int</span> <span>i</span> <span>=</span> <span>0</span>;
        <span>int</span> <span>upperBound</span> <span>=</span> SPECIES.loopBound(a.length);
        <span>FloatVector</span> <span>acc</span> <span>=</span> FloatVector.zero(SPECIES);

        <span>for</span> (; i &lt; upperBound; i += SPECIES.length()) {
            <span>FloatVector</span> <span>va</span> <span>=</span> FloatVector.fromArray(SPECIES, a, i);
            <span>FloatVector</span> <span>vb</span> <span>=</span> FloatVector.fromArray(SPECIES, b, i);
            acc = acc.add(va.mul(vb));
        }

        <span>double</span> <span>sum</span> <span>=</span> acc.reduceLanes(VectorOperators.ADD);
        <span>for</span> (; i &lt; a.length; i++) {         <span>// 尾部不足一个向量宽度，标量兜底</span>
            sum += (<span>double</span>) a[i] * b[i];
        }
        <span>return</span> sum;
    }
}
</code></pre>
<p>有了向量和尺子，下一个问题很现实：数据量上来之后，难道真的一条条 <code>for</code> 循环去算？</p>
<h2 id="四向量库与-ann-索引为什么不能自己-for-循环">四、向量库与 ANN 索引：为什么不能自己 for 循环</h2>
<p><strong>先算一笔账</strong>：100 万条 1024 维向量，每条查询要 1024 次乘加，单次查询约 <strong>20 亿次浮点运算</strong>；光把 4GB 向量从内存读一遍就够喝一壶。100 并发？CPU 排队到天亮。</p>
<p><strong>破局思路</strong>：允许自己"不算那么准"——<strong>ANN（近似最近邻）用少量召回率换数量级速度</strong>。</p>
<div><table>
<thead>
<tr>
<th>索引</th>
<th>核心思想</th>
<th>优点</th>
<th>代价</th>
<th>适用</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Flat</strong></td>
<td>暴力全量比对</td>
<td>召回率 100%，无需训练</td>
<td>O(N×dim)，慢</td>
<td>&lt; 10 万条，或作为召回基准</td>
</tr>
<tr>
<td><strong>IVF</strong></td>
<td>K-means 聚类分桶，只搜 <code>nprobe</code> 个最近簇</td>
<td>内存友好、可扩展</td>
<td>边界向量易漏召</td>
<td>千万级以上、可接受离线重建</td>
</tr>
<tr>
<td><strong>HNSW</strong></td>
<td>分层可导航小世界图</td>
<td><strong>召回/延迟综合最优</strong>，主流默认</td>
<td>内存占用高、构建慢、删除不友好</td>
<td>通用首选</td>
</tr>
<tr>
<td><strong>PQ</strong></td>
<td>乘积量化压缩向量</td>
<td>内存降一个数量级</td>
<td>精度损失，需重排补偿</td>
<td>亿级规模、内存受限</td>
</tr>
</tbody>
</table></div>
<p>理解 HNSW 一句话就够：<strong>跳表解决"跳得远"，小世界图解决"跳得准"</strong>——从高层入口大步跳，逐层下降、每层贪心走向更近的邻居，用 O(log N) 的访问路径逼近目标。</p>
<p>生产上用 <code>recall@K</code>（ANN 结果与暴力结果的 Top-K 重合比例）验收，一般调到 <strong>95%~99%</strong>，同时把延迟从秒级压到毫秒级。</p>
<h3 id="41-java-侧选型对照表">4.1 Java 侧选型对照表</h3>
<div><table>
<thead>
<tr>
<th>场景</th>
<th>选型</th>
<th>理由</th>
</tr>
</thead>
<tbody>
<tr>
<td>已有 ES 集群</td>
<td>Elasticsearch 8.x <code>dense_vector</code></td>
<td>一套系统同时吃 BM25 + 向量，混合检索最省事</td>
</tr>
<tr>
<td>已有 PostgreSQL</td>
<td>pgvector</td>
<td>事务、权限、备份全复用，运维零新增</td>
</tr>
<tr>
<td>千万~亿级、要低延迟</td>
<td>Milvus / Qdrant</td>
<td>专业向量库，HNSW/PQ 参数可精细调</td>
</tr>
<tr>
<td>单元测试 / 小数据</td>
<td>内存 Map + 余弦</td>
<td>别引入重组件，<code>SimpleVectorStore</code> 足够</td>
</tr>
</tbody>
</table></div>
<blockquote>
<p>⚠️ <strong>踩坑提醒</strong>：不要自己去实现 ANN 索引。亮点应该是"<strong>怎么选索引、怎么调 <code>nprobe</code> / <code>efSearch</code>、怎么用 recall@K 验收</strong>"，而不是手写 HNSW。千万级向量下检索延迟超 1s，标准解法是 HNSW 索引 + 热门向量本地缓存（Caffeine）+ 冷热数据分库。</p>
</blockquote>
<p>pgvector 场景下，计算直接下沉到数据库，避免把全量向量拉到 Java 内存：</p>
<pre highlighted="true"><code><span>-- &lt;=&gt; 是 pgvector 的余弦距离操作符，1 - 距离 = 余弦相似度</span>
<span>SELECT</span> id, content, <span>1</span> <span>-</span> (embedding <span>&lt;=&gt;</span> :qvec) <span>AS</span> score
<span>FROM</span> doc_chunk
<span>WHERE</span> tenant_id <span>=</span> :tenantId
<span>ORDER</span> <span>BY</span> embedding <span>&lt;=&gt;</span> :qvec
LIMIT <span>5</span>;
</code></pre>
<p>Spring Data JPA 里用原生查询包一层即可：</p>
<pre highlighted="true"><code><span>@Query(value = """
    SELECT id, content, 1 - (embedding &lt;=&gt; :queryVector) AS similarity
    FROM document_chunks
    WHERE 1 - (embedding &lt;=&gt; :queryVector) &gt; :threshold
    ORDER BY similarity DESC
    LIMIT :topK
""", nativeQuery = true)</span>
List&lt;DocSimilarity&gt; <span>findTopKByCosine</span><span>(<span>@Param("queryVector")</span> <span>float</span>[] queryVector,
                                     <span>@Param("threshold")</span> <span>double</span> threshold,
                                     <span>@Param("topK")</span> <span>int</span> topK)</span>;
</code></pre>
<p>Milvus 场景的声明式配置，注意<strong>维度必须和 Embedding 模型严格对齐</strong>：</p>
<pre highlighted="true"><code><span>@Configuration</span>
<span>public</span> <span>class</span> <span>MilvusVectorConfig</span> {

    <span>@Bean</span>
    <span>public</span> VectorStore <span>milvusVectorStore</span><span>(EmbeddingModel embeddingModel)</span> {
        <span>return</span> MilvusVectorStore.builder()
                .embeddingModel(embeddingModel)
                .host(<span>"milvus-internal-host"</span>)
                .port(<span>19530</span>)
                .collectionName(<span>"knowledge_base"</span>)
                .dimension(<span>1536</span>)                 <span>// 与 Embedding 模型维度严格对齐</span>
                .indexType(IndexType.HNSW)       <span>// 高性能向量索引</span>
                .metricType(MetricType.COSINE)   <span>// 余弦度量</span>
                .build();
    }
}
</code></pre>
<p>地基打完了，正式进入应用层。先讲面试第一关——RAG。</p>
<h2 id="五rag开卷考试但瓶颈在检索不在生成">五、RAG：开卷考试，但瓶颈在检索不在生成</h2>
<p>先纠正一个高频错误答案：</p>
<blockquote>
<p><strong>RAG 不是"向量库 + 大模型"，而是"外部知识管理 + 检索系统 + 生成模型"的一整套协同机制。</strong> 它解决四个问题：<strong>知识不新、私有知识不知道、容易编（幻觉）、答案不可追溯</strong>。</p>
</blockquote>
<h3 id="51-完整链路两阶段必须按步骤讲">5.1 完整链路：两阶段，必须按步骤讲</h3>
<p><img alt="image" loading="lazy" data-src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093641336-909670874.png" src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093641336-909670874.png"></p>
<h3 id="52-高分答法先讲朴素-rag-为什么不行">5.2 高分答法：先讲"朴素 RAG 为什么不行"</h3>
<div><table>
<thead>
<tr>
<th>朴素 RAG 的失败模式</th>
<th>典型表现</th>
<th>对应解法</th>
</tr>
</thead>
<tbody>
<tr>
<td>召回不准</td>
<td>"苹果 CEO"召不回"Tim Cook"</td>
<td>混合检索（Dense + BM25）、查询改写</td>
</tr>
<tr>
<td>语义 ≠ 相似</td>
<td>搜编号 <code>AG-2024-001</code>，召回一堆含"产品编号"字样但号不对的文档</td>
<td><strong>BM25 精确匹配兜底</strong>，权重按场景调</td>
</tr>
<tr>
<td>上下文割裂</td>
<td>固定 512 字符硬切，论证被腰斩</td>
<td>结构感知切片、父子块、语义分块</td>
</tr>
<tr>
<td>多跳推理失败</td>
<td>"X 公司 CEO 的母校的 QS 排名"查不到</td>
<td>查询分解、Agentic RAG 多轮检索</td>
</tr>
<tr>
<td>全局性问题崩溃</td>
<td>"这批文档的核心主题是什么"</td>
<td>GraphRAG / 全局摘要，向量检索对此天然失效</td>
</tr>
<tr>
<td>召回多但噪音大</td>
<td>Top-20 全塞进去，模型被干扰</td>
<td>Rerank 精排，只送 top-5~8</td>
</tr>
</tbody>
</table></div>
<p>把解法攒起来，就是 2026 年的生产级 RAG 公式：</p>
<blockquote>
<p><strong>Production RAG = 高级解析（OCR / 版面还原）+ 混合检索（BM25 + Dense，RRF 融合）+ 神经重排（Cross-Encoder）+ Agentic 路由（按问题复杂度动态决定检索深度）+ GraphRAG（全局/多跳问题）+ 持续评测（RAGAS / TruLens，量化 recall@k、忠实度、幻觉率）</strong></p>
</blockquote>
<p>📌 这里有个分水岭级别的认知：<strong>RAG 的瓶颈在检索，不在生成</strong>。朴素管道在检索这一步大约 40% 的概率会失败，检索入口错了，后面 rerank 和生成再优化都白搭。</p>
<p>顺带回答一个高频疑问：现在上下文都 1M 了，还要 RAG 吗？要。三个理由：<strong>成本与延迟</strong>（每次全量灌入不可接受）、<strong>注意力衰减</strong>（塞得多不代表记得住）、<strong>实时性与权限粒度</strong>（知识库按条更新、按租户过滤）。正确姿势是：<strong>RAG 负责从海量里精准找，长上下文负责找到之后的精读推理</strong>。</p>
<h3 id="53-五个关键设计决策">5.3 五个关键设计决策</h3>
<p><strong>① 切块</strong>：固定长度硬切是语义腰斩的元凶。实践参数：500~1000 token 一块、10%~20% 重叠、按标题/段落结构感知切分，再上<strong>父子块</strong>——子块用于向量匹配，命中后把父块完整内容送进上下文。标题和元数据也要带着走，检索时能做过滤，回答时能做溯源。</p>
<p><strong>② Embedding 一致性</strong>：Query 和 Doc 必须同一模型同一维度，前面讲过，不再展开。</p>
<p><strong>③ 混合检索 + RRF 融合</strong>：纯向量会漏精确关键词（型号 <code>RTX-5090</code>、制度号 <code>HR-2025-013</code>），BM25 恰好互补。RRF（Reciprocal Rank Fusion）的打分公式是 <code>score = Σ 1/(k + rank)</code>，<strong>不需要归一化两种量纲完全不同的分数</strong>，比加权求和稳得多。</p>
<p><strong>④ 重排</strong>：向量召回是"双塔模型"，Query 和 Doc 独立编码，无法深度交互；Rerank 是交叉编码，把 Q+D 拼一起算相关性，<strong>准但慢</strong>，所以只对粗召回的 Top-50 精排，取 Top-5~8。</p>
<p><strong>⑤ 生成约束</strong>：Prompt 写死"仅依据资料回答，没有就说不知道"+ 强制引用来源。这是抑制幻觉的第一道闸。</p>
<h3 id="54-核心代码一个能上线的-rag-闭环">5.4 核心代码：一个能上线的 RAG 闭环</h3>
<p>Spring AI 里，RAG 可以被一个 Advisor 织入，业务代码几乎无感：</p>
<pre highlighted="true"><code><span>@Configuration</span>
<span>public</span> <span>class</span> <span>RagConfig</span> {

    <span>/** 生产环境换成 PgVectorStore / MilvusVectorStore / ElasticsearchVectorStore */</span>
    <span>@Bean</span>
    VectorStore <span>vectorStore</span><span>(EmbeddingModel embeddingModel)</span> {
        <span>return</span> SimpleVectorStore.builder(embeddingModel).build();
    }

    <span>/**
     * RAG 三个关键约束：
     * ① topK + similarityThreshold：控制上下文预算，宁少勿滥；
     * ② 系统提示写死"只依据资料回答，没有就说不知道"——抑制幻觉的第一道闸；
     * ③ 绑定引用来源，可追溯（企业合规刚需）。
     */</span>
    <span>@Bean</span>
    ChatClient <span>chatClient</span><span>(ChatClient.Builder builder, VectorStore vectorStore)</span> {
        <span>return</span> builder
                .defaultSystem(<span>"""
                        你是企业知识助手。只能依据【检索资料】回答问题，
                        并在答案末尾用 [来源: 文件名#片段号] 标注依据。
                        资料中没有相关信息时，直接回答「资料中未涉及」，禁止推测。
                        """</span>)
                .defaultAdvisors(
                        QuestionAnswerAdvisor.builder(vectorStore)
                                .searchRequest(SearchRequest.builder()
                                        .topK(<span>8</span>)
                                        .similarityThreshold(<span>0.6</span>)
                                        .build())
                                .build())
                .build();
    }
}

<span>// 调用侧：检索被 Advisor 织入，业务代码里几乎看不到 RAG 的存在</span>
<span>@RestController</span>
<span>public</span> <span>class</span> <span>KnowledgeController</span> {

    <span>private</span> <span>final</span> ChatClient chatClient;

    <span>public</span> <span>KnowledgeController</span><span>(ChatClient chatClient)</span> {
        <span>this</span>.chatClient = chatClient;
    }

    <span>@GetMapping("/kb/ask")</span>
    <span>public</span> String <span>ask</span><span>(<span>@RequestParam</span> String q)</span> {
        <span>return</span> chatClient.prompt().user(q).call().content();
    }
}
</code></pre>
<blockquote>
<p>📎 注：Spring AI 各小版本 API 略有差异（如 <code>SimpleVectorStore.builder</code> 与旧版构造器），以所用版本的官方文档为准。</p>
</blockquote>
<p>再往进一步，<strong>两阶段检索 + 流式输出</strong>：</p>
<pre highlighted="true"><code><span>@Service</span>
<span>@RequiredArgsConstructor</span>
<span>public</span> <span>class</span> <span>KnowledgeQAService</span> {

    <span>private</span> <span>final</span> VectorStore vectorStore;
    <span>private</span> <span>final</span> RerankClient rerankClient;
    <span>private</span> <span>final</span> ChatModel chatModel;

    <span>/** 两阶段检索：粗召回扩量 → 精排取 Top-5，各司其职 */</span>
    <span>public</span> List&lt;Document&gt; <span>retrieve</span><span>(String query)</span> {
        List&lt;Document&gt; candidates = vectorStore.similaritySearch(
                SearchRequest.builder()
                        .query(query)
                        .topK(<span>20</span>)                      <span>// 扩大召回，给 Rerank 留空间</span>
                        .similarityThreshold(<span>0.6</span>)      <span>// 阈值过滤，别把噪声喂给模型</span>
                        .build());
        <span>return</span> rerankClient.rerank(query, candidates, <span>5</span>);
    }

    <span>/** 流式问答：首字延迟从 3s 压到 300ms 量级 */</span>
    <span>public</span> Flux&lt;String&gt; <span>streamAnswer</span><span>(String query)</span> {
        List&lt;Document&gt; docs = retrieve(query);
        <span>String</span> <span>context</span> <span>=</span> docs.stream()
                .map(d -&gt; <span>"[%s] %s"</span>.formatted(d.getId(), d.getText()))
                .collect(Collectors.joining(<span>"\n---\n"</span>));

        <span>String</span> <span>systemPrompt</span> <span>=</span> <span>"""
                你是企业知识库助手。规则：
                1. 仅依据【资料】回答，资料不足必须回答"暂无相关信息"
                2. 每条结论标注来源编号 [DOC-xxx]
                3. 禁止编造流程、人名、金额

                【资料】
                %s
                """</span>.formatted(context);

        <span>return</span> chatModel.stream(<span>new</span> <span>Prompt</span>(
                <span>new</span> <span>SystemMessage</span>(systemPrompt),
                <span>new</span> <span>UserMessage</span>(query)))
            .mapNotNull(r -&gt; r.getResult().getOutput().getText());
    }
}
</code></pre>
<p>如果检索源有多路，用虚拟线程并行召回 + RRF 融合：</p>
<pre highlighted="true"><code><span>@Service</span>
<span>public</span> <span>class</span> <span>HybridRetriever</span> {

    <span>private</span> <span>final</span> VectorStore vectorStore;   <span>// Spring AI 抽象：PGVector / Milvus / Redis</span>
    <span>private</span> <span>final</span> Bm25Searcher bm25;
    <span>private</span> <span>final</span> <span>ExecutorService</span> <span>vt</span> <span>=</span> Executors.newVirtualThreadPerTaskExecutor();

    <span>public</span> List&lt;Doc&gt; <span>retrieve</span><span>(String query, <span>int</span> topK)</span> {
        <span>// 两路召回并行：虚拟线程让阻塞 IO 不占 OS 线程，万级并发也不炸线程池</span>
        CompletableFuture&lt;List&lt;Doc&gt;&gt; semantic =
                CompletableFuture.supplyAsync(() -&gt; vectorStore.similaritySearch(
                        SearchRequest.builder()
                                .query(query)
                                .topK(topK * <span>3</span>)          <span>// 多召回一些给 Rerank 用</span>
                                .similarityThreshold(<span>0.6</span>)
                                .filterExpression(<span>"tenantId == ''"</span> + TenantContext.get() + <span>"''"</span>) <span>// 权限下推</span>
                                .build())
                        .stream().map(Doc::from).toList(), vt);

        CompletableFuture&lt;List&lt;Doc&gt;&gt; lexical =
                CompletableFuture.supplyAsync(() -&gt; bm25.search(query, topK * <span>3</span>), vt);

        <span>return</span> rrf(List.of(semantic.join(), lexical.join()), <span>60</span>).stream()
                .limit(topK).toList();
    }

    <span>/** RRF：score = Σ 1/(k + rank)，无需归一化分数，跨源可比 */</span>
    <span>private</span> List&lt;Doc&gt; <span>rrf</span><span>(List&lt;List&lt;Doc&gt;&gt; ranks, <span>int</span> k)</span> {
        Map&lt;String, Double&gt; score = <span>new</span> <span>HashMap</span>&lt;&gt;();
        Map&lt;String, Doc&gt; index = <span>new</span> <span>HashMap</span>&lt;&gt;();
        <span>for</span> (List&lt;Doc&gt; rank : ranks) {
            <span>for</span> (<span>int</span> <span>i</span> <span>=</span> <span>0</span>; i &lt; rank.size(); i++) {
                <span>Doc</span> <span>d</span> <span>=</span> rank.get(i);
                index.putIfAbsent(d.id(), d);
                score.merge(d.id(), <span>1.0</span> / (k + i + <span>1</span>), Double::sum);
            }
        }
        <span>return</span> score.entrySet().stream()
                .sorted(Map.Entry.&lt;String, Double&gt;comparingByValue().reversed())
                .map(e -&gt; index.get(e.getKey()))
                .toList();
    }
}
</code></pre>
<blockquote>
<p>💡 <strong>技术亮点</strong>：<strong>元数据过滤下推</strong>到向量库，先在租户/权限分区内检索，避免"检索到了但无权看"的越权泄漏；虚拟线程跑阻塞 IO，不用把全链路改造成 WebFlux 也能扛高并发。</p>
</blockquote>
<h3 id="55-入库侧切分异步向量化与缓存">5.5 入库侧：切分、异步向量化与缓存</h3>
<pre highlighted="true"><code><span>@Service</span>
<span>public</span> <span>class</span> <span>IngestService</span> {

    <span>/** 离线入库：带重叠的切分，防止语义被腰斩 */</span>
    <span>public</span> <span>void</span> <span>ingest</span><span>(List&lt;Document&gt; docs)</span> {
        List&lt;Document&gt; chunks = <span>new</span> <span>TokenTextSplitter</span>(
                <span>800</span>, <span>200</span>, <span>80</span>, <span>5000</span>, <span>true</span>).apply(docs);  <span>// 块 800 token，重叠 200</span>
        vectorStore.add(chunks);                        <span>// 内部自动调 EmbeddingModel 向量化</span>
    }
}

<span>@Service</span>
<span>public</span> <span>class</span> <span>EmbeddingService</span> {

    <span>/** 异步向量化 + MD5 缓存：避免同一文本重复调 Embedding API */</span>
    <span>@Async</span>
    <span>public</span> CompletableFuture&lt;List&lt;Float&gt;&gt; <span>embedAsync</span><span>(String text)</span> {
        <span>String</span> <span>cacheKey</span> <span>=</span> DigestUtils.md5Hex(text);
        List&lt;Float&gt; cached = cacheService.get(cacheKey);
        <span>if</span> (cached != <span>null</span>) {
            <span>return</span> CompletableFuture.completedFuture(cached);
        }
        List&lt;Float&gt; vector = embeddingClient.embed(text).getResult().getOutput();
        cacheService.put(cacheKey, vector, Duration.ofHours(<span>24</span>));
        <span>return</span> CompletableFuture.completedFuture(vector);
    }
}
</code></pre>
<blockquote>
<p>💡 <strong>技术亮点</strong>：异步非阻塞不卡主线程；MD5 缓存命中即跳过 API 调用，生产环境可省 30%+ 的 Embedding 费用。</p>
</blockquote>
<h3 id="56-两个绕不开的运维问题">5.6 两个绕不开的运维问题</h3>
<p><strong>知识库更新了，向量库还是旧的怎么办？</strong> 事件驱动 + 版本号对比 + 事务更新：</p>
<p><img alt="image" loading="lazy" data-src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093703589-1362414809.png" src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093703589-1362414809.png"></p>
<p><strong>怎么证明你的 RAG 效果变好了？</strong> 建 golden 评测集（100~500 条问答对），盯三个指标：<strong>Recall@K</strong>（召没召回）、<strong>忠实度 Faithfulness</strong>（有没有编）、<strong>答案相关性</strong>。每次改分块、改模型、改阈值都跑一遍回归，接进 CI 当门禁。<strong>RAG 不做自动评测就是信仰</strong>，靠数据说话，不靠感觉。</p>
<p>知识的问题解决了，但用户不只是来问问题的——他还想查订单、提工单、发起退款。这就轮到工具登场了。</p>
<h2 id="六tool-calling模型不执行工具它只是点了名">六、Tool Calling：模型不执行工具，它只是"点了名"</h2>
<p>这是最容易被答错的一个概念：</p>
<blockquote>
<p>❌ 错误理解：AI 自己去调用接口。<br>
✅ 正确理解：AI 说"我需要调用 <code>queryOrderStatus</code>，参数 <code>orderId=SO2026…</code>"，<strong>真正执行的是我们的 Java 程序</strong>，执行完把结果回灌给模型，模型再组织语言。</p>
</blockquote>
<pre highlighted="true"><code>用户提问 → AI 分析意图 → AI 输出「要调哪个工具 + 参数 JSON」
        → 我们的程序执行（含鉴权、限流、审计）→ 结果回灌 AI
        → AI 基于结果生成最终回答
</code></pre>
<p>这个"错位"恰恰是 Java 工程师的安全边界所在：<strong>所有真正的业务动作都在你的代码里</strong>，鉴权、幂等、审计、灰度，一个都跑不掉。</p>
<h3 id="61-tool描述就是给模型看的-api-文档">6.1 @Tool：描述就是给模型看的 API 文档</h3>
<pre highlighted="true"><code><span>@Component</span>
<span>public</span> <span>class</span> <span>OrderTools</span> {

    <span>private</span> <span>final</span> OrderService orderService;

    <span>/** 工具描述就是给模型看的 API 文档，写不清楚模型必然误调用 */</span>
    <span>@Tool("按订单号查询订单状态与物流轨迹。只读操作，不会修改任何数据。")</span>
    <span>public</span> String <span>queryOrderStatus</span><span>(
            <span>@P("订单号，形如 SO202610150001")</span> String orderId)</span> {
        <span>// 入参强校验：格式非法时返回明确错误文本，让模型有机会自我修正</span>
        <span>if</span> (!orderId.matches(<span>"SO\\d{8,}"</span>)) {
            <span>return</span> <span>"订单号格式非法，应为 SO 开头加数字，例如 SO202610150001"</span>;
        }
        <span>return</span> JsonUtils.toJson(orderService.queryStatus(orderId));
    }
}
</code></pre>
<p>注解式声明零侵入，框架自动完成参数解析、类型转换、结果序列化。注意防御性校验的技巧：<strong>参数不合法时别抛异常了事，返回一段模型能看懂的错误说明</strong>，它会自己修正参数重试。</p>
<p>工具调不通、参数乱填是常态，生产上要加重试反馈闭环：</p>
<pre highlighted="true"><code><span>public</span> ToolResult <span>executeWithRetry</span><span>(ToolCall call, <span>int</span> maxRetries)</span> {
    <span>for</span> (<span>int</span> <span>i</span> <span>=</span> <span>0</span>; i &lt; maxRetries; i++) {
        <span>try</span> {
            <span>Tool</span> <span>tool</span> <span>=</span> toolRegistry.get(call.name());
            <span>if</span> (tool == <span>null</span>) <span>throw</span> <span>new</span> <span>ToolNotFoundException</span>(<span>"工具不存在："</span> + call.name());
            validateParams(tool.getInputSchema(), call.arguments());  <span>// JSON Schema 强校验</span>
            <span>return</span> tool.execute(call.arguments());
        } <span>catch</span> (ToolValidationException e) {
            call.setFeedback(<span>"参数错误："</span> + e.getMessage());          <span>// 错误回灌，让模型自我修正</span>
        }
    }
    <span>return</span> <span>new</span> <span>ToolResult</span>(<span>"error"</span>, <span>"多次重试仍失败，请换个方式提问"</span>);
}
</code></pre>
<h3 id="62-运行时收敛工具集一个值回票价的优化">6.2 运行时收敛工具集：一个值回票价的优化</h3>
<p>为什么不能把所有 <code>@Tool</code> 一次性挂给模型？三个理由：</p>
<ul>
<li><strong>Token 成本爆炸</strong>：28 个工具能让单次请求从 800 Token 涨到 4200 Token；</li>
<li><strong>模型选错</strong>：描述里"订单"出现 6 次，用户问"订单到哪了"，它去调了退款接口；</li>
<li><strong>权限边界失守</strong>：工具列表本身就是权限边界，写死在注解里等于把鉴权交给提示词——而提示词是拦不住越权的。</li>
</ul>
<blockquote>
<p>🚀 <strong>技术亮点</strong>：用 <code>ToolProvider</code> 按租户/角色/意图<strong>运行时动态下发工具集</strong>。我们把工具从 28 个收敛到 5~8 个后，单次请求 Token 从 4200 降到 1200，误调用率显著下降。</p>
</blockquote>
<pre highlighted="true"><code><span>@Bean</span>
ToolProvider <span>scopedToolProvider</span><span>(OrderTools orderTools, RefundTools refundTools)</span> {
    <span>return</span> (ToolProviderRequest request) -&gt; {
        <span>UserContext</span> <span>ctx</span> <span>=</span> UserContextHolder.current();   <span>// 当前租户/角色，由网关透传</span>
        ToolProviderResult.<span>Builder</span> <span>builder</span> <span>=</span> ToolProviderResult.builder();

        <span>if</span> (ctx.hasPermission(<span>"order:read"</span>) &amp;&amp; looksLikeOrderQuestion(request.userMessage())) {
            builder.add(toolSpecification(<span>"queryOrderStatus"</span>), executor(orderTools));
        }
        <span>if</span> (ctx.hasPermission(<span>"order:refund"</span>)) {         <span>// 高危写操作单独授权，默认不给</span>
            builder.add(toolSpecification(<span>"applyRefund"</span>), executor(refundTools));
        }
        <span>return</span> builder.build();
    };
}
</code></pre>
<blockquote>
<p>📎 注：<code>toolSpecification / executor</code> 为示意写法，实际用 LangChain4j 的 <code>ToolSpecifications</code> 等工具类生成，方法签名随版本变化，以官方文档为准。</p>
</blockquote>
<p>工具是"手脚"，那"这类活该按什么流程干"谁来管？答案是 Skills。</p>
<h2 id="七skills别把操作手册塞进-system-prompt">七、Skills：别把"操作手册"塞进 System Prompt</h2>
<blockquote>
<p><strong>Skills 是把"某类任务该怎么做"沉淀成文件（<code>SKILL.md</code> + 脚本 + 参考资料），让 Agent 在需要时才加载的行为手册。</strong></p>
</blockquote>
<h3 id="71-灵魂设计渐进式披露progressive-disclosure">7.1 灵魂设计：渐进式披露（Progressive Disclosure）</h3>
<p><img alt="image" loading="lazy" data-src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093721615-1140037106.png" src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093721615-1140037106.png"></p>
<p>为什么这个设计值钱？看对比：</p>
<div><table>
<thead>
<tr>
<th>对比项</th>
<th>塞进 System Prompt</th>
<th>Skills</th>
</tr>
</thead>
<tbody>
<tr>
<td>加载时机</td>
<td><strong>永远常驻</strong>，字字占预算</td>
<td>按需加载，不用就<strong>不花 Token</strong></td>
</tr>
<tr>
<td>规模上限</td>
<td>十几个流程就撑爆上下文</td>
<td>装 100 个 Skill 也只占摘要开销</td>
</tr>
<tr>
<td>可维护性</td>
<td>一改全乱、无法版本化</td>
<td>一个文件夹一个职责，可独立演进</td>
</tr>
</tbody>
</table></div>
<p>用 Java 的类比：<strong>Skills 之于 Agent，就是"设计模式手册 + 操作规程"之于新员工</strong>。你不会让新员工入职第一天背完 500 页 SOP——你会给他一张清单，写明"遇到 XX 场景，去翻第 3 章"。反过来，System Prompt 就是"岗位 JD"，必须常驻但必须极短。</p>
<h3 id="72-落地三条硬规则">7.2 落地三条硬规则</h3>
<ol>
<li><code>SKILL.md</code> 正文<strong>控制在 500 行以内</strong>，超了就拆；</li>
<li>参考文件<strong>只放一层深</strong>——嵌套太深时 Agent 只会读到部分内容，拿到的信息是残缺的；</li>
<li>超过 100 行的参考文件，<strong>顶部必须放目录（TOC）</strong>，让 Agent 在部分读取时也能看见全貌。</li>
</ol>
<p>一个技能定义长这样：</p>
<pre highlighted="true"><code><span># skill-definition.yaml —— 一个「工单分类」技能</span>
<span>name:</span> <span>ticket-classifier</span>
<span>version:</span> <span>1.2</span><span>.0</span>
<span>description:</span> <span>用户工单自动分类与优先级判定</span>
<span>prompt_template:</span> <span>prompts/classify.st</span>        <span># 提示词模板</span>
<span>tools:</span>                                      <span># 依赖的工具（MCP 暴露）</span>
  <span>-</span> <span>query_user_profile</span>
  <span>-</span> <span>lookup_sla_policy</span>
<span>inputs:</span>  [<span>ticket_content</span>, <span>user_level</span>]
<span>outputs:</span> [<span>category</span>, <span>priority</span>, <span>reason</span>]
<span>eval_dataset:</span> <span>eval/ticket-golden-500.jsonl</span>  <span># 回归评测集</span>
</code></pre>
<h3 id="73-三组高频混淆一次掰清">7.3 三组高频混淆，一次掰清</h3>
<ul>
<li><strong>Skills vs MCP</strong>：Skills 是"<strong>知道怎么做</strong>"（SOP/流程），MCP 是"<strong>能碰到什么</strong>"（数据/动作）。Skill 的执行步骤里，通常会去调 MCP 工具；</li>
<li><strong>Skills vs Agent</strong>：Skill 是"会做某件事的工具人"，被动调用、输入→输出；Agent 是"会自己决定做什么的员工"，主动规划、循环、调用多个 Skill；</li>
<li><strong>Skills vs Prompt</strong>：Prompt 是<strong>这一次</strong>要做什么，Skills 是<strong>这一类任务</strong>按什么流程做。</li>
</ul>
<blockquote>
<p>📎 <strong>趋势提示</strong>：Agent Skills 已成为开放事实标准——同一套文件夹结构可被 Claude Code、Cursor、GitHub Copilot、Codex CLI、Gemini CLI 直接读取，"写一次，处处能跑"。JVM 侧也出现了对应抽象（如 LangChain4j 的 <code>dev.langchain4j.skills</code>），这个模式正在从"文档约定"走向"框架能力"。</p>
</blockquote>
<p>Skills 管"怎么做"，MCP 管"碰到什么"，后者值得单独一大章——它是这两年 Java 圈最值得关注的新协议。</p>
<h2 id="八mcpai-世界的usb-c-接口">八、MCP：AI 世界的"USB-C 接口"</h2>
<blockquote>
<p><strong>MCP（Model Context Protocol）是 Anthropic 于 2024 年底开源的开放标准，统一了"AI 应用如何安全、标准化地访问外部数据和工具"。</strong> 类比：HTTP 统一了 Web API 的发现与调用；MCP 统一了 AI 工具的发现（<code>tools/list</code>）与调用（<code>tools/call</code>）。</p>
</blockquote>
<h3 id="81-它解决的是-mn-集成灾难">8.1 它解决的是 M×N 集成灾难</h3>
<p>在 MCP 之前：OpenAI Function Calling 一套、Claude 私有格式一套、LangChain 又一套——每个工具要写 N 套适配。在 MCP 之后：实现标准协议即可被任意支持 MCP 的客户端调用。</p>
<p><img alt="image" loading="lazy" data-src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093737541-1236474623.png" src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093737541-1236474623.png"></p>
<h3 id="82-三个核心原语基于-json-rpc-20">8.2 三个核心原语（基于 JSON-RPC 2.0）</h3>
<div><table>
<thead>
<tr>
<th>原语</th>
<th>谁控制</th>
<th>含义</th>
<th>例子</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Tools</strong></td>
<td><strong>模型控制</strong></td>
<td>模型可调用的可执行函数</td>
<td>查询订单、写文件</td>
</tr>
<tr>
<td><strong>Resources</strong></td>
<td>应用控制</td>
<td>附加给模型的上下文数据</td>
<td>文件内容、配置、Git 历史</td>
</tr>
<tr>
<td><strong>Prompts</strong></td>
<td>用户控制</td>
<td>预定义提示模板</td>
<td>斜杠命令、菜单项</td>
</tr>
</tbody>
</table></div>
<p>此外还有 <strong>Sampling</strong>：Server 反向请求 LLM 做推理，用于递归式智能任务。</p>
<h3 id="83-传输方式演进时效性知识面试加分">8.3 传输方式演进（时效性知识，面试加分）</h3>
<div><table>
<thead>
<tr>
<th>传输</th>
<th>场景</th>
<th>状态</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>STDIO</strong></td>
<td>本地进程，客户端直接启动 Server</td>
<td>适合本地 CLI 工具，无法跨网络</td>
</tr>
<tr>
<td><strong>SSE + HTTP</strong></td>
<td>远程部署</td>
<td>长连接占内存（约 80KB/连接）、弱网断线率高，<strong>Spring AI 2.0 起已标记废弃</strong></td>
</tr>
<tr>
<td><strong>Streamable HTTP</strong></td>
<td>远程部署，<strong>首选</strong></td>
<td>请求-响应与流式推送揉进同一套 HTTP 语义，网关/负载均衡/鉴权中间件都能正常介入</td>
</tr>
<tr>
<td><strong>Stateless Streamable HTTP</strong></td>
<td>无状态、Serverless</td>
<td>内存 &lt; 5KB/请求，请求可路由到任意实例</td>
</tr>
</tbody>
</table></div>
<blockquote>
<p>⏱️ <strong>2026-07-28 新版规范（第 5 版，历次最大修订）三个关键变化</strong>：</p>
<ol>
<li><strong>从"有状态连接"全面转向"无状态核心"</strong>——取消协议级初始化握手、移除 Session ID，每个请求自包含，可水平扩展、可跑 Serverless；</li>
<li><strong>引入版本化扩展框架</strong>，Extensions 成为一等公民（MCP Apps、Tasks），新增 <code>server/discover</code> 能力发现、TTL/缓存语义；</li>
<li><strong>生产级加固</strong>：强化 OAuth 2.0 / OIDC 适配，引入完整 JSON Schema 2020-12 和 <strong>W3C Trace Context 链路追踪</strong>——调用链和证据留存可追溯，对企业合规是决定性的。</li>
</ol>
</blockquote>
<h3 id="84-mcp-和-function-calling-到底啥关系">8.4 MCP 和 Function Calling 到底啥关系</h3>
<div><table>
<thead>
<tr>
<th></th>
<th>Function Calling</th>
<th>MCP</th>
</tr>
</thead>
<tbody>
<tr>
<td>定位</td>
<td>模型<strong>能力</strong>：输出结构化调用意图</td>
<td>工具<strong>供给协议</strong>：发现、传输、鉴权</td>
</tr>
<tr>
<td>耦合</td>
<td>绑定具体模型厂商</td>
<td><strong>模型无关</strong>，换模型不用改工具</td>
</tr>
<tr>
<td>复用</td>
<td>每个应用各写一遍</td>
<td>一次实现，多应用/多模型复用</td>
</tr>
</tbody>
</table></div>
<p>一句话：<strong>Function Calling 是动词，MCP 是 USB-C 接口</strong>。前者是模型侧"决定调哪个函数"，后者是工程侧"函数/资源如何标准化接入"，互补不冲突。</p>
<h3 id="85-java-程序员为什么必须关注">8.5 Java 程序员为什么必须关注</h3>
<blockquote>
<p><strong>企业存量核心系统（订单、支付、风控、ERP、供应链）绝大多数是 Java 写的。MCP 的价值就在于让这些存量系统"零业务改动"地暴露给 AI。</strong></p>
</blockquote>
<p>三分钟把一个 Spring Boot 服务变成 MCP Server：</p>
<pre highlighted="true"><code><span>&lt;!-- 三选一：WebMVC 项目 / WebFlux 响应式项目 / 本地 STDIO 工具 --&gt;</span>
<span>&lt;<span>dependency</span>&gt;</span>
    <span>&lt;<span>groupId</span>&gt;</span>org.springframework.ai<span>&lt;/<span>groupId</span>&gt;</span>
    <span>&lt;<span>artifactId</span>&gt;</span>spring-ai-starter-mcp-server-webmvc<span>&lt;/<span>artifactId</span>&gt;</span>
<span>&lt;/<span>dependency</span>&gt;</span>
</code></pre>
<pre highlighted="true"><code><span># application.yml</span>
<span>spring:</span>
  <span>ai:</span>
    <span>mcp:</span>
      <span>server:</span>
        <span>name:</span> <span>order-mcp-server</span>
        <span>version:</span> <span>1.0</span><span>.0</span>
        <span>protocol:</span> <span>STREAMABLE</span>            <span># 2.0 起 SSE 已废弃；可选 STREAMABLE / STATELESS</span>
        <span>streamable-http:</span>
          <span>mcp-endpoint:</span> <span>/api/mcp</span>        <span># Streamable HTTP 端点</span>
</code></pre>
<pre highlighted="true"><code><span>@SpringBootApplication</span>
<span>public</span> <span>class</span> <span>OrderMcpServerApplication</span> {

    <span>public</span> <span>static</span> <span>void</span> <span>main</span><span>(String[] args)</span> {
        SpringApplication.run(OrderMcpServerApplication.class, args);
    }

    <span>/**
     * 存量 Service 一行不改，包一层就变成 AI 可调用的工具：
     * 自动配置会把所有 ToolCallback 合并注册为 MCP Tools。
     */</span>
    <span>@Bean</span>
    ToolCallbackProvider <span>orderTools</span><span>(OrderService orderService)</span> {
        <span>return</span> MethodToolCallbackProvider.builder()
                .toolObjects(orderService)      <span>// 内部是 @Tool 标注的方法</span>
                .build();
    }
}
</code></pre>
<p>客户端侧，一个 <code>ToolProvider</code> 可以同时挂多个 MCP Server：</p>
<pre highlighted="true"><code><span>// LangChain4j 风格：工具的召回交给模型运行时决策</span>
<span>@Bean</span>
ToolProvider <span>mcpToolProvider</span><span>()</span> {
    <span>McpClient</span> <span>orderClient</span> <span>=</span> <span>new</span> <span>DefaultMcpClient</span>.Builder()
            .transport(<span>new</span> <span>HttpMcpTransport</span>.Builder()
                    .sseUrl(<span>"http://order-mcp:8080/api/mcp"</span>)
                    .logRequests(<span>true</span>)
                    .logResponses(<span>true</span>)
                    .build())
            .build();

    <span>return</span> McpToolProvider.builder()
            .mcpClients(List.of(orderClient))
            .failIfOneServerFails(<span>false</span>)     <span>// 单个 Server 挂了不影响其他工具</span>
            .build();
}
</code></pre>
<p>还可以运行时动态发现并注册新工具，<strong>新增外部工具只需部署一个 MCP Server，应用自动发现，无需重启，真正做到热插拔</strong>：</p>
<pre highlighted="true"><code><span>@Bean</span>
<span>public</span> List&lt;ToolCallback&gt; <span>dynamicMcpTools</span><span>(McpClientManager manager)</span> {
    <span>return</span> manager.getClients().stream()
            .flatMap(client -&gt; client.listTools().stream())
            .map(tool -&gt; (ToolCallback) tool)
            .collect(Collectors.toList());
}
</code></pre>
<h3 id="86-安全红线与写操作纪律">8.6 安全红线与写操作纪律</h3>
<blockquote>
<p>⚠️ <strong>安全红线</strong>：Spring AI 官方文档明确——HTTP 传输的 MCP Server 默认暴露的是<strong>无鉴权的 JSON-RPC 端点</strong>，任何能访问到的客户端都能列出并调用全部工具。<strong>上线前必须前置安全边界</strong>：OAuth2 / OIDC 鉴权、网关限流、工具级权限、调用审计。<strong>绝不能把 MCP Server 裸暴露在内网。</strong></p>
</blockquote>
<p>写操作工具还要守三条纪律：<strong>权限校验、二次确认（人在回路 HITL）、幂等</strong>：</p>
<pre highlighted="true"><code><span>/** 写操作工具：权限 + 二次确认 + 幂等 + 审计，一个都不能少 */</span>
<span>@Tool("提交报销单，写操作，需要用户确认")</span>
<span>public</span> ExpenseResult <span>submitExpense</span><span>(SubmitExpenseRequest request)</span> {
    <span>// 幂等键控制：模型重试、网络抖动都不会导致重复提交</span>
    <span>return</span> idempotentService.execute(
            request.idempotentKey(),
            () -&gt; expenseService.submit(request));
}
</code></pre>
<p>配套手段：<code>idempotencyKey</code> + 业务 outbox + 唯一索引；工具白名单、只读工具优先、高危写操作默认不开放。</p>
<p>手脚齐全了，最后需要一个"会自己干活的人"把它们组织起来——Agent 出场。</p>
<h2 id="九agent从会思考到能交付">九、Agent：从"会思考"到"能交付"</h2>
<blockquote>
<p><strong>Agent = LLM（大脑）+ Planning（规划）+ Memory（记忆）+ Tools（手脚）</strong>，核心是<strong>自主决定下一步做什么</strong>。区别于 LLM 的"一问一答"，Agent 是"给目标，自己完成"。</p>
</blockquote>
<h3 id="91-react-循环思考--行动--观察">9.1 ReAct 循环：思考 → 行动 → 观察</h3>
<p><img alt="image" loading="lazy" data-src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093756140-1243917576.png" src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093756140-1243917576.png"></p>
<p>Java 里我们熟悉的<strong>责任链 + 策略模式</strong>，就很像这个决策循环：</p>
<pre highlighted="true"><code><span>while</span> (未完成目标) {
    思考 nextStep;
    选择 tool;
    执行 tool.call(params);
    观察 toolResult;
    更新上下文;
}
</code></pre>
<h3 id="92-三层递进范式别混为一谈">9.2 三层递进范式：别混为一谈</h3>
<div><table>
<thead>
<tr>
<th>层级</th>
<th>范式</th>
<th>解决什么问题</th>
<th>终止机制</th>
<th>风险</th>
</tr>
</thead>
<tbody>
<tr>
<td>内层 · 推理</td>
<td><strong>ReAct</strong>（Thought → Action → Observation）</td>
<td>单个智能体"怎么想、怎么动"</td>
<td>模型自判断</td>
<td>易死循环、易提前终止</td>
</tr>
<tr>
<td>中层 · 调度</td>
<td><strong>循环工程 Loop</strong>（图状态机 / 多智能体循环）</td>
<td>多步骤任务"怎么跑完、怎么收敛"</td>
<td>结构化规则 + 状态判断</td>
<td>无容错、无安全管控</td>
</tr>
<tr>
<td>外层 · 管控</td>
<td><strong>驾驭工程 Harness</strong>（围栏、刹车、运维底座）</td>
<td>生产环境"怎么可控、可上线"</td>
<td>全局策略</td>
<td>——</td>
</tr>
</tbody>
</table></div>
<blockquote>
<p><strong>公式</strong>：<code>生产级多智能体 = 驾驭工程（外层管控）+ 循环工程（中层调度）+ ReAct（内层推理）</code></p>
</blockquote>
<h3 id="93-带刹车和兜底的-react-循环">9.3 带"刹车和兜底"的 ReAct 循环</h3>
<p>Demo 里只有一个 <code>while(true)</code>，生产里它会死在第一道坎上。一个能上线的循环必须有四道防护：</p>
<pre highlighted="true"><code><span>/**
 * 四道防护：① 硬性步数上限 ② 工具异常转文本回灌 ③ 预算（时间/Token）熔断 ④ 兜底收敛话术
 */</span>
<span>public</span> Answer <span>run</span><span>(String userInput, <span>int</span> maxSteps, <span>long</span> budgetMillis)</span> {
    List&lt;ChatMessage&gt; messages = <span>new</span> <span>ArrayList</span>&lt;&gt;();
    messages.add(SystemMessage.from(REACT_PROMPT + renderToolSchemas()));
    messages.add(UserMessage.from(userInput));

    <span>long</span> <span>deadline</span> <span>=</span> System.currentTimeMillis() + budgetMillis;

    <span>for</span> (<span>int</span> <span>step</span> <span>=</span> <span>0</span>; step &lt; maxSteps; step++) {                    <span>// ① 步数上限</span>
        <span>if</span> (System.currentTimeMillis() &gt; deadline) {                 <span>// ③ 预算熔断</span>
            <span>return</span> <span>new</span> <span>Answer</span>(<span>"任务超时，已停止并返回已获得的部分结论。"</span>);
        }

        <span>AiMessage</span> <span>ai</span> <span>=</span> chatModel.generate(messages).content();
        <span>if</span> (!ai.hasToolExecutionRequests()) {
            <span>return</span> <span>new</span> <span>Answer</span>(ai.text());                            <span>// 收敛：给出最终答复</span>
        }

        messages.add(ai);
        <span>for</span> (ToolExecutionRequest req : ai.toolExecutionRequests()) {
            String result;
            <span>try</span> {
                result = toolExecutor.execute(req, UserContextHolder.tenantId());
                result = truncate(result, <span>2000</span>);                     <span>// 截断：防工具结果撑爆上下文</span>
            } <span>catch</span> (Exception e) {
                <span>// ② 异常不让它抛穿：转成文本回灌，模型有机会换一条路</span>
                result = <span>"TOOL_ERROR: "</span> + e.getMessage() + <span>"，请更换方式或告知用户稍后重试。"</span>;
            }
            messages.add(ToolExecutionResultMessage.from(req, result));
        }
        <span>// 超过预算就压缩历史：保留最近 N 轮 + 早期摘要</span>
        messages = contextCompactor.compact(messages, TOKEN_BUDGET);
    }
    <span>return</span> <span>new</span> <span>Answer</span>(<span>"步骤超限，已中断。请把问题拆得更小一些。"</span>);       <span>// ④ 兜底</span>
}
</code></pre>
<blockquote>
<p>💡 <strong>技术亮点</strong>：除了 <code>MAX_STEPS</code>，还要做<strong>工具调用去重</strong>——同一工具同参数连续调用直接短路，这是"反复调同一工具烧钱不收敛"的特效药；<code>ToolResponse</code> 必须<strong>截断</strong>，一个 10 万行的 SQL 结果塞进上下文等于直接爆 token。</p>
</blockquote>
<p>上下文压缩的常见实现：记录每轮 token 数，超限时把旧消息做摘要，保留最近几轮原话：</p>
<pre highlighted="true"><code><span>public</span> List&lt;Message&gt; <span>manageContext</span><span>(List&lt;Message&gt; history)</span> {
    <span>int</span> <span>tokenCount</span> <span>=</span> countTokens(history);
    <span>if</span> (tokenCount &lt; MAX_TOKENS * <span>0.8</span>) <span>return</span> history;

    <span>// 取前一半旧消息生成摘要</span>
    List&lt;Message&gt; oldMsgs = history.subList(<span>0</span>, history.size() / <span>2</span>);
    <span>String</span> <span>summary</span> <span>=</span> llm.call(<span>"请用一句话总结以下对话："</span>, oldMsgs);

    <span>// 新上下文 = 摘要 + 最近几轮原话</span>
    List&lt;Message&gt; newContext = <span>new</span> <span>ArrayList</span>&lt;&gt;();
    newContext.add(<span>new</span> <span>SystemMessage</span>(<span>"历史摘要："</span> + summary));
    newContext.addAll(history.subList(history.size() / <span>2</span>, history.size()));
    <span>return</span> newContext;
}
</code></pre>
<h3 id="94-框架层面aiservices-极简装配">9.4 框架层面：AiServices 极简装配</h3>
<p>自己写循环是为了理解原理，实际项目直接用框架，ReAct 推理循环它帮你实现了：</p>
<pre highlighted="true"><code><span>@Configuration</span>
<span>public</span> <span>class</span> <span>AgentConfig</span> {

    <span>@Bean</span>
    <span>public</span> CustomerServiceAgent <span>customerServiceAgent</span><span>(
            ChatLanguageModel chatModel,
            OrderQuerySkill orderSkill,
            LogisticsQuerySkill logisticsSkill)</span> {

        <span>return</span> AiServices.builder(CustomerServiceAgent.class)
                .chatLanguageModel(chatModel)
                .tools(orderSkill, logisticsSkill)                       <span>// 注入业务技能</span>
                .chatMemory(MessageWindowChatMemory.withMaxMessages(<span>20</span>)) <span>// 对话记忆</span>
                .maxIterations(<span>5</span>)                                        <span>// 最大决策步数，防死循环</span>
                .timeout(Duration.ofSeconds(<span>30</span>))                         <span>// 全局超时</span>
                .build();
    }
    <span>// 使用：agent.chat("我的订单 1001 什么时候到？")</span>
}
</code></pre>
<p>记忆分两层：<strong>短期记忆</strong>用滑动窗口（<code>MessageWindowChatMemory</code>），<strong>长期记忆</strong>可以落向量库，按用户画像检索。</p>
<h3 id="95-agent-vs-workflow别为了用-agent-而用-agent">9.5 Agent vs Workflow：别为了用 Agent 而用 Agent</h3>
<p><strong>Workflow 是路径写死，Agent 是路径由模型决定</strong>。能确定性解决的流程就用 Workflow，稳定又便宜；只有任务路径真的无法预知时，才值得上 Agent——这是成本与稳定性的问题，不是技术问题。</p>
<p>评估一个 Agent 好不好，看这些指标：任务完成率、平均步数、工具调用准确率、端到端延迟、成本/token，再配合轨迹回放（Trace）排查失败原因。</p>
<p>概念全讲完了，它们到底怎么协同？来看一次完整的请求。</p>
<h2 id="十端到端串讲一次客服请求的全链路">十、端到端串讲：一次客服请求的全链路</h2>
<p>场景：电商智能客服，用户问——<strong>"我的订单 SO202610150001 为什么还没发货？"</strong></p>
<p><img alt="image" loading="lazy" data-src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093818136-1677941641.png" src="https://img2024.cnblogs.com/blog/739056/202611/739056-20261104093818136-1677941641.png"></p>
<p>这条链路里，所有概念都出场了：<strong>Skills 决定流程 → LLM 做意图识别 → Tool 决定动作 → MCP 打通存量系统 → RAG 补业务知识 → 向量与余弦相似度负责召回 → 最后回到工程治理层保证稳定、安全、便宜</strong>。不是把全部知识塞给 LLM，而是 Agent 决定查什么、调什么、怎么答。</p>
<p>同样的骨架换个场景一样成立：</p>
<ul>
<li><strong>企业差旅助手</strong>："差旅报销标准是什么？我上个月有没有未报销单据？"——意图识别拆成两个子问题，RAG 查制度（回答带 <code>[DOC-013]</code> 引用），MCP 查报销系统拿到 2 笔未报销单据，最后还能追问"要不要帮你提交"；</li>
<li><strong>智能运维助手</strong>："昨天服务器 CPU 告警多少次？"——RAG 检索操作手册无果，转调监控系统的 <code>getAlerts(...)</code> 工具，拿到"35 次"后由 LLM 组织成自然语言回答。</li>
</ul>
<p>知识问答 + 业务查询 + 可继续执行动作，三者齐活，这才是企业级 AI 应用。</p>
<h2 id="十一工程治理层java-的主场">十一、工程治理层：Java 的主场</h2>
<p>面试官真正想听的下一句往往是："如果 1000 个用户同时问，你的 Spring Boot 后端怎么设计？"三道防护，缺一不可：</p>
<pre highlighted="true"><code><span>/**
 * ① 流式输出（SSE + WebFlux）：大模型很慢，绝不能同步阻塞，边生成边返回压 TTFT；
 * ② 多租户限流：按租户做 Redis 令牌桶，防止某个租户把配额吃光；
 * ③ 超时降级：模型超时不能挂页面，降级到"知识库直出"保住可用性。
 */</span>
<span>@GetMapping(value = "/chat/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)</span>
<span>public</span> Flux&lt;String&gt; <span>stream</span><span>(<span>@RequestParam</span> String q,
                           <span>@RequestHeader("X-Tenant-Id")</span> String tenantId)</span> {

    <span>return</span> redisRateLimiter.acquire(tenantId)                 <span>// ② Redis + Lua 令牌桶</span>
            .filter(RateLimitResult::allowed)
            .switchIfEmpty(Flux.error(<span>new</span> <span>BizException</span>(<span>"TOO_MANY_REQUESTS"</span>)))
            .flatMapMany(ok -&gt; chatClient.prompt()
                    .user(q)
                    .stream()                                  <span>// ① 流式</span>
                    .content()
                    .timeout(Duration.ofSeconds(<span>30</span>))           <span>// ③ 整体超时</span>
                    .onErrorResume(e -&gt;                        <span>// ③ 降级兜底</span>
                            Flux.just(<span>"模型服务繁忙，已为你返回知识库原文检索结果。"</span>)));
}
</code></pre>
<p><strong>这几个数字要能报出来</strong>，它们体现的是工程体感：</p>
<ul>
<li><strong>流式输出</strong>：首字延迟从 8s 降到 500ms 量级，"打字机效果"直接决定用户去留；</li>
<li><strong>语义缓存</strong>：重复问题命中缓存后跳过"检索 + 重排 + 生成"全链路，<strong>推理成本可降 40%~70%</strong>；</li>
<li><strong>模型分层路由</strong>："意图识别、格式转换"给小模型，"复杂推理、关键决策"给旗舰模型，<strong>整体成本可降 40%~60%</strong>；</li>
<li><strong>模型抽象</strong>：因为做了统一 <code>ChatModel</code> 抽象，换模型 = <strong>改一条配置</strong>；没有抽象的项目，换模型 ≈ 重新开发。</li>
</ul>
<p>其余几件老本行的事，一件都不能少：</p>
<ul>
<li><strong>多租户隔离</strong>：元数据带 <code>tenantId / acl / version</code>，<strong>在检索阶段做 pre-filter</strong>，向量库按租户分区——不能只靠"检索后再过滤"；</li>
<li><strong>可观测</strong>：全链路 trace 打点 prompt / token / latency / 工具调用，Micrometer + OpenTelemetry，再用 W3C Trace Context 打通 MCP 全链路；</li>
<li><strong>模型挂了三层兜底</strong>：同模型多 Key/多地域重试 → 换备选模型（靠统一抽象层）→ 降级到知识库原文直出。<strong>可用性靠架构，不靠模型</strong>；</li>
<li><strong>数据安全</strong>：网关层脱敏，敏感字段不进模型，必要时私有化部署。</li>
</ul>
<h2 id="十二踩坑大全技术难点与解决方案对照表">十二、踩坑大全：技术难点与解决方案对照表</h2>
<p>这张表融合了所有一线踩坑，建议直接收藏当检查清单用：</p>
<div><table>
<thead>
<tr>
<th>#</th>
<th>难点</th>
<th>典型表现</th>
<th>解决方案</th>
<th>Java 侧抓手</th>
</tr>
</thead>
<tbody>
<tr>
<td>1</td>
<td><strong>幻觉</strong></td>
<td>一本正经编造订单号/政策</td>
<td>Prompt 硬约束 + 强制引用 + 低温度 + 阈值拒答 + 人工兜底；<strong>RAG 只能降低概率，不能彻底消除</strong></td>
<td>系统提示 + Advisor + 引用回填</td>
</tr>
<tr>
<td>2</td>
<td><strong>检索召回不准</strong></td>
<td>向量相似 ≠ 语义相关；编号/术语/人名是稠密检索死穴</td>
<td>混合检索（Dense + BM25 → RRF）→ Cross-Encoder 重排 → top-5~8；Multi-Query 查询改写</td>
<td>ES 一次查询吃 BM25 + 向量；<code>similarityThreshold</code> 调参</td>
</tr>
<tr>
<td>3</td>
<td><strong>切片语义割裂</strong></td>
<td>固定长度硬切，论证被腰斩</td>
<td>结构感知切片 + 10%~20% overlap + <strong>父子块</strong>（子块检索、父块喂模型）+ 元数据增强</td>
<td>可插拔切片器，策略变更走离线评测</td>
</tr>
<tr>
<td>4</td>
<td><strong>上下文爆炸 / 成本失控</strong></td>
<td>Agent 多步任务 Token 消耗是普通对话几十倍</td>
<td>滑动窗口 + 历史摘要 + 工具结果截断 + Skills 按需加载 + 语义缓存 + 模型分层路由 + 稳定前缀提 KV Cache 命中</td>
<td>Redis 语义缓存 + 网关 Token 计量 + 成本看板</td>
</tr>
<tr>
<td>5</td>
<td><strong>Agent 死循环 / 失控</strong></td>
<td>反复调同一工具、跑偏、无限烧钱</td>
<td>硬性步数上限 + 时间/Token 双预算熔断 + 调用去重 + 图状态机替代 <code>while(true)</code></td>
<td><code>maxIterations</code> + Spring StateMachine</td>
</tr>
<tr>
<td>6</td>
<td><strong>工具误调用 / 参数错误</strong></td>
<td>查订单却调了退款接口；参数格式乱填</td>
<td>优化 <code>@Tool</code> 描述 + Few-shot 示例 + JSON Schema 强校验 + 错误回灌重试闭环 + 运行时收敛工具集</td>
<td><code>ToolProvider</code> 动态决策 + Bean Validation</td>
</tr>
<tr>
<td>7</td>
<td><strong>工具安全 / 越权</strong></td>
<td>Prompt 注入、越权查他人订单</td>
<td>权限过滤下推检索层 + 工具白名单 + 最小权限 + 审计日志 + 高危操作人在回路（HITL）</td>
<td>Spring Security 工具级权限 + 网关透传用户上下文</td>
</tr>
<tr>
<td>8</td>
<td><strong>MCP 生产化</strong></td>
<td>HTTP 端点默认无鉴权，裸暴露即裸奔</td>
<td>OAuth2/OIDC 前置 + 网关限流 + 工具级权限 + 调用审计；优先 Streamable HTTP / STATELESS</td>
<td>Spring Security + MCP Server + W3C Trace Context</td>
</tr>
<tr>
<td>9</td>
<td><strong>高并发与延迟</strong></td>
<td>同步阻塞打满线程池；用户等 8 秒才见字</td>
<td>WebFlux + SSE 流式 + 虚拟线程 + 并行召回 + 多租户令牌桶 + 超时降级知识库直出</td>
<td>Redis + Lua 令牌桶、<code>timeout</code> + <code>onErrorResume</code></td>
</tr>
<tr>
<td>10</td>
<td><strong>多租户数据泄露</strong></td>
<td>不同客户文档混在一个向量库</td>
<td>元数据 <code>tenantId</code> 检索阶段 pre-filter + 按租户 Partition/Collection 隔离</td>
<td>向量库 filter 表达式 + 请求级租户上下文</td>
</tr>
<tr>
<td>11</td>
<td><strong>向量数据不一致</strong></td>
<td>业务库更新了，检索还是旧答案</td>
<td>Canal/CDC/Debezium 订阅 binlog 增量同步 + 版本号对比 + 定时全量对账 + 强制刷新 API</td>
<td>事件驱动 + 事务更新</td>
</tr>
<tr>
<td>12</td>
<td><strong>写操作幂等</strong></td>
<td>重试导致重复退款 / 重复提单</td>
<td><code>idempotencyKey</code> + 业务 outbox + 唯一索引 + 二次确认</td>
<td>AOP 前置校验 + 幂等服务</td>
</tr>
<tr>
<td>13</td>
<td><strong>效果无法度量</strong></td>
<td>"感觉还行"，上线后无法回归</td>
<td>黄金问答集，量化 recall@k / 忠实度 / 幻觉率；Prompt 与切片变更过回归门禁</td>
<td>RAGAS / TruLens 接入 CI</td>
</tr>
<tr>
<td>14</td>
<td><strong>技术栈易碎</strong></td>
<td>模型、协议、框架月月迭代（MCP 一年内规范大改、SSE 转弃用）</td>
<td>把变化关进适配层：模型统一 <code>ChatModel</code> 抽象、工具走 MCP 标准协议、Prompt 版本化</td>
<td>接口抽象 + 配置驱动 + 契约测试</td>
</tr>
<tr>
<td>15</td>
<td><strong>多轮上下文丢失</strong></td>
<td>"它的标准是多少？"不知道"它"指谁</td>
<td>基于历史会话做问题改写，补全指代再检索</td>
<td>Query Rewrite 组件</td>
</tr>
<tr>
<td>16</td>
<td><strong>数据安全</strong></td>
<td>敏感数据进入模型</td>
<td>网关脱敏 + 权限过滤 + 私有化部署</td>
<td>网关过滤器 + 数据分级</td>
</tr>
</tbody>
</table></div>
<h2 id="十三快问快答面试官的连环追问">十三、快问快答：面试官的连环追问</h2>
<div><table>
<thead>
<tr>
<th>#</th>
<th>追问</th>
<th>一句话回答</th>
</tr>
</thead>
<tbody>
<tr>
<td>1</td>
<td>余弦相似度为什么不用欧氏距离？</td>
<td>文本语义更关心<strong>方向</strong>而非长度，模长受文本长度影响会引入噪声；归一化后两者排序等价</td>
</tr>
<tr>
<td>2</td>
<td>归一化后为什么用内积？</td>
<td>省掉查询期两次开方和一次除法，检索是热路径，收益直接体现在 P99</td>
</tr>
<tr>
<td>3</td>
<td>向量库和 ES 有什么区别？</td>
<td>向量库专精 ANN 与高维检索；ES 强在"一套系统同时做文本与向量"，混合检索最省事。选型看运维成本和规模</td>
</tr>
<tr>
<td>4</td>
<td>有了 1M 上下文还要 RAG？</td>
<td>长上下文是<strong>预算</strong>不是<strong>替代</strong>。资料越多噪音越多、成本延迟越高，RAG 解决"先过滤再喂"</td>
</tr>
<tr>
<td>5</td>
<td>RAG 和微调怎么选？</td>
<td>知识频繁更新、要引用可追溯 → RAG；固定风格、专业格式、压缩 Prompt → 微调。生产常组合：<strong>小模型微调 + RAG 检索 + Agent 工具</strong></td>
</tr>
<tr>
<td>6</td>
<td>Agent 和 Workflow 的区别？</td>
<td>Workflow 路径写死，Agent 路径由模型决定。能确定性解决就用 Workflow，别为了用 Agent 而用 Agent</td>
</tr>
<tr>
<td>7</td>
<td>MCP 和 Function Calling 的关系？</td>
<td>FC 是模型侧"决定调哪个函数"，MCP 是工程侧"函数如何标准化接入"。MCP 让工具一次实现、多处复用</td>
</tr>
<tr>
<td>8</td>
<td>Skills 和 Prompt 的区别？</td>
<td>Prompt 是<strong>这一次</strong>做什么，Skills 是<strong>这一类任务</strong>按什么流程做，靠渐进式披露做到"装很多但不占上下文"</td>
</tr>
<tr>
<td>9</td>
<td>为什么需要 Rerank？</td>
<td>向量召回是双塔独立编码，无法深度交互；Rerank 交叉编码准但慢，所以只对 Top-50 精排</td>
</tr>
<tr>
<td>10</td>
<td>向量维度多少合适？</td>
<td>常见 768/1024/1536/3072，维度越高表达越细但成本线性增长，企业级常用 1024 + PQ 量化</td>
</tr>
<tr>
<td>11</td>
<td>模型挂了怎么办？</td>
<td>三层兜底：多 Key/多地域重试 → 换备选模型 → 知识库原文直出。可用性靠架构，不靠模型</td>
</tr>
<tr>
<td>12</td>
<td>怎么证明 RAG 有效？</td>
<td>黄金问答集，量化 recall@k / 忠实度 / 幻觉率，Prompt 与切片变更必须过回归门禁</td>
</tr>
<tr>
<td>13</td>
<td>Java 做 AI 比 Python 强在哪？</td>
<td>模型层 Python 生态更好，但<strong>工程层 Java 更强</strong>：虚拟线程扛高并发、强类型契合结构化输出、成熟的微服务/熔断/可观测体系，而且企业 90% 的业务系统本身就是 Java 写的——MCP Server 直接挂在现有服务上，不用重写</td>
</tr>
</tbody>
</table></div>
<h2 id="十四收尾一张速查表--三句忠告">十四、收尾：一张速查表 + 三句忠告</h2>
<p>概念速查表，存好：</p>
<div><table>
<thead>
<tr>
<th>概念</th>
<th>一句话本质</th>
<th>关键参数 / 关注点</th>
<th>Java 落地</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>LLM</strong></td>
<td>概率生成模型，不是知识库</td>
<td>temperature、maxTokens、上下文预算</td>
<td><code>ChatModel</code> / <code>ChatClient</code></td>
</tr>
<tr>
<td><strong>Token</strong></td>
<td>计费与长度单位</td>
<td>中文约 1 字 ≈ 1~1.5 token</td>
<td>网关侧计量与配额</td>
</tr>
<tr>
<td><strong>Embedding</strong></td>
<td>把语义变成高维坐标</td>
<td>维度、是否 L2 归一化、模型一致性</td>
<td><code>EmbeddingModel.embed()</code></td>
</tr>
<tr>
<td><strong>余弦相似度</strong></td>
<td>只看方向的相似度</td>
<td>[-1,1]；归一化后 == 内积</td>
<td>手写兜底 + 交给向量库</td>
</tr>
<tr>
<td><strong>向量库</strong></td>
<td>高维向量的存储与 ANN 检索</td>
<td>recall@K、HNSW <code>efSearch</code>、IVF <code>nprobe</code></td>
<td>Milvus / pgvector / ES 8.x</td>
</tr>
<tr>
<td><strong>RAG</strong></td>
<td>外部知识管理 + 检索 + 生成</td>
<td>topK、阈值、切片策略、Rerank</td>
<td><code>QuestionAnswerAdvisor</code></td>
</tr>
<tr>
<td><strong>Tool Calling</strong></td>
<td>模型点名，程序执行</td>
<td>描述质量、参数 Schema、权限</td>
<td><code>@Tool</code> / <code>ToolCallback</code></td>
</tr>
<tr>
<td><strong>Agent</strong></td>
<td>自己决定下一步干什么</td>
<td>步数上限、预算熔断、终止条件</td>
<td><code>AiServices</code> + 状态机</td>
</tr>
<tr>
<td><strong>MCP</strong></td>
<td>AI 工具的统一插座</td>
<td>Tools/Resources/Prompts；Streamable HTTP</td>
<td><code>spring-ai-starter-mcp-server-*</code></td>
</tr>
<tr>
<td><strong>Skills</strong></td>
<td>按需加载的行为手册</td>
<td>渐进式披露、<code>SKILL.md</code> &lt; 500 行、引用只放一层</td>
<td>文件目录 + 按需注入</td>
</tr>
</tbody>
</table></div>
<p>最后送三句忠告，都是真金白银换来的：</p>
<ol>
<li><strong>把 LLM 当成一个"不可靠的第三方服务"来治理</strong>——超时、重试、熔断、降级、可观测，老本行一套都不能少，只是这次处理的是概率性输出；</li>
<li><strong>用 RAG 把答案锚定在事实上，用评测集把效果变成数字</strong>——这两件事做了，项目才算从 Demo 走向生产；</li>
<li><strong>Skills、MCP、Agent 本质都是面向对象思想在 AI 时代的复用</strong>：封装、抽象、标准化接口。想清楚这一点，新名词再多也不慌。</li>
</ol>
<p>记住这句话就够了：<strong>AI 应用的本质，是把"不确定的模型能力"，装进"确定的工程系统"里。而这件事，恰好是 Java 工程师最擅长的事。</strong> 造发动机的不多，造整车、修高速、建加油站的，才是大多数人的战场。</p>
<hr>
<p>聊个具体的：你做 RAG 或 Agent 落地时，<strong>踩过最疼的坑是哪个</strong>？切片把语义切碎了、检索召不准、还是模型一本正经地编？评论区聊聊你的场景和参数，我看到会挨个回复交流。</p>
<p>如果这篇全景图帮你把概念串起来了，点个赞、点个在看、顺手关注一下——后续还会持续更新 Java AI 工程化的实战干货，比如混合检索调参实录和 Agent 状态机设计，别错过。</p>


</div></div>', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-05 11:44:52.030478+08'::timestamptz),
  ('fe187b19-2019-489a-8aa1-8cd37bf5212f'::uuid, '26561010-f249-4b0d-a786-f9114ec06230'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '油猴｜搜索查重脚本（百度+必应双版本）', '<h1></h1><blockquote><p>用途：百度/必应搜索页本地扫描搜索结果，检测目标作者、匹配已发布标题库；控制台输出日志 + 浏览器桌面通知。 运行环境：Tampermonkey油猴，<strong>全部逻辑浏览器本地执行，不上传任何数据</strong>。 脱敏调整：<code>TARGET_AUTHOR</code>、<code>PUBLISHED_TITLES</code>仅保留示例占位，业务实际数据不在笔记内硬编码，使用时自行填入。 Haven标签：<code>#油猴 #tampermonkey #js脚本 #浏览器脚本 #搜索查重</code></p></blockquote><h2>能力总览</h2><ol><li><p><strong>文本归一化</strong>：剔除全部标点，只保留中文、英文、数字，转小写做匹配</p></li><li><p><strong>两套命中规则</strong></p><ul><li><p>标题匹配：页面标题归一化后包含库内标题片段则命中</p></li><li><p>作者匹配：搜索结果来源作者等于配置目标作者则命中</p></li></ul></li><li><p><strong>去重机制</strong>：Set集合，同一标题只打印一次日志、只触发一次通知</p></li><li><p><strong>防抖扫描</strong>：DOM变动、滚动事件防抖，避免高频重复执行</p></li><li><p><strong>通知提醒</strong>：命中触发浏览器系统通知；通知被禁用时仅保留控制台日志</p></li><li><p>百度版：适配PC新旧卡片、移动端，无自动滚动</p></li><li><p>必应版：PC+移动端，自动逐屏下滑停顿人工复核，遍历完毕回滚页面顶部</p></li></ol><h2>脚本1：百度搜索查重 baidu‑check.user.js</h2><pre class="hljs"><code>// ==UserScript==
// @name         内容查重（百度PC+移动端兼容｜浏览器本地通知）
// @namespace    [http://tampermonkey.net/](http://tampermonkey.net/)
// @version      2.14
// @description  适配百度新旧搜索卡片、移动端搜索；忽略标点，仅比对中英文字数字；控制台日志输出，浏览器系统通知提醒，全部本地运算不上传数据
// @author       You
// @match        *://www.baidu.com/*
// @match        *://m.baidu.com/*
// @grant        none
// ==/UserScript==
(function() {
    ''use strict'';
    console.log("=====内容查重脚本【百度】启动=====");
    const CONFIG = {
        // 使用时替换为实际目标作者名称
        TARGET_AUTHOR: "示例作者名称"
    };
    // 使用时替换为真实已发布标题列表
    const PUBLISHED_TITLES = [
        "示例标题一",
        "示例标题二",
        "示例标题三"
    ];

    /**
     * 文本归一化：清除全部标点符号，仅保留中文/英文/数字，转小写
     * @param {string} str
     * @returns {string}
     */
    function normalize(str){
        return str.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '''')
            .trim()
            .toLowerCase();
    }
    const libNormalized = PUBLISHED_TITLES.map(t=&gt;normalize(t));

    // 获取搜索词
    function getSearchWord() {
        const urlParams = new URLSearchParams(location.search);
        return urlParams.get(''word'') || urlParams.get(''wd'') || '''';
    }

    let isRunning = false;
    let debounceTimer = null;
    const notifiedSet = new Set();
    const printedSet = new Set();

    /**
     * 触发浏览器桌面通知
     * @param {string} titleText 命中标题
     * @param {string} matchText 命中原因
     */
    function sendNotify(titleText, matchText){
        const msg = `标题：${titleText}\n${matchText}`;
        if("Notification" in window &amp;&amp; Notification.permission === "granted"){
            new Notification(''查重命中【百度】'', { body: msg });
        }
    }

    /**
     * 扫描页面搜索结果卡片
     */
    function scan(){
        if(isRunning) return;
        isRunning = true;
        try{
            const keyword = getSearchWord();
            // 百度三类结果卡片选择器
            const pcOldCards = document.querySelectorAll(''a.normal-sub_11u5j'');
            const pcNewCards = document.querySelectorAll(''div.cosc-card'');
            const mobileCards = document.querySelectorAll(''section.cosc-card-content'');
            const allCards = [...pcOldCards, ...pcNewCards, ...mobileCards];

            console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`);

            allCards.forEach(card=&gt;{
                let rawTitle = "";
                let linkUrl = "";
                let hitReason = null;

                // 旧版卡片 a.normal‑sub_11u5j
                if (card.tagName === "A") {
                    const titleEl = card.querySelector(''h3[data-module="top_title"]'');
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    linkUrl = card.href;
                    const titleNorm = normalize(rawTitle);
                    for(const s of libNormalized){
                        if(titleNorm.includes(s)){
                            hitReason = `标题库匹配：${s}`;
                            break;
                        }
                    }
                    // 匹配作者来源
                    if(!hitReason){
                        const sourceWrap = card.querySelector(''div[data-module="source"]'');
                        if(sourceWrap){
                            const authorDiv = sourceWrap.querySelector(''div.source-left_J1XTH div'');
                            if(authorDiv &amp;&amp; authorDiv.innerText.trim() === CONFIG.TARGET_AUTHOR){
                                hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`;
                            }
                        }
                    }
                }
                // PC新版 cosc‑card
                else if (card.classList.contains(''cosc-card'')) {
                    const titleEl = card.querySelector(''h3[data-module="title"]'');
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    const aTag = titleEl.querySelector(''a'');
                    linkUrl = aTag?.href || "";
                    const titleNorm = normalize(rawTitle);
                    for(const s of libNormalized){
                        if(titleNorm.includes(s)){
                            hitReason = `标题库匹配：${s}`;
                            break;
                        }
                    }
                    if(!hitReason){
                        const sourceWrap = card.querySelector(''div[data-module="source"]'');
                        if(sourceWrap){
                            const authorSpan = sourceWrap.querySelector(''span.cosc-source-text'');
                            if(authorSpan &amp;&amp; authorSpan.innerText.trim() === CONFIG.TARGET_AUTHOR){
                                hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`;
                            }
                        }
                    }
                }
                // 移动端 section.cosc‑card‑content
                else {
                    const titleEl = card.querySelector(''div[data-module="title"] h3'');
                    if(!titleEl) return;
                    rawTitle = titleEl.innerText.trim();
                    const aTag = card.querySelector("a");
                    linkUrl = aTag?.href || "";
                    const titleNorm = normalize(rawTitle);
                    for(const s of libNormalized){
                        if(titleNorm.includes(s)){
                            hitReason = `标题库匹配：${s}`;
                            break;
                        }
                    }
                    if(!hitReason){
                        const sourceWrap = card.querySelector(''div[data-module="source"]'');
                        if(sourceWrap){
                            const authorSpan = sourceWrap.querySelector(''span.cosc-source-text'');
                            if(authorSpan &amp;&amp; authorSpan.innerText.trim() === CONFIG.TARGET_AUTHOR){
                                hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`;
                            }
                        }
                    }
                }

                const titleKey = rawTitle;
                if(printedSet.has(titleKey)) return;
                printedSet.add(titleKey);

                if(hitReason){
                    notifiedSet.add(titleKey);
                    console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl} | 原因：${hitReason}`);
                    sendNotify(rawTitle, hitReason);
                }else{
                    console.log(`- 普通 | 标题：${rawTitle} | 链接：${linkUrl}`);
                }
            })
        }finally{
            isRunning = false;
        }
    }

    // 防抖调度
    function debounceScan(){
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(scan, 400);
    }

    function start(){
        // 请求通知权限
        if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){
            Notification.requestPermission();
        }
        // 监听DOM变化
        const observer = new MutationObserver(()=&gt; debounceScan());
        observer.observe(document.body, {childList:true, subtree:true});
        window.addEventListener(''scroll'', debounceScan, {passive:true});
        scan();
        setTimeout(scan, 1200);
    }

    if(document.body) start();
    else document.addEventListener(''DOMContentLoaded'', start);
})();
</code></pre><h2>脚本2：必应搜索查重 bing‑check.user.js</h2><pre class="hljs"><code>// ==UserScript==
// @name         内容查重（必应Bing版｜PC移动端｜自动逐屏复核）
// @namespace    [http://tampermonkey.net/](http://tampermonkey.net/)
// @version      1.8
// @description  必应搜索查重；搜索结果自动分段缓慢下滑，每屏停顿人工复核，扫描完成回顶部；控制台输出标题与链接，浏览器本地通知提醒，全部本地运算不上传
// @author       You
// @match        *://cn.bing.com/search*
// @match        *://www.bing.com/search*
// @grant        none
// ==/UserScript==
(function() {
    ''use strict'';
    console.log("=====内容查重脚本【必应】启动=====");
    const CONFIG = {
        // 使用时替换实际目标作者
        TARGET_AUTHOR: "示例作者名称",
        scrollSegmentTime: 800,     // 单段滑动动画毫秒
        pausePerScreen: 1600,       // 每屏停留复核时间毫秒（主要调参）
        scrollUpTime: 1200          // 全部扫描完回顶部滚动时长
    };

    // 使用时替换为真实已发布标题列表
    const PUBLISHED_TITLES = [
        "示例标题一",
        "示例标题二",
        "示例标题三"
    ];

    /**
     * 文本归一化：清除全部标点符号，仅保留中文/英文/数字，转小写
     * @param {string} str
     * @returns {string}
     */
    function normalize(str){
        return str.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '''')
            .trim()
            .toLowerCase();
    }
    const libNormalized = PUBLISHED_TITLES.map(t=&gt;normalize(t));

    function getSearchWord() {
        const urlParams = new URLSearchParams(location.search);
        return urlParams.get(''q'') || '''';
    }

    let isRunning = false;
    let debounceTimer = null;
    const notifiedSet = new Set();
    const printedSet = new Set();
    let lastQuery = "";

    function sendNotify(titleText, matchText){
        const msg = `标题：${titleText}\n${matchText}`;
        if("Notification" in window &amp;&amp; Notification.permission === "granted"){
            new Notification(''查重命中【必应】'', { body: msg });
        }
    }

    /**
     * 平滑滚动Promise封装，自定义缓动
     * @param {number} targetTop
     * @param {number} duration
     * @returns {Promise&lt;void&gt;}
     */
    function smoothScrollTo(targetTop, duration) {
        return new Promise(resolve =&gt; {
            const startTop = window.scrollY;
            const distance = targetTop - startTop;
            const startTime = performance.now();
            function step(now) {
                const elapsed = now - startTime;
                const progress = Math.min(elapsed / duration, 1);
                const ease = 1 - Math.pow(1 - progress, 2);
                window.scrollTo(0, startTop + distance * ease);
                if (progress &lt; 1) {
                    requestAnimationFrame(step);
                } else {
                    resolve();
                }
            }
            requestAnimationFrame(step);
        });
    }

    /**
     * 自动逐屏下滑复核，到底返回顶部
     */
    async function runScrollCycle() {
        const viewH = window.innerHeight;
        let currentY = window.scrollY;
        const maxY = document.documentElement.scrollHeight - viewH;
        while(currentY &lt; maxY - 50){
            currentY = currentY + viewH * 0.85; // 屏幕重叠系数，避免漏看
            if(currentY &gt; maxY) currentY = maxY;
            await smoothScrollTo(currentY, CONFIG.scrollSegmentTime);
            await new Promise(r =&gt; setTimeout(r, CONFIG.pausePerScreen));
        }
        await smoothScrollTo(0, CONFIG.scrollUpTime);
    }

    function scan(){
        if(isRunning) return;
        isRunning = true;
        try{
            const keyword = getSearchWord();
            // 必应多类型卡片选择器
            const pcCards = document.querySelectorAll(''li.b_algo'');
            const mobileCards = document.querySelectorAll(''div.algocore, div.b_mcard, div.b_richcard'');
            const pcNewsCards = document.querySelectorAll(''.na_card_wrp'');
            const mobileNewsCards = document.querySelectorAll(''.nnews_card, .b_news_card'');
            const allCards = [...pcCards, ...mobileCards, ...pcNewsCards, ...mobileNewsCards];

            // 搜索词变化时重置状态并启动自动滚动
            if (keyword !== lastQuery) {
                console.log(`=====${keyword}===== 页面链接总数：${allCards.length}`);
                lastQuery = keyword;
                printedSet.clear();
                runScrollCycle();
            }

            allCards.forEach(card=&gt;{
                let rawTitle = "";
                let linkUrl = "";
                let hitReason = null;
                let sourceText = "";

                const titleLink = card.querySelector(''a[href] h2 a, h2 &gt; a, a.title, a[href]:has(h2)'');
                if(titleLink){
                    rawTitle = titleLink.innerText.trim();
                    linkUrl = titleLink.href;
                }else{
                    const directA = card.querySelector(''a[href]'');
                    if(directA){
                        rawTitle = directA.innerText.trim();
                        linkUrl = directA.href;
                    }
                }
                const sourceEl = card.querySelector(''.b_attribution, .source, .na_footer_name, .cap_txt, .b_caption'');
                sourceText = sourceEl?.innerText.trim() || '''';

                if (!rawTitle || !linkUrl) return;

                const titleNorm = normalize(rawTitle);
                for(const s of libNormalized){
                    if(titleNorm.includes(s)){
                        hitReason = `标题库匹配：${s}`;
                        break;
                    }
                }
                if(!hitReason &amp;&amp; sourceText === CONFIG.TARGET_AUTHOR){
                    hitReason = `来源作者匹配：${CONFIG.TARGET_AUTHOR}`;
                }

                const titleKey = rawTitle;
                if(printedSet.has(titleKey)) return;
                printedSet.add(titleKey);

                if(hitReason){
                    notifiedSet.add(titleKey);
                    console.log(`✅命中 | 标题：${rawTitle} | 链接：${linkUrl} | 原因：${hitReason}`);
                    sendNotify(rawTitle, hitReason);
                }else{
                    console.log(`- 普通 | 标题：${rawTitle} | 链接：${linkUrl}`);
                }
            })
        }finally{
            isRunning = false;
        }
    }

    function debounceScan(){
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(scan, 400);
    }

    function start(){
        if ("Notification" in window &amp;&amp; Notification.permission !== "granted" &amp;&amp; Notification.permission !== "denied"){
            Notification.requestPermission();
        }
        const observer = new MutationObserver(()=&gt; debounceScan());
        observer.observe(document.body, {childList:true, subtree:true});
        window.addEventListener(''scroll'', debounceScan, {passive:true});
        scan();
        setTimeout(scan, 1200);
    }

    if(document.body) start();
    else document.addEventListener(''DOMContentLoaded'', start);
})();
</code></pre><h2>使用说明</h2><h3>安装步骤</h3><ol><li><p>浏览器安装 Tampermonkey（油猴）扩展</p></li><li><p>新建脚本，复制对应版本全部代码保存</p></li><li><p>打开百度/必应搜索页自动加载；首次运行允许<strong>浏览器通知权限</strong>，否则无弹窗提醒</p></li></ol><h3>配置替换（每次新建脚本必须改）</h3><ol><li><p><code>CONFIG.TARGET_AUTHOR</code>：替换为实际要监控的作者名字</p></li><li><p><code>PUBLISHED_TITLES</code>数组：填入真实业务标题字符串</p><blockquote><p>新增/删减文章，直接修改此数组，保存脚本即生效</p></blockquote></li></ol><h3>必应版可调参数（CONFIG对象）</h3><table style="min-width: 50px;"><colgroup><col style="min-width: 25px;"><col style="min-width: 25px;"></colgroup><tbody><tr><th><p>参数</p></th><th><p>含义</p></th></tr><tr><td><p>pausePerScreen</p></td><td><p>每屏停留时间ms，越大人工复核越从容，推荐1200‑2000</p></td></tr><tr><td><p>scrollSegmentTime</p></td><td><p>单段滑动动画耗时</p></td></tr><tr><td><p>scrollUpTime</p></td><td><p>全部遍历完成回顶部动画时长</p></td></tr></tbody></table><h3>查看输出结果</h3><ol><li><p>F12 → Console控制台查看完整日志；<code>✅</code>代表命中条目</p></li><li><p>命中会弹出浏览器桌面通知，显示标题与命中原因；通知被屏蔽仅保留控制台输出</p></li></ol><h3>限制与风险</h3><ol><li><p>纯前端本地运行，不上传任何数据</p></li><li><p>搜索引擎前端改版会导致DOM选择器失效，需要更新卡片querySelector</p></li><li><p>浏览器全局/站点通知权限关闭，则只有控制台日志</p></li><li><p>必应切换搜索关键词会重新执行完整自动滚动复核</p></li></ol><h3>故障排查</h3><ol><li><p>没有通知：检查网站通知权限是否允许</p></li><li><p>扫描不到结果：Console确认脚本已启动；判断是否搜索引擎DOM改版，选择器失效</p></li><li><p>重复打印日志：页面DOM频繁刷新触发，脚本自带Set去重，极端场景仍会出现</p></li></ol><blockquote><p>Haven使用提示：笔记保存后，实际业务标题库不要写进笔记正文；新建油猴脚本时，手动粘贴真实作者与标题数组。</p></blockquote><p>需要我把这份输出再压缩为极简版（去掉JS内注释，适合Haven存储）吗？</p>', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-05 13:05:03.358975+08'::timestamptz),
  ('a4482ab7-9184-475f-8dd0-dd67e030303e'::uuid, 'df15267d-3eb5-4da6-b161-fe38e1bbf7a4'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'archlinux 简明指南', '<div id="readability-page-1" class="page"><div data-v-fc4727e6=""><blockquote><h3 id="⛵-万事俱备-只欠东风" tabindex="-1">⛵ 万事俱备，只欠东风 <a href="#⛵-万事俱备-只欠东风" aria-label="Permalink to &quot;⛵ 万事俱备，只欠东风&quot;">​</a></h3><p>经过了上一节的准备工作，我们可以开始正式安装 archlinux 了。如果你还没有完成前面的阅读，请先仔细阅读章节 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html">安装前的准备</a>。如果对本节的步骤不理解或者有疑问，请阅读下一节 <a href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a></p></blockquote><p>本节从安装最基础的、无图形化界面的 archlinux 系统开始。如有需要可以参阅 <a href="https://wiki.archlinux.org/title/Installation_guide_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)" target="_blank" rel="noreferrer">ArchWiki 官方安装指南</a>。</p><div><p>ℹ️ 提示</p><p>本节中的截图来自虚拟机和已经安装好的 archlinux。不用担心！和你在实体机看到的是一样的。</p></div><div><p>⚠️ 注意</p><p>请按照指南的步骤一步一步进行！不要跳步、也不要在步骤中添加多余的动作！</p><p>另外，如果安装中有报错，请弄清楚报错的原因（这要求你起码能看懂有报错）！常见的原因包括但不限于输错了命令、添加了多余的步骤等。在解决了问题之后再进行下一步！</p></div><h2 id="_0-进入安装环境" tabindex="-1">0. 进入安装环境 <a href="#_0-进入安装环境" aria-label="Permalink to &quot;0. 进入安装环境&quot;">​</a></h2><p><img src="https://arch.icekylin.online/assets/pre-virt_vb-14.pyALUo_J.png" alt="archlinux-iso-1"></p><ol><li>在第一个选项回车</li></ol><p><img src="https://arch.icekylin.online/assets/pre-virt_vb-15.CqUq5u2n.png" alt="archlinux-iso-2"></p><ol start="2"><li>进入安装环境后，便可以开始通过命令安装 archlinux 了</li></ol><div><p>ℹ️ 提示</p><ul><li>在2025年后，用于自动更新 <code>mirrorlist</code>（软件包管理器 <code>pacman</code> 的软件源）的 <code>reflector</code> 服务由于会误删某些有用的源信息已被默认禁用，无需再手动禁用。</li></ul></div><div><p>ℹ️ 提示</p><ul><li><p>在命令行中你可以使用如下命令清屏：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>clear</span></span></code></pre></div><p>同时，你可以使用 <code>Tab</code> 键在输入命令的时候对命令、参数或文件路径进行自动补全，提高效率的同时降低输入错误的风险。</p></li><li><p><code>Tab</code> 无法补全时，有些设备的蜂鸣器会发出“哔——”声，可以使用如下命令禁用蜂鸣器内核模块：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rmmod</span><span> pcspkr</span></span></code></pre></div></li><li><p>要永久禁用蜂鸣器内核模块, 请创建并编辑 <code>/etc/modprobe.d/blacklist.conf</code></p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>sudoedit</span><span> /etc/modprobe.d/blacklist.conf</span></span></code></pre></div><p>加入以下内容</p><div><pre tabindex="0"><code><span><span>blacklist pcspkr</span></span></code></pre></div><p>这样下次启动就不会加载 pcspkr 模块了</p></li></ul></div><h2 id="_1-确认是否为-uefi-模式" tabindex="-1">1. 确认是否为 UEFI 模式 <a href="#_1-确认是否为-uefi-模式" aria-label="Permalink to &quot;1. 确认是否为 UEFI 模式&quot;">​</a></h2><p>我们先来确认一下是否为 <code>UEFI</code> 模式：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>ls</span><span> /sys/firmware/efi/efivars</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_check-efi.Cst0GaUE.png" alt="check-efi"></p><p>若输出了一堆东西（<code>efi</code> 变量），则说明已在 <code>UEFI</code> 模式。否则请确认你的启动方式是否为 <code>UEFI</code>。</p><h2 id="_2-连接网络" tabindex="-1">2. 连接网络 <a href="#_2-连接网络" aria-label="Permalink to &quot;2. 连接网络&quot;">​</a></h2><div><p>ℹ️ 提示</p><p>archlinux 的安装<strong>必须</strong>要求网络环境。</p></div><div><p>ℹ️ 提示</p><p>若为虚拟机且按照上一节 <a href="https://arch.icekylin.online/guide/rookie/pre-virt.html#_3-%E9%85%8D%E7%BD%AE-virtualbox">虚拟机安装前的准备</a> 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。</p></div><h3 id="若使用无线连接" tabindex="-1">若使用<strong>无线连接</strong> <a href="#若使用无线连接" aria-label="Permalink to &quot;若使用**无线连接**&quot;">​</a></h3><p>使用 <code>iwctl</code> 进行连接：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>iwctl</span><span> # 进入交互式命令行</span></span>
<span><span>device</span><span> list</span><span> # 列出无线网卡设备名，比如无线网卡看到叫 wlan0</span></span>
<span><span>station</span><span> wlan0</span><span> scan</span><span> # 扫描网络</span></span>
<span><span>station</span><span> wlan0</span><span> get-networks</span><span> # 列出所有 wifi 网络</span></span>
<span><span>station</span><span> wlan0</span><span> connect</span><span> wifi-name</span><span> # 进行连接，注意这里无法输入中文。回车后输入密码即可</span></span>
<span><span>exit</span><span> # 连接成功后退出</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>若无线网卡无法显示，请按照上一节 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html#_1-%E7%A1%AE%E4%BF%9D%E7%BD%91%E7%BB%9C%E7%8E%AF%E5%A2%83">确保网络环境</a> 的说明<strong>确保你的无线网卡硬件开关处于打开状态</strong>。</p><p>你可以使用如下命令查看内核是否加载了你的无线网卡驱动。</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lspci</span><span> -k</span><span> |</span><span> grep</span><span> Network</span></span></code></pre></div><p>以我的硬件为例，输出如下：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>00:14.3</span><span> Network</span><span> controller:</span><span> Intel</span><span> Corporation</span><span> Wi-Fi</span><span> 6</span><span> AX201</span><span> (rev </span><span>20</span><span>)</span></span></code></pre></div><p>如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 <code>WIFI</code></p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rfkill</span><span> list</span><span> #查看无线连接 是否被禁用(blocked: yes)</span></span>
<span><span>ip</span><span> link</span><span> set</span><span> wlan0</span><span> up</span><span> #比如无线网卡看到叫 wlan0</span></span></code></pre></div><p>若看到类似<code>Operation not possible due to RF-kill</code>的报错，继续尝试<code>rfkill unblock wifi</code>来解锁无线网卡。</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rfkill</span><span> unblock</span><span> wifi</span></span></code></pre></div><p>部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。</p></div><h3 id="若使用有线连接" tabindex="-1">若使用<strong>有线连接</strong> <a href="#若使用有线连接" aria-label="Permalink to &quot;若使用**有线连接**&quot;">​</a></h3><p>正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。</p><p>可以等待几秒等网络建立连接后再进行下一步测试网络的操作。</p><p>若笔记本没有网线接口请使用带网线接口的扩展坞。</p><h2 id="_3-测试网络连通性" tabindex="-1">3. 测试网络连通性 <a href="#_3-测试网络连通性" aria-label="Permalink to &quot;3. 测试网络连通性&quot;">​</a></h2><p>通过 <code>ping</code> 命令测试网络连通性：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>ping</span><span> www.bilibili.com</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_ping.BDHpp9ke.png" alt="ping"></p><p>稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 <code>Ctrl</code> + <code>C</code> 手动退出 <code>ping</code> 命令。</p><div><p>ℹ️ 提示</p><p>如果无线网络还是无法连接，请使用 <code>ip link</code> 命令查看无线网卡设备，使用 <code>ip link set &lt;设备名&gt; up</code> 命令激活对应的无线网卡。若看到类似 <code>Operation not possible due to RF-kill</code> 的报错，继续尝试 <code>rfkill unblock wifi</code> 来解锁无线网卡。</p><p>如有需要，可以参考 <a href="https://wiki.archlinux.org/title/Network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Wireless_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E6%A3%80%E6%9F%A5%E8%AE%BE%E5%A4%87%E7%8A%B6%E6%80%81" target="_blank" rel="noreferrer">ArchWiki 相关内容</a>。</p></div><h2 id="_4-更新系统时钟" tabindex="-1">4. 更新系统时钟 <a href="#_4-更新系统时钟" aria-label="Permalink to &quot;4. 更新系统时钟&quot;">​</a></h2><p>使用 <code>timedatectl</code> 确保系统时间是准确的。这一步<strong>不是</strong>可选的，正确的系统时间对于部分程序来说非常重要：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>timedatectl</span><span> set-ntp</span><span> true</span><span> # 将系统时间与网络时间进行同步</span></span>
<span><span>timedatectl</span><span> status</span><span> # 检查服务状态</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_time.Dmuxtefc.png" alt="time"></p><h2 id="_5-更换国内软件仓库镜像源加快下载速度" tabindex="-1">5. 更换国内软件仓库镜像源加快下载速度 <a href="#_5-更换国内软件仓库镜像源加快下载速度" aria-label="Permalink to &quot;5. 更换国内软件仓库镜像源加快下载速度&quot;">​</a></h2><p>使用 <code>vim</code> 编辑器修改 <code>/etc/pacman.d/mirrorlist</code> 文件。将 <code>pacman</code> 软件仓库源更换为国内软件仓库镜像源：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/pacman.d/mirrorlist</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>如果不会使用 <code>vim</code> 编辑器，请参阅 <a href="https://arch.icekylin.online/guide/advanced/system-ctl.html#%E7%BB%88%E7%AB%AF%E7%BC%96%E8%BE%91%E5%99%A8-vim-%E7%9A%84%E4%BD%BF%E7%94%A8">这里</a>。</p><p><code>vim</code> 编辑器在安装和配置系统的过程中还需要使用多次。</p></div><p>放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下：</p><div><p><span>mirrorlist</span></p><pre tabindex="0"><code><span><span>Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站</span></span>
<span><span>Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站</span></span>
<span><span>Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站</span></span>
<span><span>Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mirrorlist-1.DS2ha-4u.png" alt="mirrorlist-1"></p><p>修改完成的 <code>/etc/pacman.d/mirrorlist</code> 文件如图所示。</p><div><p>ℹ️ 提示</p><p>如果发现 <code>/etc/pacman.d/mirrorlist</code> 是如图这个样子的，那么说明你禁用 <code>reflector</code> 服务晚了。<code>reflector</code> 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。</p><p><img src="https://arch.icekylin.online/assets/basic-install_mirrorlist-2.CITp5j1o.png" alt="mirrorlist-2"></p></div><div><p>⚠️ 注意</p><p>前车之鉴 —— 请不在这一步中添加 <code>archlinuxcn</code> 源！如果你在 <code>/etc/pacman.conf</code> 中添加了内容，请将它们删掉。</p></div><h2 id="_6-分区和格式化-使用-btrfs-文件系统" tabindex="-1">6. 分区和格式化（使用 Btrfs 文件系统） <a href="#_6-分区和格式化-使用-btrfs-文件系统" aria-label="Permalink to &quot;6. 分区和格式化（使用 Btrfs 文件系统）&quot;">​</a></h2><h3 id="_6-1-分区" tabindex="-1">6-1. 分区 <a href="#_6-1-分区" aria-label="Permalink to &quot;6-1. 分区&quot;">​</a></h3><div><p>☢️ 警告</p><p>分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！</p><p>同时，请提前做好数据备份，防止数据丢失！</p></div><p>本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。</p><ul><li><code>/</code> 根目录：<code>&gt;= 128GB</code>（和用户主目录在同一个 <code>Btrfs</code> 文件系统上）</li><li><code>/home</code> 用户主目录：<code>&gt;= 128GB</code>（和根目录在同一个 <code>Btrfs</code> 文件系统上）</li><li><code>/boot</code> EFI 分区：<code>256MB</code>（由电脑厂商或 Windows 决定，无需再次创建）</li><li>Swap 分区：<code>&gt;= 电脑实际运行内存的 60%</code>（设置这个大小是为了配置休眠准备）</li></ul><div><p>ℹ️ 提示</p><p>因为采用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。</p></div><ol><li>通过 <code>lsblk</code> 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lsblk</span><span> # 显示当前分区情况</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_partition-1.Bh1Xqg5R.png" alt="partition-1"></p><p>此处要分区和安装 archlinux 的磁盘即为 <code>sda</code>。请根据你的实际情况判断！</p><div><p>ℹ️ 提示</p><p>为了模拟真实的环境，笔者手动创建了三个分区分别代表：</p><ol><li><code>sda1</code> —— EFI 分区</li><li><code>sda2</code> —— win10 下的 C 盘（象征性的分了 <code>1GB</code>）</li><li><code>sda3</code> —— win10 下的 D 盘（象征性的分了 <code>1GB</code>）</li></ol></div><div><p>ℹ️ 提示</p><p>注意此处并不会显出出未分配的磁盘空间！只有在使用 <code>cfdisk</code> 执行分区操作后才会显示出来。</p></div><div><p>ℹ️ 提示</p><p>如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 <code>sdx</code> 而是 <code>nvmexn1</code>。</p></div><ol start="2"><li>接下来使用 <code>cfdisk</code> 命令对磁盘分区（对于 SATA 协议的硬盘，<code>x</code> 为字母 <code>a</code>、<code>b</code> 或 <code>c</code> 等等；对于 NVME 协议的硬盘，<code>x</code> 为数字 <code>0</code>、<code>1</code> 或 <code>2</code> 等等，请根据实际情况判断）：</li></ol><div><p><label data-title="SATA" for="tab-JNt3hoI">SATA</label><label data-title="NVME" for="tab-GnrA27S">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cfdisk</span><span> /dev/sdx</span><span> # 对安装 archlinux 的磁盘分区</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cfdisk</span><span> /dev/nvmexn1</span><span> # 对安装 archlinux 的磁盘分区</span></span></code></pre></div></div></div><p><img src="https://arch.icekylin.online/assets/basic-install_partition-2.DLT4hhE7.png" alt="partition-2"></p><p>进入 <code>cfdisk</code> 分区工具之后，你会看到如图所示的界面。通过方向键 <code>↑</code> 和 <code>↓</code> 可以在要操作磁盘分区或空余空间中移动；通过方向键 <code>←</code> 和 <code>→</code> 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。</p><ol start="3"><li>首先创建 Swap 分区。选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建 <code>swap</code> 分区（类似 Windows 的交换文件）</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-3.BjLUGd3s.png" alt="partition-3"></p><ol start="4"><li>按下回车后会提示输入 <code>分区大小</code>，Swap 分区建议为<strong>电脑内存大小的 60%</strong>，或者和内存大小相等 &gt; 然后按下回车 <code>Enter</code></li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-4.Dqv4NCG5.png" alt="partition-4"></p><div><p>ℹ️ 提示</p><p>单位可以自行输入，如 <code>GB</code>、<code>MB</code> 等等。</p></div><ol start="5"><li>默认新建的类型是 <code>Linux filesystem</code>，我们需要将类型更改为 <code>Linux swap</code>。选中操作 <code>[Type]</code> &gt; 然后按下回车 <code>Enter</code> &gt; 通过方向键 <code>↑</code> 和 <code>↓</code> 选中 <code>Linux swap</code> &gt; 最后按下回车 <code>Enter</code></li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-5.Dyfk--lB.png" alt="partition-5"></p><p><img src="https://arch.icekylin.online/assets/basic-install_partition-6.B8rtj9qg.png" alt="partition-6"></p><p><img src="https://arch.icekylin.online/assets/basic-install_partition-7._YVoQizt.png" alt="partition-7"></p><ol start="6"><li>我们再只需要一个分区即可（因为使用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建分区</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-8.B5Mxus1B.png" alt="partition-8"></p><ol start="7"><li>输入 <code>分区大小</code>（默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 <code>Enter</code></li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-9.CHsqU1Wz.png" alt="partition-9"></p><ol start="8"><li>分区类型默认即可，无需更改。接下来选中操作 <code>[Write]</code> 并回车 <code>Enter</code> &gt; 输入 <code>yes</code> 并回车 <code>Enter</code> 确认分区操作</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-10.B4WDaAwE.png" alt="partition-10"></p><p><img src="https://arch.icekylin.online/assets/basic-install_partition-11.BbqbEG9-.png" alt="partition-11"></p><div><p>⚠️ 注意</p><p>只有写入了操作分区表才会更改。</p></div><ol start="9"><li>选中操作 <code>[Quit]</code> 并回车 <code>Enter</code> 以退出 <code>cfdisk</code> 分区工具</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_partition-12.CDCzeWEA.png" alt="partition-12"></p><div><p>☢️ 警告</p><p>再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！</p><p>常见的错误包括不小心把 Windows 的分区删掉了 😥。</p></div><ol start="10"><li>分区完成后，使用 <code>fdisk</code> 或 <code>lsblk</code> 命令复查分区情况：</li></ol><div><p><label data-title="fdisk" for="tab-JTCp_Om">fdisk</label><label data-title="lsblk" for="tab-NYjisnf">lsblk</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>fdisk</span><span> -l</span><span> # 复查磁盘情况</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lsblk</span><span> # 复查磁盘情况</span></span></code></pre></div></div></div><p><img src="https://arch.icekylin.online/assets/basic-install_partition-13.BZSCCyuz.png" alt="partition-13"></p><p><img src="https://arch.icekylin.online/assets/basic-install_partition-14.BzdDh6PY.png" alt="partition-14"></p><h3 id="_6-2-格式化并创建-btrfs-子卷" tabindex="-1">6-2. 格式化并创建 Btrfs 子卷 <a href="#_6-2-格式化并创建-btrfs-子卷" aria-label="Permalink to &quot;6-2. 格式化并创建 Btrfs 子卷&quot;">​</a></h3><h4 id="_6-2-0-格式化-efi-分区" tabindex="-1">6-2.0. 格式化 EFI 分区 <a href="#_6-2-0-格式化-efi-分区" aria-label="Permalink to &quot;6-2.0. 格式化 EFI 分区&quot;">​</a></h4><div><p><label data-title="SATA" for="tab-fB977cO">SATA</label><label data-title="NVME" for="tab-oSPbfYl">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.fat</span><span> -F32</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.fat</span><span> -F32</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><div><p>⚠️ 注意</p><p>如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。</p></div><h4 id="_6-2-1-格式化-swap-分区" tabindex="-1">6-2-1. 格式化 Swap 分区 <a href="#_6-2-1-格式化-swap-分区" aria-label="Permalink to &quot;6-2-1. 格式化 Swap 分区&quot;">​</a></h4><p>通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 <code>x</code> 和 <code>n</code>（下同）：</p><div><p><label data-title="SATA" for="tab-bMYjshz">SATA</label><label data-title="NVME" for="tab-bJdH8q5">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkswap</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkswap</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkswap.CzM8dA_8.png" alt="mkswap"></p><h4 id="_6-2-2-格式化-btrfs-分区" tabindex="-1">6-2-2. 格式化 Btrfs 分区 <a href="#_6-2-2-格式化-btrfs-分区" aria-label="Permalink to &quot;6-2-2. 格式化 Btrfs 分区&quot;">​</a></h4><ol><li>首先我们需要将整一个分区格式化为 <code>Btrfs</code> 文件系统。使用如下命令进行格式化：</li></ol><div><p><label data-title="SATA" for="tab-yKWcJNq">SATA</label><label data-title="NVME" for="tab-7zPnUOS">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.btrfs</span><span> -L</span><span> myArch</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.btrfs</span><span> -L</span><span> myArch</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-L</code> 选项后指定该分区的 <code>LABLE</code>，这里以 <code>myArch</code> 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义</li></ul></blockquote><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-1.CpWxbwoC.png" alt="mkbtrfs_step-1"></p><ol start="2"><li>为了创建子卷，我们需要先将 <code>Btrfs</code> 分区挂载到 <code>/mnt</code> 下：</li></ol><div><p><label data-title="SATA" for="tab-8eEMaUS">SATA</label><label data-title="NVME" for="tab-b_uxJkQ">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> compress=zstd</span><span> /dev/sdxn</span><span> /mnt</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt</span></span></code></pre></div></div></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-t</code> 选项后指定挂载分区文件系统类型</li><li><code>-o</code> 选项后添加挂载参数： <ul><li><code>compress=zstd</code> —— 开启透明压缩</li></ul></li></ul></blockquote><ol start="3"><li>使用 <code>df</code> 命令复查挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>df</span><span> -h</span><span> # -h 选项会使输出以人类可读的单位显示</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-2.CNm0O5gq.png" alt="mkbtrfs_step-2"></p><h4 id="_6-2-3-创建-btrfs-子卷" tabindex="-1">6-2-3. 创建 Btrfs 子卷 <a href="#_6-2-3-创建-btrfs-子卷" aria-label="Permalink to &quot;6-2-3. 创建 Btrfs 子卷&quot;">​</a></h4><ol><li>通过以下命令创建两个 <code>Btrfs</code> 子卷，之后将分别挂载到 <code>/</code> 根目录和 <code>/home</code> 用户主目录：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>btrfs</span><span> subvolume</span><span> create</span><span> /mnt/@</span><span> # 创建 / 目录子卷</span></span>
<span><span>btrfs</span><span> subvolume</span><span> create</span><span> /mnt/@home</span><span> # 创建 /home 目录子卷</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-3.DnVJ6tP6.png" alt="mkbtrfs_step-3"></p><div><p>⚠️ 注意</p><p>除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 <code>timeshift</code> 只支持这种子卷布局。</p></div><ol start="2"><li>通过以下命令复查子卷情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>btrfs</span><span> subvolume</span><span> list</span><span> -p</span><span> /mnt</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-4.Q0fek3jd.png" alt="mkbtrfs_step-4"></p><ol start="3"><li>子卷创建好后，我们需要将 <code>/mnt</code> 卸载掉，以挂载子卷：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>umount</span><span> /mnt</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mkbtrfs-5.EEnZGPJv.png" alt="mkbtrfs_step-5"></p><h2 id="_7-挂载" tabindex="-1">7. 挂载 <a href="#_7-挂载" aria-label="Permalink to &quot;7. 挂载&quot;">​</a></h2><ol><li>在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷：</li></ol><div><p><label data-title="SATA" for="tab-OEzwwGo">SATA</label><label data-title="NVME" for="tab-Zic-Y0O">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@,compress=zstd</span><span> /dev/sdxn</span><span> /mnt</span><span> # 挂载 / 目录</span></span>
<span><span>mkdir</span><span> /mnt/home</span><span> # 创建 /home 目录</span></span>
<span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@home,compress=zstd</span><span> /dev/sdxn</span><span> /mnt/home</span><span> # 挂载 /home 目录</span></span>
<span><span>mkdir</span><span> -p</span><span> /mnt/boot</span><span> # 创建 /boot 目录</span></span>
<span><span>mount</span><span> /dev/sdxn</span><span> /mnt/boot</span><span> # 挂载 /boot 目录</span></span>
<span><span>swapon</span><span> /dev/sdxn</span><span> # 挂载交换分区</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@,compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt</span><span> # 挂载 / 目录</span></span>
<span><span>mkdir</span><span> /mnt/home</span><span> # 创建 /home 目录</span></span>
<span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@home,compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt/home</span><span> # 挂载 /home 目录</span></span>
<span><span>mkdir</span><span> -p</span><span> /mnt/boot</span><span> # 创建 /boot 目录</span></span>
<span><span>mount</span><span> /dev/nvmexn1pn</span><span> /mnt/boot</span><span> # 挂载 /boot 目录</span></span>
<span><span>swapon</span><span> /dev/nvmexn1pn</span><span> # 挂载交换分区</span></span></code></pre></div></div></div><p><img src="https://arch.icekylin.online/assets/basic-install_mount-1.DSGPGhwn.png" alt="mount_step-1"></p><p><img src="https://arch.icekylin.online/assets/basic-install_mount-2.C_eaivrb.png" alt="mount_step-2"></p><ol start="2"><li>使用 <code>df</code> 命令复查挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>df</span><span> -h</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mount-3.9HC0QeP4.png" alt="mount_step-3"></p><ol start="3"><li>使用 <code>free</code> 命令复查 Swap 分区挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>free</span><span> -h</span><span> # -h 选项会使输出以人类可读的单位显示</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_mount-4.BOyAfSXA.png" alt="mount_step-4"></p><h2 id="_8-安装系统" tabindex="-1">8. 安装系统 <a href="#_8-安装系统" aria-label="Permalink to &quot;8. 安装系统&quot;">​</a></h2><ol><li>通过如下命令使用 <code>pacstrap</code> 脚本安装基础包：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacstrap</span><span> /mnt</span><span> base</span><span> base-devel</span><span> linux</span><span> linux-firmware</span><span> btrfs-progs</span></span>
<span><span># 如果使用btrfs文件系统，额外安装一个btrfs-progs包</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>base-devel</code> —— <code>base-devel</code> 在 <code>AUR</code> 包的安装过程中是必须用到的</li><li><code>linux</code> —— 内核软件包，这里建议先不要替换为其它内核</li></ul></blockquote><p><img src="https://arch.icekylin.online/assets/basic-install_pacstrap-1.Q3dLs9X-.png" alt="pacstrap_step-1"></p><p>如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 <code>archlinux-keyring</code> 解决此问题</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> archlinux-keyring</span></span></code></pre></div><ol start="2"><li>通过如下命令使用 <code>pacstrap</code> 脚本安装其它必要的功能性软件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacstrap</span><span> /mnt</span><span> networkmanager</span><span> vim</span><span> sudo</span><span> zsh</span><span> zsh-completions</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>zsh</code> —— <code>zsh-completions</code> 如果你是 bash 的爱好者，请把这两个包换成<code>bash-completion</code></li><li>如果你是第一次接触*nix 系统的新手，不建议换成 bash</li></ul></blockquote><p><img src="https://arch.icekylin.online/assets/basic-install_pacstrap-2.6jDXL0pu.png" alt="pacstrap_step-2"></p><p>经过一系列安装时提示信息的刷屏，这些包就安装好了。</p><div><p>⚠️ 注意</p><p>在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。</p><p>很多人在后续的步骤中报错就是因为这里漏装了东西。</p><p>如果报错，请<strong>检查拼写</strong>，同时请确保之前的步骤 <a href="#_6-更换国内软件仓库镜像源加快下载速度">更换国内软件仓库镜像源加快下载速度</a> 中<strong>没有</strong>添加 <code>archlinuxcn</code> 源。</p></div><h2 id="_9-生成-fstab-文件" tabindex="-1">9. 生成 fstab 文件 <a href="#_9-生成-fstab-文件" aria-label="Permalink to &quot;9. 生成 fstab 文件&quot;">​</a></h2><ol><li><code>fstab</code> 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 <code>genfstab</code> 自动根据当前挂载情况生成并写入 <code>fstab</code> 文件：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>genfstab</span><span> -U</span><span> /mnt</span><span> &gt;</span><span> /mnt/etc/fstab</span></span></code></pre></div><ol start="2"><li>复查一下 <code>/mnt/etc/fstab</code> 确保没有错误：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cat</span><span> /mnt/etc/fstab</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_fstab.CtqAJn7q.png" alt="fstab"></p><p>若为 NVME 协议的硬盘，输出结果应该与此类似：</p><div><p><span>fstab</span></p><pre tabindex="0"><code><span><span># /dev/nvme0n1p6  /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0</span></span>
<span><span>UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@  0 0</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p1  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro      0 2</span></span>
<span><span>UUID=522C-80C6  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p6  /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0</span></span>
<span><span>UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p5  none  swap  defaults  0 0</span></span>
<span><span>UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none  swap  defaults  0 0</span></span></code></pre></div><h2 id="_10-change-root" tabindex="-1">10. change root <a href="#_10-change-root" aria-label="Permalink to &quot;10. change root&quot;">​</a></h2><p>使用以下命令把系统环境切换到新系统下：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>arch-chroot</span><span> /mnt</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_chroot.d0svrCrQ.png" alt="arch-chroot"></p><p>此时，原来安装盘下的 <code>/mnt</code> 目录就变成了新系统的 <code>/</code> 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。</p><h2 id="_11-设置主机名与时区" tabindex="-1">11. 设置主机名与时区 <a href="#_11-设置主机名与时区" aria-label="Permalink to &quot;11. 设置主机名与时区&quot;">​</a></h2><ol><li>首先在 <code>/etc/hostname</code> 设置主机名：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/hostname</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-1.B918CSnw.png" alt="set-name-and-timezone_step-1"></p><p>加入你想为主机取的主机名，这里比如叫 myarch。</p><div><p>ℹ️ 提示</p><p>主机名不要包含特殊字符以及空格。</p></div><ol start="2"><li>接下来在 <code>/etc/hosts</code> 设置与其匹配的条目：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/hosts</span></span></code></pre></div><p>加入如下内容：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>127.0.0.1</span><span>   localhost</span></span>
<span><span>:</span><span>:1</span><span>         localhost</span></span>
<span><span>127.0.1.1</span><span>   myarch.localdomain</span><span> myarch</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-2.CLbXR1mh.png" alt="set-name-and-timezone_step-2"></p><div><p>ℹ️ 提示</p><p>你可以使用 <code>Tab</code> 对齐。</p></div><div><p>ℹ️ 提示</p><p>某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 <code>No protocol specified qt.qpa.xcb: could not connect to display</code> 的错误。这种情况极为少见。</p><p>但不管如何，即使没有问题，我们都应该设置好主机名。</p></div><ol start="3"><li>随后设置时区，在 <code>/etc/localtime</code> 下用 <code>/usr</code> 中合适的时区创建符号链接：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>ln</span><span> -sf</span><span> /usr/share/zoneinfo/Asia/Shanghai</span><span> /etc/localtime</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-3.BFRWq2B4.png" alt="set-name-and-timezone_step-3"></p><blockquote><h4 id="🍧-碎碎念" tabindex="-1">🍧 碎碎念 <a href="#🍧-碎碎念" aria-label="Permalink to &quot;🍧 碎碎念&quot;">​</a></h4><p>不要找北京啦！这里没有北京，只有上海啦！🚀</p></blockquote><div><p>ℹ️ 提示</p><p>同时，你也可以使用其它时区：</p><p><img src="https://arch.icekylin.online/assets/basic-install_set-name-and-timezone-4.BCj7m2n9.png" alt="set-name-and-timezone_step-4"></p></div><h2 id="_12-硬件时间设置" tabindex="-1">12. 硬件时间设置 <a href="#_12-硬件时间设置" aria-label="Permalink to &quot;12. 硬件时间设置&quot;">​</a></h2><p>使用如下命令将系统时间同步到硬件时间：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>hwclock</span><span> --systohc</span></span></code></pre></div><h2 id="_13-设置-locale" tabindex="-1">13. 设置 Locale <a href="#_13-设置-locale" aria-label="Permalink to &quot;13. 设置 Locale&quot;">​</a></h2><p><code>Locale</code> 决定了软件使用的语言、书写习惯和字符集。</p><ol><li>编辑 <code>/etc/locale.gen</code>，去掉 <code>en_US.UTF-8 UTF-8</code> 以及 <code>zh_CN.UTF-8 UTF-8</code> 行前的注释符号（<code>#</code>）：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/locale.gen</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_locale-1.BesWF7lc.png" alt="locale_step-1"></p><p><img src="https://arch.icekylin.online/assets/basic-install_locale-2.DWnbYuMb.png" alt="locale_step-2"></p><div><p>ℹ️ 提示</p><p>有几个选项极具迷惑性，请不要取消注释错了。</p></div><ol start="2"><li>然后使用如下命令生成 <code>locale</code>：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>locale-gen</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_locale-3.lyU3oGqg.png" alt="locale_step-3"></p><ol start="3"><li>向 <code>/etc/locale.conf</code> 输入内容：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>echo</span><span> ''LANG=en_US.UTF-8''</span><span>  &gt;</span><span> /etc/locale.conf</span></span></code></pre></div><div><p>⚠️ 注意</p><p>不推荐在此设置任何中文 <code>locale</code>，会导致 <code>tty</code> 乱码。</p></div><h2 id="_14-为-root-用户设置密码" tabindex="-1">14. 为 root 用户设置密码 <a href="#_14-为-root-用户设置密码" aria-label="Permalink to &quot;14. 为 root 用户设置密码&quot;">​</a></h2><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>passwd</span><span> root</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_passwd.C4vgFnXJ.png" alt="password"></p><div><p>ℹ️ 提示</p><p>根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。</p></div><h2 id="_15-安装微码" tabindex="-1">15. 安装微码 <a href="#_15-安装微码" aria-label="Permalink to &quot;15. 安装微码&quot;">​</a></h2><p>通过以下命令安装对应芯片制造商的微码：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> intel-ucode</span><span> # Intel</span></span>
<span><span>pacman</span><span> -S</span><span> amd-ucode</span><span> # AMD</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>🎉 恭喜你！这是你在新系统中第一次使用 <code>pacman</code> 软件包管理器安装软件！在这里一路回车完成安装即可。</p><p>如果你不会使用，请参阅 <a href="https://arch.icekylin.online/guide/rookie/.html">这里</a>。</p></div><h2 id="_16-安装引导程序" tabindex="-1">16. 安装引导程序 <a href="#_16-安装引导程序" aria-label="Permalink to &quot;16. 安装引导程序&quot;">​</a></h2><p>如有需要可以参阅 <a href="https://wiki.archlinux.org/title/GRUB_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)" target="_blank" rel="noreferrer">ArchWiki 相关内容</a>。</p><ol><li>安装相应的包：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> grub</span><span> efibootmgr</span><span> os-prober</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-S</code> 选项后指定要通过 <code>pacman</code> 包管理器安装的包： <ul><li><code>grub</code> —— 启动引导器</li><li><code>efibootmgr</code> —— <code>efibootmgr</code> 被 <code>grub</code> 脚本用来将启动项写入 NVRAM</li><li><code>os-prober</code> —— 为了能够引导 win10，需要安装 <code>os-prober</code> 以检测到它</li></ul></li></ul></blockquote><ol start="2"><li>安装 GRUB 到 EFI 分区：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-install</span><span> --target=x86_64-efi</span><span> --efi-directory=/boot</span><span> --bootloader-id=ARCH</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>--efi-directory=/boot</code> —— 将 <code>grubx64.efi</code> 安装到之前的指定位置（EFI 分区）</li><li><code>--bootloader-id=ARCH</code> —— 取名为 <code>ARCH</code></li></ul></blockquote><p><img src="https://arch.icekylin.online/assets/basic-install_grub-1.BRcfVSlw.png" alt="grub_step-1"></p><ol start="3"><li>接下来使用 <code>vim</code> 编辑 <code>/etc/default/grub</code> 文件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/default/grub</span></span></code></pre></div><p>进行如下修改：</p><ul><li>去掉 <code>GRUB_CMDLINE_LINUX_DEFAULT</code> 一行中最后的 <code>quiet</code> 参数</li><li>把 <code>loglevel</code> 的数值从 <code>3</code> 改成 <code>5</code>。这样是为了后续如果出现系统错误，方便排错</li><li>加入 <code>nowatchdog</code> 参数，这可以显著提高开关机速度</li></ul><p><img src="https://arch.icekylin.online/assets/basic-install_grub-2.HfHVvAuo.png" alt="grub_step-2"></p><ul><li>为了引导 win10，则还需要添加新的一行 <code>GRUB_DISABLE_OS_PROBER=false</code></li></ul><div><p><span>grub</span></p><pre tabindex="0"><code><span><span># GRUB boot loader configuration</span></span>
<span><span></span></span>
<span><span>GRUB_DEFAULT=0</span></span>
<span><span>GRUB_TIMEOUT=5</span></span>
<span><span>GRUB_DISTRIBUTOR="Arch"</span></span>
<span><span>GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"</span></span>
<span><span>GRUB_CMDLINE_LINUX=""</span></span>
<span><span>GRUB_DISABLE_OS_PROBER=false</span></span>
<span><span>...</span></span></code></pre></div><div><p>ℹ️ 提示</p><p><code>nowatchdog</code> 参数无法禁用英特尔的看门狗硬件，改为 <code>modprobe.blacklist=iTCO_wdt</code> 即可。如有需要可以参考 <a href="https://wiki.archlinuxcn.org/wiki/%E6%80%A7%E8%83%BD%E4%BC%98%E5%8C%96#%E7%9C%8B%E9%97%A8%E7%8B%97" target="_blank" rel="noreferrer">ArchWiki 对应内容</a></p></div><ol start="4"><li>最后生成 <code>GRUB</code> 所需的配置文件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-mkconfig</span><span> -o</span><span> /boot/grub/grub.cfg</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_grub-3.1YkNI2Qy.png" alt="grub_step-3"></p><p>若引导了 win10，则输出应该包含倒数第二行：</p><p><img src="https://arch.icekylin.online/assets/os-prober-1.CUiTrPp8.png" alt="os-prober-1"></p><p>若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令</p><div><p>ℹ️ 提示</p><p>1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 <code>efi</code> 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 <code>GRUB</code>。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了），<code>chroot</code> 到 <code>/mnt</code>，然后你可以重新用 <code>--removable</code> 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 <a href="https://wiki.archlinuxcn.org/wiki/GRUB#%E7%BC%BA%E7%9C%81/%E5%90%8E%E5%A4%87%E5%90%AF%E5%8A%A8%E8%B7%AF%E5%BE%84" target="_blank" rel="noreferrer">ArchWiki 对应内容</a>。</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-install</span><span> --target=x86_64-efi</span><span> --efi-directory=/boot</span><span> --bootloader-id=ARCH</span><span> --removable</span></span></code></pre></div><p>2.<code>os-prober</code> 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。</p></div><h2 id="_17-完成安装" tabindex="-1">17. 完成安装 <a href="#_17-完成安装" aria-label="Permalink to &quot;17. 完成安装&quot;">​</a></h2><ol><li>输入以下命令：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>exit</span><span> # 退回安装环境</span></span>
<span><span>umount</span><span> -R</span><span> /mnt</span><span> # 卸载新分区</span></span>
<span><span>reboot</span><span> # 重启</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_finish.BFJMMeTg.png" alt="finish-install"></p><p>注意，<strong>重启前要先拔掉优盘</strong>，否则你重启后还是进安装程序而不是安装好的系统。</p><div><p>ℹ️ 提示</p><p>虚拟机直接重启即可。</p></div><p><img src="https://arch.icekylin.online/assets/basic-install_last-step-1.BbAeF2iD.png" alt="last-step-1"></p><p>如图即为 GRUB 引导界面。</p><div><p>ℹ️ 提示</p><p>若引导了 win10 也会显示出来。</p></div><div><p>ℹ️ 提示</p><p>若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。</p><p>你应该在步骤 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html#_5-%E8%8E%B7%E5%8F%96-bitlocker-%E6%81%A2%E5%A4%8D%E5%AF%86%E9%92%A5">5. 获取 Bitlocker 恢复密钥</a> 中已经知晓了 Bitlocker 解锁密钥。</p><p>若无法从 <a href="https://aka.ms/myrecoverykey" target="_blank" rel="noreferrer">aka.ms 相关页面</a> 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。</p></div><ol start="2"><li>重启后使用 root 账户登录系统：</li></ol><p><img src="https://arch.icekylin.online/assets/basic-install_last-step-2.OQfzBdal.png" alt="last-step-2"></p><ol start="3"><li>设置开机自启并立即启动 networkmanager 服务，即可连接网络：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>systemctl</span><span> enable</span><span> --now</span><span> NetworkManager</span><span> # 设置开机自启并立即启动 NetworkManager 服务</span></span>
<span><span>ping</span><span> www.bilibili.com</span><span> # 测试网络连接</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_last-step-3.CRy-Yj5U.png" alt="last-step-3"></p><ol start="4"><li>若为无线连接，则需要在启动 <code>networkmanager</code> 后使用 <code>nmcli</code> 连接网络：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>nmcli</span><span> dev</span><span> wifi</span><span> list</span><span> # 显示附近的 Wi-Fi 网络</span></span>
<span><span>nmcli</span><span> dev</span><span> wifi</span><span> connect</span><span> "Wi-Fi名（SSID）"</span><span> password</span><span> "网络密码"</span><span> # 连接指定的无线网络</span></span></code></pre></div><p>也可以使用 <code>nmtui</code> 来配置网络</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>nmtui</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 <code>fastfetch</code> 代替 <code>neofetch</code>。</p></div><ol start="5"><li><code>fastfetch</code> 可以将系统信息和发行版 logo 一并打印出来。通过 <code>pacman</code> 安装 <code>fastfetch</code>：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> fastfetch</span></span></code></pre></div><p>使用 <code>fastfetch</code> 打印系统信息：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>fastfetch</span></span></code></pre></div><p><img src="https://arch.icekylin.online/assets/basic-install_fastfetch.Dc0n1esH.png" alt="fastfetch"></p><blockquote><h4 id="🍧-碎碎念-1" tabindex="-1">🍧 碎碎念 <a href="#🍧-碎碎念-1" aria-label="Permalink to &quot;🍧 碎碎念&quot;">​</a></h4><p>又到了 <code>fastfetch</code> 的时间了吗？</p></blockquote><h2 id="🎉-祝贺-🎉" tabindex="-1">🎉 祝贺！🎉 <a href="#🎉-祝贺-🎉" aria-label="Permalink to &quot;🎉 祝贺！🎉&quot;">​</a></h2><p>到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！</p><p>如果你对本节的部分步骤不理解，请仔细阅读下一节 <a href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a>。在此之后，我们来安装图形界面。</p><div><p>ℹ️ 提示</p><p>你可以使用以下命令关机：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>shutdown</span><span> -h</span><span> now</span></span>
<span><span># 或者</span></span>
<span><span>poweroff</span></span></code></pre></div></div><div><p>ℹ️ 提示</p><p>archlinux 在 2021 年 4 月在安装镜像中内置了一个 <a href="https://archlinux.org/packages/extra/any/archinstall/" target="_blank" rel="noreferrer">安装脚本</a>，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于：</p><ol><li>只提供有限的文件系统格式</li><li>只可限定在一个磁盘</li><li>不能指定软件仓库镜像源</li><li>只提供有限的桌面选择</li><li>自动分区不可手动干预</li><li>输入错误直接崩溃退出</li><li>仅支持 UEFI 等</li></ol><p>不建议使用这个安装脚本，除了以上各种原因，初学者也无法在这种安装过程中学到任何东西。如果你因为某些原因需要快速启动一个基础的 archlinux 环境，那么可以尝试此脚本。</p></div></div></div>', 'c59ba8f6-bf7e-4c30-81e4-327ea96f7fa4'::uuid, '{}'::uuid[], '2026-11-06 10:54:27.749892+08'::timestamptz),
  ('d17823a0-b8db-4536-a5db-56e87a8c1b8f'::uuid, '5595efba-f221-4806-9a91-ad05cd4a5b08'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'archlinux 简明指南', '<div id="readability-page-1" class="page"><div data-v-fc4727e6=""><blockquote><h3 id="⛵-万事俱备-只欠东风" tabindex="-1">⛵ 万事俱备，只欠东风 <a href="#⛵-万事俱备-只欠东风" aria-label="Permalink to &quot;⛵ 万事俱备，只欠东风&quot;">​</a></h3><p>经过了上一节的准备工作，我们可以开始正式安装 archlinux 了。如果你还没有完成前面的阅读，请先仔细阅读章节 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html">安装前的准备</a>。如果对本节的步骤不理解或者有疑问，请阅读下一节 <a href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a></p></blockquote><p>本节从安装最基础的、无图形化界面的 archlinux 系统开始。如有需要可以参阅 <a href="https://wiki.archlinux.org/title/Installation_guide_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)" target="_blank" rel="noreferrer">ArchWiki 官方安装指南</a>。</p><div><p>ℹ️ 提示</p><p>本节中的截图来自虚拟机和已经安装好的 archlinux。不用担心！和你在实体机看到的是一样的。</p></div><div><p>⚠️ 注意</p><p>请按照指南的步骤一步一步进行！不要跳步、也不要在步骤中添加多余的动作！</p><p>另外，如果安装中有报错，请弄清楚报错的原因（这要求你起码能看懂有报错）！常见的原因包括但不限于输错了命令、添加了多余的步骤等。在解决了问题之后再进行下一步！</p></div><h2 id="_0-进入安装环境" tabindex="-1">0. 进入安装环境 <a href="#_0-进入安装环境" aria-label="Permalink to &quot;0. 进入安装环境&quot;">​</a></h2><p><img src="https://note.vorin.icu/uploads/notes/2026/11/1c49c2b27d33ebafbf88f79af23da588.png" alt="archlinux-iso-1"></p><ol><li>在第一个选项回车</li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/816da1abaf196207db08159760483187.png" alt="archlinux-iso-2"></p><ol start="2"><li>进入安装环境后，便可以开始通过命令安装 archlinux 了</li></ol><div><p>ℹ️ 提示</p><ul><li>在2025年后，用于自动更新 <code>mirrorlist</code>（软件包管理器 <code>pacman</code> 的软件源）的 <code>reflector</code> 服务由于会误删某些有用的源信息已被默认禁用，无需再手动禁用。</li></ul></div><div><p>ℹ️ 提示</p><ul><li><p>在命令行中你可以使用如下命令清屏：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>clear</span></span></code></pre></div><p>同时，你可以使用 <code>Tab</code> 键在输入命令的时候对命令、参数或文件路径进行自动补全，提高效率的同时降低输入错误的风险。</p></li><li><p><code>Tab</code> 无法补全时，有些设备的蜂鸣器会发出“哔——”声，可以使用如下命令禁用蜂鸣器内核模块：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rmmod</span><span> pcspkr</span></span></code></pre></div></li><li><p>要永久禁用蜂鸣器内核模块, 请创建并编辑 <code>/etc/modprobe.d/blacklist.conf</code></p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>sudoedit</span><span> /etc/modprobe.d/blacklist.conf</span></span></code></pre></div><p>加入以下内容</p><div><pre tabindex="0"><code><span><span>blacklist pcspkr</span></span></code></pre></div><p>这样下次启动就不会加载 pcspkr 模块了</p></li></ul></div><h2 id="_1-确认是否为-uefi-模式" tabindex="-1">1. 确认是否为 UEFI 模式 <a href="#_1-确认是否为-uefi-模式" aria-label="Permalink to &quot;1. 确认是否为 UEFI 模式&quot;">​</a></h2><p>我们先来确认一下是否为 <code>UEFI</code> 模式：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>ls</span><span> /sys/firmware/efi/efivars</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/7e9ffb9a2afd541ddcca19ecc245718f.png" alt="check-efi"></p><p>若输出了一堆东西（<code>efi</code> 变量），则说明已在 <code>UEFI</code> 模式。否则请确认你的启动方式是否为 <code>UEFI</code>。</p><h2 id="_2-连接网络" tabindex="-1">2. 连接网络 <a href="#_2-连接网络" aria-label="Permalink to &quot;2. 连接网络&quot;">​</a></h2><div><p>ℹ️ 提示</p><p>archlinux 的安装<strong>必须</strong>要求网络环境。</p></div><div><p>ℹ️ 提示</p><p>若为虚拟机且按照上一节 <a href="https://arch.icekylin.online/guide/rookie/pre-virt.html#_3-%E9%85%8D%E7%BD%AE-virtualbox">虚拟机安装前的准备</a> 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。</p></div><h3 id="若使用无线连接" tabindex="-1">若使用<strong>无线连接</strong> <a href="#若使用无线连接" aria-label="Permalink to &quot;若使用**无线连接**&quot;">​</a></h3><p>使用 <code>iwctl</code> 进行连接：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>iwctl</span><span> # 进入交互式命令行</span></span>
<span><span>device</span><span> list</span><span> # 列出无线网卡设备名，比如无线网卡看到叫 wlan0</span></span>
<span><span>station</span><span> wlan0</span><span> scan</span><span> # 扫描网络</span></span>
<span><span>station</span><span> wlan0</span><span> get-networks</span><span> # 列出所有 wifi 网络</span></span>
<span><span>station</span><span> wlan0</span><span> connect</span><span> wifi-name</span><span> # 进行连接，注意这里无法输入中文。回车后输入密码即可</span></span>
<span><span>exit</span><span> # 连接成功后退出</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>若无线网卡无法显示，请按照上一节 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html#_1-%E7%A1%AE%E4%BF%9D%E7%BD%91%E7%BB%9C%E7%8E%AF%E5%A2%83">确保网络环境</a> 的说明<strong>确保你的无线网卡硬件开关处于打开状态</strong>。</p><p>你可以使用如下命令查看内核是否加载了你的无线网卡驱动。</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lspci</span><span> -k</span><span> |</span><span> grep</span><span> Network</span></span></code></pre></div><p>以我的硬件为例，输出如下：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>00:14.3</span><span> Network</span><span> controller:</span><span> Intel</span><span> Corporation</span><span> Wi-Fi</span><span> 6</span><span> AX201</span><span> (rev </span><span>20</span><span>)</span></span></code></pre></div><p>如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 <code>WIFI</code></p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rfkill</span><span> list</span><span> #查看无线连接 是否被禁用(blocked: yes)</span></span>
<span><span>ip</span><span> link</span><span> set</span><span> wlan0</span><span> up</span><span> #比如无线网卡看到叫 wlan0</span></span></code></pre></div><p>若看到类似<code>Operation not possible due to RF-kill</code>的报错，继续尝试<code>rfkill unblock wifi</code>来解锁无线网卡。</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>rfkill</span><span> unblock</span><span> wifi</span></span></code></pre></div><p>部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。</p></div><h3 id="若使用有线连接" tabindex="-1">若使用<strong>有线连接</strong> <a href="#若使用有线连接" aria-label="Permalink to &quot;若使用**有线连接**&quot;">​</a></h3><p>正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。</p><p>可以等待几秒等网络建立连接后再进行下一步测试网络的操作。</p><p>若笔记本没有网线接口请使用带网线接口的扩展坞。</p><h2 id="_3-测试网络连通性" tabindex="-1">3. 测试网络连通性 <a href="#_3-测试网络连通性" aria-label="Permalink to &quot;3. 测试网络连通性&quot;">​</a></h2><p>通过 <code>ping</code> 命令测试网络连通性：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>ping</span><span> www.bilibili.com</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/4d711234e173867eb91cbccada70d0dd.png" alt="ping"></p><p>稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 <code>Ctrl</code> + <code>C</code> 手动退出 <code>ping</code> 命令。</p><div><p>ℹ️ 提示</p><p>如果无线网络还是无法连接，请使用 <code>ip link</code> 命令查看无线网卡设备，使用 <code>ip link set &lt;设备名&gt; up</code> 命令激活对应的无线网卡。若看到类似 <code>Operation not possible due to RF-kill</code> 的报错，继续尝试 <code>rfkill unblock wifi</code> 来解锁无线网卡。</p><p>如有需要，可以参考 <a href="https://wiki.archlinux.org/title/Network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Wireless_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E6%A3%80%E6%9F%A5%E8%AE%BE%E5%A4%87%E7%8A%B6%E6%80%81" target="_blank" rel="noreferrer">ArchWiki 相关内容</a>。</p></div><h2 id="_4-更新系统时钟" tabindex="-1">4. 更新系统时钟 <a href="#_4-更新系统时钟" aria-label="Permalink to &quot;4. 更新系统时钟&quot;">​</a></h2><p>使用 <code>timedatectl</code> 确保系统时间是准确的。这一步<strong>不是</strong>可选的，正确的系统时间对于部分程序来说非常重要：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>timedatectl</span><span> set-ntp</span><span> true</span><span> # 将系统时间与网络时间进行同步</span></span>
<span><span>timedatectl</span><span> status</span><span> # 检查服务状态</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/161741754b0badb9456bdc1fb2cca328.png" alt="time"></p><h2 id="_5-更换国内软件仓库镜像源加快下载速度" tabindex="-1">5. 更换国内软件仓库镜像源加快下载速度 <a href="#_5-更换国内软件仓库镜像源加快下载速度" aria-label="Permalink to &quot;5. 更换国内软件仓库镜像源加快下载速度&quot;">​</a></h2><p>使用 <code>vim</code> 编辑器修改 <code>/etc/pacman.d/mirrorlist</code> 文件。将 <code>pacman</code> 软件仓库源更换为国内软件仓库镜像源：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/pacman.d/mirrorlist</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>如果不会使用 <code>vim</code> 编辑器，请参阅 <a href="https://arch.icekylin.online/guide/advanced/system-ctl.html#%E7%BB%88%E7%AB%AF%E7%BC%96%E8%BE%91%E5%99%A8-vim-%E7%9A%84%E4%BD%BF%E7%94%A8">这里</a>。</p><p><code>vim</code> 编辑器在安装和配置系统的过程中还需要使用多次。</p></div><p>放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下：</p><div><p><span>mirrorlist</span></p><pre tabindex="0"><code><span><span>Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站</span></span>
<span><span>Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站</span></span>
<span><span>Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站</span></span>
<span><span>Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/71c7b33c15cd6630f9ce08e818504730.png" alt="mirrorlist-1"></p><p>修改完成的 <code>/etc/pacman.d/mirrorlist</code> 文件如图所示。</p><div><p>ℹ️ 提示</p><p>如果发现 <code>/etc/pacman.d/mirrorlist</code> 是如图这个样子的，那么说明你禁用 <code>reflector</code> 服务晚了。<code>reflector</code> 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。</p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/14a6dcf29c9548f821f0b2ca30b343c6.png" alt="mirrorlist-2"></p></div><div><p>⚠️ 注意</p><p>前车之鉴 —— 请不在这一步中添加 <code>archlinuxcn</code> 源！如果你在 <code>/etc/pacman.conf</code> 中添加了内容，请将它们删掉。</p></div><h2 id="_6-分区和格式化-使用-btrfs-文件系统" tabindex="-1">6. 分区和格式化（使用 Btrfs 文件系统） <a href="#_6-分区和格式化-使用-btrfs-文件系统" aria-label="Permalink to &quot;6. 分区和格式化（使用 Btrfs 文件系统）&quot;">​</a></h2><h3 id="_6-1-分区" tabindex="-1">6-1. 分区 <a href="#_6-1-分区" aria-label="Permalink to &quot;6-1. 分区&quot;">​</a></h3><div><p>☢️ 警告</p><p>分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！</p><p>同时，请提前做好数据备份，防止数据丢失！</p></div><p>本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。</p><ul><li><code>/</code> 根目录：<code>&gt;= 128GB</code>（和用户主目录在同一个 <code>Btrfs</code> 文件系统上）</li><li><code>/home</code> 用户主目录：<code>&gt;= 128GB</code>（和根目录在同一个 <code>Btrfs</code> 文件系统上）</li><li><code>/boot</code> EFI 分区：<code>256MB</code>（由电脑厂商或 Windows 决定，无需再次创建）</li><li>Swap 分区：<code>&gt;= 电脑实际运行内存的 60%</code>（设置这个大小是为了配置休眠准备）</li></ul><div><p>ℹ️ 提示</p><p>因为采用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。</p></div><ol><li>通过 <code>lsblk</code> 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lsblk</span><span> # 显示当前分区情况</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/016eb074a697dbbf3fc67e447406d906.png" alt="partition-1"></p><p>此处要分区和安装 archlinux 的磁盘即为 <code>sda</code>。请根据你的实际情况判断！</p><div><p>ℹ️ 提示</p><p>为了模拟真实的环境，笔者手动创建了三个分区分别代表：</p><ol><li><code>sda1</code> —— EFI 分区</li><li><code>sda2</code> —— win10 下的 C 盘（象征性的分了 <code>1GB</code>）</li><li><code>sda3</code> —— win10 下的 D 盘（象征性的分了 <code>1GB</code>）</li></ol></div><div><p>ℹ️ 提示</p><p>注意此处并不会显出出未分配的磁盘空间！只有在使用 <code>cfdisk</code> 执行分区操作后才会显示出来。</p></div><div><p>ℹ️ 提示</p><p>如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 <code>sdx</code> 而是 <code>nvmexn1</code>。</p></div><ol start="2"><li>接下来使用 <code>cfdisk</code> 命令对磁盘分区（对于 SATA 协议的硬盘，<code>x</code> 为字母 <code>a</code>、<code>b</code> 或 <code>c</code> 等等；对于 NVME 协议的硬盘，<code>x</code> 为数字 <code>0</code>、<code>1</code> 或 <code>2</code> 等等，请根据实际情况判断）：</li></ol><div><p><label data-title="SATA" for="tab-JNt3hoI">SATA</label><label data-title="NVME" for="tab-GnrA27S">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cfdisk</span><span> /dev/sdx</span><span> # 对安装 archlinux 的磁盘分区</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cfdisk</span><span> /dev/nvmexn1</span><span> # 对安装 archlinux 的磁盘分区</span></span></code></pre></div></div></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/1e13934a1f04511c2e6ddd219ec5b4b2.png" alt="partition-2"></p><p>进入 <code>cfdisk</code> 分区工具之后，你会看到如图所示的界面。通过方向键 <code>↑</code> 和 <code>↓</code> 可以在要操作磁盘分区或空余空间中移动；通过方向键 <code>←</code> 和 <code>→</code> 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。</p><ol start="3"><li>首先创建 Swap 分区。选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建 <code>swap</code> 分区（类似 Windows 的交换文件）</li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/740f059974d6a532798e88cad6709df9.png" alt="partition-3"></p><ol start="4"><li>按下回车后会提示输入 <code>分区大小</code>，Swap 分区建议为<strong>电脑内存大小的 60%</strong>，或者和内存大小相等 &gt; 然后按下回车 <code>Enter</code></li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/07584afc577e71873270fcfcaf257210.png" alt="partition-4"></p><div><p>ℹ️ 提示</p><p>单位可以自行输入，如 <code>GB</code>、<code>MB</code> 等等。</p></div><ol start="5"><li>默认新建的类型是 <code>Linux filesystem</code>，我们需要将类型更改为 <code>Linux swap</code>。选中操作 <code>[Type]</code> &gt; 然后按下回车 <code>Enter</code> &gt; 通过方向键 <code>↑</code> 和 <code>↓</code> 选中 <code>Linux swap</code> &gt; 最后按下回车 <code>Enter</code></li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/ce33cab00aa2eed6521056b197e1d0e3.png" alt="partition-5"></p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/5dfd710025e102444b2f0c275b239df0.png" alt="partition-6"></p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/d604b3eb1b89bb857033a5f85fd94a43.png" alt="partition-7"></p><ol start="6"><li>我们再只需要一个分区即可（因为使用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建分区</li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/143318a7f8a966527ff63182a792f89a.png" alt="partition-8"></p><ol start="7"><li>输入 <code>分区大小</code>（默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 <code>Enter</code></li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/510ac8c843a89dc2c96af1c9a0946c91.png" alt="partition-9"></p><ol start="8"><li>分区类型默认即可，无需更改。接下来选中操作 <code>[Write]</code> 并回车 <code>Enter</code> &gt; 输入 <code>yes</code> 并回车 <code>Enter</code> 确认分区操作</li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/7a67d13f48fd024e0a9b76a61caf0357.png" alt="partition-10"></p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/b17e518b2b7ab8670c6d9cad70450a25.png" alt="partition-11"></p><div><p>⚠️ 注意</p><p>只有写入了操作分区表才会更改。</p></div><ol start="9"><li>选中操作 <code>[Quit]</code> 并回车 <code>Enter</code> 以退出 <code>cfdisk</code> 分区工具</li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/996e7763e7450a7e130dabd78cab57bb.png" alt="partition-12"></p><div><p>☢️ 警告</p><p>再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！</p><p>常见的错误包括不小心把 Windows 的分区删掉了 😥。</p></div><ol start="10"><li>分区完成后，使用 <code>fdisk</code> 或 <code>lsblk</code> 命令复查分区情况：</li></ol><div><p><label data-title="fdisk" for="tab-JTCp_Om">fdisk</label><label data-title="lsblk" for="tab-NYjisnf">lsblk</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>fdisk</span><span> -l</span><span> # 复查磁盘情况</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>lsblk</span><span> # 复查磁盘情况</span></span></code></pre></div></div></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/ff5d7b426d380404d0de4dba029b01ed.png" alt="partition-13"></p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/11e1037a913515a5d5c3dd8b4095f26e.png" alt="partition-14"></p><h3 id="_6-2-格式化并创建-btrfs-子卷" tabindex="-1">6-2. 格式化并创建 Btrfs 子卷 <a href="#_6-2-格式化并创建-btrfs-子卷" aria-label="Permalink to &quot;6-2. 格式化并创建 Btrfs 子卷&quot;">​</a></h3><h4 id="_6-2-0-格式化-efi-分区" tabindex="-1">6-2.0. 格式化 EFI 分区 <a href="#_6-2-0-格式化-efi-分区" aria-label="Permalink to &quot;6-2.0. 格式化 EFI 分区&quot;">​</a></h4><div><p><label data-title="SATA" for="tab-fB977cO">SATA</label><label data-title="NVME" for="tab-oSPbfYl">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.fat</span><span> -F32</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.fat</span><span> -F32</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><div><p>⚠️ 注意</p><p>如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。</p></div><h4 id="_6-2-1-格式化-swap-分区" tabindex="-1">6-2-1. 格式化 Swap 分区 <a href="#_6-2-1-格式化-swap-分区" aria-label="Permalink to &quot;6-2-1. 格式化 Swap 分区&quot;">​</a></h4><p>通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 <code>x</code> 和 <code>n</code>（下同）：</p><div><p><label data-title="SATA" for="tab-bMYjshz">SATA</label><label data-title="NVME" for="tab-bJdH8q5">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkswap</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkswap</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/4fbedb00c5a03febda64833d3fd3f254.png" alt="mkswap"></p><h4 id="_6-2-2-格式化-btrfs-分区" tabindex="-1">6-2-2. 格式化 Btrfs 分区 <a href="#_6-2-2-格式化-btrfs-分区" aria-label="Permalink to &quot;6-2-2. 格式化 Btrfs 分区&quot;">​</a></h4><ol><li>首先我们需要将整一个分区格式化为 <code>Btrfs</code> 文件系统。使用如下命令进行格式化：</li></ol><div><p><label data-title="SATA" for="tab-yKWcJNq">SATA</label><label data-title="NVME" for="tab-7zPnUOS">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.btrfs</span><span> -L</span><span> myArch</span><span> /dev/sdxn</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mkfs.btrfs</span><span> -L</span><span> myArch</span><span> /dev/nvmexn1pn</span></span></code></pre></div></div></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-L</code> 选项后指定该分区的 <code>LABLE</code>，这里以 <code>myArch</code> 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义</li></ul></blockquote><p><img src="https://note.vorin.icu/uploads/notes/2026/11/ca059c15ad2026eea54f378b39e4e03e.png" alt="mkbtrfs_step-1"></p><ol start="2"><li>为了创建子卷，我们需要先将 <code>Btrfs</code> 分区挂载到 <code>/mnt</code> 下：</li></ol><div><p><label data-title="SATA" for="tab-8eEMaUS">SATA</label><label data-title="NVME" for="tab-b_uxJkQ">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> compress=zstd</span><span> /dev/sdxn</span><span> /mnt</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt</span></span></code></pre></div></div></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-t</code> 选项后指定挂载分区文件系统类型</li><li><code>-o</code> 选项后添加挂载参数： <ul><li><code>compress=zstd</code> —— 开启透明压缩</li></ul></li></ul></blockquote><ol start="3"><li>使用 <code>df</code> 命令复查挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>df</span><span> -h</span><span> # -h 选项会使输出以人类可读的单位显示</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/7690b7d52b0f67d6ca3ca6a55b83b221.png" alt="mkbtrfs_step-2"></p><h4 id="_6-2-3-创建-btrfs-子卷" tabindex="-1">6-2-3. 创建 Btrfs 子卷 <a href="#_6-2-3-创建-btrfs-子卷" aria-label="Permalink to &quot;6-2-3. 创建 Btrfs 子卷&quot;">​</a></h4><ol><li>通过以下命令创建两个 <code>Btrfs</code> 子卷，之后将分别挂载到 <code>/</code> 根目录和 <code>/home</code> 用户主目录：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>btrfs</span><span> subvolume</span><span> create</span><span> /mnt/@</span><span> # 创建 / 目录子卷</span></span>
<span><span>btrfs</span><span> subvolume</span><span> create</span><span> /mnt/@home</span><span> # 创建 /home 目录子卷</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/7a3a3da28ec004600ad88a6021edb709.png" alt="mkbtrfs_step-3"></p><div><p>⚠️ 注意</p><p>除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 <code>timeshift</code> 只支持这种子卷布局。</p></div><ol start="2"><li>通过以下命令复查子卷情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>btrfs</span><span> subvolume</span><span> list</span><span> -p</span><span> /mnt</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/7f9e2178de84670b3e77a9ba6e968ef4.png" alt="mkbtrfs_step-4"></p><ol start="3"><li>子卷创建好后，我们需要将 <code>/mnt</code> 卸载掉，以挂载子卷：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>umount</span><span> /mnt</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/edcf936430061b33ca22a72e16ad7d62.png" alt="mkbtrfs_step-5"></p><h2 id="_7-挂载" tabindex="-1">7. 挂载 <a href="#_7-挂载" aria-label="Permalink to &quot;7. 挂载&quot;">​</a></h2><ol><li>在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷：</li></ol><div><p><label data-title="SATA" for="tab-OEzwwGo">SATA</label><label data-title="NVME" for="tab-Zic-Y0O">NVME</label></p><div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@,compress=zstd</span><span> /dev/sdxn</span><span> /mnt</span><span> # 挂载 / 目录</span></span>
<span><span>mkdir</span><span> /mnt/home</span><span> # 创建 /home 目录</span></span>
<span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@home,compress=zstd</span><span> /dev/sdxn</span><span> /mnt/home</span><span> # 挂载 /home 目录</span></span>
<span><span>mkdir</span><span> -p</span><span> /mnt/boot</span><span> # 创建 /boot 目录</span></span>
<span><span>mount</span><span> /dev/sdxn</span><span> /mnt/boot</span><span> # 挂载 /boot 目录</span></span>
<span><span>swapon</span><span> /dev/sdxn</span><span> # 挂载交换分区</span></span></code></pre></div><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@,compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt</span><span> # 挂载 / 目录</span></span>
<span><span>mkdir</span><span> /mnt/home</span><span> # 创建 /home 目录</span></span>
<span><span>mount</span><span> -t</span><span> btrfs</span><span> -o</span><span> subvol=/@home,compress=zstd</span><span> /dev/nvmexn1pn</span><span> /mnt/home</span><span> # 挂载 /home 目录</span></span>
<span><span>mkdir</span><span> -p</span><span> /mnt/boot</span><span> # 创建 /boot 目录</span></span>
<span><span>mount</span><span> /dev/nvmexn1pn</span><span> /mnt/boot</span><span> # 挂载 /boot 目录</span></span>
<span><span>swapon</span><span> /dev/nvmexn1pn</span><span> # 挂载交换分区</span></span></code></pre></div></div></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/b894b8e0c9839b0526138aea5f4e78d6.png" alt="mount_step-1"></p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/506c4e34b10b8ff8ae17f63294e55850.png" alt="mount_step-2"></p><ol start="2"><li>使用 <code>df</code> 命令复查挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>df</span><span> -h</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/d739761ac153fbc43d84973353e203ad.png" alt="mount_step-3"></p><ol start="3"><li>使用 <code>free</code> 命令复查 Swap 分区挂载情况：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>free</span><span> -h</span><span> # -h 选项会使输出以人类可读的单位显示</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/62e1d02735c22000a5d04b98099467cd.png" alt="mount_step-4"></p><h2 id="_8-安装系统" tabindex="-1">8. 安装系统 <a href="#_8-安装系统" aria-label="Permalink to &quot;8. 安装系统&quot;">​</a></h2><ol><li>通过如下命令使用 <code>pacstrap</code> 脚本安装基础包：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacstrap</span><span> /mnt</span><span> base</span><span> base-devel</span><span> linux</span><span> linux-firmware</span><span> btrfs-progs</span></span>
<span><span># 如果使用btrfs文件系统，额外安装一个btrfs-progs包</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>base-devel</code> —— <code>base-devel</code> 在 <code>AUR</code> 包的安装过程中是必须用到的</li><li><code>linux</code> —— 内核软件包，这里建议先不要替换为其它内核</li></ul></blockquote><p><img src="https://note.vorin.icu/uploads/notes/2026/11/ae760f45a34f6fddc4c4ec61036858e8.png" alt="pacstrap_step-1"></p><p>如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 <code>archlinux-keyring</code> 解决此问题</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> archlinux-keyring</span></span></code></pre></div><ol start="2"><li>通过如下命令使用 <code>pacstrap</code> 脚本安装其它必要的功能性软件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacstrap</span><span> /mnt</span><span> networkmanager</span><span> vim</span><span> sudo</span><span> zsh</span><span> zsh-completions</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>zsh</code> —— <code>zsh-completions</code> 如果你是 bash 的爱好者，请把这两个包换成<code>bash-completion</code></li><li>如果你是第一次接触*nix 系统的新手，不建议换成 bash</li></ul></blockquote><p><img src="https://note.vorin.icu/uploads/notes/2026/11/167d4cb5774ba77f01eefefd4e79100e.png" alt="pacstrap_step-2"></p><p>经过一系列安装时提示信息的刷屏，这些包就安装好了。</p><div><p>⚠️ 注意</p><p>在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。</p><p>很多人在后续的步骤中报错就是因为这里漏装了东西。</p><p>如果报错，请<strong>检查拼写</strong>，同时请确保之前的步骤 <a href="#_6-更换国内软件仓库镜像源加快下载速度">更换国内软件仓库镜像源加快下载速度</a> 中<strong>没有</strong>添加 <code>archlinuxcn</code> 源。</p></div><h2 id="_9-生成-fstab-文件" tabindex="-1">9. 生成 fstab 文件 <a href="#_9-生成-fstab-文件" aria-label="Permalink to &quot;9. 生成 fstab 文件&quot;">​</a></h2><ol><li><code>fstab</code> 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 <code>genfstab</code> 自动根据当前挂载情况生成并写入 <code>fstab</code> 文件：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>genfstab</span><span> -U</span><span> /mnt</span><span> &gt;</span><span> /mnt/etc/fstab</span></span></code></pre></div><ol start="2"><li>复查一下 <code>/mnt/etc/fstab</code> 确保没有错误：</li></ol><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>cat</span><span> /mnt/etc/fstab</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/44b99b8a73112951d535f1baaa9d5e42.png" alt="fstab"></p><p>若为 NVME 协议的硬盘，输出结果应该与此类似：</p><div><p><span>fstab</span></p><pre tabindex="0"><code><span><span># /dev/nvme0n1p6  /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0</span></span>
<span><span>UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@  0 0</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p1  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro      0 2</span></span>
<span><span>UUID=522C-80C6  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p6  /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0</span></span>
<span><span>UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0</span></span>
<span><span></span></span>
<span><span># /dev/nvme0n1p5  none  swap  defaults  0 0</span></span>
<span><span>UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none  swap  defaults  0 0</span></span></code></pre></div><h2 id="_10-change-root" tabindex="-1">10. change root <a href="#_10-change-root" aria-label="Permalink to &quot;10. change root&quot;">​</a></h2><p>使用以下命令把系统环境切换到新系统下：</p><div><p><span>zsh</span></p><pre tabindex="0"><code><span><span>arch-chroot</span><span> /mnt</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/55fb96520f3e6f49388bd5c59a121842.png" alt="arch-chroot"></p><p>此时，原来安装盘下的 <code>/mnt</code> 目录就变成了新系统的 <code>/</code> 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。</p><h2 id="_11-设置主机名与时区" tabindex="-1">11. 设置主机名与时区 <a href="#_11-设置主机名与时区" aria-label="Permalink to &quot;11. 设置主机名与时区&quot;">​</a></h2><ol><li>首先在 <code>/etc/hostname</code> 设置主机名：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/hostname</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/e20d8d3ebdda3d1864638b4ed9322239.png" alt="set-name-and-timezone_step-1"></p><p>加入你想为主机取的主机名，这里比如叫 myarch。</p><div><p>ℹ️ 提示</p><p>主机名不要包含特殊字符以及空格。</p></div><ol start="2"><li>接下来在 <code>/etc/hosts</code> 设置与其匹配的条目：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/hosts</span></span></code></pre></div><p>加入如下内容：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>127.0.0.1</span><span>   localhost</span></span>
<span><span>:</span><span>:1</span><span>         localhost</span></span>
<span><span>127.0.1.1</span><span>   myarch.localdomain</span><span> myarch</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/80a6d0135d981c9b639ef6b14f8ec283.png" alt="set-name-and-timezone_step-2"></p><div><p>ℹ️ 提示</p><p>你可以使用 <code>Tab</code> 对齐。</p></div><div><p>ℹ️ 提示</p><p>某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 <code>No protocol specified qt.qpa.xcb: could not connect to display</code> 的错误。这种情况极为少见。</p><p>但不管如何，即使没有问题，我们都应该设置好主机名。</p></div><ol start="3"><li>随后设置时区，在 <code>/etc/localtime</code> 下用 <code>/usr</code> 中合适的时区创建符号链接：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>ln</span><span> -sf</span><span> /usr/share/zoneinfo/Asia/Shanghai</span><span> /etc/localtime</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/134dcad892ba4b2119c3f810b442d979.png" alt="set-name-and-timezone_step-3"></p><blockquote><h4 id="🍧-碎碎念" tabindex="-1">🍧 碎碎念 <a href="#🍧-碎碎念" aria-label="Permalink to &quot;🍧 碎碎念&quot;">​</a></h4><p>不要找北京啦！这里没有北京，只有上海啦！🚀</p></blockquote><div><p>ℹ️ 提示</p><p>同时，你也可以使用其它时区：</p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/629a744e7bce9f793ba977302de58742.png" alt="set-name-and-timezone_step-4"></p></div><h2 id="_12-硬件时间设置" tabindex="-1">12. 硬件时间设置 <a href="#_12-硬件时间设置" aria-label="Permalink to &quot;12. 硬件时间设置&quot;">​</a></h2><p>使用如下命令将系统时间同步到硬件时间：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>hwclock</span><span> --systohc</span></span></code></pre></div><h2 id="_13-设置-locale" tabindex="-1">13. 设置 Locale <a href="#_13-设置-locale" aria-label="Permalink to &quot;13. 设置 Locale&quot;">​</a></h2><p><code>Locale</code> 决定了软件使用的语言、书写习惯和字符集。</p><ol><li>编辑 <code>/etc/locale.gen</code>，去掉 <code>en_US.UTF-8 UTF-8</code> 以及 <code>zh_CN.UTF-8 UTF-8</code> 行前的注释符号（<code>#</code>）：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/locale.gen</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/6aaa345096e18758d8e4b2aeba7e54b7.png" alt="locale_step-1"></p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/8b78db6150971360bb2673f714810840.png" alt="locale_step-2"></p><div><p>ℹ️ 提示</p><p>有几个选项极具迷惑性，请不要取消注释错了。</p></div><ol start="2"><li>然后使用如下命令生成 <code>locale</code>：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>locale-gen</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/c7f9237c69e49eb1e32d8cde93faf967.png" alt="locale_step-3"></p><ol start="3"><li>向 <code>/etc/locale.conf</code> 输入内容：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>echo</span><span> ''LANG=en_US.UTF-8''</span><span>  &gt;</span><span> /etc/locale.conf</span></span></code></pre></div><div><p>⚠️ 注意</p><p>不推荐在此设置任何中文 <code>locale</code>，会导致 <code>tty</code> 乱码。</p></div><h2 id="_14-为-root-用户设置密码" tabindex="-1">14. 为 root 用户设置密码 <a href="#_14-为-root-用户设置密码" aria-label="Permalink to &quot;14. 为 root 用户设置密码&quot;">​</a></h2><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>passwd</span><span> root</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/516b20a72ccd89dfdc436e36826805e8.png" alt="password"></p><div><p>ℹ️ 提示</p><p>根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。</p></div><h2 id="_15-安装微码" tabindex="-1">15. 安装微码 <a href="#_15-安装微码" aria-label="Permalink to &quot;15. 安装微码&quot;">​</a></h2><p>通过以下命令安装对应芯片制造商的微码：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> intel-ucode</span><span> # Intel</span></span>
<span><span>pacman</span><span> -S</span><span> amd-ucode</span><span> # AMD</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>🎉 恭喜你！这是你在新系统中第一次使用 <code>pacman</code> 软件包管理器安装软件！在这里一路回车完成安装即可。</p><p>如果你不会使用，请参阅 <a href="https://arch.icekylin.online/guide/rookie/.html">这里</a>。</p></div><h2 id="_16-安装引导程序" tabindex="-1">16. 安装引导程序 <a href="#_16-安装引导程序" aria-label="Permalink to &quot;16. 安装引导程序&quot;">​</a></h2><p>如有需要可以参阅 <a href="https://wiki.archlinux.org/title/GRUB_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)" target="_blank" rel="noreferrer">ArchWiki 相关内容</a>。</p><ol><li>安装相应的包：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> grub</span><span> efibootmgr</span><span> os-prober</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>-S</code> 选项后指定要通过 <code>pacman</code> 包管理器安装的包： <ul><li><code>grub</code> —— 启动引导器</li><li><code>efibootmgr</code> —— <code>efibootmgr</code> 被 <code>grub</code> 脚本用来将启动项写入 NVRAM</li><li><code>os-prober</code> —— 为了能够引导 win10，需要安装 <code>os-prober</code> 以检测到它</li></ul></li></ul></blockquote><ol start="2"><li>安装 GRUB 到 EFI 分区：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-install</span><span> --target=x86_64-efi</span><span> --efi-directory=/boot</span><span> --bootloader-id=ARCH</span></span></code></pre></div><blockquote><p>📑 命令参数说明：</p><ul><li><code>--efi-directory=/boot</code> —— 将 <code>grubx64.efi</code> 安装到之前的指定位置（EFI 分区）</li><li><code>--bootloader-id=ARCH</code> —— 取名为 <code>ARCH</code></li></ul></blockquote><p><img src="https://note.vorin.icu/uploads/notes/2026/11/157b21463e390e2a9f510d1cc88826a4.png" alt="grub_step-1"></p><ol start="3"><li>接下来使用 <code>vim</code> 编辑 <code>/etc/default/grub</code> 文件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>vim</span><span> /etc/default/grub</span></span></code></pre></div><p>进行如下修改：</p><ul><li>去掉 <code>GRUB_CMDLINE_LINUX_DEFAULT</code> 一行中最后的 <code>quiet</code> 参数</li><li>把 <code>loglevel</code> 的数值从 <code>3</code> 改成 <code>5</code>。这样是为了后续如果出现系统错误，方便排错</li><li>加入 <code>nowatchdog</code> 参数，这可以显著提高开关机速度</li></ul><p><img src="https://note.vorin.icu/uploads/notes/2026/11/11392c08e07e08fe58e2a8f5b1081457.png" alt="grub_step-2"></p><ul><li>为了引导 win10，则还需要添加新的一行 <code>GRUB_DISABLE_OS_PROBER=false</code></li></ul><div><p><span>grub</span></p><pre tabindex="0"><code><span><span># GRUB boot loader configuration</span></span>
<span><span></span></span>
<span><span>GRUB_DEFAULT=0</span></span>
<span><span>GRUB_TIMEOUT=5</span></span>
<span><span>GRUB_DISTRIBUTOR="Arch"</span></span>
<span><span>GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"</span></span>
<span><span>GRUB_CMDLINE_LINUX=""</span></span>
<span><span>GRUB_DISABLE_OS_PROBER=false</span></span>
<span><span>...</span></span></code></pre></div><div><p>ℹ️ 提示</p><p><code>nowatchdog</code> 参数无法禁用英特尔的看门狗硬件，改为 <code>modprobe.blacklist=iTCO_wdt</code> 即可。如有需要可以参考 <a href="https://wiki.archlinuxcn.org/wiki/%E6%80%A7%E8%83%BD%E4%BC%98%E5%8C%96#%E7%9C%8B%E9%97%A8%E7%8B%97" target="_blank" rel="noreferrer">ArchWiki 对应内容</a></p></div><ol start="4"><li>最后生成 <code>GRUB</code> 所需的配置文件：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-mkconfig</span><span> -o</span><span> /boot/grub/grub.cfg</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/b4b7c7a4e0d0f0974884a26028d6e899.png" alt="grub_step-3"></p><p>若引导了 win10，则输出应该包含倒数第二行：</p><p><img src="https://note.vorin.icu/uploads/notes/2026/11/e64d1fc8406dfde2ad9a244c14747070.png" alt="os-prober-1"></p><p>若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令</p><div><p>ℹ️ 提示</p><p>1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 <code>efi</code> 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 <code>GRUB</code>。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了），<code>chroot</code> 到 <code>/mnt</code>，然后你可以重新用 <code>--removable</code> 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 <a href="https://wiki.archlinuxcn.org/wiki/GRUB#%E7%BC%BA%E7%9C%81/%E5%90%8E%E5%A4%87%E5%90%AF%E5%8A%A8%E8%B7%AF%E5%BE%84" target="_blank" rel="noreferrer">ArchWiki 对应内容</a>。</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>grub-install</span><span> --target=x86_64-efi</span><span> --efi-directory=/boot</span><span> --bootloader-id=ARCH</span><span> --removable</span></span></code></pre></div><p>2.<code>os-prober</code> 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。</p></div><h2 id="_17-完成安装" tabindex="-1">17. 完成安装 <a href="#_17-完成安装" aria-label="Permalink to &quot;17. 完成安装&quot;">​</a></h2><ol><li>输入以下命令：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>exit</span><span> # 退回安装环境</span></span>
<span><span>umount</span><span> -R</span><span> /mnt</span><span> # 卸载新分区</span></span>
<span><span>reboot</span><span> # 重启</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/766bd448e0ab11d14d45ed55342f6076.png" alt="finish-install"></p><p>注意，<strong>重启前要先拔掉优盘</strong>，否则你重启后还是进安装程序而不是安装好的系统。</p><div><p>ℹ️ 提示</p><p>虚拟机直接重启即可。</p></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/63eea508bb8df5b93e6bc7b2980061ac.png" alt="last-step-1"></p><p>如图即为 GRUB 引导界面。</p><div><p>ℹ️ 提示</p><p>若引导了 win10 也会显示出来。</p></div><div><p>ℹ️ 提示</p><p>若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。</p><p>你应该在步骤 <a href="https://arch.icekylin.online/guide/rookie/pre-install.html#_5-%E8%8E%B7%E5%8F%96-bitlocker-%E6%81%A2%E5%A4%8D%E5%AF%86%E9%92%A5">5. 获取 Bitlocker 恢复密钥</a> 中已经知晓了 Bitlocker 解锁密钥。</p><p>若无法从 <a href="https://aka.ms/myrecoverykey" target="_blank" rel="noreferrer">aka.ms 相关页面</a> 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。</p></div><ol start="2"><li>重启后使用 root 账户登录系统：</li></ol><p><img src="https://note.vorin.icu/uploads/notes/2026/11/73984846fea4c629a35b35a656f23d3c.png" alt="last-step-2"></p><ol start="3"><li>设置开机自启并立即启动 networkmanager 服务，即可连接网络：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>systemctl</span><span> enable</span><span> --now</span><span> NetworkManager</span><span> # 设置开机自启并立即启动 NetworkManager 服务</span></span>
<span><span>ping</span><span> www.bilibili.com</span><span> # 测试网络连接</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/d5089bdf6f69a37bb4caa1510f98f744.png" alt="last-step-3"></p><ol start="4"><li>若为无线连接，则需要在启动 <code>networkmanager</code> 后使用 <code>nmcli</code> 连接网络：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>nmcli</span><span> dev</span><span> wifi</span><span> list</span><span> # 显示附近的 Wi-Fi 网络</span></span>
<span><span>nmcli</span><span> dev</span><span> wifi</span><span> connect</span><span> "Wi-Fi名（SSID）"</span><span> password</span><span> "网络密码"</span><span> # 连接指定的无线网络</span></span></code></pre></div><p>也可以使用 <code>nmtui</code> 来配置网络</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>nmtui</span></span></code></pre></div><div><p>ℹ️ 提示</p><p>neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 <code>fastfetch</code> 代替 <code>neofetch</code>。</p></div><ol start="5"><li><code>fastfetch</code> 可以将系统信息和发行版 logo 一并打印出来。通过 <code>pacman</code> 安装 <code>fastfetch</code>：</li></ol><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>pacman</span><span> -S</span><span> fastfetch</span></span></code></pre></div><p>使用 <code>fastfetch</code> 打印系统信息：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>fastfetch</span></span></code></pre></div><p><img src="https://note.vorin.icu/uploads/notes/2026/11/b880d1920a5c09db5b03262406da0d7a.png" alt="fastfetch"></p><blockquote><h4 id="🍧-碎碎念-1" tabindex="-1">🍧 碎碎念 <a href="#🍧-碎碎念-1" aria-label="Permalink to &quot;🍧 碎碎念&quot;">​</a></h4><p>又到了 <code>fastfetch</code> 的时间了吗？</p></blockquote><h2 id="🎉-祝贺-🎉" tabindex="-1">🎉 祝贺！🎉 <a href="#🎉-祝贺-🎉" aria-label="Permalink to &quot;🎉 祝贺！🎉&quot;">​</a></h2><p>到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！</p><p>如果你对本节的部分步骤不理解，请仔细阅读下一节 <a href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a>。在此之后，我们来安装图形界面。</p><div><p>ℹ️ 提示</p><p>你可以使用以下命令关机：</p><div><p><span>bash</span></p><pre tabindex="0"><code><span><span>shutdown</span><span> -h</span><span> now</span></span>
<span><span># 或者</span></span>
<span><span>poweroff</span></span></code></pre></div></div><div><p>ℹ️ 提示</p><p>archlinux 在 2021 年 4 月在安装镜像中内置了一个 <a href="https://archlinux.org/packages/extra/any/archinstall/" target="_blank" rel="noreferrer">安装脚本</a>，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于：</p><ol><li>只提供有限的文件系统格式</li><li>只可限定在一个磁盘</li><li>不能指定软件仓库镜像源</li><li>只提供有限的桌面选择</li><li>自动分区不可手动干预</li><li>输入错误直接崩溃退出</li><li>仅支持 UEFI 等</li></ol><p>不建议使用这个安装脚本，除了以上各种原因，初学者也无法在这种安装过程中学到任何东西。如果你因为某些原因需要快速启动一个基础的 archlinux 环境，那么可以尝试此脚本。</p></div></div></div>', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-06 13:06:54.413275+08'::timestamptz),
  ('b99b3932-763f-4890-83b6-a078c42f11f2'::uuid, '5595efba-f221-4806-9a91-ad05cd4a5b08'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'archlinux 简明指南', '<h2>1. 确认是否为 UEFI 模式 <a target="_blank" rel="noopener noreferrer nofollow" href="#_1-确认是否为-uefi-模式">​</a></h2><p>我们先来确认一下是否为 <code>UEFI</code> 模式：</p><pre class="hljs"><code>ls /sys/firmware/efi/efivars</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/7e9ffb9a2afd541ddcca19ecc245718f.png" alt="check-efi"><p>若输出了一堆东西（<code>efi</code> 变量），则说明已在 <code>UEFI</code> 模式。否则请确认你的启动方式是否为 <code>UEFI</code>。</p><h2>2. 连接网络 <a target="_blank" rel="noopener noreferrer nofollow" href="#_2-连接网络">​</a></h2><blockquote><p>ℹ️ 提示</p><p>archlinux 的安装<strong>必须</strong>要求网络环境。</p><p>ℹ️ 提示</p><p>若为虚拟机且按照上一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-virt.html#_3-%E9%85%8D%E7%BD%AE-virtualbox">虚拟机安装前的准备</a> 进行了配置；同时宿主机连接了网络，那么虚拟机应该已经连接网络了。</p></blockquote><h3>若使用<strong>无线连接</strong> <a target="_blank" rel="noopener noreferrer nofollow" href="#若使用无线连接">​</a></h3><p>使用 <code>iwctl</code> 进行连接：</p><pre class="hljs"><code>iwctl # 进入交互式命令行device list # 列出无线网卡设备名，比如无线网卡看到叫 wlan0station wlan0 scan # 扫描网络station wlan0 get-networks # 列出所有 wifi 网络station wlan0 connect wifi-name # 进行连接，注意这里无法输入中文。回车后输入密码即可exit # 连接成功后退出</code></pre><blockquote><p>ℹ️ 提示</p><p>若无线网卡无法显示，请按照上一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-install.html#_1-%E7%A1%AE%E4%BF%9D%E7%BD%91%E7%BB%9C%E7%8E%AF%E5%A2%83">确保网络环境</a> 的说明<strong>确保你的无线网卡硬件开关处于打开状态</strong>。</p><p>你可以使用如下命令查看内核是否加载了你的无线网卡驱动。</p></blockquote><pre class="hljs"><code>lspci -k | grep Network</code></pre><p>以我的硬件为例，输出如下：</p><pre class="hljs"><code>00:14.3 Network controller: Intel Corporation Wi-Fi 6 AX201 (rev 20)</code></pre><p>如果你的 BIOS 没有开启无线网卡的开关可以参考下列的命令来开启 <code>WIFI</code></p><pre class="hljs"><code>rfkill list #查看无线连接 是否被禁用(blocked: yes)ip link set wlan0 up #比如无线网卡看到叫 wlan0</code></pre><p>若看到类似<code>Operation not possible due to RF-kill</code>的报错，继续尝试<code>rfkill unblock wifi</code>来解锁无线网卡。</p><p>zsh</p><pre class="hljs"><code>rfkill unblock wifi</code></pre><p>部分无线网卡不兼容，请考虑使用有线连接安装 archlinux。</p><h3>若使用<strong>有线连接</strong> <a target="_blank" rel="noopener noreferrer nofollow" href="#若使用有线连接">​</a></h3><p>正常来说，只要插上一个已经联网的路由器分出的网线（DHCP），直接就能联网。</p><p>可以等待几秒等网络建立连接后再进行下一步测试网络的操作。</p><p>若笔记本没有网线接口请使用带网线接口的扩展坞。</p><h2>3. 测试网络连通性 <a target="_blank" rel="noopener noreferrer nofollow" href="#_3-测试网络连通性">​</a></h2><p>通过 <code>ping</code> 命令测试网络连通性：</p><p>zsh</p><pre class="hljs"><code>ping www.bilibili.com</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/4d711234e173867eb91cbccada70d0dd.png" alt="ping"><p>稍等片刻，若能看到数据返回，即说明已经联网。与 Windows 不同的是，需要按下 <code>Ctrl</code> + <code>C</code> 手动退出 <code>ping</code> 命令。</p><blockquote><p>ℹ️ 提示</p><p>如果无线网络还是无法连接，请使用 <code>ip link</code> 命令查看无线网卡设备，使用 <code>ip link set &lt;设备名&gt; up</code> 命令激活对应的无线网卡。若看到类似 <code>Operation not possible due to RF-kill</code> 的报错，继续尝试 <code>rfkill unblock wifi</code> 来解锁无线网卡。</p><p>如有需要，可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinux.org/title/Network_configuration_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Wireless_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E6%A3%80%E6%9F%A5%E8%AE%BE%E5%A4%87%E7%8A%B6%E6%80%81">ArchWiki 相关内容</a>。</p></blockquote><h2>4. 更新系统时钟 <a target="_blank" rel="noopener noreferrer nofollow" href="#_4-更新系统时钟">​</a></h2><p>使用 <code>timedatectl</code> 确保系统时间是准确的。这一步<strong>不是</strong>可选的，正确的系统时间对于部分程序来说非常重要：</p><p>zsh</p><pre class="hljs"><code>timedatectl set-ntp true # 将系统时间与网络时间进行同步timedatectl status # 检查服务状态</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/161741754b0badb9456bdc1fb2cca328.png" alt="time"><h2>5. 更换国内软件仓库镜像源加快下载速度 <a target="_blank" rel="noopener noreferrer nofollow" href="#_5-更换国内软件仓库镜像源加快下载速度">​</a></h2><p>使用 <code>vim</code> 编辑器修改 <code>/etc/pacman.d/mirrorlist</code> 文件。将 <code>pacman</code> 软件仓库源更换为国内软件仓库镜像源：</p><p>zsh</p><pre class="hljs"><code>vim /etc/pacman.d/mirrorlist</code></pre><p>ℹ️ 提示</p><p>如果不会使用 <code>vim</code> 编辑器，请参阅 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/advanced/system-ctl.html#%E7%BB%88%E7%AB%AF%E7%BC%96%E8%BE%91%E5%99%A8-vim-%E7%9A%84%E4%BD%BF%E7%94%A8">这里</a>。</p><p><code>vim</code> 编辑器在安装和配置系统的过程中还需要使用多次。</p><p>放在最上面的是会使用的软件仓库镜像源，推荐的镜像源如下：</p><p>mirrorlist</p><pre class="hljs"><code>Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch # 中国科学技术大学开源镜像站Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch # 清华大学开源软件镜像站Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch # 华为开源镜像站Server = http://mirror.lzu.edu.cn/archlinux/$repo/os/$arch # 兰州大学开源镜像站</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/71c7b33c15cd6630f9ce08e818504730.png" alt="mirrorlist-1"><p>修改完成的 <code>/etc/pacman.d/mirrorlist</code> 文件如图所示。</p><blockquote><p>ℹ️ 提示</p><p>如果发现 <code>/etc/pacman.d/mirrorlist</code> 是如图这个样子的，那么说明你禁用 <code>reflector</code> 服务晚了。<code>reflector</code> 已经自动帮你生成了新的软件仓库镜像源列表。不过没有关系，手动将国内软件仓库镜像源放在最前面即可。</p></blockquote><img src="https://note.vorin.icu/uploads/notes/2026/11/14a6dcf29c9548f821f0b2ca30b343c6.png" alt="mirrorlist-2"><blockquote><p>⚠️ 注意</p><p>前车之鉴 —— 请不在这一步中添加 <code>archlinuxcn</code> 源！如果你在 <code>/etc/pacman.conf</code> 中添加了内容，请将它们删掉。</p></blockquote><h2>6. 分区和格式化（使用 Btrfs 文件系统） <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-分区和格式化-使用-btrfs-文件系统">​</a></h2><h3>6-1. 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-1-分区">​</a></h3><p>☢️ 警告</p><p>分区操作的部分命令具有危险性！除非你知道每一个命令在干什么，否则请不要执行！</p><p>同时，请提前做好数据备份，防止数据丢失！</p><p>本指南考虑到多数情况，在这里首先介绍 win10 和 archlinux 在一个磁盘上双系统的分区配置。</p><ul><li><p><code>/</code> 根目录：<code>&gt;= 128GB</code>（和用户主目录在同一个 <code>Btrfs</code> 文件系统上）</p></li><li><p><code>/home</code> 用户主目录：<code>&gt;= 128GB</code>（和根目录在同一个 <code>Btrfs</code> 文件系统上）</p></li><li><p><code>/boot</code> EFI 分区：<code>256MB</code>（由电脑厂商或 Windows 决定，无需再次创建）</p></li><li><p>Swap 分区：<code>&gt;= 电脑实际运行内存的 60%</code>（设置这个大小是为了配置休眠准备）</p></li></ul><blockquote><p>ℹ️ 提示</p><p>因为采用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录实际在一个分区上，只是在不同的子卷上而已。这里根目录和用户主目录的大小仅为参考，一般来说日常使用的 linux 分配 128GB 已经够用了。</p></blockquote><ol><li><p>通过 <code>lsblk</code> 命令，区分要安装 archlinux 的磁盘（通过观察磁盘的大小、已存在的分区情况等判断）并显示当前磁盘的分区情况：</p></li></ol><pre class="hljs"><code>lsblk # 显示当前分区情况</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/016eb074a697dbbf3fc67e447406d906.png" alt="partition-1"><p>此处要分区和安装 archlinux 的磁盘即为 <code>sda</code>。请根据你的实际情况判断！</p><p>ℹ️ 提示</p><p>为了模拟真实的环境，笔者手动创建了三个分区分别代表：</p><ol><li><p><code>sda1</code> —— EFI 分区</p></li><li><p><code>sda2</code> —— win10 下的 C 盘（象征性的分了 <code>1GB</code>）</p></li><li><p><code>sda3</code> —— win10 下的 D 盘（象征性的分了 <code>1GB</code>）</p></li></ol><p>ℹ️ 提示</p><p>注意此处并不会显出出未分配的磁盘空间！只有在使用 <code>cfdisk</code> 执行分区操作后才会显示出来。</p><p>ℹ️ 提示</p><p>如果你的硬盘是 NVME 协议的固态硬盘，那么将不是 <code>sdx</code> 而是 <code>nvmexn1</code>。</p><ol start="2"><li><p>接下来使用 <code>cfdisk</code> 命令对磁盘分区（对于 SATA 协议的硬盘，<code>x</code> 为字母 <code>a</code>、<code>b</code> 或 <code>c</code> 等等；对于 NVME 协议的硬盘，<code>x</code> 为数字 <code>0</code>、<code>1</code> 或 <code>2</code> 等等，请根据实际情况判断）：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>cfdisk /dev/sdx # 对安装 archlinux 的磁盘分区</code></pre><p>zsh</p><pre class="hljs"><code>cfdisk /dev/nvmexn1 # 对安装 archlinux 的磁盘分区</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/1e13934a1f04511c2e6ddd219ec5b4b2.png" alt="partition-2"><p>进入 <code>cfdisk</code> 分区工具之后，你会看到如图所示的界面。通过方向键 <code>↑</code> 和 <code>↓</code> 可以在要操作磁盘分区或空余空间中移动；通过方向键 <code>←</code> 和 <code>→</code> 在对当前高亮的磁盘分区或空余空间要执行的操作中移动。</p><ol start="3"><li><p>首先创建 Swap 分区。选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建 <code>swap</code> 分区（类似 Windows 的交换文件）</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/740f059974d6a532798e88cad6709df9.png" alt="partition-3"><ol start="4"><li><p>按下回车后会提示输入 <code>分区大小</code>，Swap 分区建议为<strong>电脑内存大小的 60%</strong>，或者和内存大小相等 &gt; 然后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/07584afc577e71873270fcfcaf257210.png" alt="partition-4"><p>ℹ️ 提示</p><p>单位可以自行输入，如 <code>GB</code>、<code>MB</code> 等等。</p><ol start="5"><li><p>默认新建的类型是 <code>Linux filesystem</code>，我们需要将类型更改为 <code>Linux swap</code>。选中操作 <code>[Type]</code> &gt; 然后按下回车 <code>Enter</code> &gt; 通过方向键 <code>↑</code> 和 <code>↓</code> 选中 <code>Linux swap</code> &gt; 最后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/ce33cab00aa2eed6521056b197e1d0e3.png" alt="partition-5"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/5dfd710025e102444b2f0c275b239df0.png" alt="partition-6"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/d604b3eb1b89bb857033a5f85fd94a43.png" alt="partition-7"><ol start="6"><li><p>我们再只需要一个分区即可（因为使用 <code>Btrfs</code> 文件系统，所以根目录和用户主目录在一个分区上），所以类似的：选中 <code>Free space</code> &gt; 再选中操作 <code>[New]</code> &gt; 然后按下回车 <code>Enter</code> 以新建分区</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/143318a7f8a966527ff63182a792f89a.png" alt="partition-8"><ol start="7"><li><p>输入 <code>分区大小</code>（默认是剩余的全部空间。请根据实际情况输入）&gt; 然后按下回车 <code>Enter</code></p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/510ac8c843a89dc2c96af1c9a0946c91.png" alt="partition-9"><ol start="8"><li><p>分区类型默认即可，无需更改。接下来选中操作 <code>[Write]</code> 并回车 <code>Enter</code> &gt; 输入 <code>yes</code> 并回车 <code>Enter</code> 确认分区操作</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/7a67d13f48fd024e0a9b76a61caf0357.png" alt="partition-10"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/b17e518b2b7ab8670c6d9cad70450a25.png" alt="partition-11"><p>⚠️ 注意</p><p>只有写入了操作分区表才会更改。</p><ol start="9"><li><p>选中操作 <code>[Quit]</code> 并回车 <code>Enter</code> 以退出 <code>cfdisk</code> 分区工具</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/996e7763e7450a7e130dabd78cab57bb.png" alt="partition-12"><p>☢️ 警告</p><p>再次提醒！请仔细检查命令和操作的正确性，否则将出现不可预料的情况。最危险的是可能造成数据丢失！</p><p>常见的错误包括不小心把 Windows 的分区删掉了 😥。</p><ol start="10"><li><p>分区完成后，使用 <code>fdisk</code> 或 <code>lsblk</code> 命令复查分区情况：</p></li></ol><p>fdisklsblk</p><p>zsh</p><pre class="hljs"><code>fdisk -l # 复查磁盘情况</code></pre><p>zsh</p><pre class="hljs"><code>lsblk # 复查磁盘情况</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/ff5d7b426d380404d0de4dba029b01ed.png" alt="partition-13"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/11e1037a913515a5d5c3dd8b4095f26e.png" alt="partition-14"><h3>6-2. 格式化并创建 Btrfs 子卷 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-格式化并创建-btrfs-子卷">​</a></h3><h4>6-2.0. 格式化 EFI 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-0-格式化-efi-分区">​</a></h4><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkfs.fat -F32 /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkfs.fat -F32 /dev/nvmexn1pn</code></pre><p>⚠️ 注意</p><p>如果目标是双系统（Win10/Win11 + Arch Linux），并且 Win10/Win11 和 Arch Linux 将要共存在一个硬盘上的话，不要重新格式化原有的 EFI 分区，因为它可能包含启动其他操作系统所需的文件。</p><h4>6-2-1. 格式化 Swap 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-1-格式化-swap-分区">​</a></h4><p>通过以下命令格式化对应的 Swap 分区，请按照实际情况替换 <code>x</code> 和 <code>n</code>（下同）：</p><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkswap /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkswap /dev/nvmexn1pn</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/4fbedb00c5a03febda64833d3fd3f254.png" alt="mkswap"><h4>6-2-2. 格式化 Btrfs 分区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-2-格式化-btrfs-分区">​</a></h4><ol><li><p>首先我们需要将整一个分区格式化为 <code>Btrfs</code> 文件系统。使用如下命令进行格式化：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mkfs.btrfs -L myArch /dev/sdxn</code></pre><p>zsh</p><pre class="hljs"><code>mkfs.btrfs -L myArch /dev/nvmexn1pn</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-L</code> 选项后指定该分区的 <code>LABLE</code>，这里以 <code>myArch</code> 为例，也可以自定义，但不能使用特殊字符以及空格，且最好有意义</p></li></ul></blockquote><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/ca059c15ad2026eea54f378b39e4e03e.png" alt="mkbtrfs_step-1"><ol start="2"><li><p>为了创建子卷，我们需要先将 <code>Btrfs</code> 分区挂载到 <code>/mnt</code> 下：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o compress=zstd /dev/sdxn /mnt</code></pre><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o compress=zstd /dev/nvmexn1pn /mnt</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-t</code> 选项后指定挂载分区文件系统类型</p></li><li><p><code>-o</code> 选项后添加挂载参数：</p><ul><li><p><code>compress=zstd</code> —— 开启透明压缩</p></li></ul></li></ul></blockquote><ol start="3"><li><p>使用 <code>df</code> 命令复查挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>df -h # -h 选项会使输出以人类可读的单位显示</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/7690b7d52b0f67d6ca3ca6a55b83b221.png" alt="mkbtrfs_step-2"><h4>6-2-3. 创建 Btrfs 子卷 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-2-3-创建-btrfs-子卷">​</a></h4><ol><li><p>通过以下命令创建两个 <code>Btrfs</code> 子卷，之后将分别挂载到 <code>/</code> 根目录和 <code>/home</code> 用户主目录：</p></li></ol><p>zsh</p><pre class="hljs"><code>btrfs subvolume create /mnt/@ # 创建 / 目录子卷btrfs subvolume create /mnt/@home # 创建 /home 目录子卷</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/7a3a3da28ec004600ad88a6021edb709.png" alt="mkbtrfs_step-3"><p>⚠️ 注意</p><p>除非你清楚你的操作产生的后果，否则请保持子卷名称和结构与本指南一致，因为在后面我们会设置的快照工具 <code>timeshift</code> 只支持这种子卷布局。</p><ol start="2"><li><p>通过以下命令复查子卷情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>btrfs subvolume list -p /mnt</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/7f9e2178de84670b3e77a9ba6e968ef4.png" alt="mkbtrfs_step-4"><ol start="3"><li><p>子卷创建好后，我们需要将 <code>/mnt</code> 卸载掉，以挂载子卷：</p></li></ol><p>zsh</p><pre class="hljs"><code>umount /mnt</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/edcf936430061b33ca22a72e16ad7d62.png" alt="mkbtrfs_step-5"><h2>7. 挂载 <a target="_blank" rel="noopener noreferrer nofollow" href="#_7-挂载">​</a></h2><ol><li><p>在挂载时，挂载是有顺序的，需要从根目录开始挂载。使用如下命令挂载子卷：</p></li></ol><p>SATANVME</p><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o subvol=/@,compress=zstd /dev/sdxn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/sdxn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/sdxn /mnt/boot # 挂载 /boot 目录swapon /dev/sdxn # 挂载交换分区</code></pre><p>zsh</p><pre class="hljs"><code>mount -t btrfs -o subvol=/@,compress=zstd /dev/nvmexn1pn /mnt # 挂载 / 目录mkdir /mnt/home # 创建 /home 目录mount -t btrfs -o subvol=/@home,compress=zstd /dev/nvmexn1pn /mnt/home # 挂载 /home 目录mkdir -p /mnt/boot # 创建 /boot 目录mount /dev/nvmexn1pn /mnt/boot # 挂载 /boot 目录swapon /dev/nvmexn1pn # 挂载交换分区</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/b894b8e0c9839b0526138aea5f4e78d6.png" alt="mount_step-1"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/506c4e34b10b8ff8ae17f63294e55850.png" alt="mount_step-2"><ol start="2"><li><p>使用 <code>df</code> 命令复查挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>df -h</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/d739761ac153fbc43d84973353e203ad.png" alt="mount_step-3"><ol start="3"><li><p>使用 <code>free</code> 命令复查 Swap 分区挂载情况：</p></li></ol><p>zsh</p><pre class="hljs"><code>free -h # -h 选项会使输出以人类可读的单位显示</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/62e1d02735c22000a5d04b98099467cd.png" alt="mount_step-4"><h2>8. 安装系统 <a target="_blank" rel="noopener noreferrer nofollow" href="#_8-安装系统">​</a></h2><ol><li><p>通过如下命令使用 <code>pacstrap</code> 脚本安装基础包：</p></li></ol><pre class="hljs"><code>pacstrap /mnt base base-devel linux linux-firmware btrfs-progs# 如果使用btrfs文件系统，额外安装一个btrfs-progs包</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>base-devel</code> —— <code>base-devel</code> 在 <code>AUR</code> 包的安装过程中是必须用到的</p></li><li><p><code>linux</code> —— 内核软件包，这里建议先不要替换为其它内核</p></li></ul></blockquote><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/ae760f45a34f6fddc4c4ec61036858e8.png" alt="pacstrap_step-1"><p>如果提示 GPG 证书错误，可能是因为使用的不是最新的镜像文件，可以通过更新 <code>archlinux-keyring</code> 解决此问题</p><p>bash</p><pre class="hljs"><code>pacman -S archlinux-keyring</code></pre><ol start="2"><li><p>通过如下命令使用 <code>pacstrap</code> 脚本安装其它必要的功能性软件：</p></li></ol><p>bash</p><pre class="hljs"><code>pacstrap /mnt networkmanager vim sudo zsh zsh-completions</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>zsh</code> —— <code>zsh-completions</code> 如果你是 bash 的爱好者，请把这两个包换成<code>bash-completion</code></p></li><li><p>如果你是第一次接触*nix 系统的新手，不建议换成 bash</p></li></ul></blockquote><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/167d4cb5774ba77f01eefefd4e79100e.png" alt="pacstrap_step-2"><p>经过一系列安装时提示信息的刷屏，这些包就安装好了。</p><p>⚠️ 注意</p><p>在执行命令前，请仔细检查命令的拼写正确；同时注意不要漏装东西。</p><p>很多人在后续的步骤中报错就是因为这里漏装了东西。</p><p>如果报错，请<strong>检查拼写</strong>，同时请确保之前的步骤 <a target="_blank" rel="noopener noreferrer nofollow" href="#_6-更换国内软件仓库镜像源加快下载速度">更换国内软件仓库镜像源加快下载速度</a> 中<strong>没有</strong>添加 <code>archlinuxcn</code> 源。</p><h2>9. 生成 fstab 文件 <a target="_blank" rel="noopener noreferrer nofollow" href="#_9-生成-fstab-文件">​</a></h2><ol><li><p><code>fstab</code> 用来定义磁盘分区。它是 Linux 系统中重要的文件之一。使用 <code>genfstab</code> 自动根据当前挂载情况生成并写入 <code>fstab</code> 文件：</p></li></ol><p>zsh</p><pre class="hljs"><code>genfstab -U /mnt &gt; /mnt/etc/fstab</code></pre><ol start="2"><li><p>复查一下 <code>/mnt/etc/fstab</code> 确保没有错误：</p></li></ol><p>zsh</p><pre class="hljs"><code>cat /mnt/etc/fstab</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/44b99b8a73112951d535f1baaa9d5e42.png" alt="fstab"><p>若为 NVME 协议的硬盘，输出结果应该与此类似：</p><p>fstab</p><pre class="hljs"><code># /dev/nvme0n1p6  /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@ 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /  btrfs  rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=/@,subvol=@  0 0# /dev/nvme0n1p1  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro      0 2UUID=522C-80C6  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2# /dev/nvme0n1p6  /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0UUID=d01a3ca5-0798-462e-9a30-97065e7e36e1 /home btrfs rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=257,subvol=/@home,subvol=@home 0 0# /dev/nvme0n1p5  none  swap  defaults  0 0UUID=8e40dbed-590f-4cb8-80de-5cef8343a9fc none  swap  defaults  0 0</code></pre><h2>10. change root <a target="_blank" rel="noopener noreferrer nofollow" href="#_10-change-root">​</a></h2><p>使用以下命令把系统环境切换到新系统下：</p><p>zsh</p><pre class="hljs"><code>arch-chroot /mnt</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/55fb96520f3e6f49388bd5c59a121842.png" alt="arch-chroot"><p>此时，原来安装盘下的 <code>/mnt</code> 目录就变成了新系统的 <code>/</code> 目录。同时，可以发现命令行的提示符颜色和样式也发生了改变。</p><h2>11. 设置主机名与时区 <a target="_blank" rel="noopener noreferrer nofollow" href="#_11-设置主机名与时区">​</a></h2><ol><li><p>首先在 <code>/etc/hostname</code> 设置主机名：</p></li></ol><p>bash</p><pre class="hljs"><code>vim /etc/hostname</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/e20d8d3ebdda3d1864638b4ed9322239.png" alt="set-name-and-timezone_step-1"><p>加入你想为主机取的主机名，这里比如叫 myarch。</p><p>ℹ️ 提示</p><p>主机名不要包含特殊字符以及空格。</p><ol start="2"><li><p>接下来在 <code>/etc/hosts</code> 设置与其匹配的条目：</p></li></ol><p>bash</p><pre class="hljs"><code>vim /etc/hosts</code></pre><p>加入如下内容：</p><p>bash</p><pre class="hljs"><code>127.0.0.1   localhost::1         localhost127.0.1.1   myarch.localdomain myarch</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/80a6d0135d981c9b639ef6b14f8ec283.png" alt="set-name-and-timezone_step-2"><p>ℹ️ 提示</p><p>你可以使用 <code>Tab</code> 对齐。</p><p>ℹ️ 提示</p><p>某些情况下如不设置主机名，在 KDE 下可能会存在网络情况变更时无法启动 GUI 应用的问题，在终端中出现形如 <code>No protocol specified qt.qpa.xcb: could not connect to display</code> 的错误。这种情况极为少见。</p><p>但不管如何，即使没有问题，我们都应该设置好主机名。</p><ol start="3"><li><p>随后设置时区，在 <code>/etc/localtime</code> 下用 <code>/usr</code> 中合适的时区创建符号链接：</p></li></ol><pre class="hljs"><code>ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/134dcad892ba4b2119c3f810b442d979.png" alt="set-name-and-timezone_step-3"><blockquote><h4>🍧 碎碎念 <a target="_blank" rel="noopener noreferrer nofollow" href="#🍧-碎碎念">​</a></h4><p>不要找北京啦！这里没有北京，只有上海啦！🚀</p></blockquote><p>ℹ️ 提示</p><p>同时，你也可以使用其它时区：</p><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/629a744e7bce9f793ba977302de58742.png" alt="set-name-and-timezone_step-4"><h2>12. 硬件时间设置 <a target="_blank" rel="noopener noreferrer nofollow" href="#_12-硬件时间设置">​</a></h2><p>使用如下命令将系统时间同步到硬件时间：</p><pre class="hljs"><code>hwclock --systohc</code></pre><h2>13. 设置 Locale <a target="_blank" rel="noopener noreferrer nofollow" href="#_13-设置-locale">​</a></h2><p><code>Locale</code> 决定了软件使用的语言、书写习惯和字符集。</p><ol><li><p>编辑 <code>/etc/locale.gen</code>，去掉 <code>en_US.UTF-8 UTF-8</code> 以及 <code>zh_CN.UTF-8 UTF-8</code> 行前的注释符号（<code>#</code>）：</p></li></ol><pre class="hljs"><code>vim /etc/locale.gen</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/6aaa345096e18758d8e4b2aeba7e54b7.png" alt="locale_step-1"><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/8b78db6150971360bb2673f714810840.png" alt="locale_step-2"><p>ℹ️ 提示</p><p>有几个选项极具迷惑性，请不要取消注释错了。</p><ol start="2"><li><p>然后使用如下命令生成 <code>locale</code>：</p></li></ol><pre class="hljs"><code>locale-gen</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/c7f9237c69e49eb1e32d8cde93faf967.png" alt="locale_step-3"><ol start="3"><li><p>向 <code>/etc/locale.conf</code> 输入内容：</p></li></ol><pre class="hljs"><code>echo ''LANG=en_US.UTF-8''  &gt; /etc/locale.conf</code></pre><p>⚠️ 注意</p><p>不推荐在此设置任何中文 <code>locale</code>，会导致 <code>tty</code> 乱码。</p><h2>14. 为 root 用户设置密码 <a target="_blank" rel="noopener noreferrer nofollow" href="#_14-为-root-用户设置密码">​</a></h2><pre class="hljs"><code>passwd root</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/516b20a72ccd89dfdc436e36826805e8.png" alt="password"><p>ℹ️ 提示</p><p>根据提示操作即可。注意输入密码时不会显示哦，不要以为 ⌨ 键盘坏了。</p><h2>15. 安装微码 <a target="_blank" rel="noopener noreferrer nofollow" href="#_15-安装微码">​</a></h2><p>通过以下命令安装对应芯片制造商的微码：</p><pre class="hljs"><code>pacman -S intel-ucode # Intelpacman -S amd-ucode # AMD</code></pre><p>ℹ️ 提示</p><p>🎉 恭喜你！这是你在新系统中第一次使用 <code>pacman</code> 软件包管理器安装软件！在这里一路回车完成安装即可。</p><p>如果你不会使用，请参阅 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/.html">这里</a>。</p><h2>16. 安装引导程序 <a target="_blank" rel="noopener noreferrer nofollow" href="#_16-安装引导程序">​</a></h2><p>如有需要可以参阅 <a target="_blank" rel="noreferrer" href="https://wiki.archlinux.org/title/GRUB_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)">ArchWiki 相关内容</a>。</p><ol><li><p>安装相应的包：</p></li></ol><pre class="hljs"><code>pacman -S grub efibootmgr os-prober</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>-S</code> 选项后指定要通过 <code>pacman</code> 包管理器安装的包：</p><ul><li><p><code>grub</code> —— 启动引导器</p></li><li><p><code>efibootmgr</code> —— <code>efibootmgr</code> 被 <code>grub</code> 脚本用来将启动项写入 NVRAM</p></li><li><p><code>os-prober</code> —— 为了能够引导 win10，需要安装 <code>os-prober</code> 以检测到它</p></li></ul></li></ul></blockquote><ol start="2"><li><p>安装 GRUB 到 EFI 分区：</p></li></ol><pre class="hljs"><code>grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH</code></pre><blockquote><p>📑 命令参数说明：</p><ul><li><p><code>--efi-directory=/boot</code> —— 将 <code>grubx64.efi</code> 安装到之前的指定位置（EFI 分区）</p></li><li><p><code>--bootloader-id=ARCH</code> —— 取名为 <code>ARCH</code></p></li></ul></blockquote><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/157b21463e390e2a9f510d1cc88826a4.png" alt="grub_step-1"><ol start="3"><li><p>接下来使用 <code>vim</code> 编辑 <code>/etc/default/grub</code> 文件：</p></li></ol><pre class="hljs"><code>vim /etc/default/grub</code></pre><p>进行如下修改：</p><ul><li><p>去掉 <code>GRUB_CMDLINE_LINUX_DEFAULT</code> 一行中最后的 <code>quiet</code> 参数</p></li><li><p>把 <code>loglevel</code> 的数值从 <code>3</code> 改成 <code>5</code>。这样是为了后续如果出现系统错误，方便排错</p></li><li><p>加入 <code>nowatchdog</code> 参数，这可以显著提高开关机速度</p></li></ul><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/11392c08e07e08fe58e2a8f5b1081457.png" alt="grub_step-2"><ul><li><p>为了引导 win10，则还需要添加新的一行 <code>GRUB_DISABLE_OS_PROBER=false</code></p></li></ul><p>grub</p><pre class="hljs"><code># GRUB boot loader configurationGRUB_DEFAULT=0GRUB_TIMEOUT=5GRUB_DISTRIBUTOR="Arch"GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"GRUB_CMDLINE_LINUX=""GRUB_DISABLE_OS_PROBER=false...</code></pre><p>ℹ️ 提示</p><p><code>nowatchdog</code> 参数无法禁用英特尔的看门狗硬件，改为 <code>modprobe.blacklist=iTCO_wdt</code> 即可。如有需要可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinuxcn.org/wiki/%E6%80%A7%E8%83%BD%E4%BC%98%E5%8C%96#%E7%9C%8B%E9%97%A8%E7%8B%97">ArchWiki 对应内容</a></p><ol start="4"><li><p>最后生成 <code>GRUB</code> 所需的配置文件：</p></li></ol><pre class="hljs"><code>grub-mkconfig -o /boot/grub/grub.cfg</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/b4b7c7a4e0d0f0974884a26028d6e899.png" alt="grub_step-3"><p>若引导了 win10，则输出应该包含倒数第二行：</p><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/e64d1fc8406dfde2ad9a244c14747070.png" alt="os-prober-1"><p>若 win10 安装在另一个硬盘中则不会输出 可在进入系统后挂载硬盘并重新执行该命令</p><blockquote><p>ℹ️ 提示</p><p>1.在某些主板安装完成后，你会发现没有启动条目。这是因为某些主板的 UEFI 固件在显示 UEFI NVRAM 引导条目之前，需要在特定的位置存放可引导文件，不支持自定义存放 <code>efi</code> 文件（如微星 Z170-A Gaming PRO）。解决方案是在默认启动路径下安装 <code>GRUB</code>。重新插入安装优盘，按原先顺序挂载目录（不需要再次创建文件夹了），<code>chroot</code> 到 <code>/mnt</code>，然后你可以重新用 <code>--removable</code> 安装grub2，如下命令所示。只有安装完成后你的主板不出现启动条目才需要尝试如下命令，正常安装无需执行。如有需要可以参考 <a target="_blank" rel="noreferrer" href="https://wiki.archlinuxcn.org/wiki/GRUB#%E7%BC%BA%E7%9C%81/%E5%90%8E%E5%A4%87%E5%90%AF%E5%8A%A8%E8%B7%AF%E5%BE%84">ArchWiki 对应内容</a>。</p></blockquote><pre class="hljs"><code>grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH --removable</code></pre><p>2.<code>os-prober</code> 在 chroot 环境中可能无法正常运作。如果遇到这种情况，重启并引导进入系统后再次尝试生成配置文件。</p><h2>17. 完成安装 <a target="_blank" rel="noopener noreferrer nofollow" href="#_17-完成安装">​</a></h2><ol><li><p>输入以下命令：</p></li></ol><pre class="hljs"><code>exit # 退回安装环境umount -R /mnt # 卸载新分区reboot # 重启</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/766bd448e0ab11d14d45ed55342f6076.png" alt="finish-install"><p>注意，<strong>重启前要先拔掉优盘</strong>，否则你重启后还是进安装程序而不是安装好的系统。</p><p>ℹ️ 提示</p><p>虚拟机直接重启即可。</p><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/63eea508bb8df5b93e6bc7b2980061ac.png" alt="last-step-1"><p>如图即为 GRUB 引导界面。</p><p>ℹ️ 提示</p><p>若引导了 win10 也会显示出来。</p><p>ℹ️ 提示</p><p>若 win10 分区使用了 🔐 Bitlocker 加密，则第一次从 GRUB 进入需要输入解锁密钥。</p><p>你应该在步骤 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/pre-install.html#_5-%E8%8E%B7%E5%8F%96-bitlocker-%E6%81%A2%E5%A4%8D%E5%AF%86%E9%92%A5">5. 获取 Bitlocker 恢复密钥</a> 中已经知晓了 Bitlocker 解锁密钥。</p><p>若无法从 <a target="_blank" rel="noreferrer" href="https://aka.ms/myrecoverykey">aka.ms 相关页面</a> 获取解锁密钥，请尝试在 BIOS 中将 Windows Boot Manager 移动到启动顺序首位再尝试进入 win10。</p><ol start="2"><li><p>重启后使用 root 账户登录系统：</p></li></ol><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/73984846fea4c629a35b35a656f23d3c.png" alt="last-step-2"><ol start="3"><li><p>设置开机自启并立即启动 networkmanager 服务，即可连接网络：</p></li></ol><pre class="hljs"><code>systemctl enable --now NetworkManager # 设置开机自启并立即启动 NetworkManager 服务ping www.bilibili.com # 测试网络连接</code></pre><p></p><img src="https://note.vorin.icu/uploads/notes/2026/11/d5089bdf6f69a37bb4caa1510f98f744.png" alt="last-step-3"><ol start="4"><li><p>若为无线连接，则需要在启动 <code>networkmanager</code> 后使用 <code>nmcli</code> 连接网络：</p></li></ol><pre class="hljs"><code>nmcli dev wifi list # 显示附近的 Wi-Fi 网络nmcli dev wifi connect "Wi-Fi名（SSID）" password "网络密码" # 连接指定的无线网络</code></pre><p>也可以使用 <code>nmtui</code> 来配置网络</p><pre class="hljs"><code>nmtui</code></pre><p>ℹ️ 提示</p><p>neofetch 原作者 dylanaraps 已于 2024 年 04 月 26 日归档 neofetch 仓库，在下面我们会使用 <code>fastfetch</code> 代替 <code>neofetch</code>。</p><ol start="5"><li><p><code>fastfetch</code> 可以将系统信息和发行版 logo 一并打印出来。通过 <code>pacman</code> 安装 <code>fastfetch</code>：</p></li></ol><pre class="hljs"><code>pacman -S fastfetch</code></pre><p>使用 <code>fastfetch</code> 打印系统信息：</p><pre class="hljs"><code>fastfetch</code></pre><img src="https://note.vorin.icu/uploads/notes/2026/11/b880d1920a5c09db5b03262406da0d7a.png" alt="fastfetch"><blockquote><h4>🍧 碎碎念 <a target="_blank" rel="noopener noreferrer nofollow" href="#🍧-碎碎念-1">​</a></h4><p>又到了 <code>fastfetch</code> 的时间了吗？</p></blockquote><h2>🎉 祝贺！🎉 <a target="_blank" rel="noopener noreferrer nofollow" href="#🎉-祝贺-🎉">​</a></h2><p>到此为止，一个基础的、无图形界面的 archlinux 已经安装完成了！这时你应该可以感到满满的满足感（即使你还没有见到图形化的界面）。好好享受一下成功安装 archlinux 的喜悦吧！</p><p>如果你对本节的部分步骤不理解，请仔细阅读下一节 <a target="_blank" rel="noopener noreferrer nofollow" href="https://arch.icekylin.online/guide/rookie/basic-install-detail.html">基础安装详解</a>。在此之后，我们来安装图形界面。</p><p>ℹ️ 提示</p><p>你可以使用以下命令关机：</p><pre class="hljs"><code>shutdown -h now# 或者poweroff</code></pre><blockquote><p>ℹ️ 提示</p><p>archlinux 在 2021 年 4 月在安装镜像中内置了一个 <a target="_blank" rel="noreferrer" href="https://archlinux.org/packages/extra/any/archinstall/">安装脚本</a>，类似一个一键安装脚本，提供一些选项，即可快速安装（填问卷安系统）。和所有一键安装脚本类似，提供自动化，但不灵活的安装过程。缺陷包括但不限于：</p><ol><li><p>只提供有限的文件系统格式</p></li><li><p>只可限定在一个磁盘</p></li><li><p>不能指定软件仓库镜像源</p></li><li><p>只提供有限的桌面选择</p></li><li><p>自动分区不可手动干预</p></li><li><p>输入错误直接崩溃退出</p></li><li><p>仅支持 UEFI 等</p></li></ol></blockquote><p></p>', '9c148a65-cedb-468d-a365-91531f8bf973'::uuid, '{}'::uuid[], '2026-11-06 13:11:54.677501+08'::timestamptz),
  ('e74c3c1f-4158-43e5-81b8-c178c90b83d2'::uuid, 'dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'CVE-2025-53784 漏洞学习笔记（OpenSSH + musl libc 密码绕过）', NULL, '4da8644b-2afb-428e-b02f-21aa06e8bdeb'::uuid, '{}'::uuid[], '2026-11-06 14:56:04.376727+08'::timestamptz),
  ('12791f8f-deea-4c7e-9bc6-24e54e9b7950'::uuid, 'dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'CVE-2025-53784 漏洞学习笔记（OpenSSH + musl libc 密码绕过）', '<h2>基础信息</h2><ul><li><p>漏洞编号：CVE-2025-53784</p></li><li><p>核心类型：跨组件语义冲突漏洞（不是单一函数崩溃）</p></li><li><p>影响条件（全部满足才可以触发）</p><ol><li><p>OpenSSH 版本 &lt; 10.6p2（未打补丁）</p></li><li><p>系统 libc 为 musl（Alpine Linux 默认；Debian/Ubuntu glibc 不受影响）</p></li><li><p><code>sshd_config</code> 配置 <code>UsePAM no</code></p></li><li><p>目标用户 <code>/etc/shadow</code> 密码字段为 <code>*</code>（账号锁定，禁止密码登录）</p></li><li><p>系统内<strong>至少存在一个拥有合法 sha512 哈希的用户</strong>，给 <code>crypt()</code> 提供 salt</p></li></ol></li><li><p>补丁版本：OpenSSH 10.6p2 及以上</p></li></ul><h2>漏洞原理</h2><ol><li><p><code>crypt()</code> 是 Unix 传统密码哈希函数，POSIX 约定：<strong>计算失败应当返回 NULL</strong>。</p></li><li><p>musl 的实现选择：密码长度 ≥ 257 字节时，内部处理超限，<strong>不返回 NULL，返回静态字符串 </strong><code>*</code>。</p><ul><li><p>musl 设计者本意：<code>*</code> 是密码体系里约定的「本次哈希计算失败标记」，避免返回 NULL 造成上层空指针崩溃。</p></li></ul></li><li><p><code>/etc/shadow</code> 体系约定：<code>*</code> / <code>!</code> 代表账号锁定，<strong>禁止密码登录</strong>。</p></li><li><p>老版本 OpenSSH 在 <code>UsePAM=no</code> 路径下的校验逻辑：</p><ul><li><p>读取 shadow 里存储的哈希串</p></li><li><p>直接调用 <code>crypt(用户输入密码, salt)</code></p></li><li><p>仅判断返回值不为 NULL，然后直接做字符串相等比对</p></li></ul></li><li><p>巧合碰撞： 攻击者输入 257 字节超长密码 → musl crypt 返回 <code>*</code> shadow 里锁定账号的值正好也是 <code>*</code> <code>strcmp</code> 判断相等 → 认证通过，绕过锁定账号限制登录</p></li></ol><blockquote><p>关键结论：不能简单归罪于 musl 的 <code>crypt()</code>。 musl 只是错误分支返回了特殊标记；<strong>真正的安全缺陷是 OpenSSH 缺少前置语义校验，盲目信任库返回值、只做简单字符串对比</strong>。</p></blockquote><h2>关键代码逻辑对比</h2><h3>1. 有漏洞的 OpenSSH 校验逻辑（简化）</h3><pre class="hljs"><code>char *computed = crypt(password, stored_hash);
if (computed &amp;&amp; strcmp(computed, stored_hash) == 0) {
    return 1; // 校验通过
}
</code></pre><p>缺陷：没有提前判断 <code>stored_hash</code> 是否是锁定标记，也没有区分 crypt 返回值是正常结果还是错误标记。</p><h3>2. musl crypt 超长密码分支（简化）</h3><pre class="hljs"><code>if (keylen &gt; 256) {
    strcpy(result, "*");
    return result;
}
</code></pre><h3>3. OpenSSH 官方补丁逻辑（核心）</h3><p>在调用 <code>crypt()</code> <strong>之前</strong>，先判断 shadow 字段语义：</p><pre class="hljs"><code>// 如果是锁定标记，直接拒绝，不再进入密码哈希计算
if (stored_hash[0] == ''*'' || stored_hash[0] == ''!'') {
    return 0;
}
// 后续才调用 crypt 做哈希比对
</code></pre><p>✅ 补丁思路：<strong>校验账号状态语义，而不是去限制密码长度</strong></p><ul><li><p>密码长度限制：属于针对 musl 特有bug 的临时 workaround，不可移植</p></li><li><p>锁定标记前置判断：符合 shadow 原生规范，通用、长期有效，不受 libc 实现差异影响</p></li></ul><h2>为什么本次在 Docker Alpine 里复现失败</h2><p>官方 Alpine 源已经给 openssh 升级到 10.6p2+ 补丁版本； 只要 shadow 字段是 <code>*</code>，sshd 在最开始就直接拦截，打印日志： <code>User testuser not allowed because account is locked</code> 根本不会走到 <code>crypt()</code> 调用分支，漏洞逻辑无法触发。</p><h2>模拟代码（Python，仅演示逻辑，非EXP）</h2><pre class="hljs"><code>def musl_crypt_sim(password: str, salt: str):
    if len(password) &gt;= 257:
        # 超长密码，bug行为：返回 *
        return "*"
    else:
        import hashlib
        return hashlib.sha512((password + salt).encode()).hexdigest()


shadow = {
    "testuser": "*",
    "normaluser": "$6$rounds=5000$abc123456$FAKEHASH"
}

real_hash = shadow["normaluser"]
salt = real_hash.split("$")[2]

print("=== 短密码 aaaa ===")
ret1 = musl_crypt_sim("aaaa", salt)
print(f"crypt返回：{ret1}")
print(f"比对结果：{''放行'' if ret1 == shadow[''testuser''] else ''拒绝''}")

print("\n=== payload：257个A ===")
ret2 = musl_crypt_sim("A"*257, salt)
print(f"crypt返回：{ret2}")
print(f"比对结果：{''放行'' if ret2 == shadow[''testuser''] else ''拒绝''}")
</code></pre><h2>开发学习收获 &amp; 教训</h2><ol><li><p><strong>第三方库 / 系统调用的返回值不可无条件信任</strong>。接口文档的契约、不同libc的实际实现，可能存在差异。</p></li><li><p>异常分支的返回值是高危点：错误场景下，有可能返回一个具备业务语义的合法字符串，而不是明显的失败标识（NULL、报错码）。</p></li><li><p>字符串相等是非常弱的校验手段；优先校验<strong>数据的语义、类型、状态</strong>，而不是只比对内容。</p></li><li><p>跨组件边界是漏洞高发区：每个组件单独看逻辑都合理，但组件之间的隐性行为撞在一起，就会形成安全绕过。</p></li><li><p>修复方案优先选择「语义层拦截」，尽量避免写死平台私有阈值的hack式修复。</p></li></ol><h2>补充备注</h2><ul><li><p>glibc 环境下超长密码传入 <code>crypt()</code> 返回 NULL，不会触发该漏洞；</p></li><li><p>该漏洞属于巧妙的边界巧合，不是密码哈希算法本身被破解。</p></li></ul><p></p>', '5eee4f85-0aaf-4fb0-9447-cc7dc089047b'::uuid, '{0e919136-6a50-458d-ae70-3a2cde87d866,5e055b7c-a86d-431e-befd-12fc20efe7f9,7657dad3-b0bb-4cd3-8b7a-4ea382aef526,7b5f1d69-c6c9-4733-84c8-6c395f23199d,a8bdd31d-6a36-4ba4-941a-cc0bdefb123e}'::uuid[], '2026-11-06 15:01:18.05971+08'::timestamptz),
  ('8c581601-31cc-4530-a470-4d59b0398d7f'::uuid, 'dbf04d76-8cb7-4649-b973-d9ca21d3107f'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'CVE-2026-12315 漏洞学习笔记（OpenSSH + musl libc 密码绕过）', '<h2>基础信息</h2><ul><li><p>漏洞编号：CVE-2025-53784</p></li><li><p>核心类型：跨组件语义冲突漏洞（不是单一函数崩溃）</p></li><li><p>影响条件（全部满足才可以触发）</p><ol><li><p>OpenSSH 版本 &lt; 10.6p2（未打补丁）</p></li><li><p>系统 libc 为 musl（Alpine Linux 默认；Debian/Ubuntu glibc 不受影响）</p></li><li><p><code>sshd_config</code> 配置 <code>UsePAM no</code></p></li><li><p>目标用户 <code>/etc/shadow</code> 密码字段为 <code>*</code>（账号锁定，禁止密码登录）</p></li><li><p>系统内<strong>至少存在一个拥有合法 sha512 哈希的用户</strong>，给 <code>crypt()</code> 提供 salt</p></li></ol></li><li><p>补丁版本：OpenSSH 10.6p2 及以上</p></li></ul><h2>漏洞原理</h2><ol><li><p><code>crypt()</code> 是 Unix 传统密码哈希函数，POSIX 约定：<strong>计算失败应当返回 NULL</strong>。</p></li><li><p>musl 的实现选择：密码长度 ≥ 257 字节时，内部处理超限，<strong>不返回 NULL，返回静态字符串 </strong><code>*</code>。</p><ul><li><p>musl 设计者本意：<code>*</code> 是密码体系里约定的「本次哈希计算失败标记」，避免返回 NULL 造成上层空指针崩溃。</p></li></ul></li><li><p><code>/etc/shadow</code> 体系约定：<code>*</code> / <code>!</code> 代表账号锁定，<strong>禁止密码登录</strong>。</p></li><li><p>老版本 OpenSSH 在 <code>UsePAM=no</code> 路径下的校验逻辑：</p><ul><li><p>读取 shadow 里存储的哈希串</p></li><li><p>直接调用 <code>crypt(用户输入密码, salt)</code></p></li><li><p>仅判断返回值不为 NULL，然后直接做字符串相等比对</p></li></ul></li><li><p>巧合碰撞： 攻击者输入 257 字节超长密码 → musl crypt 返回 <code>*</code> shadow 里锁定账号的值正好也是 <code>*</code> <code>strcmp</code> 判断相等 → 认证通过，绕过锁定账号限制登录</p></li></ol><blockquote><p>关键结论：不能简单归罪于 musl 的 <code>crypt()</code>。 musl 只是错误分支返回了特殊标记；<strong>真正的安全缺陷是 OpenSSH 缺少前置语义校验，盲目信任库返回值、只做简单字符串对比</strong>。</p></blockquote><h2>关键代码逻辑对比</h2><h3>1. 有漏洞的 OpenSSH 校验逻辑（简化）</h3><pre class="hljs"><code>char *computed = crypt(password, stored_hash);
if (computed &amp;&amp; strcmp(computed, stored_hash) == 0) {
    return 1; // 校验通过
}
</code></pre><p>缺陷：没有提前判断 <code>stored_hash</code> 是否是锁定标记，也没有区分 crypt 返回值是正常结果还是错误标记。</p><h3>2. musl crypt 超长密码分支（简化）</h3><pre class="hljs"><code>if (keylen &gt; 256) {
    strcpy(result, "*");
    return result;
}
</code></pre><h3>3. OpenSSH 官方补丁逻辑（核心）</h3><p>在调用 <code>crypt()</code> <strong>之前</strong>，先判断 shadow 字段语义：</p><pre class="hljs"><code>// 如果是锁定标记，直接拒绝，不再进入密码哈希计算
if (stored_hash[0] == ''*'' || stored_hash[0] == ''!'') {
    return 0;
}
// 后续才调用 crypt 做哈希比对
</code></pre><p>✅ 补丁思路：<strong>校验账号状态语义，而不是去限制密码长度</strong></p><ul><li><p>密码长度限制：属于针对 musl 特有bug 的临时 workaround，不可移植</p></li><li><p>锁定标记前置判断：符合 shadow 原生规范，通用、长期有效，不受 libc 实现差异影响</p></li></ul><h2>为什么本次在 Docker Alpine 里复现失败</h2><p>官方 Alpine 源已经给 openssh 升级到 10.6p2+ 补丁版本； 只要 shadow 字段是 <code>*</code>，sshd 在最开始就直接拦截，打印日志： <code>User testuser not allowed because account is locked</code> 根本不会走到 <code>crypt()</code> 调用分支，漏洞逻辑无法触发。</p><h2>模拟代码（Python，仅演示逻辑，非EXP）</h2><pre class="hljs"><code>def musl_crypt_sim(password: str, salt: str):
    if len(password) &gt;= 257:
        # 超长密码，bug行为：返回 *
        return "*"
    else:
        import hashlib
        return hashlib.sha512((password + salt).encode()).hexdigest()


shadow = {
    "testuser": "*",
    "normaluser": "$6$rounds=5000$abc123456$FAKEHASH"
}

real_hash = shadow["normaluser"]
salt = real_hash.split("$")[2]

print("=== 短密码 aaaa ===")
ret1 = musl_crypt_sim("aaaa", salt)
print(f"crypt返回：{ret1}")
print(f"比对结果：{''放行'' if ret1 == shadow[''testuser''] else ''拒绝''}")

print("\n=== payload：257个A ===")
ret2 = musl_crypt_sim("A"*257, salt)
print(f"crypt返回：{ret2}")
print(f"比对结果：{''放行'' if ret2 == shadow[''testuser''] else ''拒绝''}")
</code></pre><h2>开发学习收获 &amp; 教训</h2><ol><li><p><strong>第三方库 / 系统调用的返回值不可无条件信任</strong>。接口文档的契约、不同libc的实际实现，可能存在差异。</p></li><li><p>异常分支的返回值是高危点：错误场景下，有可能返回一个具备业务语义的合法字符串，而不是明显的失败标识（NULL、报错码）。</p></li><li><p>字符串相等是非常弱的校验手段；优先校验<strong>数据的语义、类型、状态</strong>，而不是只比对内容。</p></li><li><p>跨组件边界是漏洞高发区：每个组件单独看逻辑都合理，但组件之间的隐性行为撞在一起，就会形成安全绕过。</p></li><li><p>修复方案优先选择「语义层拦截」，尽量避免写死平台私有阈值的hack式修复。</p></li></ol><h2>补充备注</h2><ul><li><p>glibc 环境下超长密码传入 <code>crypt()</code> 返回 NULL，不会触发该漏洞；</p></li><li><p>该漏洞属于巧妙的边界巧合，不是密码哈希算法本身被破解。</p></li></ul><p></p>', '5eee4f85-0aaf-4fb0-9447-cc7dc089047b'::uuid, '{0e919136-6a50-458d-ae70-3a2cde87d866,5e055b7c-a86d-431e-befd-12fc20efe7f9,6c1df245-5e8a-42e2-86b7-8c82dfa5b737,7657dad3-b0bb-4cd3-8b7a-4ea382aef526,7b5f1d69-c6c9-4733-84c8-6c395f23199d,a8bdd31d-6a36-4ba4-941a-cc0bdefb123e}'::uuid[], '2026-11-06 15:06:46.087425+08'::timestamptz),
  ('4f3dfc3e-acd7-4546-9592-a5c564d28cd4'::uuid, '663f783f-a60a-499d-b197-5d46379d0c36'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'CVE-2026-123158 漏洞学习笔记（sshole / OpenSSH + musl libc 密码绕过）', '<h1></h1><p><span style="color: rgb(29, 78, 216);">CVEOpenSSHmusl libcAlpineLinux漏洞</span></p><p><strong>📌 基础信息概览</strong><br>漏洞代号：sshole｜披露时间：2026-11-05｜补丁版本：OpenSSH ≥ 10.6p2</p><h2>触发条件（全部满足才可利用）</h2><ol><li><p>OpenSSH 版本 &lt; 10.6p2（未合并补丁）</p></li><li><p>系统 libc 为 musl（Alpine、OpenWrt 默认；glibc 不受影响）</p></li><li><p><code>sshd_config</code> 开启 <code>UsePAM no</code>，走传统 crypt 认证路径</p></li><li><p>目标用户在 <code>/etc/shadow</code> 的密码字段为 <code>*</code>，账号锁定、禁止密码登录</p></li><li><p>系统内至少存在一个正常用户，拥有合法 sha512 哈希，为 crypt 提供 salt</p></li></ol><h2>漏洞原理</h2><p>这是一个<strong>跨组件语义冲突漏洞</strong>，不是代码崩溃，也不是哈希算法被破解。</p><ul><li><p>Unix 标准函数 <code>crypt()</code>，规范约定：计算失败时应当返回 <code>NULL</code></p></li><li><p>musl 的实现取舍：密码长度 ≥ 257 字节时超限，不返回 NULL，返回静态字符串 <code>*</code><br>musl 设计者本意：<code>*</code> 是密码生态公认的「哈希计算失败标记」，避免上层无判空代码直接空指针崩溃。</p></li><li><p>shadow 体系约定：<code>*</code> / <code>!</code> 代表<strong>账号锁定，禁止密码登录</strong>，两套语义撞在了同一个字符串上。</p></li><li><p>旧 OpenSSH 校验逻辑：拿到 crypt 返回值，只判断不为 NULL，直接做字符串相等对比。</p></li></ul><blockquote><p>攻击链路：传入257字节超长密码 → musl crypt 返回 <code>*</code> → 和 shadow 里锁定标记 <code>*</code> 字符串相等 → 认证放行，绕过锁定限制。</p></blockquote><h2>三段核心C代码对比</h2><h3>1. 存在漏洞的原始校验逻辑</h3><pre class="hljs"><code>char *computed = crypt(password, stored_hash);
if (computed &amp;&amp; strcmp(computed, stored_hash) == 0) {
    return 1; // 校验通过，放行
}
</code></pre><p>缺陷：没有提前判断账号锁定标记，不区分 crypt 返回值是正常哈希，还是错误标记。</p><h3>2. musl crypt 超长密码分支（简化）</h3><pre class="hljs"><code>if (keylen &gt; 256) {
    strcpy(result, "*");
    return result;
}
</code></pre><h3>3. OpenSSH 官方补丁逻辑（修复方案）</h3><pre class="hljs"><code>// 调用crypt之前，优先判断账号锁定语义
if (stored_hash[0] == ''*'' || stored_hash[0] == ''!'') {
    return 0; // 直接拒绝，不再执行密码哈希计算
}
// 再往下才调用 crypt 做比对
</code></pre><p><strong>💡 重点区分：</strong> 不是限制密码长度（只针对musl的hack方案），而是<strong>遵循shadow语义，锁定账号直接拦截</strong>，通用、可移植，不受libc差异影响。</p><h2>本次复现失败原因</h2><p>Alpine官方源已经升级 OpenSSH 至带补丁的版本，读到 <code>*</code> 锁定标记就直接打印日志：</p><p><code>User testuser not allowed because account is locked</code></p><p>直接跳出，根本不会进入 crypt 函数调用，漏洞无法触发。</p><h2>Python逻辑模拟代码（仅演示原理，非可利用EXP）</h2><pre class="hljs"><code>def musl_crypt_sim(password: str, salt: str):
    if len(password) &gt;= 257:
        # musl超长密码的异常行为：返回 *
        return "*"
    import hashlib
    return hashlib.sha512((password + salt).encode()).hexdigest()

shadow = {
    "testuser": "*",
    "normaluser": "$6$rounds=5000$abc123$FAKEHASH"
}
real_hash = shadow["normaluser"]
salt = real_hash.split("$")[2]

print("=== 短密码 aaaa ===")
ret1 = musl_crypt_sim("aaaa", salt)
print(f"crypt返回：{ret1}")
print(f"比对结果：{''放行'' if ret1 == shadow[''testuser''] else ''拒绝''}")

print("\n=== payload：257个A ===")
ret2 = musl_crypt_sim("A"*257, salt)
print(f"比对结果：{''放行'' if ret2 == shadow[''testuser''] else ''拒绝''}")
</code></pre><h2>开发学习收获 &amp; 教训</h2><ul><li><p>第三方库、系统调用返回值<strong>不可无条件信任</strong>，文档契约和不同平台实现经常不一致。</p></li><li><p>异常分支是高危点：报错时有可能返回一个具备业务含义的字符串，而不是NULL。</p></li><li><p>单纯字符串相等是非常弱的校验，优先校验<strong>数据语义、状态</strong>，而不是只比对内容。</p></li><li><p>跨组件边界是漏洞高发区：单独看每个组件逻辑都合理，但隐性行为组合之后产生绕过。</p></li><li><p>修复优先选择语义层拦截，尽量避免写死平台私有阈值的临时hack。</p></li></ul><h2>官方参考链接</h2><ul><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="http://CVE.org">CVE.org</a><a target="_blank" rel="noopener noreferrer nofollow" href="https://cve.org/CVERecord?id=CVE-2026-123158"> 官方记录</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://nvd.nist.gov/vuln/detail/cve-2026-123158">NVD 漏洞详情</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://www.openssh.com/releasenotes.html#10.6p2">OpenSSH Release Notes 10.6p2</a></p></li><li><p><a target="_blank" rel="noopener noreferrer nofollow" href="https://sshhole.com/">sshhole 漏洞专题页</a></p></li></ul><p></p>', '5eee4f85-0aaf-4fb0-9447-cc7dc089047b'::uuid, '{}'::uuid[], '2026-11-06 15:10:19.580898+08'::timestamptz);

-- portfolio_items: 1 条
INSERT INTO portfolio_items (id, user_id, title, description, sort_order, created_at, content) VALUES
  ('0b48f5b7-d34c-4225-bbe1-8a754452529b'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'Haven', '自托管的个人知识中台', 0, '2026-10-31 20:25:44.295103+08'::timestamptz, '# Haven

一个自托管的个人知识中台。写笔记、整理目录、发布文章、展示作品集——全部跑在自己的机器上，数据只存在自己的 PostgreSQL 里。

## 为什么要自己做一套

市面上的笔记工具要么数据在别人服务器上，要么为了通用性堆了太多用不到的功能。我想要的是一个**刚好够用、完全归自己所有**的系统：

- 写给自己的笔记是私有的，需要公开时单独发布；
- 在网吧、公司、家里共用同一套数据，但凭证可以随时撤销；
- 不依赖任何 SaaS，宕机只怪自己。

## 核心设计

### 数据只存在一个地方

PostgreSQL 是唯一真值源。不引入 Redis、对象存储或任何"辅助数据库"存真值——少一个组件就少一个故障点，也少一份备份要操心。

### 鉴权按"环境可信度"分层

日常在三种环境之间切换，对安全的要求完全不同：

| 环境 | 策略 |
|---|---|
| 家里终端 | 授信设备，30 天内免二次验证 |
| 公司电脑 | 需要登录，可授信 |
| 网吧等公共机器 | 完整鉴权，离开后可远程撤销全部凭证 |

登录走「账号密码 → TOTP」两步，会话、授信设备、API Token 三类凭证彼此独立、可单独撤销。改密码会连带撤销所有会话与授信设备，但**不动 API Token**——那些可能挂在自动化脚本里。

### 公开与私有物理分离

公开站和后台跑在同一份构建上，但按域名分流：

- `example.com` —— 公开笔记、搜索、作品集，匿名可访问，**没有登录入口**；
- `app.example.com` —— 后台工作台，登录后才能进。

cookie 只发给私有域，公开域天然无凭证，CSRF 面小得多。

### 写作是 Markdown，但不用记语法

编辑器基于 Milkdown（ProseMirror），所见即所得。正文本身存的仍是 Markdown 原文，所以：

- 想改格式随时能改；
- 数据不被编辑器绑架，换个工具也能读；
- 阅读态渲染走 marked + DOMPurify，脚本与内联事件一律过滤。

### 误删不丢，改坏能回

这是二期专门补的两个能力：

- **回收站**：删除只是打一个时间戳，原位置保留，30 天内随时还原；原文件夹没了就回收到收件箱；
- **历史版本**：每次实质性编辑前留一份快照，同一篇 5 分钟内的连续修改合并成一条，避免自动保存把时间线刷爆。编辑器里点"历史"，能看到当前内容与该版本的逐行差异。

## 技术栈

| 层 | 选型 | 理由 |
|---|---|---|
| 后端 | Go + Gin | 单一二进制、部署简单 |
| 数据库 | PostgreSQL | 生成列、部分索引、递归查询都是现成的 |
| 数据访问 | `database/sql` + `pgx` | 手写 SQL，不用 ORM——查询逻辑看得见 |
| 前端 | Vue 3 + Vite + TypeScript | 纯 SPA，构建产物由后端托管 |
| 编辑器 | Milkdown | ProseMirror 内核，扩展可控 |
| 样式 | 原生 CSS | 不引组件库，全部手写 |

整套系统只有一个 Go 二进制 + 一份前端构建产物 + 一个 PostgreSQL，部署到任意一台 Linux 机器即可。

## 一些刻意的取舍

**不做多用户。** 这是单人自用系统。数据模型保留了 `user_id` 字段，是为将来可能的第二个账号留技术位，但**不提供注册、邀请、账号管理**。

**不用容器。** 同机跑的 Gogs 如果在容器里会导致 SSH 异常，为了避免同类问题，Haven 直接跑在宿主机上，用 systemd 管理。

**没有中文分词。** 搜索是 `ILIKE` 子串匹配，一两个字的查询会退化成全表扫描。数据量小，接受这个代价；语义检索留给以后。

**TUI 和 Neovim 插件暂不做。** 接口已经完备（API Token 可用），但客户端本身还没写。');

-- issues: 3 条
INSERT INTO issues (id, user_id, title, description, type, status, priority, created_at, updated_at, parent_id) VALUES
  ('9669480c-87a5-4705-8588-b41537d2c757'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '无法创建新的标签', '编辑页面无法创建新的标签', 'bug', 'done', 'high', '2026-11-04 14:09:15.253502+08'::timestamptz, '2026-11-04 14:09:15.253502+08'::timestamptz, NULL),
  ('50ed8330-7361-45e0-ac17-2872e9fade93'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '快捷键未生效', 'C-s 没有劫持', 'bug', 'done', 'medium', '2026-11-04 14:09:45.997979+08'::timestamptz, '2026-11-05 10:00:45.973201+08'::timestamptz, NULL),
  ('62e4d73c-0961-4dd1-a492-72f894224063'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, '获取当天的天气', '编辑器，斜杠命令加上当前天气，默认插入当前位置', 'feature', 'todo', 'medium', '2026-11-05 11:14:06.637389+08'::timestamptz, '2026-11-05 11:14:06.637389+08'::timestamptz, NULL);

-- issue_status_events: 3 条
INSERT INTO issue_status_events (id, issue_id, user_id, from_status, to_status, created_at) VALUES
  ('1fb9d17b-5e46-4268-b2cc-a0a336f3647f'::uuid, '50ed8330-7361-45e0-ac17-2872e9fade93'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'done', 'in_progress', '2026-11-05 10:00:44.605493+08'::timestamptz),
  ('ba23e8fc-bf7e-4662-ac16-b11d76d34ee6'::uuid, '50ed8330-7361-45e0-ac17-2872e9fade93'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, 'in_progress', 'done', '2026-11-05 10:00:45.973201+08'::timestamptz),
  ('3685deb5-b406-4faf-b3c5-53bcc8db2f4a'::uuid, '62e4d73c-0961-4dd1-a492-72f894224063'::uuid, 'dcd6d70e-0e2d-4322-847f-513de23fb161'::uuid, NULL, 'todo', '2026-11-05 11:14:06.637389+08'::timestamptz);

COMMIT;